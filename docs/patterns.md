# Pattern Catalog

Reference for all patterns in `quicue.ca/patterns@v0`. Every pattern is a CUE definition that takes typed inputs and produces computed outputs. Patterns compose — most accept `Graph: #InfraGraph` and can be combined freely.

## Graph construction

### `#InfraGraph`

**File:** `patterns/graph.cue`
**Purpose:** Convert flat resource definitions into a dependency graph with computed depth, ancestors, topology, and inverse lookups.

**Input:**
```cue
infra: patterns.#InfraGraph & {
    Input: {
        "router": {name: "router", "@type": {Router: true}}
        "dns":    {name: "dns", "@type": {DNSServer: true}, depends_on: {router: true}}
    }
}
```

**Output fields:**

| Field | Type | Description |
|-------|------|-------------|
| `resources[name]._depth` | `int` | 0 for roots, max(parent depths) + 1 otherwise |
| `resources[name]._ancestors` | `{[string]: true}` | Transitive closure of all dependencies |
| `resources[name]._path` | `[...string]` | Path to root via first parent |
| `topology` | `{layer_N: {[name]: true}}` | Resources grouped by depth |
| `roots` | `{[name]: true}` | Resources with depth 0 |
| `leaves` | `{[name]: true}` | Resources with no dependents |
| `dependents` | `{[name]: {[name]: true}}` | Inverse ancestor map |
| `valid` | `bool` | False if any dependency references a nonexistent resource |

**Performance:** Transitive closure cost depends on topology (fan-in), not node count. For high-fan-in graphs, supply `Precomputed: {depth: {...}}`.

### `#ValidateGraph`

**File:** `patterns/graph.cue`
**Purpose:** Check graph structure without computing the full closure.

```cue
v: patterns.#ValidateGraph & {Input: _resources}
// v.valid == true
// v.issues.missing_dependencies == []
// v.issues.self_references == []
// v.issues.empty_types == []
```

Cheaper than `#InfraGraph` — use this for fast validation when you don't need depth or ancestors.

## Impact analysis

### `#ImpactQuery`

**Purpose:** Find all resources affected if a target goes down.

```cue
impact: patterns.#ImpactQuery & {Graph: infra, Target: "dns"}
// impact.affected = {proxy: true, web: true, api: true}
// impact.affected_count = 3
```

Uses precomputed `_ancestors` for O(1) per-resource checks.

### `#BlastRadius`

**Purpose:** Full impact analysis with rollback and startup ordering.

```cue
blast: patterns.#BlastRadius & {Graph: infra, Target: "dns"}
// blast.affected        — all transitively affected resources
// blast.rollback_order  — deepest first, then target (leaves-first teardown)
// blast.startup_order   — target first, then dependents (roots-first startup)
// blast.safe_peers      — same-layer resources NOT affected
// blast.summary         — {target, affected_count, rollback_steps, safe_peer_count}
```

### `#ZoneAwareBlastRadius`

**Purpose:** Blast radius grouped by network zone.

```cue
zblast: patterns.#ZoneAwareBlastRadius & {
    Graph:  infra
    Target: "dns"
    Zones:  {"dns": "Restricted", "web": "DMZ", "api": "Internal"}
}
// zblast.by_zone = {Restricted: {...}, DMZ: {...}}
// zblast.zone_risk = {Restricted: {count: 1, level: "low"}, DMZ: {count: 3, level: "medium"}}
```

Zone risk levels: `critical` (10+), `high` (5+), `medium` (2+), `low` (1).

### `#CompoundRiskAnalysis`

**Purpose:** Analyze compound risk when multiple resources change simultaneously.

```cue
compound: patterns.#CompoundRiskAnalysis & {
    Graph:   infra
    Targets: ["dns", "auth"]
}
// compound.compound_risk — resources hit by 2+ targets
// compound.all_affected  — union of all affected resources
```

### `#GraphMetrics`

**Purpose:** Summary statistics for the graph.

```cue
m: patterns.#GraphMetrics & {Graph: infra}
// m.total_resources = 14
// m.root_count = 2
// m.leaf_count = 5
// m.max_depth = 4
// m.total_edges = 10  (count of resources that have dependencies)
```

