"""Hydra W3C JSON-LD endpoints — serves pre-computed semantic data."""

from __future__ import annotations

import copy
import json
import logging

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import JSONResponse

from app.config import settings
from app.spec_loader import build_route_key

log = logging.getLogger(__name__)
router = APIRouter(tags=["hydra"])

JSONLD_CONTENT_TYPE = "application/ld+json"


def _load_jsonld(path) -> dict | None:
    """Load a JSON-LD file, returning None if missing."""
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return None
    except json.JSONDecodeError:
        log.warning("Invalid JSON in %s", path)
        return None


def _with_commands(doc: dict, routes: dict) -> dict:
    """Add quicue:command to each operation from the route table.

    The published document carries no commands. Each class @id ends in the
    resource name; with the operation's provider and action that gives the
    route key the action router uses.
    """
    doc = copy.deepcopy(doc)
    for cls in doc.get("hydra:supportedClass", []):
        resource = str(cls.get("@id", "")).rstrip("/").rsplit("/", 1)[-1]
        for op in cls.get("hydra:supportedOperation", []):
            key = build_route_key(
                resource, op.get("quicue:provider", ""), op.get("quicue:action", "")
            )
            entry = routes.get(key)
            if entry is not None and entry.command:
                op["quicue:command"] = entry.command
    return doc


def _without_commands(doc: dict) -> dict:
    """Remove any quicue:command, in case an older document still has them."""
    doc = copy.deepcopy(doc)
    for cls in doc.get("hydra:supportedClass", []):
        for op in cls.get("hydra:supportedOperation", []):
            op.pop("quicue:command", None)
    return doc


@router.get("/hydra")
async def get_hydra(request: Request) -> JSONResponse:
    """W3C Hydra API documentation — available operations and classes.

    Commands are included only in live mode (trusted subnet and a valid
    token); everyone else gets the document without them.
    """
    data = _load_jsonld(settings.hydra_path)
    if data is None:
        raise HTTPException(404, "Hydra document not available")
    if getattr(request.state, "execution_mode", "mock") == "live":
        spec = getattr(request.app.state, "spec", None)
        data = _with_commands(data, spec.routes if spec else {})
    else:
        data = _without_commands(data)
    return JSONResponse(data, media_type=JSONLD_CONTENT_TYPE)


@router.get("/graph.jsonld")
async def get_graph(request: Request) -> JSONResponse:
    """Full infrastructure graph as W3C JSON-LD with typed IRIs."""
    data = _load_jsonld(settings.graph_jsonld_path)
    if data is None:
        raise HTTPException(404, "JSON-LD graph not available")
    return JSONResponse(data, media_type=JSONLD_CONTENT_TYPE)
