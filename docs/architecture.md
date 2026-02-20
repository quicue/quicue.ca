# Architecture

quicue.ca models any domain as typed dependency graphs in CUE. This document explains how the layers compose, what each module does, and how data flows from resource definitions to executable plans.

## Four-layer model

```
Definition (vocab/)          What things ARE and what you can DO to them
    ↓
Pattern (patterns/)          How to analyze, bind, plan, and export
    ↓
Template (template/*/)       Platform-specific action implementations
    ↓
Value (examples/, your code) Concrete infrastructure instances
```

Each layer imports only from the layer below it. CUE's type system enforces that values satisfy all constraints from every layer simultaneously — there is no runtime, no fallback, and no partial evaluation.

## Definition layer: `vocab/`

The vocabulary defines the type system. Every infrastructure entity, action, and semantic type is a CUE definition here.

### `#Resource` (`resource.cue`)

The foundation. Every infrastructure component is a `#Resource`:

```cue
dns: vocab.#Resource & {
    name:         "dns"
    "@type":      {LXCContainer: true, DNSServer: true}
    depends_on:   {router: true}
    host:         "pve-node1"
    container_id: 101
    ip:           "198.51.100.211"
}
```

Key design decisions:

- **Struct-as-set for `@type` and `depends_on`.** `{LXCContainer: true}` gives O(1) membership checks. Patterns test `resource["@type"][SomeType] != _|_` instead of iterating a list.
- **Generic field names.** `host` (not `node`), `container_id` (not `lxcid`), `vm_id` (not `vmid`). Providers map generic names to platform-specific commands. This decouples the graph from any single platform.
- **Open schema (`...`).** Resources can carry domain-specific fields without modifying vocab. A Proxmox resource can have `pool: "production"` alongside the standard fields.
- **ASCII-safe identifiers.** All resource names, `@type` keys, `depends_on` keys, and tag keys are constrained to ASCII via `#SafeID` and `#SafeLabel` regex patterns. This prevents zero-width unicode injection, homoglyph attacks (Cyrillic "a" vs Latin "a"), and invisible characters that would break CUE unification silently. `cue vet` catches violations at compile time.

### `#Action` and `#ActionDef` (`actions.cue`)

Actions are executable operations. Two schemas serve different purposes:

- **`#Action`** — a resolved action with a concrete `command` string. This is what the binding layer produces.
- **`#ActionDef`** — an action *definition* with typed parameters and a command template. Providers declare these; the binding layer resolves them against resources.

```cue
// ActionDef (provider declares this)
ping: vocab.#ActionDef & {
    name:             "Ping"
    description:      "Test connectivity"
    category:         "info"
    params:           {ip: {from_field: "ip"}}
    command_template: "ping -c 3 {ip}"
    idempotent:       true
}

// Action (binding produces this)
ping: vocab.#Action & {
    name:        "Ping"
    command:     "ping -c 3 198.51.100.211"  // resolved
    idempotent:  true
}
```

