"""Apache Guacamole REST API client for ephemeral SSH/VNC connections."""

from __future__ import annotations

import logging
from urllib.parse import quote

import httpx

from app.config import settings
from app.executor.parser import ConnectParams

log = logging.getLogger(__name__)


class GuacamoleClient:
    """Manages authentication and ephemeral connections via Guacamole REST API."""

    def __init__(self, base_url: str, username: str, password: str) -> None:
        self._base_url = base_url.rstrip("/")
        self._api = f"{self._base_url}/api"
        self._username = username
        self._password = password
        self._token: str | None = None
        self._data_source: str = "default"

    async def _authenticate(self) -> str:
        """Obtain an auth token from Guacamole."""
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self._api}/tokens",
                data={
                    "username": self._username,
                    "password": self._password,
                },
            )
            resp.raise_for_status()
            data = resp.json()
            self._token = data["authToken"]
            # Use first available data source
            sources = data.get("availableDataSources", ["default"])
            self._data_source = sources[0] if sources else "default"
            return self._token

    async def _ensure_token(self) -> str:
        if not self._token:
            return await self._authenticate()
        return self._token

    async def create_connection(
        self, params: ConnectParams
    ) -> tuple[str, str]:
        """Create an ephemeral connection and return (connection_id, client_url).

        The connection is created as a temporary connection in Guacamole.
        """
        token = await self._ensure_token()

        protocol = params.guacamole_protocol
        conn_name = f"quicue-{params.hostname}-{params.username or protocol}"

        body: dict = {
            "name": conn_name,
            "parentIdentifier": "ROOT",
            "protocol": protocol,
            "parameters": self._build_params(params),
            "attributes": {
                "max-connections": "1",
                "max-connections-per-user": "1",
            },
        }

        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self._api}/session/data/{self._data_source}/connections",
                params={"token": token},
                json=body,
            )
            if resp.status_code == 401:
                # Token expired, re-auth and retry
                token = await self._authenticate()
                resp = await client.post(
                    f"{self._api}/session/data/{self._data_source}/connections",
                    params={"token": token},
                    json=body,
                )
            resp.raise_for_status()
            data = resp.json()

        conn_id = data["identifier"]
        # Build client URL: base/#/client/{encoded_id}
        # Guacamole client ID format: {conn_id}\0c\0{data_source}
        client_id = f"{conn_id}\0c\0{self._data_source}"
        encoded = quote(client_id, safe="")
        client_url = f"{self._base_url}/#/client/{encoded}?token={token}"

        log.info(
            "Created Guacamole %s connection %s to %s",
            protocol,
            conn_id,
            params.hostname,
        )
        return conn_id, client_url

    def _build_params(self, params: ConnectParams) -> dict[str, str]:
        """Build Guacamole connection parameters from ConnectParams."""
        if params.guacamole_protocol == "ssh":
            p: dict[str, str] = {
                "hostname": params.hostname,
                "port": str(params.port),
            }
            if params.username:
                p["username"] = params.username
            if settings.ssh_key_path.exists():
                p["private-key"] = settings.ssh_key_path.read_text()
            if params.command:
                p["command"] = params.command
            return p

        # VNC
        return {
            "hostname": params.hostname,
            "port": "5900",
        }

    async def delete_connection(self, conn_id: str) -> None:
        """Delete an ephemeral connection (cleanup)."""
        token = await self._ensure_token()
        async with httpx.AsyncClient() as client:
            resp = await client.delete(
                f"{self._api}/session/data/{self._data_source}/connections/{conn_id}",
                params={"token": token},
            )
            if resp.status_code == 404:
                return  # already gone
            resp.raise_for_status()
        log.info("Deleted Guacamole connection %s", conn_id)


_client: GuacamoleClient | None = None


def get_guacamole_client() -> GuacamoleClient:
    """Get or create the singleton Guacamole client."""
    global _client
    if _client is None:
        _client = GuacamoleClient(
            base_url=settings.guacamole_url,
            username=settings.guacamole_username,
            password=settings.guacamole_password,
        )
    return _client
