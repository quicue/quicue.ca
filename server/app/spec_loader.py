"""Parse openapi.json into a route lookup table."""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

log = logging.getLogger(__name__)


@dataclass(frozen=True, slots=True)
class RouteEntry:
    path: str  # /resources/{resource}/{provider}/{action}
    resource: str
    provider: str
    action: str
    command: str  # resolved x-command
    category: str  # info | admin | monitor | connect
    description: str
    idempotent: bool = False
    destructive: bool = False


# path string → RouteEntry
RouteTable = dict[str, RouteEntry]


@dataclass
class SpecState:
    """Mutable state for the loaded spec and reload metadata."""

    routes: RouteTable = field(default_factory=dict)
    mtime: float = 0.0
    last_reload: str = ""
    categories: dict[str, int] = field(default_factory=dict)
    providers: dict[str, int] = field(default_factory=dict)
    destructive_count: int = 0


def load_spec(spec_path: Path) -> SpecState:
    """Load openapi.json and return a SpecState with the route table."""
    from datetime import datetime, timezone

    raw = json.loads(spec_path.read_text())
    paths: dict = raw.get("paths", {})

    routes: RouteTable = {}
    categories: dict[str, int] = {}
    providers: dict[str, int] = {}
    destructive_count = 0

    for path_str, path_obj in paths.items():
        op = path_obj.get("post")
        if not op:
            continue

        # Parse path: /resources/{resource}/{provider}/{action}
        parts = path_str.strip("/").split("/")
        if len(parts) != 4 or parts[0] != "resources":
            log.warning("Skipping unexpected path format: %s", path_str)
            continue

        _, resource, provider, action = parts
        tags = op.get("tags", [])
        category = tags[0] if tags else "info"
        destructive = bool(op.get("x-destructive", False))

        entry = RouteEntry(
            path=path_str,
            resource=resource,
            provider=provider,
            action=action,
            command=op.get("x-command", ""),
            category=category,
            description=op.get("description", ""),
            idempotent=bool(op.get("x-idempotent", False)),
            destructive=destructive,
        )
        routes[path_str] = entry

        categories[category] = categories.get(category, 0) + 1
        providers[provider] = providers.get(provider, 0) + 1
        if destructive:
            destructive_count += 1

    mtime = spec_path.stat().st_mtime

    state = SpecState(
        routes=routes,
        mtime=mtime,
        last_reload=datetime.now(timezone.utc).isoformat(),
        categories=categories,
        providers=providers,
        destructive_count=destructive_count,
    )
    log.info(
        "Loaded %d routes from %s (%d destructive)",
        len(routes),
        spec_path,
        destructive_count,
    )
    return state


def build_route_key(resource: str, provider: str, action: str) -> str:
    """Build the dict key used for route lookup."""
    return f"/resources/{resource}/{provider}/{action}"
