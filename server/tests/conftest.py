"""Shared fixtures for the test suite."""

from __future__ import annotations

import json
import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def trusted_ip():
    """Patch _get_client_ip so TestClient appears on the trusted subnet.

    Starlette's TestClient sets request.client.host to "testclient" (not a
    valid IPv4 address), so _in_trusted_subnet always returns False.  This
    fixture patches the accessor to return 127.0.0.1, matching the test
    trusted subnet of 127.0.0.0/8.
    """
    with patch(
        "app.middleware.access._get_client_ip", return_value="127.0.0.1"
    ):
        yield


# Minimal OpenAPI spec for testing
SAMPLE_SPEC = {
    "openapi": "3.0.3",
    "info": {"title": "Test", "version": "0.0.1"},
    "tags": [],
    "paths": {
        "/resources/router-core/vyos/show_interfaces": {
            "post": {
                "summary": "show_interfaces",
                "description": "Show interfaces",
                "operationId": "router-core--vyos--show_interfaces",
                "tags": ["info"],
                "x-command": "ssh vyos@198.51.100.1 'show interfaces'",
                "x-idempotent": True,
                "x-provider": "vyos",
                "responses": {"200": {"description": "OK"}},
            }
        },
        "/resources/vcenter/govc/vm_power_off_hard": {
            "post": {
                "summary": "vm_power_off_hard",
                "description": "Hard power off a VM",
                "operationId": "vcenter--govc--vm_power_off_hard",
                "tags": ["admin"],
                "x-command": "govc vm.power -off /DC1/vm/web-server",
                "x-destructive": True,
                "x-provider": "govc",
                "responses": {"200": {"description": "OK"}},
            }
        },
        "/resources/pve-node1/proxmox/ping": {
            "post": {
                "summary": "ping",
                "description": "Ping a host",
                "operationId": "pve-node1--proxmox--ping",
                "tags": ["connect"],
                "x-command": "ping -c 3 198.51.100.10",
                "x-idempotent": True,
                "x-provider": "proxmox",
                "responses": {"200": {"description": "OK"}},
            }
        },
        "/resources/pve-node1/proxmox/ssh": {
            "post": {
                "summary": "ssh",
                "description": "SSH to host",
                "operationId": "pve-node1--proxmox--ssh",
                "tags": ["connect"],
                "x-command": "ssh root@198.51.100.10",
                "x-provider": "proxmox",
                "responses": {"200": {"description": "OK"}},
            }
        },
        "/resources/dns-internal/proxmox/pct_console": {
            "post": {
                "summary": "pct_console",
                "description": "Enter container console",
                "operationId": "dns-internal--proxmox--pct_console",
                "tags": ["connect"],
                "x-command": "ssh -t pve-node1 'pct enter 100'",
                "x-provider": "proxmox",
                "responses": {"200": {"description": "OK"}},
            }
        },
    },
}


@pytest.fixture
def spec_file(tmp_path: Path) -> Path:
    """Write sample spec to a temp file and return its path."""
    p = tmp_path / "openapi.json"
    p.write_text(json.dumps(SAMPLE_SPEC))
    return p


@pytest.fixture
def app_client(spec_file: Path, tmp_path: Path) -> TestClient:
    """Create a test client with the sample spec loaded."""
    deploy_log = tmp_path / "deploy.jsonl"
    deploy_lock = tmp_path / "deploy.lock.json"
    with patch.dict(
        "os.environ",
        {
            "QUICUE_SPEC_PATH": str(spec_file),
            "QUICUE_API_TOKEN": "test-token",
            "QUICUE_TRUSTED_SUBNET": "127.0.0.0/8",
            "QUICUE_DEPLOY_LOG_PATH": str(deploy_log),
            "QUICUE_DEPLOY_LOCK_PATH": str(deploy_lock),
        },
    ):
        # Reload modules so they pick up patched env vars.
        # Order matters: config first (settings object), then modules that
        # import settings (middleware, routers), then main (app factory).
        import importlib

        import app.config
        importlib.reload(app.config)

        import app.middleware.access
        importlib.reload(app.middleware.access)

        import app.deploy.lock
        importlib.reload(app.deploy.lock)

        import app.deploy.log
        importlib.reload(app.deploy.log)

        import app.routers.actions
        importlib.reload(app.routers.actions)

        import app.routers.deploy
        importlib.reload(app.routers.deploy)

        import app.routers.hydra
        importlib.reload(app.routers.hydra)

        import app.main
        importlib.reload(app.main)

        # Reset deploy lock global state (survives across tests otherwise)
        app.deploy.lock._state = app.deploy.lock.LockState()
        app.deploy.lock._loaded = False

        from app.main import create_app
        test_app = create_app()
        with TestClient(test_app) as client:
            yield client
