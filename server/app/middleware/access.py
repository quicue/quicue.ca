"""Access control middleware: IP subnet + bearer token → execution_mode."""

from __future__ import annotations

import logging
from ipaddress import IPv4Address, IPv4Network

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from app.config import settings

log = logging.getLogger(__name__)


def _get_client_ip(request: Request) -> str:
    """Extract the real client IP, respecting trusted proxy."""
    if settings.trusted_proxy_ip and request.client:
        proxy_ip = request.client.host
        if proxy_ip == settings.trusted_proxy_ip:
            forwarded = request.headers.get("x-forwarded-for", "")
            if forwarded:
                return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return ""


def _check_token(request: Request) -> bool:
    """Check if a valid bearer token is present."""
    if not settings.api_token:
        return False
    auth = request.headers.get("authorization", "")
    if auth.startswith("Bearer "):
        return auth[7:] == settings.api_token
    return False


def _in_trusted_subnet(ip: str) -> bool:
    """Check if IP is within the trusted subnet."""
    try:
        return IPv4Address(ip) in settings.trusted_subnet
    except ValueError:
        return False


def resolve_execution_mode(request: Request) -> str:
    """Determine execution mode from request context.

    Returns: "mock" | "live"
    """
    client_ip = _get_client_ip(request)
    has_token = _check_token(request)
    in_subnet = _in_trusted_subnet(client_ip)

    if has_token and in_subnet:
        return "live"
    return "mock"


class AccessMiddleware(BaseHTTPMiddleware):
    """Sets request.state.execution_mode based on IP and token."""

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        request.state.execution_mode = resolve_execution_mode(request)
        return await call_next(request)
