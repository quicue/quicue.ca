# Everything-is-a-Projection

**Category:** architecture

## Problem

Adding new output formats requires writing new code in each target language, duplicating graph traversal.

## Solution

Maintain one canonical CUE graph. Every output format is a CUE comprehension over that graph.

## Context

Any CUE project that produces multiple output formats from the same source data.


## Used In

- quicue.ca
- apercue

## Related

- compile_time_binding
- universe_cheatsheet
- hidden_wrapper

---
*Generated from quicue.ca registries by `#DocsProjection`*