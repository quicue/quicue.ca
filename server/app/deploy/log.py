"""Append-only deployment log backed by a JSONL file.

Each line is a JSON object recording one action execution.
No external dependencies — uses stdlib json + file I/O.
"""

from __future__ import annotations

import json
import os
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

from app.config import settings


@dataclass(frozen=True, slots=True)
class LogEntry:
    timestamp: float
    resource: str
    provider: str
    action: str
    command: str
    mode: str  # live | mock | blocked | error
    returncode: int | None = None
    duration_ms: int | None = None
    output: str | None = None
    operator: str | None = None
    category: str | None = None
    destructive: bool = False


def _log_path() -> Path:
    return settings.deploy_log_path


def append(entry: LogEntry) -> None:
    """Append a log entry to the JSONL file."""
    path = _log_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "a") as f:
        f.write(json.dumps(asdict(entry)) + "\n")


def read_history(
    limit: int = 100,
    resource: str | None = None,
    since: float | None = None,
) -> list[dict[str, Any]]:
    """Read recent log entries, newest first.

    Reads the file in reverse for efficiency on large logs.
    """
    path = _log_path()
    if not path.exists():
        return []

    entries: list[dict[str, Any]] = []
    with open(path) as f:
        lines = f.readlines()

    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        if resource and entry.get("resource") != resource:
            continue
        if since and entry.get("timestamp", 0) < since:
            break  # entries are chronological, stop early

        entries.append(entry)
        if len(entries) >= limit:
            break

    return entries


def record_execution(
    resource: str,
    provider: str,
    action: str,
    command: str,
    mode: str,
    returncode: int | None = None,
    duration_ms: int | None = None,
    output: str | None = None,
    operator: str | None = None,
    category: str | None = None,
    destructive: bool = False,
) -> None:
    """Convenience wrapper to record an action execution."""
    # Truncate output to keep log manageable
    truncated = output[:2000] if output and len(output) > 2000 else output

    entry = LogEntry(
        timestamp=time.time(),
        resource=resource,
        provider=provider,
        action=action,
        command=command,
        mode=mode,
        returncode=returncode,
        duration_ms=duration_ms,
        output=truncated,
        operator=operator,
        category=category,
        destructive=destructive,
    )
    append(entry)
