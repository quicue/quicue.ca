# Charter

`quicue.ca/charter` — constraint-first project planning via CUE unification.

Declare what "done" looks like. Build the graph incrementally. `cue vet` tells you what's missing. When it passes, the charter is satisfied.

The gap between constraints and data IS the remaining work.

## How it works

A charter is a set of CUE constraints that the project graph must eventually satisfy. You declare scope (what must exist), gates (checkpoints along the way), and let CUE compute the delta.

```cue
import "quicue.ca/charter"

_charter: charter.#Charter & {
    name: "NHCF Deep Retrofit"
    scope: {
        total_resources: 18
        root:            "nhcf-agreement"
        required_resources: {"rideau-design": true, "gladstone-design": true}
        required_types: {Assessment: true, Design: true, Retrofit: true}
        min_depth: 3
    }
    gates: {
        "assessment-complete": {
            phase: 1
            requires: {"site-audit": true, "energy-model": true}
        }
        "design-complete": {
            phase: 3
            requires: {"rideau-design": true, "gladstone-design": true}
            depends_on: {"assessment-complete": true}
        }
    }
}
```

## Gap analysis

`#GapAnalysis` takes a charter and a graph, and computes what's missing:

```cue
import (
    "quicue.ca/charter"
    "quicue.ca/patterns@v0"
)

_graph: patterns.#InfraGraph & {Input: _resources}

gaps: charter.#GapAnalysis & {
    Charter: _charter
    Graph:   _graph
}
```

**Output fields:**

| Field | Type | Description |
|-------|------|-------------|
| `complete` | `bool` | `true` when all constraints are satisfied |
| `missing_resources` | `{[string]: true}` | Named resources not yet in the graph |
| `missing_resource_count` | `int` | Count of missing resources |
| `missing_types` | `{[string]: true}` | Required types not represented |
| `missing_type_count` | `int` | Count of missing types |
| `depth_satisfied` | `bool` | Graph reaches `min_depth` |
| `count_satisfied` | `bool` | Graph has `total_resources` or more |
| `gate_status` | `{[name]: {satisfied, missing, ready}}` | Per-gate evaluation |
| `unsatisfied_gates` | `{[name]: {missing}}` | Gates not yet met |
| `next_gate` | `string` | Lowest-phase unsatisfied gate |

When `gaps.complete == true`, the charter is satisfied. When it's `false`, the missing fields tell you exactly what to build next.

## Gates

Gates are DAG-ordered checkpoints. Each gate names resources that must exist, and can depend on other gates:

```cue
gates: {
    "db-ready": {
        phase:    1
        requires: {"postgres": true, "redis": true}
    }
    "api-ready": {
        phase:    2
        requires: {"api-server": true}
        depends_on: {"db-ready": true}
    }
}
```

A gate is `satisfied` when all its required resources exist in the graph. A gate is `ready` when it's satisfied AND all its dependency gates are also satisfied. This lets you model non-linear project workflows where multiple workstreams converge.

## Milestones

`#Milestone` evaluates a single gate in isolation:

```cue
milestone: charter.#Milestone & {
    Charter: _charter
    Gate:    "design-complete"
    Graph:   _graph
}
// milestone.satisfied     — bool
// milestone.missing       — resources still needed
// milestone.blockers      — missing resources that are also in required_resources
// milestone.summary       — {gate, phase, satisfied, missing_count, blocker_count}
```

Use milestones for focused progress checks on a specific phase without computing the full gap analysis.

## Scope constraints

The `scope` block supports five constraint types, all optional:

| Constraint | Type | Meaning |
|-----------|------|---------|
| `total_resources` | `int & >0` | Minimum resource count |
| `root` | `string \| {[string]: true}` | Named root(s) that must exist as graph roots |
| `required_resources` | `{[string]: true}` | Resources that must exist by name |
| `required_types` | `{[string]: true}` | Types that must be represented |
| `min_depth` | `int & >=0` | Minimum graph depth (dependency layers) |

## Relationship to patterns

Charter sits alongside the existing pattern library:

```
Definition (vocab/)      What things ARE
Pattern (patterns/)      How to analyze a finished graph
Template (template/*/)   Platform-specific actions
Charter (charter/)       What "done" looks like for an incomplete graph
Value (examples/, ...)   Concrete instances
```

- `patterns/` computes over a **finished** graph: blast radius, SPOF, deployment plans
- `charter/` computes over an **incomplete** graph: what's missing, what's next, what gates are satisfied

Both take `#InfraGraph` as input. Both validate with `cue vet`.

## Example: test graph

The test suite uses a minimal 5-node graph to exercise all three definitions:

```cue
_resources: {
    "docker":   {name: "docker",   "@type": {DockerHost: true}}
    "postgres": {name: "postgres", "@type": {Database: true},     depends_on: {"docker": true}}
    "redis":    {name: "redis",    "@type": {Cache: true},        depends_on: {"docker": true}}
    "api":      {name: "api",      "@type": {AppWorkload: true},  depends_on: {"postgres": true, "redis": true}}
    "frontend": {name: "frontend", "@type": {AppWorkload: true},  depends_on: {"api": true}}
}
```

**Complete charter** (all resources present):
```cue
scope: {
    total_resources: 5
    root: "docker"
    required_resources: {"docker": true, "postgres": true, "api": true}
    required_types: {Database: true, AppWorkload: true}
    min_depth: 2
}
// gaps.complete == true
// gaps.missing_resource_count == 0
```

**Incomplete charter** (missing resources):
```cue
scope: {
    total_resources: 8  // only 5 exist
    required_resources: {"docker": true, "monitoring": true, "logging": true}
    required_types: {Database: true, MonitoringStack: true}
}
// gaps.complete == false
// gaps.missing_resources == {monitoring: true, logging: true}
// gaps.missing_types == {MonitoringStack: true}
```

The gap IS the backlog. No separate tracking system needed.

## Live integrations

Charter is used across five downstream projects, each a different domain shape:

| Project | Graph | Nodes | Gates | Domain |
|---------|-------|-------|-------|--------|
| [cmhc-retrofit](https://github.com/quicue/cmhc-retrofit) NHCF | Project delivery | 18 | 5 (audits → baseline → design → construction → closeout) | Construction PM |
| cmhc-retrofit Greener Homes | Service topology | 17 | 5 (data → storage → compute → quality → live) | IT platform |
| maison-613 Transaction | Deal phases | 16 | 6 (listing → prep → market → offer → conditions → closing) | Real estate |
| maison-613 Compliance | Obligation graph | 12 | 4 (foundations → post-reg → transaction → renewal) | Regulatory |
| grdn | Infrastructure | 50 | 2 (hardware → core-services) | Homelab |

**Example: NHCF gap analysis**

```bash
cue eval ./nhcf/ -e nhcf_gaps.complete
# true

cue eval ./nhcf/ -e nhcf_milestone
# gate:          "design-complete"
# phase:         4
# satisfied:     true
# missing_count: 0
# blocker_count: 0
```

When resources are missing, the gap analysis tells you exactly what to build:

```bash
cue eval ./nhcf/ -e nhcf_gaps.unsatisfied_gates
# "construction-complete": {
#     "rideau-retrofit":    true
#     "gladstone-retrofit": true
# }

cue eval ./nhcf/ -e nhcf_gaps.next_gate
# "construction-complete"
```

The gap IS the backlog. No separate tracking system needed.

## Validation

```bash
# Validate charter definitions
cue vet ./charter/

# Run all tests (includes charter)
make test
```
