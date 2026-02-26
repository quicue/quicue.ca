# Charter

`quicue.ca/charter` — constraint-first project planning via CUE unification.

Declare what "done" looks like. Build the graph incrementally. `cue vet` tells you what's missing.

## Schemas

- `#Charter`
- `#Gate`
- `#GapAnalysis`
- `#Milestone`
- `#InfraCharter`

## How It Works

A charter is a set of CUE constraints that the project graph must eventually satisfy. You declare scope (what must exist), gates (checkpoints along the way), and let CUE compute the delta.

```cue
import "quicue.ca/charter"

_charter: charter.#Charter & {
    name: "My Project"
    scope: {
        total_resources: 18
        root:            "entry-point"
        required_types:  {Database: true, WebServer: true}
    }
    gates: {
        "db-ready": {
            phase:    1
            requires: {"postgres": true, "redis": true}
        }
    }
}
```

## Gap Analysis

`#GapAnalysis` computes what's missing:

| Field | Description |
|-------|-------------|
| `complete` | `true` when all constraints satisfied |
| `missing_resources` | Named resources not yet in graph |
| `gate_status` | Per-gate evaluation |
| `next_gate` | Lowest-phase unsatisfied gate |

The gap IS the backlog. No separate tracking system needed.

---
*Generated from quicue.ca registries by `#DocsProjection`*