"""Response models for the operations API."""

from __future__ import annotations

from pydantic import BaseModel


class ActionResponse(BaseModel):
    mode: str  # "mock" | "live" | "blocked" | "connect"
    path: str
    command: str
    provider: str
    category: str
    output: str | None = None
    returncode: int | None = None
    duration_ms: int | None = None
    destructive: bool = False
    idempotent: bool = False


class ConnectResponse(BaseModel):
    mode: str  # "connect"
    path: str
    command: str
    provider: str
    protocol: str  # "ssh" | "vnc" | "ping" | "unsupported"
    guacamole_url: str | None = None
    connection_id: str | None = None
    output: str | None = None  # for ping (direct execute)
    returncode: int | None = None
    duration_ms: int | None = None


class HealthResponse(BaseModel):
    status: str
    spec_loaded: bool
    route_count: int
    spec_mtime: str | None = None


class SpecInfo(BaseModel):
    route_count: int
    spec_mtime: str | None = None
    last_reload: str | None = None
    categories: dict[str, int]
    providers: dict[str, int]
    destructive_count: int
