# Projections Demo

6-node web stack demonstrating three W3C projection patterns that require
small graph sizes for CUE evaluation to complete.

## What it shows

| Projection | W3C Spec | Output |
|------------|----------|--------|
| Context event log | PROV-O + OWL-Time | Federation audit trail as `prov:Activity` with `time:Instant` |
| Form projection | Custom (apercue) | UI form definitions generated from `#TypeRegistry` |
| RDF-Star annotation | RDF 1.2 | Per-edge metadata (confidence, provenance) via `@annotation` |

## Run

```bash
cue vet ./examples/projections-demo/

cue eval ./examples/projections-demo/ -e summary

cue export ./examples/projections-demo/ -e context_events --out json

cue export ./examples/projections-demo/ -e form_projection --out json

cue export ./examples/projections-demo/ -e rdf_star --out json
```

## Why a separate example

These projections work correctly but add enough evaluation overhead that
bundling them into the 30-node datacenter `_bulk` export causes CUE to
report incomplete values. CUE's non-memoizing evaluation model means each
additional comprehension over `Graph.resources` multiplies total eval time.

At 6 nodes, all three complete in under 2 seconds.
