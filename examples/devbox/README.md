# Devbox — Single-Machine Developer Tooling Stack

Everything runs on one host via Docker. No hypervisor, no multi-node clustering — just a clean dev environment with proper dependency tracking.

## Infrastructure (11 resources)

| Layer | Resource | Type | Purpose |
|-------|----------|------|---------|
| 0 | docker | DockerHost | Container runtime |
| 1 | postgres | Database | Backing store for Gitea, Keycloak, apps |
| 1 | redis | CacheServer | Sessions, job queues, pub/sub |
| 1 | traefik | ReverseProxy | Auto-discovery via Docker labels |
| 1 | vault-dev | Vault | Local secrets (dev mode) |
| 1 | minio | ObjectStorage | S3-compatible storage |
| 2 | gitea | SourceControlManagement | Git forge with CI |
| 2 | k3d | KubernetesCluster | Local K8s for manifest testing |
| 2 | registry | ContainerRegistry | Local image storage |
| 2 | grafana | MonitoringServer | Dashboards |
| 3 | runner | CIRunner | Gitea Actions execution |

## Deploy any app

`apps.cue` provides an `#App` template. Define an app, get a graph-integrated resource:

```cue
_apps: myapp: #App & {
    image:      "myapp:latest"
    port:       8080
    needs_db:   true
    needs_cache: true
}
```

This computes:
- A Docker resource with `@type: {DockerContainer, AppWorkload}`
- Traefik FQDN (`myapp.dev.local`)
- Dependency edges to postgres, redis, traefik (based on declared needs)
- Full graph integration — impact queries, blast radius, deployment ordering

Three example apps are included: an API (Express.js), a background worker (Celery), and a frontend (Vite). Together the devbox grows from 11 to 14 resources.

## Quick start

```bash
cue vet ./examples/devbox/
cue eval ./examples/devbox/ -e output.summary
cue eval ./examples/devbox/ -e output.deployment_plan
cue eval ./examples/devbox/ -e output.impact
```

## Contrast with other examples

| Example | Resources | Nodes | Providers | Commands | Use case |
|---------|-----------|-------|-----------|----------|----------|
| **devbox** | 14 | 1 host | 10 | 238+ | Solo developer workstation |
| homelab | 14 | 3 nodes | 12 | ~350 | Multi-node Proxmox cluster |
| datacenter | 30 | 3+ nodes | 29 | 654 | Enterprise infrastructure |
