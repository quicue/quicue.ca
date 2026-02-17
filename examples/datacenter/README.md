# Datacenter Example

30 resources, 29 providers, 7 deployment layers, 654 resolved commands — all from [one CUE file](datacenter.cue).

## Run

```bash
cue vet  ./examples/datacenter/
cue eval ./examples/datacenter/ -e output.summary
cue eval ./examples/datacenter/ -e output.topology
cue eval ./examples/datacenter/ -e output.criticality_top10
cue eval ./examples/datacenter/ -e output.impact
cue eval ./examples/datacenter/ -e output.health_simulation
cue export ./examples/datacenter/ -e openapi_spec --out json
```

## What it computes

From a flat list of resources with `@type` and `depends_on`, the pattern library produces:

**Graph summary:**
```json
{"total_resources": 30, "max_depth": 6, "total_edges": 29, "root_count": 1, "leaf_count": 15, "providers_used": 29}
```

**Topology** — resources grouped by dependency depth (layer 0 has no dependencies, layer N depends only on layers 0..N-1):

| Layer | Resources |
|-------|-----------|
| 0 | router-core |
| 1 | pve-node1, pve-node2, pve-node3, vcenter |
| 2 | dns-internal, backup-pbs |
| 3 | dns-external, netbox, foreman, vault, postgresql, docker-host, incus-cluster |
| 4 | keycloak, caddy-proxy, k3d-dev, k8s-prod, ansible-controller, zabbix, restic-offsite |
| 5 | nginx-web, kubevirt-vms, gitlab-scm, awx, opentofu-iac |
| 6 | argocd, gitlab-runner, dagger-ci, terraform-state |

**Criticality** — top 10 by transitive dependent count:

| Resource | Dependents |
|----------|-----------|
| router-core | 29 |
| pve-node1 | 24 |
| dns-internal | 23 |
| vault | 14 |
| pve-node2 | 13 |
| postgresql | 7 |
| pve-node3 | 6 |
| keycloak | 6 |
| caddy-proxy | 6 |
| gitlab-scm | 4 |

**Impact analysis** — "what breaks if X fails?":

| Target | Affected count |
|--------|---------------|
| router-core | 29 (everything) |
| dns-internal | 23 |
| vault | 14 |
| postgresql | 7 |
| gitlab-scm | 4 |
| k8s-prod | 3 |

**SPOF detection:** 1 single point of failure (router-core — 29 dependents, no peer redundancy).

**Health simulation** (vault goes down): 15 healthy, 14 degraded, 1 down. Degradation propagates through keycloak, caddy-proxy, k8s-prod, gitlab-scm, and everything downstream.

**Command binding:** 654 executable actions resolved at compile time across 29 providers. Every `{param}` placeholder in every command template is resolved against resource fields — no unresolved templates pass `cue vet`.

## Architecture layers

| Layer | Role | Resources | Providers |
|-------|------|-----------|-----------|
| 0 | Network/Physical | router-core | vyos |
| 1 | Hypervisors | pve-node1/2/3, vcenter | proxmox, govc, powercli |
| 2 | Core services | dns-internal, backup-pbs | powerdns, pbs |
| 3 | Security/identity/data | dns-external, netbox, foreman, vault, postgresql, docker-host, incus-cluster | cloudflare, netbox, foreman, vault, postgresql, docker, incus |
| 4 | Networking/containers/k8s | keycloak, caddy-proxy, k3d-dev, k8s-prod, ansible-controller, zabbix, restic-offsite | keycloak, caddy, k3d, kubectl, ansible, zabbix, restic |
| 5 | CI/CD/automation | nginx-web, kubevirt-vms, gitlab-scm, awx, opentofu-iac | nginx, kubevirt, gitlab, awx, opentofu |
| 6 | GitOps/IaC | argocd, gitlab-runner, dagger-ci, terraform-state | argocd, dagger, terraform |

Each resource exercises at least one of the [29 provider templates](../../template/).

## More queries

```bash
# Blast radius for a specific resource
cue eval ./examples/datacenter/ -e output.blast_radius

# Rollback plan if layer 3 deployment fails
cue eval ./examples/datacenter/ -e output.rollback_plan

# Executable commands for a specific resource
cue eval ./examples/datacenter/ -e 'output.commands."gitlab-scm"'

# Full JSON export
cue export ./examples/datacenter/ -e output --out json

# OpenAPI spec from resolved commands
cue export ./examples/datacenter/ -e openapi_spec --out json

# JSON-LD graph
cue export ./examples/datacenter/ -e jsonld --out json
```
