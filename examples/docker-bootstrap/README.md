# docker-bootstrap

Create a complete Docker service stack from composable service templates.

## Key Concepts

- **`bootstrap.#DockerSite`** composes named services into a dependency graph with auto-generated `docker run` commands
- **Pre-built templates**: `#PostgresService`, `#RedisService`, `#PrometheusService`, `#GrafanaService`, `#AppService`
- Every service automatically depends on the site network
- **`boot.#BootstrapResource`** wraps services with health checks and credential collection

## The Stack

```
monitoring-net (Docker network)
    ├── mon-postgres     (PostgreSQL — Grafana backend)
    ├── mon-redis        (Redis — caching)
    ├── mon-prometheus   (Prometheus — metrics)
    ├── mon-grafana      (Grafana — dashboards, depends on postgres + prometheus)
    └── mon-alertmanager (Alertmanager — alerts, depends on prometheus)
```

## Run

```bash
# Full output
cue eval ./examples/docker-bootstrap/ -e output

# Just the generated docker run commands
cue eval ./examples/docker-bootstrap/ -e output.create_commands

# Dependency graph
cue eval ./examples/docker-bootstrap/ -e output.dependencies
```

## What it demonstrates

1. **Service composition**: Define services with typed templates, add ports/volumes/environment
2. **Automatic dependency merging**: Every service inherits network dependency; Grafana adds explicit deps on postgres and prometheus
3. **Command generation**: CUE templates produce executable `docker run` commands with correct flags
4. **Bootstrap lifecycle**: `#BootstrapResource` adds health probes and credential collection for post-deploy verification
