"""Health, readiness, and service info endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Request

from app.models import HealthResponse, SpecInfo

router = APIRouter(tags=["health"])


@router.get("/healthz", response_model=HealthResponse)
async def healthz(request: Request) -> HealthResponse:
    spec = request.app.state.spec
    return HealthResponse(
        status="ok",
        spec_loaded=len(spec.routes) > 0,
        route_count=len(spec.routes),
        spec_mtime=str(spec.mtime) if spec.mtime else None,
    )


@router.get("/readyz", response_model=HealthResponse)
async def readyz(request: Request) -> HealthResponse:
    spec = request.app.state.spec
    loaded = len(spec.routes) > 0
    return HealthResponse(
        status="ok" if loaded else "not_ready",
        spec_loaded=loaded,
        route_count=len(spec.routes),
        spec_mtime=str(spec.mtime) if spec.mtime else None,
    )


@router.get("/spec-info", response_model=SpecInfo)
async def spec_info(request: Request) -> SpecInfo:
    spec = request.app.state.spec
    return SpecInfo(
        route_count=len(spec.routes),
        spec_mtime=str(spec.mtime) if spec.mtime else None,
        last_reload=spec.last_reload or None,
        categories=spec.categories,
        providers=spec.providers,
        destructive_count=spec.destructive_count,
    )