### `#ImmediateDependents`

**Purpose:** Find resources that directly depend on a target (one hop only, not transitive).

```cue
deps: patterns.#ImmediateDependents & {Graph: infra, Target: "dns"}
// deps.dependents = {web: true, proxy: true}
// deps.count = 2
```

### `#DependencyChain`

**Purpose:** Retrieve the full dependency path from a resource to its root.

```cue
chain: patterns.#DependencyChain & {Graph: infra, Target: "proxy"}
// chain.path = ["proxy", "web", "dns", "router"]
// chain.depth = 3
// chain.ancestors = {web: true, dns: true, router: true}
```

### `#ExportGraph`

**Purpose:** Export graph with clean IDs for external consumption (flat list with string references).

```cue
export: patterns.#ExportGraph & {Graph: infra}
// export.resources = [{name: "router", depth: 0, types: [...], depends_on: [...]}, ...]
// export.summary = {total: 14, roots: 2, leaves: 5}
```

## Ranking and classification

### `#CriticalityRank`

**Purpose:** Rank resources by transitive dependent count.

```cue
crit: patterns.#CriticalityRank & {Graph: infra}
// crit.ranked = [{name: "router", dependents: 12}, {name: "dns", dependents: 8}, ...]
```

### `#RiskScore`

**Purpose:** Rank by `direct_dependents × (transitive_dependents + 1)`.

```cue
risk: patterns.#RiskScore & {Graph: infra}
// risk.ranked = [{name: "router", direct: 3, transitive: 12, score: 39}, ...]
```

Sorted by score descending.

### `#GroupByType`

**Purpose:** Group resources by their `@type` values.

```cue
byType: patterns.#GroupByType & {Graph: infra}
// byType.groups.DNSServer = {dns_primary: true, dns_secondary: true}
// byType.counts.DNSServer = 2
```

### `#SinglePointsOfFailure`

**Purpose:** Find resources with dependents but no peer of same type at same depth.

```cue
spof: patterns.#SinglePointsOfFailure & {Graph: infra}
// spof.risks = [{name: "router", dependents: 12, types: {Router: true}, depth: 0}]
```

### `#SPOFWithRedundancy`

**Purpose:** SPOF detection accounting for peer overlap. A resource is NOT a SPOF if a peer of the same type at the same depth shares enough dependents (configurable threshold).

```cue
spof: patterns.#SPOFWithRedundancy & {
    Graph:            infra
    OverlapThreshold: 50  // 50% shared dependents = redundant
}
```

## Health and operations

### `#HealthStatus`

**Purpose:** Simulate health propagation. "Down" resources make all their dependents "degraded."

```cue
health: patterns.#HealthStatus & {
    Graph:  infra
    Status: {"dns": "down"}
}
// health.propagated.web = "degraded"
// health.summary = {healthy: 10, degraded: 5, down: 1}
```

### `#DeploymentPlan`

**Purpose:** Generate layer-by-layer deployment sequence with gates.

```cue
deploy: patterns.#DeploymentPlan & {Graph: infra}
// deploy.layers = [
//   {layer: 0, resources: ["router"], gate: "Layer 0 complete - ready for layer 1"},
//   {layer: 1, resources: ["dns", "auth"], gate: "..."},
// ]
// deploy.startup_sequence  = ["router", "dns", "auth", ...]
// deploy.shutdown_sequence = [..., "auth", "dns", "router"]
```

### `#RollbackPlan`

**Purpose:** Generate rollback sequence from a given failure layer.

```cue
rollback: patterns.#RollbackPlan & {Graph: infra, FailedAt: 2}
// rollback.sequence = ["web", "api", "proxy"]  // layer 2+ in reverse depth order
// rollback.safe = ["router", "dns", "auth"]    // layers 0-1 untouched
```

## Validation

**File:** `patterns/validation.cue`

These patterns enforce structural constraints at compile time. Use them to validate resource maps before feeding them into graph analysis.

### `#UniqueFieldValidation`

**Purpose:** Ensure a field is unique across all resources (e.g., no duplicate IPs).

