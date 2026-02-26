# Compile-Time Binding

**Category:** architecture

## Problem

Command templates with runtime placeholders can fail at execution time if a field is missing.

## Solution

Resolve all template parameters at CUE evaluation time using #ResolveTemplate. No placeholders survive.

## Context

Provider action templates where parameters come from resource fields.


## Used In

- quicue.ca

## Related

- struct_as_set

---
*Generated from quicue.ca registries by `#DocsProjection`*