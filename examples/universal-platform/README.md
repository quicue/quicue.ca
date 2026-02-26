# Universal Platform

Change impact analysis for infrastructure at any scale.

Click a resource, see its blast radius, ancestors, safe shutdown/startup
sequence, and SPOF status. Select multiple resources in CAB Check mode to
see overlap between simultaneous changes. Switch tiers to see the same
topology with different provider commands.

The dependency edges don't change — only the `@type` annotations and the
commands that resolve from them. A laptop Docker stack and a VMware
datacenter have the same blast radius, the same deployment order, the same
single points of failure.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Validate CUE, build JSON data, run tests
make test

# Start the explorer (builds data first)
make demo
# Open http://localhost:<port> (port printed to console)

# Or with live command execution (requires Docker for desktop tier)
make up              # start Docker containers
make build           # compile CUE → JSON
make serve-live      # start server in live mode
```

## API

Impact analysis endpoints follow a common contract shape for
infrastructure graph servers:

| Endpoint | Method | Returns |
|----------|--------|---------|
| `/api/impact/{resource}?tier=` | GET | Blast radius, ancestors, depth |
| `/api/cab-check?r=X&r=Y&tier=` | GET | Overlap matrix, compound risk |
| `/api/risk?tier=&limit=` | GET | Resources ranked by blast radius |
| `/api/tier/{tier}` | GET | Full tier data (vizData, commands, closure, impact, spof) |
| `/api/tiers` | GET | Available tiers |
| `/api/execute` | POST | Execute a CUE-compiled command (mock or live) |

All analysis data is pre-computed by CUE at build time. The server reads
from static JSON files — no runtime graph traversal.

## Tiers

| Tier | Providers | Compute | Services |
|------|-----------|---------|----------|
| **Desktop** | docker | DockerHost | Docker containers |
| **Node** | proxmox, docker, powerdns, caddy, postgresql, zabbix | VirtualizationPlatform | LXC + Docker |
| **Cluster** | k3d, kubectl | KubernetesCluster | K8s deployments |
| **Enterprise** | govc, powerdns, caddy, postgresql, vault, zabbix | VMwareCluster | VMs + full ops |

## Graph

```
gateway (layer 0)          auth (layer 0)          storage (layer 0)
├── dns (layer 1)          │                       ├── database (layer 1)
│   └── proxy (layer 2)    │                       ├── cache (layer 1)
│       └─┐                │                       └── queue (layer 1)
│         api (layer 3) ←──┤←── database, proxy        │
│         ├── frontend (4) │                       worker (layer 2) ←── queue, database
│         ├── admin (4) ←──┘                       ├── scheduler (4) ←── worker, api
│         ├── monitoring (4) ←── worker            └── backup (2) ←── database, storage
│         └── scheduler (4) ←── worker
```

19 edges, 5 layers, 3 independent roots, non-trivial blast radii.
Storage affects 10 downstream, gateway 7, database 7, auth 5.
Identical across all 4 tiers.

## What This Demonstrates

- **Impact analysis**: Click any resource → blast radius count, affected
  resource list, ancestor chain, safe change sequence
- **CAB check**: Select 2+ resources → overlap matrix showing which
  downstream resources are affected by both changes simultaneously
- **Topology invariance**: Same graph, same blast radius, same SPOF list
  across all 4 tiers — only the commands differ
- **Compile-time security**: Only CUE-resolved commands can execute;
  arbitrary input is rejected (HTTP 403)
- **Scalable API contract**: Same endpoint shapes work at demo scale
  (15 resources) and production scale (thousands of resources)

## Files

| File | Purpose |
|------|---------|
| `resources.cue` | Shared 15-resource topology (depends_on only) |
| `desktop.cue` | Desktop tier: Docker types + fields |
| `node.cue` | Node tier: Proxmox + services |
| `cluster.cue` | Cluster tier: k3d + kubectl |
| `enterprise.cue` | Enterprise tier: govc + full suite |
| `providers.cue` | Provider declarations per tier |
| `output.cue` | Shared analysis + per-tier binding + JSON-LD |
| `precomputed.cue` | Depth/ancestors/dependents (shared topology) |
| `verify.cue` | Topology invariant assertions |
| `charter.cue` | 3-gate bootstrap tracking |
| `build.sh` | Export all tiers to `data/*.json` |
| `serve.py` | FastAPI server — impact/CAB/risk + mock/live execution |
| `index.html` | D3 graph explorer with impact-first detail panel |
| `docker-compose.yml` | Desktop tier containers (all 15 resources) |
| `test.sh` | 72 tests: CUE, build, data, API, impact, CAB, risk, security |
| `requirements.txt` | Python dependencies |
