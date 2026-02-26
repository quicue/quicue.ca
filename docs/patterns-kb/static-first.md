# Static-First

**Category:** architecture

## Problem

Web servers introduce failure modes even when serving read-only data that changes only at build time.

## Solution

Pre-compute everything possible at cue export time. Read-only API surfaces are directories of JSON files served by CDN.

## Context

Deployment dashboards, API documentation, graph visualization, risk reports.


## Used In

- quicue.ca

## Related

- universe_cheatsheet
- everything_is_projection
- safe_deploy

---
*Generated from quicue.ca registries by `#DocsProjection`*