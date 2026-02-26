# Contract-via-Unification

**Category:** verification

## Problem

Projects need to verify graph invariants but traditional assertion frameworks add a separate test layer.

## Solution

Write CUE constraints as plain struct values that must unify with computed output. The language IS the test harness.

## Context

Any project with a dependency graph where structural invariants must hold.


## Used In

- quicue.ca
- cmhc-retrofit
- maison-613
- grdn

## Related

- struct_as_set
- hidden_wrapper
- gap_as_backlog

---
*Generated from quicue.ca registries by `#DocsProjection`*