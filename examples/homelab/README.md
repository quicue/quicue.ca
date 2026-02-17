# homelab

Reference homelab — deployable on any supported provider stack.

A complete 3-node homelab with 14 resources: router, reverse proxy, git forge, secrets manager, database, monitoring, backup, and container workloads. Swap `providers.cue` to target your platform.

## Quick start

1. Copy this directory
2. Edit `_site` in `homelab.cue` with your subnet and domain
3. Edit `providers.cue` to match your stack (default: Proxmox)
4. Run: `cue export ./examples/homelab/ -e output --out json`

## Resources (14)

| Layer | Resources | Purpose |
|-------|-----------|---------|
| 0 | router | Core routing |
| 0 | node-a, node-b, node-c | Compute nodes |
| 1 | dns, reverse-proxy | Name resolution, TLS termination |
| 2 | vault, database | Secrets management, PostgreSQL |
| 3 | gitea, docker-host, wiki | Git forge, containers, documentation |
| 4 | monitoring, backup, restic-offsite | Zabbix, PBS, off-site encryption |

## Provider stacks

Default is Proxmox. To switch, replace the provider declarations in `providers.cue`:

| Stack | Providers |
|-------|-----------|
| **Proxmox** (default) | proxmox, vyos, powerdns, caddy, vault, postgresql, docker, zabbix, pbs, restic, nginx, gitlab |
| **Docker-only** | docker, caddy, vault, postgresql, zabbix, restic, nginx, gitlab |
| **Kubernetes** | kubectl, argocd, vault, postgresql, zabbix, restic, gitlab |
| **Incus** | incus, vyos, powerdns, caddy, vault, postgresql, docker, zabbix, restic, nginx, gitlab |

Only providers whose `@type` values overlap with resource `@type` values will bind. Unmatched providers are silently ignored.

## Run

```bash
# Validate
cue vet ./examples/homelab/

# Summary
cue eval ./examples/homelab/ -e output.summary

# What breaks if the router dies?
cue eval ./examples/homelab/ -e output.impact.router

# Blast radius
cue eval ./examples/homelab/ -e output.blast_radius

# Deployment plan
cue eval ./examples/homelab/ -e output.deployment_plan

# Executable commands for the router
cue eval ./examples/homelab/ -e output.commands.router

# All commands as JSON
cue export ./examples/homelab/ -e output.commands --out json

# JSON-LD graph
cue export ./examples/homelab/ -e jsonld --out json
```

## Output summary

```
total_resources: 14
max_depth:       4
total_edges:     13
root_count:      1
leaf_count:      5

binding_summary:
  total_resources: 14
  total_providers: 12
  resolved_commands: 233
```

Router blast radius: 13/14 resources affected (total SPOF).
DNS blast radius: 8/14 resources affected, 1 safe peer.
