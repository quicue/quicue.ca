#!/usr/bin/env python3
"""Universal Platform Demo — single-file FastAPI server.

Serves the explorer UI and per-tier JSON data. Supports mock and live
execution with JSONL audit log and SSE streaming.

Commands are resolved at CUE compile time. The server builds an allowlist
from tier data — only pre-compiled commands can execute. No user input
is interpolated at runtime.

Patterns:
  - Async subprocess with timeout for live execution
  - Append-only JSONL audit log

Usage:
  python3 serve.py                    # mock mode (default, safe)
  python3 serve.py --live             # live execution of CUE-bound commands
  python3 serve.py --live --port 9090 # custom port
"""

import asyncio
import json
import logging
import re
import time
from pathlib import Path
from typing import AsyncIterator, Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

BASE = Path(__file__).parent
DATA = BASE / "data"
LOG_FILE = BASE / "deploy.jsonl"

# Execution timeout for live commands (seconds)
COMMAND_TIMEOUT = 30

# Valid tier name pattern — alphanumeric + hyphens only
_TIER_RE = re.compile(r"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$")

# Allowed origins for CORS (localhost dev servers)
_CORS_ORIGINS = [
    "http://localhost:*",
    "http://127.0.0.1:*",
]


# ── Request models ──────────────────────────────────────────────────

class ExecuteRequest(BaseModel):
    tier: str = "desktop"
    resource: Optional[str] = None
    action: Optional[str] = None
    command: str = ""


class BatchItem(BaseModel):
    resource: Optional[str] = None
    action: Optional[str] = None
    command: str = ""


class BatchRequest(BaseModel):
    tier: str = "desktop"
    commands: list[BatchItem] = []


# ── Helpers ─────────────────────────────────────────────────────────

def _validate_tier(tier: str) -> None:
    """Reject tier names that could traverse the filesystem."""
    if not _TIER_RE.match(tier) or ".." in tier:
        raise HTTPException(400, f"Invalid tier name: '{tier}'")


def _build_allowlist() -> dict[str, set[str]]:
    """Build per-tier command allowlists from compiled JSON data.

    Returns {tier: {command_string, ...}} so we can validate that any
    command submitted for execution was actually resolved by CUE.
    """
    allowlist: dict[str, set[str]] = {}
    if not DATA.exists():
        return allowlist
    for path in DATA.glob("*.json"):
        tier = path.stem
        try:
            data = json.loads(path.read_text())
        except (json.JSONDecodeError, OSError) as exc:
            log.warning("Failed to load %s: %s", path, exc)
            continue
        commands = set()
        for _resource, actions in data.get("commands", {}).items():
            if not isinstance(actions, dict):
                continue
            for _action_key, cmd in actions.items():
                if isinstance(cmd, str):
                    commands.add(cmd)
        allowlist[tier] = commands
    return allowlist


async def _run_command(command: str) -> dict:
    """Execute a shell command asynchronously with timeout.

    All commands come from CUE-compiled tier data. No user input
    is interpolated at runtime.
    """
    start = time.monotonic()
    try:
        proc = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout_bytes, stderr_bytes = await asyncio.wait_for(
            proc.communicate(), timeout=COMMAND_TIMEOUT
        )
        elapsed = int((time.monotonic() - start) * 1000)
        return {
            "stdout": stdout_bytes.decode("utf-8", errors="replace"),
            "stderr": stderr_bytes.decode("utf-8", errors="replace"),
            "returncode": proc.returncode if proc.returncode is not None else 0,
            "duration_ms": elapsed,
        }
    except asyncio.TimeoutError:
        proc.kill()
        await proc.wait()
        elapsed = int((time.monotonic() - start) * 1000)
        return {
            "stdout": "",
            "stderr": f"Command timed out after {COMMAND_TIMEOUT}s",
            "returncode": -1,
            "duration_ms": elapsed,
        }


def _append_log(entry: dict) -> None:
    """Append a JSON entry to the deploy log, logging errors."""
    try:
        with open(LOG_FILE, "a") as f:
            f.write(json.dumps(entry) + "\n")
    except OSError as exc:
        log.error("Failed to write log: %s", exc)


def _read_tier_json(tier: str) -> dict:
    """Read and parse a tier's JSON data file."""
    _validate_tier(tier)
    path = DATA / f"{tier}.json"
    if not path.exists():
        raise HTTPException(404, f"Tier '{tier}' not found")
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        log.error("Corrupt tier data %s: %s", path, exc)
        raise HTTPException(500, f"Corrupt data for tier '{tier}'")


# ── App factory ─────────────────────────────────────────────────────

