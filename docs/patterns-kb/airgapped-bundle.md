# Airgapped Bundle

**Category:** operations

## Problem

Deploying to air-gapped or restricted networks fails because package managers (apt, pip, docker pull) require internet access. Partial offline solutions miss transitive dependencies or version conflicts.

## Solution

Define a `#Bundle` CUE schema declaring all artifacts needed for offline deployment: git repos, Docker images (app + base), Python wheels (including pip bootstrap), static binaries, and system packages with recursive dependencies. A `#Gotcha` registry captures known deployment traps with tested workarounds. `bundle.sh` reads the manifest and collects everything. `install-airgapped.sh` deploys on the target.

## Context

Any deployment to networks with restricted internet access: institutional data centers, classified environments, factory floors, or POC demonstrations that must work reliably without external dependencies.

E2E proven: 284MB bundle deployed to a fresh Ubuntu 24.04 VM, 37/37 smoke tests passed on a completely airgapped machine.

## Used In

- quicue.ca

## Related

- idempotent_by_construction
- types_compose
- safe_deploy

---
*Generated from quicue.ca registries by `#DocsProjection`*
