# Graph Projection from Existing Config

**Category:** adoption

## Problem

Existing CUE codebases don't use @type or depends_on. Rewriting is invasive.

## Solution

Write a single additive file (graph.cue) that reads from existing config fields and produces a flat resource map.

## Context

Any existing CUE project considering adoption of quicue.ca patterns.


## Used In

- grdn

## Related

- struct_as_set
- three_layer

---
*Generated from quicue.ca registries by `#DocsProjection`*