The `from_field` key is what makes compile-time binding work. If a resource lacks the field a parameter needs, the action is silently omitted (not an error — the provider simply doesn't apply to that resource). If a *required* parameter references a field that exists but has the wrong type, CUE catches it.

### `#TypeRegistry` (`types.cue`)

Semantic types describe WHAT a resource IS. Each type declares:

- `requires` — fields that resources of this type must have
- `grants` — action names this type enables
- `structural_deps` — fields that imply dependency relationships

Types fall into three categories:

| Category | Examples | Purpose |
|----------|----------|---------|
| Implementation | `LXCContainer`, `VirtualMachine`, `DockerContainer` | How it runs |
| Semantic | `DNSServer`, `ReverseProxy`, `Database` | What it does |
| Classification | `CriticalInfra` | Operational tier |

A resource can have multiple types. A Proxmox LXC running PowerDNS is `{LXCContainer: true, DNSServer: true}` — it gets both container management actions from the proxmox provider AND DNS-specific actions from the powerdns provider.

### `#VizData` (`viz-contract.cue`)

The visualization contract defines the JSON shape consumed by D3.js graph explorers:

```
{nodes: [...], edges: [...], topology: {...}, metrics: {...}}
```

This contract is implemented by `patterns/#VizData` and consumed by the graph explorer at quicue.ca.

## Pattern layer: `patterns/`

Patterns are CUE definitions that compute derived data from resources. They compose by accepting the same `#InfraGraph` input.

### `#InfraGraph` (`graph.cue`) — the core

Converts a flat set of resources into a dependency graph with computed properties:

```cue
infra: patterns.#InfraGraph & {Input: _resources}
// Now available:
//   infra.resources.dns._depth     = 1
//   infra.resources.dns._ancestors = {router: true}
//   infra.resources.dns._path      = ["dns", "router"]
//   infra.topology                 = {layer_0: {router: true}, layer_1: {dns: true}}
//   infra.roots                    = {router: true}
//   infra.leaves                   = {dns: true}
//   infra.dependents.router        = {dns: true}
```

Computed properties:

| Property | Type | Description |
|----------|------|-------------|
| `_depth` | `int` | Distance from root (0 = no dependencies) |
| `_ancestors` | `{[string]: true}` | Transitive closure — all resources this one depends on |
| `_path` | `[...string]` | Path to root via first parent |
| `topology` | `{layer_N: {[name]: true}}` | Resources grouped by depth |
| `roots` | `{[name]: true}` | Resources with no dependencies |
| `leaves` | `{[name]: true}` | Resources nothing depends on |
| `dependents` | `{[name]: {[name]: true}}` | Inverse of ancestors — O(1) impact lookups |

**Performance note.** Transitive closure (`_ancestors`) is computed via CUE unification (the rogpeppe fixpoint pattern). Performance depends on topology — wide fan-in (many deps per node) is the bottleneck, not node count. For high-fan-in graphs, provide precomputed depth values:

```cue
infra: #InfraGraph & {
    Input:       _resources
    Precomputed: {depth: {"dns": 1, "router": 0, ...}}
}
```

Precomputed depth values bypass transitive closure for graphs with wide fan-in.

### Query patterns

All query patterns accept a `Graph: #InfraGraph` input:

| Pattern | Input | Output | Use case |
|---------|-------|--------|----------|
| `#ImpactQuery` | `Target: string` | `affected`, `affected_count` | "What breaks if X fails?" |
| `#BlastRadius` | `Target: string` | `affected`, `rollback_order`, `startup_order`, `safe_peers` | Change impact analysis |
| `#ZoneAwareBlastRadius` | `Target`, `Zones` | Same + `by_zone`, `zone_risk` | Multi-zone blast radius |
| `#CompoundRiskAnalysis` | `Targets: [...]` | `compound_risk`, `all_affected` | Simultaneous changes |
| `#DependencyChain` | `Target: string` | `path`, `depth`, `ancestors` | Startup path |
| `#CriticalityRank` | — | `ranked` (by dependent count) | Priority ordering |
| `#RiskScore` | — | `ranked` (direct × transitive) | Risk scoring |
| `#SinglePointsOfFailure` | — | `risks` | No-redundancy detection |
| `#SPOFWithRedundancy` | `OverlapThreshold` | `risks` | SPOF with peer overlap analysis |
| `#GroupByType` | — | `groups`, `counts` | Type inventory |
| `#ImmediateDependents` | `Target: string` | `dependents`, `count` | Direct dependents only |
| `#GraphMetrics` | — | `total_resources`, `max_depth`, etc. | Summary stats |
| `#HealthStatus` | `Status: {[name]: "healthy"\|"down"}` | `propagated`, `summary` | Health simulation |

### `#BindCluster` (`bind.cue`) — command resolution

Matches providers to resources by `@type` overlap and resolves command templates:

```cue
cluster: patterns.#BindCluster & {
    resources: _resources
    providers: {
        proxmox: patterns.#ProviderDecl & {
            types:    {LXCContainer: true, VirtualMachine: true}
            registry: proxmox_patterns.#ProxmoxRegistry
        }
    }
}
// cluster.bound.dns.actions.proxmox.container_status.command = "pct status 101"
```

The binding algorithm:

1. For each resource, iterate all providers
2. If `provider.types ∩ resource["@type"] ≠ ∅`, the provider matches
3. For each action in the provider's registry, check if all required parameters resolve from resource fields via `from_field`
4. Resolve the command template with `#ResolveTemplate` (compile-time string substitution, handles up to 8 parameters)
5. Produce a concrete `vocab.#Action` with the resolved command

### `#ExecutionPlan` (`deploy.cue`) — the unifier

Composes binding, graph analysis, and deployment planning over the same resource set:

```cue
execution: patterns.#ExecutionPlan & {
    resources: _resources
    providers: _providers
}
// execution.cluster.bound     — resources with resolved commands
// execution.graph.topology    — dependency layers
// execution.plan.layers       — ordered deployment with gates
```

CUE enforces that all three agree. If a resource's dependencies are inconsistent with its binding, evaluation fails — not at deploy time, at `cue vet` time.

### `#DeploymentPlan` and `#RollbackPlan` (`graph.cue`)

Layer-by-layer orchestration:

```cue
deploy: patterns.#DeploymentPlan & {Graph: infra}
// deploy.layers = [
//   {layer: 0, resources: ["router"], gate: "Layer 0 complete - ready for layer 1"},
//   {layer: 1, resources: ["dns", "auth"], gate: "Layer 1 complete - ready for layer 2"},
// ]
// deploy.startup_sequence  = ["router", "dns", "auth", ...]
// deploy.shutdown_sequence = [..., "auth", "dns", "router"]
```

`#RollbackPlan` reverses from a given failure layer (deepest affected resources first).

### Export projections (`projections.cue`)

The execution plan can be projected into multiple output formats:

| Projection | Format | Target |
|------------|--------|--------|
| `notebook` | `.ipynb` JSON | Jupyter runbook with per-layer cells |
| `rundeck` | YAML | Rundeck job definitions |
| `http` | `.http` | RFC 9110 REST Client files |
| `wiki` | Markdown | MkDocs site (index + per-resource pages) |
| `script` | Bash | Self-contained deployment script with parallelism |
| `ops` | JSON | Task list for `cue cmd` consumption |

### Visualization (`visualization.cue`)

Graphviz DOT and Mermaid diagram generation from the dependency graph.

## Template layer: `template/*/`

Each of the 29 provider templates follows a standard layout:

```
template/<name>/
  meta/meta.cue         # Provider metadata + type matching
  patterns/<name>.cue   # Action registry (ActionDef definitions)
  examples/demo.cue     # Working example
  README.md
```

### `meta/meta.cue`

Declares what resource types this provider serves:

```cue
package meta
import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
    types:    {VirtualizationPlatform: true}
    provider: "proxmox"
}
```

### `patterns/<name>.cue`

Implements concrete actions as `#ActionDef` registries. Example from Proxmox:

```cue
#ProxmoxRegistry: {
    container_status: vocab.#ActionDef & {
        name:             "Container Status"
        description:      "Get LXC container status"
        category:         "info"
        params: {
            host:         {from_field: "host"}
            container_id: {from_field: "container_id", type: "int"}
        }
        command_template: "ssh {host} 'pct status {container_id}'"
        idempotent:       true
    }
    // ...
}
```

### 29 providers

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

## Value layer: examples and your code

The value layer provides concrete resource instances. Here's how the datacenter example composes everything:

```cue
// examples/datacenter/main.cue
_resources: {
    "router-core": {
        name:     "router-core"
        "@type":  {Router: true, CriticalInfra: true}
        ip:       "198.51.100.1"
        ssh_user: "vyos"
    }
    "dns-primary": {
        name:         "dns-primary"
        "@type":      {LXCContainer: true, DNSServer: true}
        depends_on:   {"router-core": true}
        host:         "pve-alpha"
        container_id: 100
        ip:           "198.51.100.211"
    }
    // ... 28 more resources
}

_providers: {
    vyos:     {types: {Router: true}, registry: vyos_patterns.#VyOSRegistry}
    proxmox:  {types: {VirtualMachine: true, LXCContainer: true}, registry: proxmox_patterns.#ProxmoxRegistry}
    powerdns: {types: {DNSServer: true}, registry: powerdns_patterns.#PowerDNSRegistry}
    // ... 25 more providers
}

execution: patterns.#ExecutionPlan & {
    resources: _resources
    providers: _providers
}

output: {
    summary:          execution.graph.#GraphMetrics
    topology:         execution.graph.topology
    deployment_plan:  execution.plan
    impact: {
        for rname, _ in _resources {
            (rname): (patterns.#ImpactQuery & {Graph: execution.graph, Target: rname})
        }
    }
    // ...
}
```

## Extension modules

### `ou/` — Role-scoped views

Role-scoped views that filter resources and actions by role:

- `ops` — full access to all actions
- `dev` — read-only monitoring and log access
- `readonly` — status queries only

Exports W3C Hydra JSON-LD for semantic API navigation.

### `boot/` — Bootstrap sequencing

Credential collection and bootstrap ordering for initial infrastructure setup. Handles the chicken-and-egg problem (e.g., you need DNS to reach the vault, but you need the vault to configure DNS).

### `orche/` — Multi-site federation

Models core + edge topology for multi-site deployments. Includes drift detection patterns for declared-vs-live state reconciliation.

### `cab/` — Change Advisory Board

Generates CAB reports from impact analysis: what's changing, what's affected, what's the rollback plan, who needs to approve.

### `wiki/` — Documentation generation

Produces MkDocs-compatible markdown from the resource graph: index page, per-layer views, per-resource detail pages.

### `server/` — FastAPI gateway

HTTP API for executing resolved commands. Reads the CUE-generated OpenAPI spec and exposes 654 actions across 29 providers as REST endpoints. Live at [api.quicue.ca](https://api.quicue.ca/docs) (public, mock mode — unauthenticated callers see resolved commands without execution). Serves W3C Hydra JSON-LD and graph data for the [operator dashboard](https://demo.quicue.ca/) which provides D3 graph visualization, execution planner, resource browser, and Hydra explorer.

### `kg/` — Knowledge graph

Vendored copy of the [quicue-kg](https://github.com/quicue/quicue-kg) framework. The `.kb/` directory at the repo root is a multi-graph knowledge base with typed subdirectories (decisions/, patterns/, insights/, rejected/), each an independent CUE package validated against its kg type.

#### Downstream validation

`.kb/downstream.cue` registers known consumers (grdn, cmhc-retrofit, maison-613, apercue). Each consumer maintains its own `.kb/` with a deps registry cataloging which vocab and pattern definitions it imports and where they're used — for example, grdn's deps.cue records 14 pattern and 2 vocab definitions with source, purpose, and consuming files.

The `make check-downstream` target runs `cue vet` on validation targets across downstream projects. Renaming a field in `#InfraGraph` produces a unification error in any consumer that references it, caught at build time rather than discovered in production.

## Data flow summary

```
1. Define resources (CUE values with @type and depends_on)
                    ↓
2. Declare providers (type matching + action registries)
                    ↓
3. #ExecutionPlan unifies:
   ├── #BindCluster  → resolved commands per resource per provider
   ├── #InfraGraph   → depth, ancestors, topology, dependents
   └── #DeploymentPlan → ordered layers with gates
                    ↓
4. CUE validates everything simultaneously:
   - Missing fields → compile error
   - Dangling dependencies → validation error
   - Type mismatches → unification error
                    ↓
5. Export to any format:
   - cue export -e output --out json          → full execution data
   - cue export -e execution.notebook         → Jupyter runbook
   - cue export -e execution.script --out text → deployment script
   - cue export -e jsonld --out json          → JSON-LD graph
```

## Key invariants

1. **No runtime template resolution.** Every `{param}` placeholder is resolved at `cue vet` time. If a command has an unresolved placeholder, it won't compile.

2. **The graph is the source of truth.** Deployment plans, rollback sequences, blast radius, documentation, and visualizations are all computed from the same unified constraint set. Change one dependency and everything updates.

3. **Struct-as-set everywhere.** `@type`, `depends_on`, `provides`, and `tags` all use `{key: true}` structs for O(1) membership testing. This is a deliberate performance decision — CUE's `list.Contains` is O(n) and compounds across comprehensions.

4. **Hidden fields for export control.** CUE exports all public (capitalized) fields. Intermediate computation uses hidden fields (`_depth`, `_ancestors`, `_graph`) to prevent JSON bloat. Export-facing definitions expose only the fields consumers need.

5. **Topology-sensitive transitive closure.** CUE's fixpoint computation for `_ancestors` is bottlenecked by fan-in (edge density), not node count. For high-fan-in graphs, precompute depth values externally.