```cue
v: patterns.#UniqueFieldValidation & {_resources: resources, _field: "ip"}
// v.valid == true or CUE evaluation error on duplicate
```

### `#ReferenceValidation`

**Purpose:** Ensure all references point to existing resources.

```cue
v: patterns.#ReferenceValidation & {
    _sources: resources
    _targets: resources
    _refField: "depends_on"
}
```

### `#DependencyValidation`

**Purpose:** Specialized reference validation for `depends_on` fields.

```cue
v: patterns.#DependencyValidation & {_resources: resources}
```

### `#TypeValidation`

**Purpose:** Ensure `@type` structs only contain types from an allowed list.

```cue
v: patterns.#TypeValidation & {
    _resources: resources
    _allowedTypes: {LXCContainer: true, VM: true, DNSServer: true, WebServer: true}
}
```

### `#RequiredFieldsValidation`

**Purpose:** Ensure required fields are present on all resources.

```cue
v: patterns.#RequiredFieldsValidation & {
    _resources: resources
    _requiredFields: ["name", "ip", "host"]
}
```

### `#IPRangeValidation`

**Purpose:** Ensure resource IPs fall within allowed network ranges.

```cue
v: patterns.#IPRangeValidation & {
    _resources: resources
    _allowedPrefix: "10.0.1."
}
```

## Network zones

**File:** `patterns/network.cue`

Patterns for classifying resources by network zone, analyzing cross-zone dependencies, and identifying zone-based risks.

### `#ZoneClassifier`

**Purpose:** Map resources to canonical network zones based on `zone` or `networkLocation` fields.

```cue
zones: patterns.#ZoneClassifier & {Resources: resources}
// zones.classified.dns = "Restricted"
// zones.classified.web = "DMZ"
```

Canonical zones: `Restricted`, `Intranet`, `Campus LAN`, `DMZ`, `Internet`, `Admin VDI`, `Management`, `Storage`, `Cloud`, `Unknown`.

### `#ZoneGrouping`

**Purpose:** Group resources by their classified zone.

```cue
groups: patterns.#ZoneGrouping & {Zones: zones.classified}
// groups.groups.DMZ = {web: true, proxy: true}
// groups.arrays.DMZ = ["web", "proxy"]
```

### `#ZoneMatrix`

**Purpose:** Cross-reference zones with resource types to build a zone × type matrix.

```cue
matrix: patterns.#ZoneMatrix & {Zones: zones.classified, Types: byType.groups}
// matrix.cells.DMZ.WebServer = 2
```

### `#ZoneRisk`

**Purpose:** Identify zone-based security risks — cross-zone data flows, internet-exposed resources, unclassified zones.

```cue
risk: patterns.#ZoneRisk & {Zones: zones.classified, Dependencies: resources}
// risk.internet_exposed = ["cdn", "lb"]
// risk.cross_zone = [{from: "web", from_zone: "DMZ", to: "db", to_zone: "Restricted"}]
```

### `#ZoneExport`

**Purpose:** Export zone data as flat arrays for external tools (Python, web UI).

```cue
export: patterns.#ZoneExport & {Classifier: zones, Grouping: groups}
```

## Type contracts

**File:** `patterns/type-contracts.cue`

Type contracts derive structural requirements from `@type` declarations — enforcing that a resource with type `LXCContainer` must have `container_id`, or that type `Database` structurally depends on a network service.

### `#ApplyTypeContracts`

**Purpose:** Validate required fields and derive structural dependencies from type declarations.

```cue
tc: patterns.#ApplyTypeContracts & {Input: resource}
// tc.grants = ["container_status", "container_console"]
// tc._allDeps = {network: true}  (structural deps derived from types)
```

### `#TypeRequirements`

**Purpose:** Extract all required fields for a set of types.

```cue
reqs: patterns.#TypeRequirements & {Types: {LXCContainer: true, Database: true}}
// reqs.requires = ["container_id", "host"]
// reqs.grants = ["container_status", "db_status"]
```

## Binding and execution

### `#BindCluster`

**File:** `patterns/bind.cue`
**Purpose:** Match providers to resources by `@type` overlap and resolve command templates.

