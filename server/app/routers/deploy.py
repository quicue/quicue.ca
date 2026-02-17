"""Deployment operations: log, lock, health gates, drift detection."""

from __future__ import annotations

import logging
import time
from dataclasses import asdict

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.config import settings
from app.deploy import lock, log
from app.executor.runner import run_command
from app.spec_loader import build_route_key


def _require_auth(request: Request) -> None:
    """Reject unauthenticated requests on write endpoints."""
    if not settings.api_token:
        return  # no token configured, allow all
    auth = request.headers.get("authorization", "")
    if auth.startswith("Bearer ") and auth[7:] == settings.api_token:
        return
    raise HTTPException(401, "Authentication required")

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/deploy", tags=["deploy"])


# -- Models --


class LockRequest(BaseModel):
    operator: str
    ttl_seconds: int = 3600


class LockReleaseRequest(BaseModel):
    operator: str | None = None


class GateCheckRequest(BaseModel):
    resources: list[str]


class DriftCheckRequest(BaseModel):
    resources: list[str]


# -- Deployment Log --


@router.get("/history")
async def get_history(
    limit: int = 100,
    resource: str | None = None,
    since: float | None = None,
) -> JSONResponse:
    """Get deployment execution history."""
    entries = log.read_history(limit=limit, resource=resource, since=since)
    return JSONResponse({"entries": entries, "count": len(entries)})


# -- Deployment Lock --


@router.get("/lock")
async def get_lock_status() -> JSONResponse:
    """Check current lock state."""
    state = lock.status()
    return JSONResponse(asdict(state))


@router.post("/lock")
async def acquire_lock(body: LockRequest, request: Request) -> JSONResponse:
    """Acquire the deployment lock."""
    _require_auth(request)
    success, state = lock.acquire(body.operator, body.ttl_seconds)
    if not success:
        return JSONResponse(
            {
                "acquired": False,
                "message": f"Lock held by {state.operator}",
                **asdict(state),
            },
            status_code=409,
        )
    return JSONResponse({"acquired": True, **asdict(state)})


@router.delete("/lock")
async def release_lock(body: LockReleaseRequest, request: Request) -> JSONResponse:
    """Release the deployment lock."""
    _require_auth(request)
    success, state = lock.release(body.operator)
    if not success:
        return JSONResponse(
            {
                "released": False,
                "message": f"Lock held by {state.operator}, not {body.operator}",
                **asdict(state),
            },
            status_code=403,
        )
    return JSONResponse({"released": True, **asdict(state)})


# -- Health Gate --


@router.post("/gate/check")
async def gate_check(body: GateCheckRequest, request: Request) -> JSONResponse:
    """Run all monitor-category actions for the given resources.

    Returns per-resource health status for gate validation.
    """
    _require_auth(request)
    spec = request.app.state.spec
    results: dict[str, dict] = {}

    for resource_name in body.resources:
        resource_results: dict[str, dict] = {}
        # Find all monitor-category routes for this resource
        for key, entry in spec.routes.items():
            if not key.startswith(f"/resources/{resource_name}/"):
                continue
            if entry.category != "monitor":
                continue

            try:
                result = await run_command(entry.command, timeout=15)
                resource_results[f"{entry.provider}/{entry.path.split('/')[-1]}"] = {
                    "status": "pass" if result.returncode == 0 else "fail",
                    "returncode": result.returncode,
                    "output": (result.stdout or result.stderr)[:500],
                    "duration_ms": result.duration_ms,
                    "command": entry.command,
                }
            except Exception as e:
                resource_results[f"{entry.provider}/error"] = {
                    "status": "error",
                    "output": str(e),
                }

        healthy = all(
            r["status"] == "pass" for r in resource_results.values()
        )
        results[resource_name] = {
            "healthy": healthy if resource_results else None,
            "checks": resource_results,
            "check_count": len(resource_results),
        }

    all_healthy = all(
        r["healthy"] is True for r in results.values() if r["healthy"] is not None
    )
    checked_count = sum(1 for r in results.values() if r["checks"])

    return JSONResponse({
        "gate_pass": all_healthy,
        "resources_checked": checked_count,
        "resources_skipped": len(body.resources) - checked_count,
        "results": results,
    })


# -- Drift Detection --


@router.post("/drift/check")
async def drift_check(body: DriftCheckRequest, request: Request) -> JSONResponse:
    """Compare current monitor outputs against last known good state.

    For each resource, runs monitor actions and compares output
    against the most recent successful execution in the deploy log.
    """
    _require_auth(request)
    spec = request.app.state.spec
    drift_results: dict[str, dict] = {}

    for resource_name in body.resources:
        resource_drift: dict[str, dict] = {}

        for key, entry in spec.routes.items():
            if not key.startswith(f"/resources/{resource_name}/"):
                continue
            if entry.category != "monitor":
                continue

            action_name = entry.path.split("/")[-1]
            action_key = f"{entry.provider}/{action_name}"

            # Get last known good output from log
            history = log.read_history(
                limit=1, resource=resource_name
            )
            last_output = None
            for h in history:
                if (
                    h.get("provider") == entry.provider
                    and h.get("action") == action_name
                    and h.get("returncode") == 0
                ):
                    last_output = h.get("output")
                    break

            # Run current check
            try:
                result = await run_command(entry.command, timeout=15)
                current_output = (result.stdout or result.stderr)[:500]
                current_ok = result.returncode == 0
            except Exception as e:
                current_output = str(e)
                current_ok = False

            if last_output is None:
                drift_status = "no_baseline"
            elif not current_ok:
                drift_status = "degraded"
            elif current_output.strip() != last_output.strip():
                drift_status = "drifted"
            else:
                drift_status = "ok"

            resource_drift[action_key] = {
                "drift": drift_status,
                "current": current_output,
                "baseline": last_output,
                "command": entry.command,
            }

        has_drift = any(
            d["drift"] in ("drifted", "degraded")
            for d in resource_drift.values()
        )
        drift_results[resource_name] = {
            "drifted": has_drift,
            "checks": resource_drift,
        }

    total_drifted = sum(1 for r in drift_results.values() if r["drifted"])
    return JSONResponse({
        "has_drift": total_drifted > 0,
        "resources_drifted": total_drifted,
        "resources_checked": len(drift_results),
        "results": drift_results,
    })
