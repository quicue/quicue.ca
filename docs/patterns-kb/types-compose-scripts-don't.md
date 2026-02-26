# Types-Compose-Scripts-Don't

**Category:** architecture

## Problem

Adding new deployment capabilities typically means writing new bash scripts that duplicate graph traversal.

## Solution

Express new capabilities as CUE types that compose with existing types via unification.

## Context

Any extension to the deployment lifecycle where the new capability needs access to the resource graph.


## Used In

- quicue.ca

## Related

- three_layer
- everything_is_projection

---
*Generated from quicue.ca registries by `#DocsProjection`*