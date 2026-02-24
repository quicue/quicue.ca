# Showcase

quicue.ca's own public surfaces modeled as a dependency graph with charter
tracking. Each deliverable (dashboard, API, documentation site) is a resource.
The graph grows as deliverables complete; the charter gap shrinks to zero.

## Run

```bash
cue eval ./examples/showcase/ -e gaps
cue eval ./examples/showcase/ -e gaps.complete
cue eval ./examples/showcase/ -e gaps.next_gate
cue eval ./examples/showcase/ -e gaps.unsatisfied_gates
```

## What it demonstrates

- Charter gap tracking integrated with infrastructure
- Self-hosting: the project models its own delivery as a graph
- Gate-based progress: deliverables must satisfy gates in dependency order
