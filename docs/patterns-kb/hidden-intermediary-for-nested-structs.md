# Hidden Intermediary for Nested Structs

**Category:** cue

## Problem

CUE field references inside nested structs resolve to the nearest enclosing scope, causing self-references.

## Solution

Define hidden intermediaries at the outer scope: _total: total. Then reference them inside the nested struct.

## Context

Any CUE definition that copies outer field values into a nested summary or output struct.


## Used In

- quicue.ca
- cmhc-retrofit
- charter

## Related

- hidden_wrapper
- contract_via_unification

---
*Generated from quicue.ca registries by `#DocsProjection`*