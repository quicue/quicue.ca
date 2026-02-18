# quicue.ca/server — FastAPI Execution Gateway

HTTP API for command execution and state management against CUE-generated execution specs.

**Live instance:** [api.quicue.ca](https://api.quicue.ca/) (mock mode — [Swagger docs](https://api.quicue.ca/docs))

## Overview

The server module implements a FastAPI gateway that executes commands from CUE-generated execution plans. Supports mock (dry-run), live (execute), and blocked modes. Manages execution history, credentials, and role-based dispatch.

The [operator](https://ops.quicue.ca/) frontend (`exec.js`) connects to this API for interactive command execution.

## Configuration

The server is configured via environment variables with `QUICUE_` prefix (pydantic `BaseSettings`). See `.env.example` for a template.

- **spec_path**: Path to OpenAPI spec JSON (default: /app/catalogue/openapi.json)
- **spec_reload_interval**: Reload interval in seconds (default: 30)
- **api_token**: Bearer token for authentication (default: "")
- **trusted_subnet**: IPv4 network for local auth (default: 198.51.100.0/24)
- **trusted_proxy_ip**: If set, trust X-Forwarded-For from this IP
- **guacamole_url**, **guacamole_username**, **guacamole_password**: Guacamole integration
- **cors_origins**: CORS-allowed origins (default: ["https://ops.quicue.ca"])
- **hydra_path**: Path to Hydra JSON-LD (default: /app/data/hydra.jsonld)
- **graph_jsonld_path**: Path to graph JSON-LD (default: /app/data/graph.jsonld)
- **deploy_log_path**: Deployment log (JSONL) (default: /app/data/deploy.jsonl)
- **deploy_lock_path**: Deployment lock file (default: /app/data/deploy.lock.json)
- **ssh_key_path**: SSH private key for execution (default: /app/secrets/id_ed25519)
- **default_timeout**: Default command timeout in seconds (default: 30)
- **admin_timeout**: Admin command timeout (default: 120)

## Modes

- **Mock** (dry-run): Print commands without executing — the default for `api.quicue.ca`
- **Live**: Execute commands and return output
- **Blocked**: Reject execution (audit/approval pending)

## API Endpoints

- `GET /api/v1/healthz` — Health check
- `GET /api/v1/readyz` — Readiness check
- `GET /api/v1/spec-info` — Loaded spec summary (providers, categories, route count)
- `POST /api/v1/resources/{resource}/{provider}/{action}` — Execute action on resource
- `GET /api/v1/hydra` — W3C Hydra API documentation (JSON-LD)
- `GET /api/v1/graph.jsonld` — Infrastructure graph as JSON-LD
- `GET /api/v1/deploy/history` — Deployment history
- `GET /api/v1/deploy/lock` — Deployment lock status
- `POST /api/v1/deploy/lock` — Acquire lock (auth required)
- `DELETE /api/v1/deploy/lock` — Release lock (auth required)
- `POST /api/v1/deploy/gate/check` — Deployment gate check (auth required)
- `POST /api/v1/deploy/drift/check` — Drift detection (auth required)

## Integration Points

- Reads OpenAPI spec from `ou.#ApiDocumentation` (Hydra)
- Loads execution state from CUE-generated JSON-LD
- Tracks deployments in JSONL log with lock file for concurrency control
- Executes via SSH (key-based) or Guacamole (console access)

## Usage

```bash
# Export CUE data to feed the server
cue export ./examples/datacenter/ -e openapi_spec --out json > catalogue/public/openapi.json
cue export ./examples/datacenter/ -e datacenter_hydra --out json > data/hydra.jsonld
cue export ./examples/datacenter/ -e jsonld --out json > data/graph.jsonld

# Start server with Docker Compose
docker compose up -d

# Query the live API
curl https://api.quicue.ca/api/v1/healthz
curl https://api.quicue.ca/api/v1/spec-info
curl https://api.quicue.ca/api/v1/graph.jsonld

# Execute an action (mock mode — returns command without running it)
curl -X POST https://api.quicue.ca/api/v1/resources/router-core/vyos/show_interfaces
```

## Files

- `app/config.py` — Settings schema
- `app/main.py` — FastAPI application
- `app/routers/` — Endpoint handlers (health, actions, deploy, hydra)
- `app/executor/` — SSH/Guacamole execution
- `app/deploy/` — Deployment state management (lock, log)
- `app/middleware/` — Access control
- `Dockerfile` — Container build
- `docker-compose.yml` — Dev environment
- `.env.example` — Environment variable template
- `update-server.sh` — Deploy script (export CUE data, push to API server)

## See Also

- `ou/` — Hydra API documentation schema
- `patterns/` — Execution plan generation
- [ops.quicue.ca](https://ops.quicue.ca/) — Operator frontend (graph explorer, planner, browse)
