"""File-based deployment lock for multi-user coordination.

Only one operator can hold the deploy lock at a time.
Lock state is persisted to a JSON file so it survives server restarts.
"""

from __future__ import annotations

import json
import time
from dataclasses import asdict, dataclass
from pathlib import Path

from app.config import settings


@dataclass
class LockState:
    locked: bool = False
    operator: str | None = None
    acquired_at: float | None = None
    expires_at: float | None = None


_state = LockState()
_loaded = False


def _lock_path() -> Path:
    return settings.deploy_lock_path


def _load() -> None:
    """Load lock state from file on first access."""
    global _state, _loaded
    if _loaded:
        return
    _loaded = True
    path = _lock_path()
    if path.exists():
        try:
            data = json.loads(path.read_text())
            _state = LockState(**data)
            # Auto-expire stale locks
            if _state.expires_at and time.time() > _state.expires_at:
                _state = LockState()
                _persist()
        except (json.JSONDecodeError, TypeError):
            _state = LockState()


def _persist() -> None:
    """Write current lock state to file."""
    path = _lock_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(asdict(_state)))


def acquire(operator: str, ttl_seconds: int = 3600) -> tuple[bool, LockState]:
    """Try to acquire the deployment lock.

    Returns (success, current_state).
    TTL defaults to 1 hour to prevent stale locks.
    """
    _load()

    # Auto-expire
    if _state.locked and _state.expires_at and time.time() > _state.expires_at:
        _state.locked = False

    if _state.locked:
        return False, _state

    now = time.time()
    _state.locked = True
    _state.operator = operator
    _state.acquired_at = now
    _state.expires_at = now + ttl_seconds
    _persist()
    return True, _state


def release(operator: str | None = None) -> tuple[bool, LockState]:
    """Release the deployment lock.

    If operator is specified, only that operator can release.
    Returns (success, current_state).
    """
    _load()

    if not _state.locked:
        return True, _state

    if operator and _state.operator != operator:
        return False, _state

    _state.locked = False
    _state.operator = None
    _state.acquired_at = None
    _state.expires_at = None
    _persist()
    return True, _state


def status() -> LockState:
    """Get current lock state."""
    _load()

    # Auto-expire
    if _state.locked and _state.expires_at and time.time() > _state.expires_at:
        _state.locked = False
        _state.operator = None
        _state.acquired_at = None
        _state.expires_at = None
        _persist()

    return _state


def is_locked_by_other(operator: str | None) -> bool:
    """Check if the lock is held by someone else."""
    _load()
    s = status()
    if not s.locked:
        return False
    if operator and s.operator == operator:
        return False
    return True
