"""Application configuration via environment variables (QUICUE_ prefix)."""

from ipaddress import IPv4Network
from pathlib import Path

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    model_config = {"env_prefix": "QUICUE_"}

    # Spec
    spec_path: Path = Path("/app/catalogue/openapi.json")
    spec_reload_interval: int = 30  # seconds

    # Auth — default subnet is RFC 5737 TEST-NET (no real host matches).
    # Set QUICUE_TRUSTED_SUBNET to your actual network for live execution.
    api_token: str = ""
    trusted_subnet: IPv4Network = IPv4Network("198.51.100.0/24")
    trusted_proxy_ip: str = ""  # if set, trust X-Forwarded-For from this IP

    # Guacamole
    guacamole_url: str = ""
    guacamole_username: str = ""
    guacamole_password: str = ""

    # CORS — public showcase serves example data in mock mode.
    # Write endpoints (deploy/*) require auth regardless of origin.
    cors_origins: list[str] = ["*"]

    # Semantic data (JSON-LD / Hydra)
    hydra_path: Path = Path("/app/data/hydra.jsonld")
    graph_jsonld_path: Path = Path("/app/data/graph.jsonld")

    # Deployment state
    deploy_log_path: Path = Path("/app/data/deploy.jsonl")
    deploy_lock_path: Path = Path("/app/data/deploy.lock.json")

    # Execution
    ssh_key_path: Path = Path("/app/secrets/id_ed25519")
    default_timeout: int = 30
    admin_timeout: int = 120

    @property
    def guacamole_enabled(self) -> bool:
        return bool(self.guacamole_url and self.guacamole_username)


settings = Settings()
