# Pattern Catalog

Reference for all computational patterns in `quicue.ca/patterns@v0`. Every pattern is a CUE definition that takes typed inputs and produces computed outputs.

## Schema Index

### Graph Construction

| Pattern | Description |
|---------|-------------|
| `#InfraGraph` | Core graph engine — computes depth, ancestors, topology, roots, leaves, DAG validation from typed resources |
| `#GraphMetrics` | Summary statistics: total resources, edges, depth, type distribution |
| `#ExportGraph` | JSON-LD graph export with typed IRIs and `dependsOn` edges |

### Provider Binding

| Pattern | Description |
|---------|-------------|
| `#BindCluster` | Match providers to resources by `@type` overlap, resolve command templates at compile time |
| `#ExecutionPlan` | Unified graph + provider binding — produces deployment-ordered, fully resolved commands |

### Impact Analysis

| Pattern | Description |
|---------|-------------|
| `#ImpactQuery` | "What breaks if X fails?" — finds all resources with X in their ancestor set |
| `#BlastRadius` | Transitive failure propagation with rollback ordering |
| `#SinglePointsOfFailure` | Resources whose failure cascades to the most dependents |
| `#CriticalityRank` | Rank all resources by downstream impact count |
| `#ImmediateDependents` | Direct (one-hop) dependents of a resource |
| `#DependencyChain` | Full dependency chain between two resources |
| `#RiskScore` | Per-resource risk score: direct dependents x (transitive dependents + 1) |
| `#ZoneAwareBlastRadius` | Blast radius grouped by network zone, with per-zone risk levels |
| `#CompoundRiskAnalysis` | Compound failure risk when multiple targets change simultaneously |
| `#SPOFWithRedundancy` | SPOF analysis accounting for redundancy groups |

### Operational Planning

| Pattern | Description |
|---------|-------------|
| `#DeploymentPlan` | Layer-by-layer startup ordering with inter-layer gates |
| `#RollbackPlan` | "If layer N fails, what do we undo?" — reverse deployment order |
| `#HealthStatus` | Simulate resource failures and see propagation through the graph |
| `#CriticalPath` | Longest weighted path through the DAG — the minimum schedule duration |

### Graph Analysis

| Pattern | Description |
|---------|-------------|
| `#CycleDetector` | Detect cycles via 5-round BFS reachability doubling (32-hop coverage) |
| `#ConnectedComponents` | Identify disconnected subgraphs |
| `#Subgraph` | Extract a subset of the graph by resource names |
| `#GraphDiff` | Compare two graphs — added, removed, and changed resources |
| `#GroupByType` | Group resources by their `@type` membership |

### Validation & Compliance

| Pattern | Description |
|---------|-------------|
| `#ValidateGraph` | Structural validation: no dangling refs, no orphans, types exist |
| `#ValidateTypes` | Ensure all resource `@type` values are in the `#TypeRegistry` |
| `#ComplianceCheck` | Rule-based validation with SHACL report output — match by type, assert structural constraints |

### Export Formats

| Pattern | Description |
|---------|-------------|
| `#TOONExport` | Token Oriented Object Notation — groups resources by field signature for ~55% smaller payloads |
| `#LifecyclePhasesSKOS` | W3C SKOS concept scheme from lifecycle phase definitions |

See [KB Patterns](patterns-kb/index.md) for the validated problem/solution pairs that inform these schemas.

---
*Generated from quicue.ca registries by `#DocsProjection`*
