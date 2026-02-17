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
}

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
        "paths": {},
    }))

    with patch.dict("os.environ", {
        "QUICUE_SPEC_PATH": str(spec_path),
        "QUICUE_API_TOKEN": "",
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
