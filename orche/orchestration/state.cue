// State - Drift detection and state comparison
// Run with: cue cmd drift ./infra/site-main.cue
package orchestration

import (
	"tool/cli"
)

// #ResourceState - Declared vs live state for a resource
#ResourceState: {
	name: string

	// Declared state (from CUE definition)
	declared: {
		exists:  bool
		status?: string
		config?: {...}
	}

	// Live state (from infrastructure probe)
	live?: {
		exists: bool
		status: string
		config?: {...}
	}

	// Drift analysis
	drift: {
		has_drift: bool
		type:      "none" | "missing" | "extra" | "changed"
		changes?: [...{
			field:    string
			declared: _
			live:     _
		}]
	}
}

// #StateReport - Full drift report for a site
#StateReport: {
	site:      string
	timestamp: string
	resources: [string]: #ResourceState

	summary: {
		total:   int
		in_sync: int
		missing: int
		changed: int
		extra:   int
	}
}

// #DriftDetector - Pattern for generating drift detection commands
#DriftDetector: {
	Resources: [string]: {
		name: string
		actions: {
			status?: {command: string, ...}
			...
		}
		...
	}

	// Generate probe commands for each resource
	probes: {
		for rname, r in Resources if r.actions.status != _|_ {
			(rname): {
				command:     r.actions.status.command
				description: "Check status of \(rname)"
			}
		}
	}
}

// =============================================================================
// DRIFT COMMAND - Compare declared vs live state
// =============================================================================
command: drift: {
	$id: "drift"

	header: cli.Print & {
		text: """
			=== DRIFT DETECTION ===
			Comparing declared state vs live infrastructure...
			"""
	}
}

// =============================================================================
// DRIFT_DRY COMMAND - Show what would be checked
// =============================================================================
command: drift_dry: {
	$id: "drift_dry"

	show: cli.Print & {
		text: """
			=== DRY RUN: Drift Detection ===

			This would probe the following resources:
			(Run 'cue cmd drift' to execute for real)
			"""
	}
}

// =============================================================================
// Docker-specific drift detection
// =============================================================================
#DockerDriftDetector: {
	Containers: [string]: {
		name:  string
		image: string
		...
	}

	// Generate drift check for each container
	checks: {
		for cname, c in Containers {
			(cname): {
				// Check if container exists and get its state
				probe_command: "docker inspect \(c.name) 2>/dev/null"

				// Expected state
				expected: {
					exists: true
					image:  c.image
					status: "running"
				}

				// Comparison logic (would be evaluated at runtime)
				check_exists: "docker ps -a --format '{{.Names}}' | grep -q '^" + c.name + "$' && echo 'exists' || echo 'missing'"
				check_status: "docker inspect -f '{{.State.Status}}' \(c.name) 2>/dev/null || echo 'not_found'"
				check_image:  "docker inspect -f '{{.Config.Image}}' \(c.name) 2>/dev/null || echo 'not_found'"
			}
		}
	}
}

// =============================================================================
// Reconciliation plan generator
// =============================================================================
#ReconciliationPlan: {
	DriftReport: #StateReport

	// Resources that need to be created
	create: [for name, state in DriftReport.resources if state.drift.type == "missing" {name}]

	// Resources that need to be updated
	update: [for name, state in DriftReport.resources if state.drift.type == "changed" {name}]

	// Resources that should be removed (if extra)
	remove: [for name, state in DriftReport.resources if state.drift.type == "extra" {name}]

	// Generate fix commands
	fixes: {
		for name in create {
			"create_\(name)": {
				action:      "create"
				resource:    name
				description: "Create missing resource \(name)"
			}
		}
		for name in update {
			"update_\(name)": {
				action:      "recreate"
				resource:    name
				description: "Recreate changed resource \(name)"
			}
		}
	}
}
