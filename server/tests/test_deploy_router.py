"""Integration tests for the deploy router endpoints."""

from __future__ import annotations

from fastapi.testclient import TestClient


AUTH = {"Authorization": "Bearer test-token"}


# -- History --


def test_history_empty(app_client: TestClient) -> None:
    resp = app_client.get("/api/v1/deploy/history")
    assert resp.status_code == 200
    data = resp.json()
    assert data["entries"] == []
    assert data["count"] == 0


def test_history_populates_after_execution(app_client: TestClient) -> None:
    """Mock execution should create a log entry."""
    app_client.post("/api/v1/resources/router-core/vyos/show_interfaces")
    resp = app_client.get("/api/v1/deploy/history")
    data = resp.json()
    assert data["count"] >= 1
    assert data["entries"][0]["resource"] == "router-core"
    assert data["entries"][0]["mode"] == "mock"


def test_history_limit(app_client: TestClient) -> None:
    for _ in range(5):
        app_client.post("/api/v1/resources/router-core/vyos/show_interfaces")
    resp = app_client.get("/api/v1/deploy/history?limit=2")
    assert resp.json()["count"] == 2


# -- Lock --


def test_lock_status_unlocked(app_client: TestClient) -> None:
    resp = app_client.get("/api/v1/deploy/lock")
    assert resp.status_code == 200
    data = resp.json()
    assert data["locked"] is False


def test_lock_acquire(app_client: TestClient) -> None:
    resp = app_client.post(
        "/api/v1/deploy/lock",
        json={"operator": "alice"},
        headers=AUTH,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["acquired"] is True
    assert data["locked"] is True
    assert data["operator"] == "alice"


def test_lock_acquire_requires_auth(app_client: TestClient) -> None:
    resp = app_client.post(
        "/api/v1/deploy/lock",
        json={"operator": "alice"},
    )
    assert resp.status_code == 401


def test_lock_conflict(app_client: TestClient) -> None:
    app_client.post("/api/v1/deploy/lock", json={"operator": "alice"}, headers=AUTH)
    resp = app_client.post(
        "/api/v1/deploy/lock",
        json={"operator": "bob"},
        headers=AUTH,
    )
    assert resp.status_code == 409
    data = resp.json()
    assert data["acquired"] is False
    assert "alice" in data["message"]


def test_lock_release(app_client: TestClient) -> None:
    app_client.post("/api/v1/deploy/lock", json={"operator": "alice"}, headers=AUTH)
    resp = app_client.request(
        "DELETE",
        "/api/v1/deploy/lock",
        json={"operator": "alice"},
        headers=AUTH,
    )
    assert resp.status_code == 200
    assert resp.json()["released"] is True


def test_lock_release_wrong_operator(app_client: TestClient) -> None:
    app_client.post("/api/v1/deploy/lock", json={"operator": "alice"}, headers=AUTH)
    resp = app_client.request(
        "DELETE",
        "/api/v1/deploy/lock",
        json={"operator": "bob"},
        headers=AUTH,
    )
    assert resp.status_code == 403
    assert resp.json()["released"] is False


# -- Gate Check --


def test_gate_check_no_monitor_routes(app_client: TestClient) -> None:
    """Resource with no monitor-category routes returns no checks."""
    resp = app_client.post(
        "/api/v1/deploy/gate/check",
        json={"resources": ["nonexistent"]},
        headers=AUTH,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["resources_checked"] == 0
    assert data["resources_skipped"] == 1


def test_gate_check_requires_auth(app_client: TestClient) -> None:
    resp = app_client.post(
        "/api/v1/deploy/gate/check",
        json={"resources": ["nonexistent"]},
    )
    assert resp.status_code == 401


def test_gate_check_validation_error(app_client: TestClient) -> None:
    resp = app_client.post(
        "/api/v1/deploy/gate/check",
        json={},
        headers=AUTH,
    )
    assert resp.status_code == 422


# -- Drift Check --


def test_drift_check_no_baseline(app_client: TestClient) -> None:
    """Drift check with no prior runs returns no_baseline."""
    resp = app_client.post(
        "/api/v1/deploy/drift/check",
        json={"resources": ["nonexistent"]},
        headers=AUTH,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["has_drift"] is False
    assert data["resources_checked"] == 1


def test_drift_check_requires_auth(app_client: TestClient) -> None:
    resp = app_client.post(
        "/api/v1/deploy/drift/check",
        json={"resources": ["nonexistent"]},
    )
    assert resp.status_code == 401


def test_drift_check_validation_error(app_client: TestClient) -> None:
    resp = app_client.post(
        "/api/v1/deploy/drift/check",
        json={},
        headers=AUTH,
    )
    assert resp.status_code == 422
