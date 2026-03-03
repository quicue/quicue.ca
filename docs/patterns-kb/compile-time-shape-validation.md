# Compile-Time Shape Validation

**Category:** verification

## Problem

The SHACL 1.2 approach to data validation requires three separate artifacts — a schema file (Turtle), a validator (pyshacl/Jena), and a runtime environment (triple store) — each of which can drift from the others. Schema changes require updating all three layers, and validation failures are detected at runtime rather than build time.

## Solution

Define shapes as CUE definitions that unify with the data they constrain. The schema IS the validator — there is no separate validation step. `cue vet` catches shape violations at compile time, and `cue export` produces W3C-compatible output (including SHACL shapes themselves) without a runtime dependency.

The same CUE definition simultaneously serves as:
- Shape constraint (equivalent to sh:NodeShape)
- Validation rule (equivalent to pyshacl execution)
- Query engine (equivalent to SPARQL CONSTRUCT)
- Export format (equivalent to RDF serialization)

## Context

Any project that needs W3C-compatible data validation but wants compile-time guarantees instead of runtime validation. Particularly relevant when the validation pipeline would otherwise require SHACL + pyshacl + a triple store. See [What We Learned from SHACL 1.2](../shacl-comparison.md) for the full comparison.

## Used In

- quicue.ca
- apercue

## Related

- contract_via_unification
- everything_is_projection
- compile_time_binding

---
*Generated from quicue.ca registries by `#DocsProjection`*
