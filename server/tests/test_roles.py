"""Role tokens: each role may run only its categories live; destructive needs ops."""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.executor.runner import CommandResult
from app.roles import ROLE_CATEGORIES, can_run

OPS = {"Authorization": "Bearer test-token"}  # legacy QUICUE_API_TOKEN counts as ops
DEV = {"Authorization": "Bearer dev-token"}
RO = {"Authorization": "Bearer ro-token"}

INFO = "/api/v1/resources/router-core/vyos/show_interfaces"
ADMIN_DESTRUCTIVE = "/api/v1/resources/vcenter/govc/vm_power_off_hard"
CONNECT_PING = "/api/v1/resources/pve-node1/proxmox/ping"


def _ok():
    return CommandResult(stdout="ok", stderr="", returncode=0, duration_ms=1)


def test_can_run_table() -> None:
    assert can_run("ops", "admin", True) == (True, "")
    assert can_run("dev", "admin", False)[0] is False
    assert can_run("dev", "connect", False)[0] is True
    assert can_run("dev", "info", True)[0] is False  # destructive needs ops
    assert can_run("readonly", "info", False)[0] is True
    assert can_run("readonly", "connect", False)[0] is False
    assert can_run(None, "info", False)[0] is False
    assert can_run("nobody", "info", False)[0] is False


@pytest.mark.parametrize("headers", [OPS, DEV, RO])
def test_every_role_runs_info_live(app_client: TestClient, trusted_ip, headers) -> None:
    with patch("app.routers.actions.run_command", new_callable=AsyncMock) as run:
        run.return_value = _ok()
        resp = app_client.post(INFO, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["mode"] == "live"


def test_readonly_cannot_connect(app_client: TestClient, trusted_ip) -> None:
    resp = app_client.post(CONNECT_PING, headers=RO)
    assert resp.status_code == 403
    assert resp.json()["mode"] == "blocked"
    assert "readonly" in resp.json()["output"]


def test_dev_cannot_run_admin_even_with_confirm(app_client: TestClient, trusted_ip) -> None:
    with patch("app.routers.actions.run_command", new_callable=AsyncMock) as run:
        resp = app_client.post(
            ADMIN_DESTRUCTIVE, headers={**DEV, "X-Confirm-Destructive": "yes"}
        )
        run.assert_not_called()
    assert resp.status_code == 403
    assert resp.json()["mode"] == "blocked"


def test_ops_destructive_still_needs_confirm(app_client: TestClient, trusted_ip) -> None:
    resp = app_client.post(ADMIN_DESTRUCTIVE, headers=OPS)
    assert resp.status_code == 403
    assert "X-Confirm-Destructive" in resp.json()["output"]


def test_ops_destructive_with_confirm_runs(app_client: TestClient, trusted_ip) -> None:
    with patch("app.routers.actions.run_command", new_callable=AsyncMock) as run:
        run.return_value = _ok()
        resp = app_client.post(
            ADMIN_DESTRUCTIVE, headers={**OPS, "X-Confirm-Destructive": "yes"}
        )
    assert resp.status_code == 200
    assert resp.json()["mode"] == "live"


def test_role_token_outside_subnet_is_mock(app_client: TestClient) -> None:
    resp = app_client.post(ADMIN_DESTRUCTIVE, headers=DEV)
    assert resp.status_code == 200
    assert resp.json()["mode"] == "mock"


def test_deploy_lock_needs_ops(app_client: TestClient) -> None:
    body = {"operator": "someone", "ttl_seconds": 60}
    assert app_client.post("/api/v1/deploy/lock", json=body, headers=DEV).status_code == 403
    assert app_client.post("/api/v1/deploy/lock", json=body).status_code == 401
    assert app_client.post("/api/v1/deploy/lock", json=body, headers=OPS).status_code == 200


def test_legacy_api_token_is_ops() -> None:
    from app.config import Settings

    s = Settings(api_token="legacy", role_tokens={"dev": "d"})
    assert s.tokens_by_role == {"dev": "d", "ops": "legacy"}
    s = Settings(api_token="legacy", role_tokens={"ops": "new"})
    assert s.tokens_by_role == {"ops": "new"}


@pytest.mark.skipif(shutil.which("cue") is None, reason="cue not installed")
def test_roles_match_ou_roles_cue() -> None:
    """app/roles.py must agree with ou/roles.cue, which scopes the Hydra document."""
    repo = Path(__file__).resolve().parents[2]
    out = subprocess.run(
        ["cue", "export", "./ou/", "-e", "{for k, v in #Roles {(k): [for c, _ in v.visible_categories {c}]}}"],
        cwd=repo, capture_output=True, text=True, check=True,
        env={"CUE_REGISTRY": "none", "PATH": shutil.os.environ["PATH"],
             "HOME": shutil.os.environ.get("HOME", "/tmp")},
    )
    cue_roles = {k: frozenset(v) for k, v in json.loads(out.stdout).items()}
    assert cue_roles == ROLE_CATEGORIES


def _client_without_tokens(tmp_path, insecure: str):
    import importlib
    import json as _json

    spec = tmp_path / "openapi.json"
    spec.write_text(_json.dumps({"openapi": "3.0.3", "info": {"title": "t", "version": "0"}, "paths": {}}))
    env = {
        "QUICUE_SPEC_PATH": str(spec),
        "QUICUE_API_TOKEN": "",
        "QUICUE_ROLE_TOKENS": "{}",
        "QUICUE_INSECURE_LOCAL": insecure,
        "QUICUE_DEPLOY_LOG_PATH": str(tmp_path / "deploy.jsonl"),
        "QUICUE_DEPLOY_LOCK_PATH": str(tmp_path / "deploy.lock.json"),
    }
    with patch.dict("os.environ", env):
        import app.config
        importlib.reload(app.config)
        for mod in ("app.middleware.access", "app.deploy.lock", "app.deploy.log",
                    "app.routers.actions", "app.routers.deploy", "app.routers.hydra", "app.main"):
            importlib.reload(importlib.import_module(mod))
        import app.deploy.lock as lk
        lk._state = lk.LockState()
        lk._loaded = False
        from app.main import create_app
        return TestClient(create_app())


def test_deploy_closed_without_tokens(tmp_path) -> None:
    client = _client_without_tokens(tmp_path, "0")
    resp = client.post("/api/v1/deploy/lock", json={"operator": "x", "ttl_seconds": 60})
    assert resp.status_code == 503


def test_deploy_open_only_with_insecure_local(tmp_path) -> None:
    client = _client_without_tokens(tmp_path, "1")
    resp = client.post("/api/v1/deploy/lock", json={"operator": "x", "ttl_seconds": 60})
    assert resp.status_code == 200
