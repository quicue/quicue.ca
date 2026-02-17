"""Tests for the deployment lock module."""

from __future__ import annotations

import json
import time
from pathlib import Path
from unittest.mock import patch

import pytest

from app.deploy import lock
from app.deploy.lock import LockState


@pytest.fixture(autouse=True)
def reset_lock_state(tmp_path: Path):
    """Reset module-level globals and point lock file at a temp path."""
    lock._state = LockState()
    lock._loaded = False
    lock_file = tmp_path / "deploy.lock.json"
    with patch.object(lock, "_lock_path", return_value=lock_file):
        yield lock_file


# -- acquire --


def test_acquire_unlocked():
    success, state = lock.acquire("alice")
    assert success is True
    assert state.locked is True
    assert state.operator == "alice"
    assert state.acquired_at is not None
    assert state.expires_at is not None


def test_acquire_conflict():
    lock.acquire("alice")
    success, state = lock.acquire("bob")
    assert success is False
    assert state.operator == "alice"


def test_acquire_same_operator_blocked():
    """Even the same operator can't double-acquire."""
    lock.acquire("alice")
    success, _ = lock.acquire("alice")
    assert success is False


def test_acquire_custom_ttl():
    _, state = lock.acquire("alice", ttl_seconds=120)
    assert state.expires_at == pytest.approx(state.acquired_at + 120, abs=1)


# -- release --


def test_release_by_owner():
    lock.acquire("alice")
    success, state = lock.release("alice")
    assert success is True
    assert state.locked is False
    assert state.operator is None


def test_release_by_wrong_operator():
    lock.acquire("alice")
    success, state = lock.release("bob")
    assert success is False
    assert state.locked is True
    assert state.operator == "alice"


def test_release_without_operator():
    """Release with operator=None always succeeds (force release)."""
    lock.acquire("alice")
    success, state = lock.release(None)
    assert success is True
    assert state.locked is False


def test_release_already_unlocked():
    success, state = lock.release("alice")
    assert success is True
    assert state.locked is False


# -- status --


def test_status_unlocked():
    state = lock.status()
    assert state.locked is False
    assert state.operator is None


def test_status_locked():
    lock.acquire("alice")
    state = lock.status()
    assert state.locked is True
    assert state.operator == "alice"


# -- TTL expiration --


def test_acquire_after_ttl_expired():
    """Expired lock should auto-release on next acquire."""
    lock.acquire("alice", ttl_seconds=1)
    # Simulate time passing
    lock._state.expires_at = time.time() - 1
    success, state = lock.acquire("bob")
    assert success is True
    assert state.operator == "bob"


def test_status_auto_expires():
    lock.acquire("alice", ttl_seconds=1)
    lock._state.expires_at = time.time() - 1
    state = lock.status()
    assert state.locked is False


# -- is_locked_by_other --


def test_is_locked_by_other_no_lock():
    assert lock.is_locked_by_other("alice") is False


def test_is_locked_by_other_same_operator():
    lock.acquire("alice")
    assert lock.is_locked_by_other("alice") is False


def test_is_locked_by_other_different_operator():
    lock.acquire("alice")
    assert lock.is_locked_by_other("bob") is True


def test_is_locked_by_other_none_operator():
    lock.acquire("alice")
    assert lock.is_locked_by_other(None) is True


# -- file persistence --


def test_persist_and_reload(reset_lock_state):
    lock.acquire("alice")
    # Verify file written
    data = json.loads(reset_lock_state.read_text())
    assert data["locked"] is True
    assert data["operator"] == "alice"

    # Simulate fresh module state (as if server restarted)
    lock._state = LockState()
    lock._loaded = False

    # Status should reload from file
    state = lock.status()
    assert state.locked is True
    assert state.operator == "alice"


def test_corrupt_lock_file_recovers(reset_lock_state):
    reset_lock_state.write_text("not json{{{")
    lock._loaded = False
    state = lock.status()
    assert state.locked is False


def test_expired_lock_file_auto_clears(reset_lock_state):
    data = {
        "locked": True,
        "operator": "stale",
        "acquired_at": time.time() - 7200,
        "expires_at": time.time() - 3600,
    }
    reset_lock_state.write_text(json.dumps(data))
    lock._loaded = False
    state = lock.status()
    assert state.locked is False
