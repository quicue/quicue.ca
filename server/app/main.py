"""FastAPI application factory with spec reload lifecycle."""

from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.middleware.access import AccessMiddleware
from app.routers import actions, deploy, health, hydra
from app.spec_loader import SpecState, load_spec

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
log = logging.getLogger(__name__)


async def _reload_loop(app: FastAPI) -> None:
    """Periodically check spec file mtime and reload if changed."""
    while True:
        await asyncio.sleep(settings.spec_reload_interval)
        try:
            current_mtime = settings.spec_path.stat().st_mtime
            if current_mtime != app.state.spec.mtime:
                log.info("Spec file changed, reloading...")
                app.state.spec = load_spec(settings.spec_path)
        except FileNotFoundError:
            log.warning("Spec file not found: %s", settings.spec_path)
        except Exception:
            log.exception("Error checking spec file")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Load spec on startup, run reload loop, cleanup on shutdown."""
    try:
        app.state.spec = load_spec(settings.spec_path)
    except FileNotFoundError:
        log.warning("Spec file not found at startup: %s", settings.spec_path)
        app.state.spec = SpecState()

    reload_task = asyncio.create_task(_reload_loop(app))
    try:
        yield
    finally:
        reload_task.cancel()
        try:
            await reload_task
        except asyncio.CancelledError:
            pass


def create_app() -> FastAPI:
    app = FastAPI(
        title="Datacenter Operations API",
        description=(
            "Execution gateway for quicue.ca resolved commands. "
            "All data comes from the representative datacenter example "
            "(RFC 5737 TEST-NET IPs). Unauthenticated requests run in mock mode — "
            "commands are shown but never executed."
        ),
        version="0.1.0",
        lifespan=lifespan,
    )

    # Auth is two-tier:
    #  1. AccessMiddleware sets execution_mode (mock vs live) based on token + subnet.
    #     Actions router uses this — unauthenticated callers get mock mode, not 401.
    #  2. Deploy router's _require_auth() gates write endpoints (lock, gate, drift)
    #     with a hard 401, since those modify server state regardless of mode.
    app.add_middleware(AccessMiddleware)

    if settings.cors_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.cors_origins,
            allow_methods=["GET", "POST", "OPTIONS"],
            allow_headers=["Authorization", "Content-Type", "X-Confirm-Destructive"],
        )

    app.include_router(health.router, prefix="/api/v1")
    app.include_router(actions.router, prefix="/api/v1")
    app.include_router(deploy.router, prefix="/api/v1")
    app.include_router(hydra.router, prefix="/api/v1")

    @app.get("/", include_in_schema=False)
    async def root():
        return {
            "service": "quicue-api",
            "version": "0.1.0",
            "mode": "mock (unauthenticated)",
            "data_source": "examples/datacenter/ (RFC 5737 TEST-NET)",
            "explorer": "https://demo.quicue.ca",
            "docs": "/docs",
            "health": "/api/v1/healthz",
            "spec": "/api/v1/spec-info",
            "hydra": "/api/v1/hydra",
            "graph": "/api/v1/graph.jsonld",
        }

    return app


app = create_app()
