# quicue.ca

[![Validate](https://github.com/quicue/quicue.ca/actions/workflows/validate.yml/badge.svg)](https://github.com/quicue/quicue.ca/actions/workflows/validate.yml)

A [CUE](https://cuelang.org/) framework for modeling any domain as typed, queryable dependency graphs.

## Why

Any domain with typed nodes and dependency edges — infrastructure, construction, research, operations — has the same problems: What depends on what? What breaks if X goes down? What's the right deployment order? The answers are usually tribal knowledge or an out-of-date wiki.

quicue.ca models these domains as graphs of typed resources with explicit dependencies. CUE's type system validates the graph at compile time — before anything runs. The graph drives impact analysis, deployment ordering, rollback plans, and documentation, all computed from one source of truth.

**Who this is for:** Anyone managing enough interconnected things that dependency relationships matter — platform engineers, project managers, research analysts, operations teams.

## What it does

```
You write CUE          quicue.ca computes           You get
─────────────          ──────────────────           ────────
Resources              Dependency graph              Deployment plans
  with @type           Blast radius                  Executable commands
  and depends_on       SPOF detection                Jupyter runbooks
                       Criticality ranking           Rundeck jobs
Provider bindings      Impact analysis               MkDocs wiki
  by @type overlap     Health simulation             JSON-LD graph
                       Rollback plans                OpenAPI spec
```

## Quick start

```bash
# Clone and validate
git clone https://github.com/quicue/quicue.ca.git
cd quicue.ca
cue vet ./vocab/ ./patterns/

# Run the datacenter example (30 resources, 29 providers, 654 resolved commands)
cue eval ./examples/datacenter/ -e output.summary

# See what breaks if the router goes down
cue eval ./examples/datacenter/ -e output.impact.\"router-core\"

# Export the full execution plan as JSON
cue export ./examples/datacenter/ -e output --out json
```

## How it works

Resources declare what they are (`@type`) and what they depend on (`depends_on`), both as sets:

```cue
dns: #Resource & {
    "@type":     {LXCContainer: true, DNSServer: true}
    depends_on:  {router: true}
    host:        "node-1"
    container_id: "101"
}
```

Providers declare what resource types they serve. quicue.ca matches providers to resources by type overlap, then resolves command templates at compile time — every `{host}` and `{container_id}` placeholder is filled from resource fields before you run anything. If a field is missing, CUE catches it as a type error.

The result is a fully resolved execution plan: deployment order, rollback sequence, and per-resource commands, all as plain JSON.

## Architecture

Four-layer model:

| Layer | Path | Purpose |
|-------|------|---------|
| **Definition** | `vocab/`, `patterns/` | Core schemas and graph algorithms |
| **Template** | `template/*/` | 29 platform-specific providers |
| **Value** | `examples/` | Concrete infrastructure definitions |
| **Interaction** | `ou/` | Role-scoped views and W3C Hydra JSON-LD API |

### Core schemas (`vocab/`)

- **`#Resource`** — Identity, network, hosting, dependencies, capabilities
- **`#Action`** — Executable operations with timeout, destructive flags, prerequisites
- **`#ActionDef`** — Action definitions with typed parameters and compile-time `from_field` bindings
- **`#TypeRegistry`** — Maps resource types to supported actions

### Graph patterns (`patterns/`)

- **`#InfraGraph`** — Dependency analysis: depth, ancestors, topology, DAG validation
- **`#BindCluster`** — Provider binding: matches `@type` overlap, resolves command templates
- **`#ExecutionPlan`** — Unified binding + deployment ordering
- **`#ImpactQuery`** — "What breaks if X fails?"
- **`#BlastRadius`** — Transitive failure propagation
- **`#SinglePointsOfFailure`** — Resources whose failure cascades widely
- **`#CriticalityRank`** — Rank resources by downstream impact
- **`#HealthStatus`** — Simulate failures and see propagation
- **`#RollbackPlan`** — "If layer N fails, what do we undo?"
- **`#DeploymentPlan`** — Layer-by-layer startup ordering with gates

## Providers (29)

| Category | Providers |
|----------|-----------|
| Compute | proxmox, govc, powercli, kubevirt |
| Container/Orchestration | docker, incus, k3d, kubectl, argocd |
| CI/CD | dagger, gitlab |
| Networking | vyos, caddy, nginx |
| DNS | cloudflare, powerdns, technitium |
| Identity/Secrets | vault, keycloak |
| Database | postgresql |
| DCIM/IPAM | netbox |
| Provisioning | foreman |
| Automation | ansible, awx |
| Monitoring | zabbix |
| IaC | terraform, opentofu |
| Backup | restic, pbs |

Each provider follows:
```
template/<name>/
  meta/meta.cue         # Metadata
  patterns/<name>.cue   # Action definitions using #ActionDef
  examples/demo.cue     # Working example
  README.md
```

## Examples

### `examples/datacenter/` — Full pipeline
30 resources across all 29 providers. Exercises every pattern: graph analysis, provider binding, impact queries, blast radius, SPOF detection, deployment planning, execution plans, JSON-LD export, OpenAPI generation.

### `examples/homelab/` — Reference homelab
14 resources on a 3-node cluster. Edit `_site` config, swap `providers.cue` for your stack (Proxmox, Docker, K8s, Incus), run `cue export`.

### `examples/devbox/` — Single-machine developer tooling
14 resources on one host via Docker Compose. Includes an `#App` template — define an app (image, port, dependencies) and get a graph-integrated resource with Traefik FQDN and computed dependency edges. Also demonstrates contract-via-unification: `verify.cue` declares graph invariants as CUE constraints that must merge with the computed output.

### Focused examples
- `graph-patterns/` — Dependency analysis patterns
- `drift-detection/` — Declared vs live state reconciliation
- `federation/` — Multi-site core/edge topology
- `type-composition/` — @type matching and provider binding
- `3-layer/` — Minimal 3-layer infrastructure
- `docker-bootstrap/` — Generate docker run commands from CUE
- `wiki-projection/` — Generate MkDocs from resource graphs
- `toon-export/` — Token-optimized compact notation (~55% smaller than JSON)

## Live projects

The same graph patterns power projects across different domains:

| Domain | Project | What it models |
|--------|---------|---------------|
| IT infrastructure | [datacenter example](examples/datacenter/) | 30 resources, 29 providers, 654 resolved commands |
| Construction | [CMHC Retrofit](https://cmhc-retrofit.quicue.ca/) | Deep retrofit work packages for 270-unit community housing program |
| Energy efficiency | [Greener Homes](https://cmhc-retrofit.quicue.ca/#greener-homes) | 17-service processing platform for Ontario Greener Homes |
| Real estate | [maison-613](https://maison613.quicue.ca/) | Transaction, referral, compliance, and onboarding workflows |
| Biomedical research | [lacuene](https://lacuene.apercue.ca/) | 95 genes × 16 databases — funding gap analysis for NIDCR |

## Additional modules

- `orche/` — Multi-site federation and drift detection
- `boot/` — Bootstrap sequencing and credential collection
- `cab/` — Change Advisory Board reports (impact analysis, runbooks)
- `ci/gitlab/` — Reusable GitLab CI templates
- `wiki/` — Generate MkDocs sites from resource graphs
- `ou/` — Role-scoped views (ops/dev/readonly) with W3C Hydra JSON-LD
- `server/` — FastAPI execution gateway ([api.quicue.ca](https://api.quicue.ca/docs))
- `kg/` — Knowledge graph framework ([quicue-kg](https://github.com/quicue/quicue-kg))

## Knowledge base

`.kb/` is a multi-graph knowledge base with typed subdirectories. Each graph is an independent CUE package validated against its [quicue-kg](https://github.com/quicue/quicue-kg) type, mapped to a W3C vocabulary:

| Graph | Directory | kg type | W3C vocabulary |
|-------|-----------|---------|---------------|
| Decisions | `.kb/decisions/` | `core.#Decision` | PROV-O |
| Patterns | `.kb/patterns/` | `core.#Pattern` | SKOS |
| Insights | `.kb/insights/` | `core.#Insight` | Web Annotation |
| Rejected | `.kb/rejected/` | `core.#Rejected` | PROV-O |

The root `.kb/manifest.cue` declares the topology via `ext.#KnowledgeBase`. Directory structure IS the ontology.

```bash
# Validate all graphs
make kb

# Validate that downstream consumers still unify with current patterns
make check-downstream
```

### Downstream tracking

`.kb/downstream.cue` registers known consumers of quicue.ca patterns. Each downstream project maintains its own `.kb/` with a deps registry cataloging which definitions it imports and where they're used.

This catches breakage early — if you rename a field in `#InfraGraph`, `check-downstream` fails on any consumer that references it.

## Requirements

- [CUE](https://cuelang.org/) v0.15.4+
- Python 3.12+ (only for the optional server)

## License

Apache 2.0
