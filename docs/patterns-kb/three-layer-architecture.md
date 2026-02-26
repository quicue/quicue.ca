# Three-Layer Architecture

**Category:** architecture

## Problem

Infrastructure models mix universal concepts with platform-specific implementations and concrete instances.

## Solution

Separate into definition, template, and value layers. Each layer constrains the next via CUE unification.

## Context

Infrastructure-as-code projects where the same resource model applies across multiple platforms.


## Used In

- quicue.ca

## Related

- compile_time_binding

---
*Generated from quicue.ca registries by `#DocsProjection`*