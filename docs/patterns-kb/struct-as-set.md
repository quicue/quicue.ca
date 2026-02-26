# Struct-as-Set

**Category:** data

## Problem

Arrays allow duplicates, require O(n) membership checks, and collide on unification.

## Solution

Use {[string]: true} for sets. O(1) membership, automatic dedup, clean unification via CUE lattice.

## Context

Any field representing membership, tags, categories, or dependency sets.

## Example

`apercue/.kb/decisions/002-struct-as-set.cue`

## Used In

- apercue
- datacenter
- quicue.ca

## Related

- bidirectional_deps
- referential_integrity

---
*Generated from quicue.ca registries by `#DocsProjection`*