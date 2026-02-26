# Universe Cheat Sheet

**Category:** architecture

## Problem

Read-only APIs backed by CUE graphs still deploy a web server, adding latency and failure modes.

## Solution

Run cue export once to produce all possible API responses as static JSON files. Deploy to CDN.

## Context

Any CUE-backed API where the query universe is finite and data changes only at build time.


## Used In

- quicue.ca

## Related

- compile_time_binding
- safe_deploy

---
*Generated from quicue.ca registries by `#DocsProjection`*