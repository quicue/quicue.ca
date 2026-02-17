"""Hydra W3C JSON-LD endpoints — serves pre-computed semantic data."""

from __future__ import annotations

import json
import logging

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import JSONResponse

from app.config import settings

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


@router.get("/hydra")
async def get_hydra(request: Request) -> JSONResponse:
    """W3C Hydra API documentation — available operations and classes."""
    data = _load_jsonld(settings.hydra_path)
    if data is None:
        raise HTTPException(404, "Hydra document not available")
    return JSONResponse(data, media_type=JSONLD_CONTENT_TYPE)


@router.get("/graph.jsonld")
async def get_graph(request: Request) -> JSONResponse:
    """Full infrastructure graph as W3C JSON-LD with typed IRIs."""
    data = _load_jsonld(settings.graph_jsonld_path)
    if data is None:
        raise HTTPException(404, "JSON-LD graph not available")
    return JSONResponse(data, media_type=JSONLD_CONTENT_TYPE)
