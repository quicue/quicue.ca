# Devbox — Single-Machine Developer Tooling Stack

Everything runs on one host via Docker. No hypervisor, no multi-node clustering — just a clean dev environment with proper dependency tracking.

## Resources (11)

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
| **devbox** | 11 | 1 host | 10 | 238 | Solo developer workstation |
| homelab | 14 | 3 nodes | 12 | ~350 | Multi-node Proxmox cluster |
| datacenter | 30 | 3+ nodes | 29 | 654 | Enterprise infrastructure |
