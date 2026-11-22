"""Access control middleware: IP subnet + bearer token → role and execution_mode."""

from __future__ import annotations

import hmac
import logging
from ipaddress import IPv4Address, IPv4Network

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from app.config import settings
from app.roles import ROLE_CATEGORIES

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


def resolve_role(request: Request) -> str | None:
    """Return the role whose token the request carries, or None.

    Tokens are compared in constant time. Unknown role names in the
    configuration are ignored with a warning.
    """
    auth = request.headers.get("authorization", "")
    if not auth.startswith("Bearer "):
        return None
    presented = auth[7:].encode()
    for role, token in settings.tokens_by_role.items():
        if role not in ROLE_CATEGORIES:
            log.warning("Ignoring token for unknown role %r", role)
            continue
        if hmac.compare_digest(presented, token.encode()):
            return role
    return None


def _check_token(request: Request) -> bool:
    """Check if a valid bearer token for any role is present."""
    return resolve_role(request) is not None


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


def resolve_live_role(request: Request) -> str | None:
    """The request's role if it is in live mode, else None."""
    if not _in_trusted_subnet(_get_client_ip(request)):
        return None
    return resolve_role(request)


class AccessMiddleware(BaseHTTPMiddleware):
    """Sets request.state.role and execution_mode from IP and token."""

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        request.state.role = resolve_live_role(request)
        request.state.execution_mode = "live" if request.state.role else "mock"
        return await call_next(request)
