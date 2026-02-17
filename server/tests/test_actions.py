"""Tests for the actions router (integration tests via TestClient)."""

from __future__ import annotations

from unittest.mock import AsyncMock, patch

from fastapi.testclient import TestClient


def test_mock_mode_no_auth(app_client: TestClient) -> None:
    """No token → mock mode, returns command without executing."""
    resp = app_client.post("/api/v1/resources/router-core/vyos/show_interfaces")
    assert resp.status_code == 200
    data = resp.json()
    assert data["mode"] == "mock"
    assert data["command"] == "ssh vyos@198.51.100.1 'show interfaces'"
    assert data["provider"] == "vyos"
    assert data["category"] == "info"
    assert data["output"] is None


def test_unknown_action_404(app_client: TestClient) -> None:
    resp = app_client.post("/api/v1/resources/fake/fake/fake")
    assert resp.status_code == 404


def test_live_mode_with_auth(app_client: TestClient, trusted_ip) -> None:
    """Token + trusted subnet → live mode."""
    with patch("app.routers.actions.run_command", new_callable=AsyncMock) as mock_run:
        from app.executor.runner import CommandResult
        mock_run.return_value = CommandResult(
            stdout="eth0: up\n",
            stderr="",
            returncode=0,
            duration_ms=42,
        )
        resp = app_client.post(
            "/api/v1/resources/router-core/vyos/show_interfaces",
            headers={"Authorization": "Bearer test-token"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["mode"] == "live"
        assert data["output"] == "eth0: up\n"
        assert data["returncode"] == 0
        assert data["duration_ms"] == 42


def test_destructive_blocked_without_confirm(app_client: TestClient, trusted_ip) -> None:
    """Destructive action without confirm header → blocked."""
    resp = app_client.post(
        "/api/v1/resources/vcenter/govc/vm_power_off_hard",
        headers={"Authorization": "Bearer test-token"},
    )
    assert resp.status_code == 403
    data = resp.json()
    assert data["mode"] == "blocked"
    assert data["destructive"] is True


def test_destructive_confirmed(app_client: TestClient, trusted_ip) -> None:
    """Destructive action with confirm header → live execution."""
    with patch("app.routers.actions.run_command", new_callable=AsyncMock) as mock_run:
        from app.executor.runner import CommandResult
        mock_run.return_value = CommandResult(
            stdout="powered off",
            stderr="",
            returncode=0,
            duration_ms=100,
        )
        resp = app_client.post(
            "/api/v1/resources/vcenter/govc/vm_power_off_hard",
            headers={
                "Authorization": "Bearer test-token",
                "X-Confirm-Destructive": "yes",
            },
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["mode"] == "live"
        assert data["destructive"] is True


def test_connect_ping_mock(app_client: TestClient) -> None:
    """Connect ping in mock mode."""
    resp = app_client.post("/api/v1/resources/pve-node1/proxmox/ping")
    assert resp.status_code == 200
    data = resp.json()
    assert data["mode"] == "mock"
    assert data["protocol"] == "ping"


def test_connect_ping_live(app_client: TestClient, trusted_ip) -> None:
    """Connect ping in live mode → actually runs ping."""
    with patch("app.routers.actions.run_command", new_callable=AsyncMock) as mock_run:
        from app.executor.runner import CommandResult
        mock_run.return_value = CommandResult(
            stdout="PING 198.51.100.10: 3 packets transmitted",
            stderr="",
            returncode=0,
            duration_ms=50,
        )
        resp = app_client.post(
            "/api/v1/resources/pve-node1/proxmox/ping",
            headers={"Authorization": "Bearer test-token"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["mode"] == "live"
        assert data["protocol"] == "ping"
        assert "198.51.100.10" in data["output"]


def test_connect_ssh_mock_no_guacamole(app_client: TestClient, trusted_ip) -> None:
    """SSH connect without Guacamole configured → mock with message."""
    resp = app_client.post(
        "/api/v1/resources/pve-node1/proxmox/ssh",
        headers={"Authorization": "Bearer test-token"},
    )
    data = resp.json()
    assert data["mode"] == "mock"
    assert data["protocol"] == "ssh"
    assert "not configured" in data["output"]


def test_healthz(app_client: TestClient) -> None:
    resp = app_client.get("/api/v1/healthz")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["route_count"] == 5
    assert data["spec_loaded"] is True


def test_readyz(app_client: TestClient) -> None:
    resp = app_client.get("/api/v1/readyz")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_spec_info(app_client: TestClient) -> None:
    resp = app_client.get("/api/v1/spec-info")
    assert resp.status_code == 200
    data = resp.json()
    assert data["route_count"] == 5
    assert data["destructive_count"] == 1
    assert "info" in data["categories"]
    assert "vyos" in data["providers"]
