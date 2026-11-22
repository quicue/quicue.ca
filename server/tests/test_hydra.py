"""Tests for Hydra JSON-LD endpoints."""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import patch

from fastapi.testclient import TestClient

SAMPLE_HYDRA = {
    "@context": {"hydra": "http://www.w3.org/ns/hydra/core#"},
    "@type": "hydra:ApiDocumentation",
    "hydra:title": "test",
    "hydra:entrypoint": "/api/v1/",
    "hydra:supportedClass": [
        {
            "@id": "https://api.quicue.ca/api/v1/resources/router-core",
            "@type": "hydra:Class",
            "hydra:supportedOperation": [
                {
                    "@type": "hydra:Operation",
                    "hydra:method": "POST",
                    "quicue:provider": "vyos",
                    "quicue:action": "show_interfaces",
                    # an older document that still carries the command
                    "quicue:command": "ssh vyos@198.51.100.1 'show interfaces'",
                }
            ],
        }
    ],
}

SAMPLE_PATHS = {
    "/resources/router-core/vyos/show_interfaces": {
        "post": {
            "summary": "show_interfaces",
            "description": "Show interfaces",
            "operationId": "router-core--vyos--show_interfaces",
            "tags": ["info"],
            "x-command": "ssh vyos@198.51.100.1 'show interfaces'",
            "x-idempotent": True,
        }
    }
}

TOKEN = "test-token"

SAMPLE_GRAPH = {
    "@context": {"quicue": "https://quicue.ca/vocab#"},
    "@graph": [
        {"@id": "urn:test:router", "@type": ["Router"], "name": "router-core"},
    ],
}


def _make_client(tmp_path: Path, hydra=True, graph=True) -> TestClient:
    """Build a test client with optional Hydra/graph files."""
    hydra_path = tmp_path / "hydra.jsonld"
    graph_path = tmp_path / "graph.jsonld"
    spec_path = tmp_path / "openapi.json"

    if hydra:
        hydra_path.write_text(json.dumps(SAMPLE_HYDRA))
    if graph:
        graph_path.write_text(json.dumps(SAMPLE_GRAPH))
    spec_path.write_text(json.dumps({
        "openapi": "3.0.3",
        "info": {"title": "Test", "version": "0.0.1"},
        "tags": [],
        "paths": SAMPLE_PATHS,
    }))

    with patch.dict("os.environ", {
        "QUICUE_SPEC_PATH": str(spec_path),
        "QUICUE_API_TOKEN": TOKEN,
        "QUICUE_TRUSTED_SUBNET": "127.0.0.0/8",
        "QUICUE_HYDRA_PATH": str(hydra_path),
        "QUICUE_GRAPH_JSONLD_PATH": str(graph_path),
        "QUICUE_DEPLOY_LOG_PATH": str(tmp_path / "deploy.jsonl"),
        "QUICUE_DEPLOY_LOCK_PATH": str(tmp_path / "deploy.lock.json"),
    }):
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

        app.deploy.lock._state = app.deploy.lock.LockState()
        app.deploy.lock._loaded = False

        from app.main import create_app
        test_app = create_app()
        return TestClient(test_app)


def test_hydra_endpoint(tmp_path):
    client = _make_client(tmp_path)
    resp = client.get("/api/v1/hydra")
    assert resp.status_code == 200
    assert resp.headers["content-type"] == "application/ld+json"
    data = resp.json()
    assert data["@type"] == "hydra:ApiDocumentation"


def test_graph_endpoint(tmp_path):
    client = _make_client(tmp_path)
    resp = client.get("/api/v1/graph.jsonld")
    assert resp.status_code == 200
    assert resp.headers["content-type"] == "application/ld+json"
    data = resp.json()
    assert len(data["@graph"]) == 1


def test_hydra_404_when_missing(tmp_path):
    client = _make_client(tmp_path, hydra=False)
    resp = client.get("/api/v1/hydra")
    assert resp.status_code == 404


def test_graph_404_when_missing(tmp_path):
    client = _make_client(tmp_path, graph=False)
    resp = client.get("/api/v1/graph.jsonld")
    assert resp.status_code == 404


def test_root_includes_hydra_links(tmp_path):
    client = _make_client(tmp_path)
    resp = client.get("/")
    data = resp.json()
    assert "hydra" in data
    assert "graph" in data


def _ops(data):
    return [op for c in data["hydra:supportedClass"] for op in c["hydra:supportedOperation"]]


def test_hydra_mock_mode_has_no_commands(tmp_path):
    client = _make_client(tmp_path)
    data = client.get("/api/v1/hydra").json()
    assert all("quicue:command" not in op for op in _ops(data))


def test_hydra_token_outside_subnet_has_no_commands(tmp_path):
    client = _make_client(tmp_path)
    resp = client.get("/api/v1/hydra", headers={"Authorization": f"Bearer {TOKEN}"})
    assert all("quicue:command" not in op for op in _ops(resp.json()))


def test_hydra_live_mode_adds_commands(tmp_path):
    # _make_client reloads app.middleware.access, so patch the client IP
    # afterwards; the context manager runs the lifespan that loads the routes
    client = _make_client(tmp_path)
    with client, patch("app.middleware.access._get_client_ip", return_value="127.0.0.1"):
        resp = client.get("/api/v1/hydra", headers={"Authorization": f"Bearer {TOKEN}"})
    (op,) = _ops(resp.json())
    assert op["quicue:command"] == "ssh vyos@198.51.100.1 'show interfaces'"
    assert op["hydra:method"] == "POST"
