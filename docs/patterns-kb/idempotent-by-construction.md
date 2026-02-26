# Idempotent-by-Construction

**Category:** operations

## Problem

Deployment scripts accumulate state. Re-running a partially-failed deployment is risky.

## Solution

CUE evaluation is deterministic — same inputs always produce identical outputs. The deployment artifact is immutable.

## Context

Any deployment pipeline where re-runnability matters.


## Used In

- quicue.ca

## Related

- compile_time_binding
- contract_via_unification

---
*Generated from quicue.ca registries by `#DocsProjection`*