"""Hydra W3C JSON-LD endpoints — serves pre-computed semantic data.

A generic Hydra client walks: entry point (/api/v1/) -> collection
(/api/v1/resources) -> resource (/api/v1/resources/{name}) -> an action link
property (quicue:action/{provider}/{action}) whose operation, described in
the ApiDocumentation, is POSTed to the link target
(/api/v1/resources/{name}/{provider}/{action}).

The CUE exports use https://api.quicue.ca/api/v1/ in their IRIs. Every
response here rewrites that prefix to the host actually serving the
request, so the links work on a local server and on any deployment.
"""

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
CANONICAL_API = "https://api.quicue.ca/api/v1/"
HYDRA = "http://www.w3.org/ns/hydra/core#"


def _load_jsonld(path) -> dict | None:
    """Load a JSON-LD file, returning None if missing."""
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return None
    except json.JSONDecodeError:
        log.warning("Invalid JSON in %s", path)
        return None


def _api_root(request: Request) -> str:
    return f"{str(request.base_url).rstrip('/')}/api/v1/"


def _rebase(obj, api_root: str):
    """Replace the canonical API prefix in every string with api_root."""
    if isinstance(obj, str):
        return api_root + obj[len(CANONICAL_API):] if obj.startswith(CANONICAL_API) else obj
    if isinstance(obj, list):
        return [_rebase(x, api_root) for x in obj]
    if isinstance(obj, dict):
        return {_rebase(k, api_root): _rebase(v, api_root) for k, v in obj.items()}
    return obj


def _jsonld(data, request: Request, status_code: int = 200) -> JSONResponse:
    root = _api_root(request)
    return JSONResponse(
        _rebase(data, root),
        status_code=status_code,
        media_type=JSONLD_CONTENT_TYPE,
        headers={"Link": f'<{root}hydra>; rel="{HYDRA}apiDocumentation"'},
    )


def _operations(doc: dict):
    """Yield every hydra:Operation in the document, wherever it is nested."""
    stack = [doc]
    while stack:
        node = stack.pop()
        if isinstance(node, dict):
            if node.get("@type") == "hydra:Operation":
                yield node
            stack.extend(node.values())
        elif isinstance(node, list):
            stack.extend(node)


def _with_commands(doc: dict, routes: dict, resources: dict) -> dict:
    """Add quicue:command to each operation from the route table.

    Operations are per provider action, shared by every resource that has
    the action, so the command is a map of resource name to command.
    """
    doc = copy.deepcopy(doc)
    for op in _operations(doc):
        p, a = op.get("quicue:provider", ""), op.get("quicue:action", "")
        cmds = {}
        for name in resources:
            entry = routes.get(build_route_key(name, p, a))
            if entry is not None and entry.command:
                cmds[name] = entry.command
        if cmds:
            op["quicue:command"] = cmds
    return doc


def _without_commands(doc: dict) -> dict:
    """Remove any quicue:command, in case an older document still has them."""
    doc = copy.deepcopy(doc)
    for op in _operations(doc):
        op.pop("quicue:command", None)
    return doc


def _resources() -> dict:
    return _load_jsonld(settings.hydra_resources_path) or {}


@router.get("/hydra")
async def get_hydra(request: Request) -> JSONResponse:
    """W3C Hydra API documentation — classes, link properties, operations.

    Commands are included only in live mode (trusted subnet and a valid
    token); everyone else gets the document without them.
    """
    data = _load_jsonld(settings.hydra_path)
    if data is None:
        raise HTTPException(404, "Hydra document not available")
    if getattr(request.state, "execution_mode", "mock") == "live":
        spec = getattr(request.app.state, "spec", None)
        data = _with_commands(data, spec.routes if spec else {}, _resources())
    else:
        data = _without_commands(data)
    return _jsonld(data, request)


@router.get("/")
async def get_entrypoint(request: Request) -> JSONResponse:
    """hydra:EntryPoint — where a generic client starts."""
    doc = _load_jsonld(settings.hydra_path) or {}
    resources = _resources()
    return _jsonld(
        {
            "@context": doc.get("@context", {"hydra": HYDRA}),
            "@id": CANONICAL_API,
            "@type": "hydra:EntryPoint",
            "hydra:collection": {
                "@id": f"{CANONICAL_API}resources",
                "@type": "hydra:Collection",
                "hydra:totalItems": len(resources),
                "hydra:manages": {"hydra:property": "rdf:type", "hydra:object": "quicue:Resource"},
            },
        },
        request,
    )


@router.get("/resources")
async def get_collection(request: Request) -> JSONResponse:
    """hydra:Collection of every resource."""
    doc = _load_jsonld(settings.hydra_path) or {}
    resources = _resources()
    return _jsonld(
        {
            "@context": doc.get("@context", {"hydra": HYDRA}),
            "@id": f"{CANONICAL_API}resources",
            "@type": "hydra:Collection",
            "hydra:totalItems": len(resources),
            "hydra:member": [
                {"@id": r.get("@id"), "@type": r.get("@type", []), "name": name}
                for name, r in sorted(resources.items())
            ],
        },
        request,
    )


@router.get("/resources/{name}")
async def get_resource(name: str, request: Request) -> JSONResponse:
    """One resource as JSON-LD, with depends_on links and action links."""
    rep = _resources().get(name)
    if rep is None:
        raise HTTPException(404, f"Unknown resource: {name}")
    return _jsonld(rep, request)


@router.get("/graph.jsonld")
async def get_graph(request: Request) -> JSONResponse:
    """Full infrastructure graph as W3C JSON-LD with typed IRIs."""
    data = _load_jsonld(settings.graph_jsonld_path)
    if data is None:
        raise HTTPException(404, "JSON-LD graph not available")
    return JSONResponse(data, media_type=JSONLD_CONTENT_TYPE)
