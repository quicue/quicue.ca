"""Catch-all action router: POST /resources/{resource}/{provider}/{action}."""

from __future__ import annotations

import logging

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import JSONResponse

from app.config import settings
from app.deploy import lock
from app.deploy import log as deploy_log
from app.executor.runner import run_command
from app.models import ActionResponse, ConnectResponse
from app.spec_loader import RouteEntry, build_route_key

log = logging.getLogger(__name__)

router = APIRouter(tags=["actions"])


def _timeout_for(entry: RouteEntry) -> int:
    """Pick timeout based on category."""
    if entry.category == "admin":
        return settings.admin_timeout
    return settings.default_timeout


async def _handle_connect(
    entry: RouteEntry, execution_mode: str, request: Request
) -> ConnectResponse:
    """Handle connect-category actions: ping direct, SSH via Guacamole."""
    from app.executor.parser import parse_connect_command

    params = parse_connect_command(entry.command)

    if execution_mode == "mock":
        return ConnectResponse(
            mode="mock",
            path=entry.path,
            command=entry.command,
            provider=entry.provider,
            protocol=params.protocol,
        )

    # Ping: execute directly
    if params.protocol == "ping":
        result = await run_command(entry.command, timeout=settings.default_timeout)
        return ConnectResponse(
            mode="live",
            path=entry.path,
            command=entry.command,
            provider=entry.provider,
            protocol="ping",
            output=result.stdout or result.stderr,
            returncode=result.returncode,
            duration_ms=result.duration_ms,
        )

    # Unsupported protocols (govc console, powercli)
    if params.protocol == "unsupported":
        return ConnectResponse(
            mode="mock",
            path=entry.path,
            command=entry.command,
            provider=entry.provider,
            protocol="unsupported",
            output=f"Interactive protocol not supported: {entry.command}",
        )

    # SSH/VNC: dispatch to Guacamole
    if not settings.guacamole_enabled:
        return ConnectResponse(
            mode="mock",
            path=entry.path,
            command=entry.command,
            provider=entry.provider,
            protocol=params.protocol,
            output="Guacamole not configured",
        )

    from app.executor.guacamole import get_guacamole_client

    client = get_guacamole_client()
    try:
        conn_id, client_url = await client.create_connection(params)
        return ConnectResponse(
            mode="connect",
            path=entry.path,
            command=entry.command,
            provider=entry.provider,
            protocol=params.protocol,
            guacamole_url=client_url,
            connection_id=conn_id,
        )
    except Exception:
        log.exception("Guacamole connection failed for %s", entry.path)
        raise HTTPException(502, "Failed to create Guacamole session")


@router.post("/resources/{resource}/{provider}/{action}")
async def dispatch_action(
    resource: str,
    provider: str,
    action: str,
    request: Request,
) -> JSONResponse:
    """Route lookup → mock / live / connect dispatch."""
    key = build_route_key(resource, provider, action)
    spec = request.app.state.spec
    entry = spec.routes.get(key)

    if not entry:
        raise HTTPException(404, f"Unknown action: {key}")

    execution_mode: str = request.state.execution_mode

    # Connect category: special dispatch
    if entry.category == "connect":
        resp = await _handle_connect(entry, execution_mode, request)
        return JSONResponse(resp.model_dump())

    # Extract operator from token or header for logging
    operator = request.headers.get("x-operator", None)

    # Mock mode: return command string without executing
    if execution_mode == "mock":
        deploy_log.record_execution(
            resource=resource, provider=provider, action=action,
            command=entry.command, mode="mock", operator=operator,
            category=entry.category, destructive=entry.destructive,
        )
        return JSONResponse(
            ActionResponse(
                mode="mock",
                path=entry.path,
                command=entry.command,
                provider=entry.provider,
                category=entry.category,
                destructive=entry.destructive,
                idempotent=entry.idempotent,
            ).model_dump()
        )

    # Lock check: if lock is held by someone else, block non-idempotent actions
    if not entry.idempotent and lock.is_locked_by_other(operator):
        lock_state = lock.status()
        return JSONResponse(
            ActionResponse(
                mode="blocked",
                path=entry.path,
                command=entry.command,
                provider=entry.provider,
                category=entry.category,
                destructive=entry.destructive,
                idempotent=entry.idempotent,
                output=f"Deploy lock held by {lock_state.operator}",
            ).model_dump(),
            status_code=423,
        )

    # Destructive gate
    if entry.destructive:
        confirm = request.headers.get("x-confirm-destructive", "")
        if confirm.lower() != "yes":
            deploy_log.record_execution(
                resource=resource, provider=provider, action=action,
                command=entry.command, mode="blocked", operator=operator,
                category=entry.category, destructive=True,
            )
            return JSONResponse(
                ActionResponse(
                    mode="blocked",
                    path=entry.path,
                    command=entry.command,
                    provider=entry.provider,
                    category=entry.category,
                    destructive=True,
                    idempotent=entry.idempotent,
                    output="Destructive action requires X-Confirm-Destructive: yes header",
                ).model_dump(),
                status_code=403,
            )

    # Live execution
    timeout = _timeout_for(entry)
    result = await run_command(entry.command, timeout=timeout)

    deploy_log.record_execution(
        resource=resource, provider=provider, action=action,
        command=entry.command, mode="live", operator=operator,
        category=entry.category, destructive=entry.destructive,
        returncode=result.returncode,
        duration_ms=result.duration_ms,
        output=result.stdout or result.stderr,
    )

    return JSONResponse(
        ActionResponse(
            mode="live",
            path=entry.path,
            command=entry.command,
            provider=entry.provider,
            category=entry.category,
            output=result.stdout or result.stderr,
            returncode=result.returncode,
            duration_ms=result.duration_ms,
            destructive=entry.destructive,
            idempotent=entry.idempotent,
        ).model_dump()
    )
