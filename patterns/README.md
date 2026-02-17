# quicue.ca/patterns — Graph Analysis & Execution Planning

Algorithms for dependency analysis, blast radius, deployment ordering, and operational health tracking.

**Use this when:** You have resources defined with `vocab.#Resource` and want to compute dependency graphs, find single points of failure, generate deployment plans, or analyze blast radius.

## Overview

The patterns module transforms infrastructure resources into actionable outputs: dependency depth, impact analysis, single points of failure, deployment layers, and rollback sequences. All patterns use CUE's fixpoint unification for graph traversal.

**Performance note:** Transitive closure computation (used by `#ImpactQuery`, `#CriticalityRank`, `#BlastRadius`) is sensitive to topology — wide fan-in is the bottleneck, not node count. For high-fan-in graphs, use the Python precompute fallback in `examples/hybrid-demo/`.

## Core Patterns

- **#InfraGraph** — Convert string-based resources to a computed graph with _depth, _ancestors, _path, topology, roots, leaves. Validates referential integrity (no dangling dependencies).
- **#GraphMetrics** — Summary statistics: total resources, max depth, root/leaf counts, edge count.
- **#ImpactQuery** — Find all resources affected if target goes down (transitive closure).
- **#DependencyChain** — Full dependency path from a resource to root.
- **#CriticalityRank** — Rank resources by how many things depend on them.
- **#RiskScore** — Risk = direct dependents × (transitive dependents + 1). Higher scores indicate blast radius.
- **#SinglePointsOfFailure** — Find resources with dependents but no peer redundancy.
- **#SPOFWithRedundancy** — Enhanced SPOF detection with configurable overlap threshold.

## Operational Patterns

- **#HealthStatus** — Propagate health through graph: if ancestor is down, dependents degrade.
- **#BlastRadius** — Analyze change impact: affected resources, rollback order, startup order, safe peers.
- **#ZoneAwareBlastRadius** — Blast radius grouped by network zones.
- **#CompoundRiskAnalysis** — Analyze risk from multiple simultaneous changes.
- **#DeploymentPlan** — Generate layer-by-layer deployment sequence with gating.
- **#RollbackPlan** — Generate rollback sequence when deployment fails at a specific layer.
- **#VizData** — Export graph for JavaScript graph explorer (Cytoscape.js): nodes, edges, topology, criticality, SPOF, coupling.

## Binding Patterns

- **#BindCluster** (`bind.cue`) — Bind provider registries to resources by @type overlap. Resolves action commands with resource field substitution.
- **#ResolveTemplate** — Substitute {param} placeholders in command templates at compile time.
- **#ExecutionPlan** (`deploy.cue`) — Unify #BindCluster, #InfraGraph, #DeploymentPlan over the same resources. Guarantees all three agree.

## Performance Notes

- Validation, depth, grouping: <0.5s (no transitive closure)
- Impact/criticality queries: 1-5s (needs _ancestors)
- Graph shape matters: wide trees (depth~10) are 10x faster than linear chains
- Use struct field presence ({key: true}) over list.Contains for O(1) vs O(n)

## Usage Example

```cue
import "quicue.ca/patterns@v0"

infra: patterns.#InfraGraph & {Input: myResources}
blast: patterns.#BlastRadius & {Graph: infra, Target: "dns"}
// blast.affected, blast.rollback_order, blast.safe_peers
```

## Files

- `graph.cue` — Core graph computation and analysis patterns
- `bind.cue` — Action binding (provider → resource)
- `deploy.cue` — Execution plan composition

## See Also

- `cab/reports/impact_report.cue` — CAB impact reports (uses #ImpactQuery, #BlastRadius)
- `infra-graph` — Python API that traverses these patterns
