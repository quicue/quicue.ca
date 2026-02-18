# charter — constraint-first project planning via CUE unification

Package path: `quicue.ca/charter@v0`

## Core idea

You declare what "done" looks like as CUE constraints. You build the graph incrementally. `cue vet` tells you what's missing. When it passes, the project satisfies its charter.

This is the "scope → unify → find gaps → build → repeat" workflow. The gap between constraints and data IS the remaining work. CUE's type system computes the backlog.

## How it relates to existing modules

- `patterns/` computes over a **finished** graph (blast radius, SPOF, deployment plans)
- `charter/` computes over an **incomplete** graph (what's missing, what's next, what gates are satisfied)
- `verify.cue` files in devbox, cmhc-retrofit, and maison-613 are the prototype — charter generalizes them

## Definitions to build

### `#Charter`

The top-level scope declaration. Defines what the finished project looks like:

```cue
charter: #Charter & {
    name: "NHCF Deep Retrofit"

    // Expected final state
    scope: {
        total_resources: 18
        root:            "nhcf-agreement"
        max_depth:       >=7
        required_types:  ["Assessment", "Design", "Retrofit", "Commissioning"]
    }

    // Phase gates — subsets of constraints that must be satisfied at checkpoints
    gates: {
        "design-complete": {
            phase:    3
            requires: ["rideau-design", "gladstone-design", "bayshore-design", "vanier-design"]
        }
        "construction-complete": {
            phase:    6
            requires: ["rideau-retrofit", "gladstone-retrofit", "bayshore-retrofit", "vanier-retrofit"]
        }
    }
}
```

### `#GapAnalysis`

Given a charter and a partial graph, compute what's missing:

```cue
gaps: #GapAnalysis & {
    Charter: charter
    Graph:   infra  // the current (possibly incomplete) #InfraGraph
}
// gaps.missing_resources    — names in charter.scope not yet in graph
// gaps.unsatisfied_gates    — gates where required resources are missing or invalid
// gaps.completion_ratio     — how much of the charter is satisfied (0.0–1.0)
// gaps.next_gate            — the nearest unsatisfied gate
```

### `#Milestone`

A checkpoint where a subset of the charter's constraints must be satisfied:

```cue
milestone: #Milestone & {
    Charter: charter
    Gate:    "design-complete"
    Graph:   infra
}
// milestone.satisfied  — bool
// milestone.missing    — resources still needed for this gate
// milestone.blockers   — dependencies of missing resources that also don't exist
```

## Design constraints

1. **Must compose with existing patterns.** Charter takes an `#InfraGraph` as input — same as every other pattern. No new graph engine.
2. **Must work incrementally.** A charter with 18 expected resources should validate when 18 exist, produce useful gap info when 12 exist, and not crash when 0 exist.
3. **Must be domain-agnostic.** Works for infrastructure, construction phases, research genes, real estate workflows — any DAG.
4. **Constraints are CUE values.** No custom assertion framework. The charter IS CUE constraints that must unify with the computed graph. The gap analysis is just "what didn't unify?"

## Test cases

Use existing projects as test beds:
- **devbox** `verify.cue` — simplest case, already works
- **cmhc-retrofit/nhcf** — 18 work packages, 8 phases, 4 named gates
- **maison-613/transaction** — 16 stages, 11 phases, deal milestone gates
- **Intentionally incomplete graph** — remove 3 resources from NHCF, charter should report exactly those 3 as gaps

## Reference material

- `examples/devbox/verify.cue` — prototype contract-via-unification
- `cmhc-retrofit/nhcf/verify.cue` — NHCF graph invariants
- `cmhc-retrofit/greener-homes/verify.cue` — Greener Homes invariants
- `maison-613/transaction/verify.cue` — transaction pipeline invariants
- `maison-613/compliance/verify.cue` — compliance obligation invariants
- `patterns/graph.cue` — `#InfraGraph`, `#GraphMetrics`, `#ValidateGraph`
- `patterns/deploy.cue` — `#DeploymentPlan`, `#RollbackPlan`

## Open questions

1. Should gap analysis be a CUE comprehension (computed at eval time) or a separate CLI step? CUE can compute "which fields are bottom (_|_)" but reporting on absence is unnatural in a constraint language — present-but-bottom vs truly-absent are different things.
2. How to handle optional resources? A charter might say "at least 3 Assessment nodes" without naming them. CUE can validate `len([for n, r in resources if r["@type"].Assessment != _|_ {n}]) >= 3` but the gap report would be "need N more Assessment nodes" rather than "missing resource X."
3. Should gates be ordered (linear phases) or a DAG themselves (gate B requires gate A)?