```cue
cluster: patterns.#BindCluster & {
    resources: _resources
    providers: {
        proxmox: patterns.#ProviderDecl & {
            types:    {LXCContainer: true}
            registry: proxmox_patterns.#ProxmoxRegistry
        }
    }
}
// cluster.bound.dns.actions.proxmox.container_status.command = "ssh pve-node1 'pct status 101'"
// cluster.summary = {total_resources: 14, total_providers: 5, bound_actions: 87}
```

**Binding algorithm:**
1. For each `(resource, provider)` pair, check if `provider.types ∩ resource["@type"] ≠ ∅`
2. If matched, iterate the provider's `registry` of `#ActionDef` entries
3. For each action, check if all required `params` with `from_field` bindings resolve from resource fields
4. Resolve command template with `#ResolveTemplate` (compile-time substitution, up to 8 params)
5. Produce a concrete `vocab.#Action`

### `#ExecutionPlan`

**File:** `patterns/deploy.cue`
**Purpose:** Unify binding, graph analysis, and deployment planning.

```cue
execution: patterns.#ExecutionPlan & {
    resources: _resources
    providers: _providers
}
// execution.cluster — #BindCluster output (resolved commands)
// execution.graph   — #InfraGraph output (topology, ancestors)
// execution.plan    — #DeploymentPlan output (ordered layers)
```

CUE enforces that all three sub-definitions agree — same resources flow through all paths.

### `#ResolveTemplate`

**File:** `patterns/bind.cue`
**Purpose:** Compile-time string substitution for `{param}` placeholders.

```cue
resolved: patterns.#ResolveTemplate & {
    template: "ssh {user}@{ip} 'pct status {container_id}'"
    values: {user: "root", ip: "10.0.1.1", container_id: "101"}
}
// resolved.result = "ssh root@10.0.1.1 'pct status 101'"
```

Handles up to 8 parameters via a conditional replacement chain.

## Visualization

### `#VizData`

**File:** `patterns/graph.cue`
**Purpose:** Generate D3.js-compatible graph data.

```cue
viz: patterns.#VizData & {Graph: infra, Resources: _resources}
// cue export -e viz.data --out json
```

Produces: `nodes` (with types, depth, risk_score), `edges`, `topology`, `criticality`, `byType`, `spof`, `coupling`, `metrics`, `validation`.

### `#GraphvizDiagram` and `#MermaidDiagram`

**File:** `patterns/visualization.cue`
**Purpose:** Text-format graph diagrams.

```cue
dot: patterns.#GraphvizDiagram & {Graph: infra}
// dot.output = "digraph { router -> dns; dns -> web; ... }"

mermaid: patterns.#MermaidDiagram & {Graph: infra}
// mermaid.output = "graph TD\n  router --> dns\n  dns --> web"
```

## Export projections

**File:** `patterns/projections.cue`

These extend `#ExecutionPlan` to produce specific output formats:

| Field | Format | Description |
|-------|--------|-------------|
| `notebook` | JSON (`.ipynb`) | Jupyter runbook with per-layer cells and gates |
| `rundeck` | YAML | Rundeck job definitions grouped by layer/provider |
| `http` | Text (`.http`) | RFC 9110 HTTP files for REST Client extensions |
| `wiki` | Markdown | MkDocs pages (index + per-resource detail) |
| `script` | Bash | Self-contained deployment script with parallelism |
| `imperator` | JSON | Task list for `cue cmd` consumption |

## Composition example

Patterns compose naturally because they share `#InfraGraph` as their common input:

```cue
import "quicue.ca/patterns@v0"

_resources: { /* ... */ }

// One graph, many views
_graph: patterns.#InfraGraph & {Input: _resources}

impact_dns:    patterns.#ImpactQuery & {Graph: _graph, Target: "dns"}
blast_dns:     patterns.#BlastRadius & {Graph: _graph, Target: "dns"}
health_sim:    patterns.#HealthStatus & {Graph: _graph, Status: {"dns": "down"}}
spof:          patterns.#SinglePointsOfFailure & {Graph: _graph}
deploy:        patterns.#DeploymentPlan & {Graph: _graph}
metrics:       patterns.#GraphMetrics & {Graph: _graph}
viz:           patterns.#VizData & {Graph: _graph, Resources: _resources}
```

