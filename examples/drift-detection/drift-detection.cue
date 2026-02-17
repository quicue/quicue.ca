// Drift Detection: compare declared vs live infrastructure state
// Run: cue eval ./examples/drift-detection/ -e output
//
// Demonstrates:
//   - orche.#ResourceState for declared/live state comparison
//   - orche.#StateReport aggregating drift across a site
//   - orche.#ReconciliationPlan generating fix commands
//   - orche.#DockerDriftDetector for container-specific probes

package main

import "quicue.ca/orche/orchestration"

// Simulated state report: 4 resources, 2 drifted
report: orchestration.#StateReport & {
	site:      "dc-core"
	timestamp: "2026-02-01T15:00:00Z"

	resources: {
		"dns-server": orchestration.#ResourceState & {
			name: "dns-server"
			declared: {exists: true, status: "running"}
			live: {exists: true, status: "running"}
			drift: {has_drift: false, type: "none"}
		}

		"proxy": orchestration.#ResourceState & {
			name: "proxy"
			declared: {exists: true, status: "running"}
			live: {exists: true, status: "running", config: {image: "caddy:2.9"}}
			drift: {
				has_drift: true
				type:      "changed"
				changes: [{
					field:    "image"
					declared: "caddy:2.8"
					live:     "caddy:2.9"
				}]
			}
		}

		"monitoring": orchestration.#ResourceState & {
			name: "monitoring"
			declared: {exists: true, status: "running"}
			drift: {has_drift: true, type: "missing"}
		}

		"legacy-app": orchestration.#ResourceState & {
			name: "legacy-app"
			declared: {exists: false}
			live: {exists: true, status: "running"}
			drift: {has_drift: true, type: "extra"}
		}
	}

	summary: {
		total:   4
		in_sync: 1
		missing: 1
		changed: 1
		extra:   1
	}
}

// Generate reconciliation plan from drift report
reconciliation: orchestration.#ReconciliationPlan & {
	DriftReport: report
}

// Docker-specific drift detector for container probes
_docker_probes: orchestration.#DockerDriftDetector & {
	Containers: {
		"mon-grafana": {
			name:  "mon-grafana"
			image: "grafana/grafana:latest"
		}
		"mon-postgres": {
			name:  "mon-postgres"
			image: "postgres:16-alpine"
		}
	}
}

output: {
	// Site drift summary
	site:    report.site
	summary: report.summary

	// What needs fixing
	fix_plan: {
		create: reconciliation.create
		update: reconciliation.update
		remove: reconciliation.remove
		fixes:  reconciliation.fixes
	}

	// Docker probe commands (would be executed to detect drift)
	docker_probes: {
		grafana: _docker_probes.checks["mon-grafana"].check_exists
		postgres: _docker_probes.checks["mon-postgres"].check_status
	}
}
