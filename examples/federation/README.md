# federation

Multi-site infrastructure with core/edge topology and cross-site replication.

## Key Concepts

- **`#Federation`** models multiple sites with automatic deployment ordering (core before edge)
- **`#Site`** defines a site with tier, location, network config, and resources
- **`#CrossSiteResource`** models replicated services with failover chains
- Resources are flattened across sites with site-prefix namespacing

## Topology

```
dc-core (tier: core, 198.51.100.0/24)
    ├── vyos-core (router)
    ├── powerdns (DNS)
    ├── caddy-proxy (reverse proxy)
    └── gitlab-scm (source control) ──── replicated ────┐
                                                         │
edge-remote (tier: edge, 203.0.113.0/24)                  │
    ├── wireguard-tunnel                                 │
    ├── restic-offsite (backup)                          │
    └── gitlab-scm (replica) ◄───────────────────────────┘
```

## Cross-site replication

GitLab is configured for async replication from `dc-core` to `edge-remote` with a 15-minute lag budget and manual failover.

## Run

```bash
# Full output
cue eval ./examples/federation/ -e output

# Deployment order (core deploys first)
cue eval ./examples/federation/ -e output.deployment_order

# Cross-site replication config
cue eval ./examples/federation/ -e output.cross_site
```

## Output

```
federation_name: "homelab"
deployment_order: ["dc-core", "edge-remote"]
total_resources: 6
```