Each pattern reads from the same precomputed graph. No redundant computation.

## Export formats

### `#TOONExport`

**File:** `patterns/toon.cue`
**Purpose:** Compact tabular export that reduces payload size by ~55% vs JSON. Groups resources by field signature.

```cue
toon: (patterns.#TOONExport & {
    Input:  resources
    Fields: ["name", "types", "ip", "host", "container_id"]
}).TOON
```

Output format:
```
resources[7]{name,types,ip,host,container_id}:
  dns-primary,DNSServer|LXCContainer,10.0.1.10,pve-node-1,100
  web-server,WebServer|LXCContainer,10.0.1.20,pve-node-2,102

dependencies[4]{from,to}:
  dns-secondary,dns-primary
  proxy,web-server
```

Configurable: `FieldSeparator`, `TypeSeparator`, `IncludeDeps`.

### `#OpenAPISpec`

**File:** `patterns/openapi.cue`
**Purpose:** Generate a valid OpenAPI 3.0.3 specification where each resource+action becomes a path.

```cue
api: patterns.#OpenAPISpec & {
    Cluster: cluster
    Info: {title: "Infrastructure API", version: "1.0.0"}
}
// api.spec — full OpenAPI 3.0.3 document
// api.summary = {total_paths: 87, resources_covered: 14}
```

### `#SHACLShapes`

**File:** `patterns/shacl.cue`
**Purpose:** Generate SHACL (Shapes Constraint Language) shapes from quicue vocabulary as JSON-LD. Describes what valid Resource serializations look like as RDF.

```cue
shapes: patterns.#SHACLShapes & {resources: resources}
// shapes.graph — JSON-LD @graph with SHACL NodeShapes and PropertyShapes
```

### `#JustfileProjection`

**File:** `patterns/justfile.cue`
**Purpose:** Generate a justfile from infrastructure actions and project actions.

```cue
just: patterns.#JustfileProjection & {
    InfraGraph: infra
    ProjectName: "my-cluster"
    ProjectActions: [patterns.#ProjectActionTemplates.validate]
}
// just.Output — complete justfile text
```

### `#DependencyMatrix`

**File:** `patterns/visualization.cue`
**Purpose:** Generate dependency matrix data as sorted lists.

```cue
matrix: patterns.#DependencyMatrix & {Input: resources}
// matrix.Dependencies = [{from: "web", to: "dns"}, ...]
// matrix.Roots = ["router"]
// matrix.Leaves = ["monitoring", "proxy"]
```

## Provider interfaces

**File:** `patterns/interfaces.cue`

Action interfaces define what operations a resource type should support. Used by provider templates to ensure completeness.

| Interface | Actions | For |
|-----------|---------|-----|
| `#VMActions` | status, console, config | Virtual machines |
| `#ContainerActions` | status, console, logs | Containers (LXC, Docker) |
| `#ConnectivityActions` | ping, ssh | Any networked resource |
| `#ServiceActions` | health, restart, logs | Managed services |
| `#SnapshotActions` | list, create, revert | Backup-capable resources |
| `#HypervisorActions` | list_vms, list_containers, cluster_status, storage_status | Hypervisor nodes |
| `#DatabaseActions` | status, connections | Databases |
| `#CostActions` | breakdown, forecast | Cost tracking |

## Summary

76 definitions across 15 files, organized into:

| Category | Count | File(s) |
|----------|-------|---------|
| Graph analysis & topology | 12 | `graph.cue` |
| Operational patterns | 8 | `graph.cue` |
| Visualization | 6 | `visualization.cue`, `graph.cue` |
| Validation | 6 | `validation.cue` |
| Network zones | 7 | `network.cue` |
| Providers & action binding | 20 | `providers.cue`, `bind.cue`, `interfaces.cue` |
| Type contracts | 3 | `type-contracts.cue` |
| Execution & deployment | 2 | `deploy.cue`, `projections.cue` |
| Export formats | 10 | `toon.cue`, `openapi.cue`, `justfile.cue`, `shacl.cue` |
