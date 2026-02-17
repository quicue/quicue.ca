"""Tests for access middleware."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

from app.middleware.access import _check_token, _get_client_ip, _in_trusted_subnet


def _make_request(
    client_host: str = "127.0.0.1",
    headers: dict | None = None,
) -> MagicMock:
    req = MagicMock()
    req.client.host = client_host
    req.headers = headers or {}
    return req


@patch("app.middleware.access.settings")
def test_check_token_valid(mock_settings: MagicMock) -> None:
    mock_settings.api_token = "secret"
    req = _make_request(headers={"authorization": "Bearer secret"})
    assert _check_token(req) is True


@patch("app.middleware.access.settings")
def test_check_token_invalid(mock_settings: MagicMock) -> None:
    mock_settings.api_token = "secret"
    req = _make_request(headers={"authorization": "Bearer wrong"})
    assert _check_token(req) is False


@patch("app.middleware.access.settings")
def test_check_token_missing(mock_settings: MagicMock) -> None:
    mock_settings.api_token = "secret"
    req = _make_request(headers={})
    assert _check_token(req) is False


@patch("app.middleware.access.settings")
def test_check_token_empty_config(mock_settings: MagicMock) -> None:
    mock_settings.api_token = ""
    req = _make_request(headers={"authorization": "Bearer anything"})
    assert _check_token(req) is False


@patch("app.middleware.access.settings")
def test_in_trusted_subnet_inside(mock_settings: MagicMock) -> None:
    from ipaddress import IPv4Network
    mock_settings.trusted_subnet = IPv4Network("198.51.100.0/24")
    assert _in_trusted_subnet("198.51.100.10") is True


@patch("app.middleware.access.settings")
def test_in_trusted_subnet_outside(mock_settings: MagicMock) -> None:
    from ipaddress import IPv4Network
    mock_settings.trusted_subnet = IPv4Network("198.51.100.0/24")
    assert _in_trusted_subnet("10.0.0.1") is False


@patch("app.middleware.access.settings")
def test_in_trusted_subnet_invalid_ip(mock_settings: MagicMock) -> None:
    from ipaddress import IPv4Network
    mock_settings.trusted_subnet = IPv4Network("198.51.100.0/24")
    assert _in_trusted_subnet("not-an-ip") is False


@patch("app.middleware.access.settings")
def test_get_client_ip_direct(mock_settings: MagicMock) -> None:
    mock_settings.trusted_proxy_ip = ""
    req = _make_request(client_host="10.0.0.5")
    assert _get_client_ip(req) == "10.0.0.5"


@patch("app.middleware.access.settings")
def test_get_client_ip_via_proxy(mock_settings: MagicMock) -> None:
    mock_settings.trusted_proxy_ip = "198.51.100.212"
    req = _make_request(
        client_host="198.51.100.212",
        headers={"x-forwarded-for": "192.168.1.100, 198.51.100.212"},
    )
    assert _get_client_ip(req) == "192.168.1.100"


@patch("app.middleware.access.settings")
def test_get_client_ip_untrusted_proxy(mock_settings: MagicMock) -> None:
    mock_settings.trusted_proxy_ip = "198.51.100.212"
    req = _make_request(
        client_host="10.0.0.99",
        headers={"x-forwarded-for": "192.168.1.100"},
    )
    # Not from trusted proxy, so ignore X-Forwarded-For
    assert _get_client_ip(req) == "10.0.0.99"
