# quicue.ca/orche — Orchestration & Drift Detection

Multi-site federation, state comparison, and drift detection patterns.

**Use this when:** You manage infrastructure across multiple sites (datacenters, regions, cloud/edge) and need to detect when live state drifts from what you declared. Also handles cross-site resource replication and failover configuration.

## Overview

The orchestration module handles deployment across multiple sites, state synchronization, and detecting divergence between declared and live infrastructure.

## Schemas

**Federation** (`orchestration/federation.cue`):
- **#Site** — Single datacenter/site with network config, resources, tier (core/edge), and metadata.
- **#Federation** — Multi-site infrastructure with member sites, global resources, sync policy. Computes deployment order (core first, then edge).
- **#CrossSiteResource** — Resource spanning multiple sites with replication mode (sync/async) and failover configuration.
- **#SiteGraph** — Generate graph for single site.
- **#FederationGraph** — Unified graph across all sites with site-prefixed resource names.

**State & Drift** (`orchestration/state.cue`):
- **#ResourceState** — Declared vs live state for a resource. Tracks drift type: none, missing, extra, changed.
- **#StateReport** — Full drift report for a site with summary counts.
- **#DriftDetector** — Generate probe commands for each resource (extracts from action registry).
- **#DockerDriftDetector** — Docker-specific drift checks (exists, status, image).
- **#ReconciliationPlan** — Generate create/update/remove actions based on drift report.

## Usage Example

```cue
import "quicue.ca/orche/orchestration@v0"

federation: orchestration.#Federation & {
	name: "example-org"
	sites: {
		primary: {
			tier: "core"
			location: "us-east"
			network: {prefix: "10.1.0.0/16", dns: ["10.1.1.5"]}
			resources: {...}
		}
		replica: {
			tier: "core"
			location: "us-west"
			network: {prefix: "10.2.0.0/16", dns: ["10.2.1.5"]}
			resources: {...}
		}
	}
}
// federation.deployment_order = ["primary", "replica"]
```

## Files

- `orchestration/federation.cue` — Multi-site infrastructure patterns
- `orchestration/state.cue` — Drift detection and state reconciliation
- `bootstrap/` — Placeholder for bootstrap orchestration

## See Also

- `vocab/resource.cue` — Base resource definition
- `patterns/graph.cue` — Graph analysis (can analyze federation graphs)