def create_app(live: bool = False) -> FastAPI:
    mode = "live" if live else "mock"
    allowlist = _build_allowlist()

    app = FastAPI(
        title="Universal Platform Demo",
        description=f"Same graph, 4 tiers, different commands (mode: {mode})",
        version="0.3.0",
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Static data files (built by build.sh)
    if DATA.exists():
        app.mount("/data", StaticFiles(directory=str(DATA)), name="data")

    @app.get("/")
    async def index():
        return FileResponse(BASE / "index.html")

    @app.get("/api/tiers")
    async def list_tiers():
        """List available tiers from data/ directory."""
        if not DATA.exists():
            return {"tiers": []}
        tiers = sorted(f.stem for f in DATA.glob("*.json"))
        return {"tiers": tiers}

    @app.get("/api/tier/{tier}")
    async def get_tier(tier: str):
        """Return full tier JSON (vizData + commands + analysis)."""
        return _read_tier_json(tier)

    @app.get("/api/tier/{tier}/commands")
    async def tier_commands(tier: str):
        """List all compile-time resolved commands for a tier."""
        data = _read_tier_json(tier)
        return {"tier": tier, "commands": data.get("commands", {})}

    @app.get("/api/impact/{resource}")
    async def impact(resource: str, tier: str = "desktop"):
        """Impact analysis for a resource — blast radius, ancestors, depth.

        Returns blast radius, ancestors, and depth from pre-computed closure.
        """
        _validate_tier(tier)
        data = _read_tier_json(tier)
        impact_data = data.get("impact", {})
        if resource not in impact_data:
            raise HTTPException(404, f"Resource '{resource}' not found in {tier}")
        entry = impact_data[resource]
        return {
            "resource": resource,
            "tier": tier,
            "depth": entry.get("depth", 0),
            "impact": {
                "affected": list(entry.get("affected", {}).keys()),
                "affected_count": entry.get("affected_count", 0),
            },
            "ancestors": list(entry.get("ancestors", {}).keys()),
            "ancestor_count": entry.get("ancestor_count", 0),
        }

    @app.get("/api/cab-check")
    async def cab_check(r: list[str] = Query(default=[]), tier: str = "desktop"):
        """CAB conflict check — overlap between simultaneous changes.

        Shows overlap between blast radii of simultaneous changes.
        Query: ?r=compute&r=dns&tier=desktop
        """
        if len(r) < 2:
            raise HTTPException(400, "Need at least 2 resources: ?r=X&r=Y")
        _validate_tier(tier)
        data = _read_tier_json(tier)
        impact_data = data.get("impact", {})

        # Validate all resources exist
        for name in r:
            if name not in impact_data:
                raise HTTPException(404, f"Resource '{name}' not found in {tier}")

        # Build blast radius per resource
        resources_result = {}
        blast_sets: dict[str, set[str]] = {}
        for name in r:
            entry = impact_data[name]
            affected = set(entry.get("affected", {}).keys())
            blast_sets[name] = affected
            resources_result[name] = {
                "affected_count": entry.get("affected_count", 0),
                "depth": entry.get("depth", 0),
            }

        # Overlap matrix
        overlap_matrix = {}
        conflicts = set()
        for i, a in enumerate(r):
            for b in r[i + 1 :]:
                overlap = blast_sets[a] & blast_sets[b]
                if overlap:
                    overlap_matrix[f"{a} / {b}"] = {
                        "count": len(overlap),
                        "resources": sorted(overlap),
                    }
                    conflicts |= overlap

        return {
            "tier": tier,
            "resources": resources_result,
            "overlap_matrix": overlap_matrix,
            "total_conflicted": len(conflicts),
            "total_in_blast_radius": len(
                set().union(*blast_sets.values())
            ),
        }

    @app.get("/api/risk")
    async def risk(tier: str = "desktop", limit: int = 25):
        """Risk-ranked resources by blast radius.

        Sorted by affected_count descending.
        """
        _validate_tier(tier)
        data = _read_tier_json(tier)
        impact_data = data.get("impact", {})
        spof_data = data.get("spof", [])

        # Build ranked list from impact data
        ranked = []
        spof_names = {s["name"] for s in spof_data}
        for name, entry in impact_data.items():
            ranked.append({
                "resource": name,
                "affected_count": entry.get("affected_count", 0),
                "ancestor_count": entry.get("ancestor_count", 0),
                "depth": entry.get("depth", 0),
                "is_spof": name in spof_names,
            })

        ranked.sort(key=lambda x: x["affected_count"], reverse=True)
        limit = max(1, min(limit, 100))

        return {
            "tier": tier,
            "total_resources": len(ranked),
            "spof_count": len(spof_data),
            "top_risk": ranked[:limit],
        }

    @app.get("/api/status")
    async def status():
        """Health check + mode + available tiers."""
        tiers = sorted(f.stem for f in DATA.glob("*.json")) if DATA.exists() else []
        return {"status": "ok", "mode": mode, "tiers": tiers, "live": live}

    @app.post("/api/execute")
    async def execute(body: ExecuteRequest):
        """Execute an action. In live mode, runs the actual command.

        The command must exist in the tier's compile-time allowlist.
        """
        tier = body.tier
        resource = body.resource
        action = body.action
        command = body.command

        # Validate command against allowlist
        tier_cmds = allowlist.get(tier, set())
        if command and command not in tier_cmds:
            raise HTTPException(
                403,
                f"Command not in {tier} allowlist. "
                "Only CUE-compiled commands can execute.",
            )

        if live and command:
            result = await _run_command(command)
            entry = {
                "timestamp": time.time(),
                "tier": tier,
                "resource": resource,
                "action": action,
                "command": command,
                "mode": "live",
                "output": result["stdout"] or result["stderr"],
                "returncode": result["returncode"],
                "duration_ms": result["duration_ms"],
            }
        else:
            entry = {
                "timestamp": time.time(),
                "tier": tier,
                "resource": resource,
                "action": action,
                "command": command,
                "mode": "mock",
                "output": f"[mock] Would execute: {command}",
                "returncode": 0,
                "duration_ms": 0,
            }

        _append_log(entry)
        return entry

    @app.post("/api/execute/batch")
    async def execute_batch(body: BatchRequest):
        """Execute multiple commands in deployment order.

        Expects: {"tier": "desktop", "commands": [{"resource": ..., "action": ..., "command": ...}, ...]}
        """
        tier = body.tier
        commands = body.commands
        tier_allowed = allowlist.get(tier, set())
        results = []

        for item in commands:
            cmd = item.command
            if cmd and cmd not in tier_allowed:
                results.append({
                    "resource": item.resource,
                    "action": item.action,
                    "command": cmd,
                    "error": "Not in allowlist",
                    "skipped": True,
                })
                continue

            if live and cmd:
                result = await _run_command(cmd)
                entry = {
                    "timestamp": time.time(),
                    "tier": tier,
                    "resource": item.resource,
                    "action": item.action,
                    "command": cmd,
                    "mode": "live",
                    "output": result["stdout"] or result["stderr"],
                    "returncode": result["returncode"],
                    "duration_ms": result["duration_ms"],
                }
            else:
                entry = {
                    "timestamp": time.time(),
                    "tier": tier,
                    "resource": item.resource,
                    "action": item.action,
                    "command": cmd,
                    "mode": "mock",
                    "output": f"[mock] Would execute: {cmd}",
                    "returncode": 0,
                    "duration_ms": 0,
                }

            _append_log(entry)
            results.append(entry)

            # Stop on failure in live mode
            if live and entry.get("returncode", 0) != 0:
                break

        return {"tier": tier, "results": results, "total": len(results)}

    @app.get("/api/logs/stream")
    async def log_stream():
        """SSE endpoint tailing the JSONL deployment log."""

        async def generate() -> AsyncIterator[str]:
            try:
                if LOG_FILE.exists():
                    for line in LOG_FILE.read_text().splitlines():
                        yield f"data: {line}\n\n"
                last_size = LOG_FILE.stat().st_size if LOG_FILE.exists() else 0
            except OSError:
                last_size = 0

            while True:
                await asyncio.sleep(1)
                try:
                    if LOG_FILE.exists():
                        current_size = LOG_FILE.stat().st_size
                        if current_size > last_size:
                            with open(LOG_FILE) as f:
                                f.seek(last_size)
                                for line in f:
                                    line = line.strip()
                                    if line:
                                        yield f"data: {line}\n\n"
                            last_size = current_size
                        else:
                            yield f"data: {json.dumps({'heartbeat': True})}\n\n"
                    else:
                        last_size = 0
                        yield f"data: {json.dumps({'heartbeat': True})}\n\n"
                except OSError:
                    yield f"data: {json.dumps({'heartbeat': True})}\n\n"

        return StreamingResponse(generate(), media_type="text/event-stream")

    @app.get("/api/logs/history")
    async def log_history(limit: int = 100):
        """Recent log entries (newest last)."""
        if not LOG_FILE.exists():
            return {"entries": []}
        try:
            lines = LOG_FILE.read_text().strip().splitlines()
            entries = []
            for line in lines[-limit:]:
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
            return {"entries": entries}
        except OSError as exc:
            log.error("Failed to read log: %s", exc)
            return {"entries": []}

    @app.delete("/api/logs")
    async def log_clear():
        """Clear the deployment log."""
        try:
            if LOG_FILE.exists():
                LOG_FILE.unlink()
        except OSError as exc:
            log.error("Failed to clear log: %s", exc)
        return {"cleared": True}

    # Keep POST for backwards compat (tests use it)
    @app.post("/api/logs/clear")
    async def log_clear_post():
        """Clear the deployment log (legacy POST endpoint)."""
        return await log_clear()

    return app


def _find_free_port() -> int:
    """Find a free TCP port by binding to port 0."""
    import socket

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("", 0))
        return s.getsockname()[1]


# Default app instance (mock mode) for uvicorn module import
app = create_app(live=False)

if __name__ == "__main__":
    import argparse

    import uvicorn

    parser = argparse.ArgumentParser(description="Universal Platform Demo server")
    parser.add_argument("--port", type=int, default=0, help="Port (0 = auto-select free port)")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument(
        "--live",
        action="store_true",
        help="Enable live command execution (only CUE-compiled commands)",
    )
    args = parser.parse_args()

    port = args.port if args.port != 0 else _find_free_port()

    app = create_app(live=args.live)
    mode_label = "LIVE" if args.live else "mock"
    print(f"\n  Universal Platform Demo ({mode_label} mode)")
    print(f"  http://localhost:{port}\n")
    uvicorn.run(app, host=args.host, port=port)
