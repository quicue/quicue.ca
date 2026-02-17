// Deployment Runbook Generator
//
// Generates ordered deployment steps and rollback plans for CAB review.
// Creates actionable runbooks with layer-by-layer gating.
//
// Usage:
//   import "quicue.ca/cab/reports"
//
//   runbook: reports.#DeploymentRunbook & {
//       Graph: infraGraph
//       Config: cabConfig
//   }

package reports

import (
	"strings"
	"list"
)

// #DeploymentRunbook - Generate deployment runbook with gating
#DeploymentRunbook: {
	// Infrastructure graph
	Graph: {
		resources: [string]: {
			name: string
			"@type": {[string]: true}
			_depth: int
			ip?:    string
			host?:  string
			...
		}
		topology: [string]: {[string]: true}
		roots:  [...string]
		leaves: [...string]
		...
	}

	// Configuration
	Config?: {
		organization?: string
		environment?:  string
		...
	}

	// Compute max depth
	_depths: [for _, r in Graph.resources {r._depth}]
	_maxDepth: [
		if len(_depths) > 0 {list.Max(_depths)},
		0,
	][0]

	// Build layers with resources
	layers: [
		for d in list.Range(0, _maxDepth+1, 1) {
			layer: d
			resources: [
				for name, r in Graph.resources
				if r._depth == d {
					{
						name: name
						types: [for t, _ in r["@type"] {t}]
						ip:    r.ip | *""
						host:  r.host | *""
					}
				},
			]
			resource_count: len([
				for _, r in Graph.resources
				if r._depth == d {1},
			])
			gate: "Layer \(d) complete - all resources verified healthy"
		},
	]

	// Startup sequence (roots first)
	startup_sequence: list.FlattenN([
		for l in layers {[for r in l.resources {r.name}]},
	], 1)

	// Shutdown sequence (leaves first)
	shutdown_sequence: list.Reverse(startup_sequence)

	// Summary
	summary: {
		total_resources: len(Graph.resources)
		total_layers:    len(layers)
		gates_required:  len(layers) - 1
		root_count:      len(Graph.roots)
		leaf_count:      len(Graph.leaves)
	}

	// Generate markdown runbook
	_header: """
		# Deployment Runbook

		**Organization**: \(Config.organization | *"N/A")
		**Environment**: \(Config.environment | *"N/A")
		**Generated**: {{.GeneratedAt}}

		---

		## Overview

		| Metric | Value |
		|--------|-------|
		| Total Resources | \(summary.total_resources) |
		| Deployment Layers | \(summary.total_layers) |
		| Gates Required | \(summary.gates_required) |
		| Root Services | \(summary.root_count) |
		| Leaf Services | \(summary.leaf_count) |

		---

		## Startup Procedure

		Deploy resources layer by layer. **Do not proceed to the next layer until
		all resources in the current layer are verified healthy.**

		"""

	_layerSections: strings.Join([
		for l in layers {
			"""

			### Layer \(l.layer) (\(l.resource_count) resources)

			| Resource | Type | IP | Host |
			|----------|------|----|----- |
			\(strings.Join([for r in l.resources {"| `\(r.name)` | \(strings.Join(r.types, ", ")) | \(r.ip) | \(r.host) |"}], "\n"))

			**Verification Checklist:**
			\(strings.Join([for r in l.resources {"- [ ] `\(r.name)` is healthy"}], "\n"))

			**Gate**: \(l.gate)

			---

			"""
		},
	], "\n")

	_shutdownSection: """
		## Shutdown Procedure

		If you need to shut down the entire environment, stop resources in reverse order:

		\(strings.Join([for i, name in shutdown_sequence {"\(i+1). `\(name)`"}], "\n"))

		**Important**: Wait for each resource to fully stop before proceeding to the next.

		"""

	_approvalSection: """
		## CAB Approval

		- [ ] All changes reviewed
		- [ ] Impact analysis reviewed
		- [ ] Rollback plan verified
		- [ ] Maintenance window confirmed
		- [ ] Stakeholders notified

		**Approved by**: __________________ **Date**: __________

		"""

	markdown: strings.Join([_header, _layerSections, _shutdownSection, _approvalSection], "\n")

	// JSON output
	json: {
		summary:           summary
		layers:            layers
		startup_sequence:  startup_sequence
		shutdown_sequence: shutdown_sequence
	}
}

// #RollbackPlan - Generate rollback plan for failed deployment
#RollbackPlan: {
	// Infrastructure graph
	Graph: {
		resources: [string]: {
			name: string
			"@type": {[string]: true}
			_depth: int
			...
		}
		...
	}

	// Layer where failure occurred (0-indexed)
	FailedAt: int

	// Optional: specific failed resources
	FailedResources?: [...string]

	// Configuration
	Config?: {
		organization?: string
		environment?:  string
		...
	}

	// Compute max depth
	_depths: [for _, r in Graph.resources {r._depth}]
	_maxDepth: [
		if len(_depths) > 0 {list.Max(_depths)},
		0,
	][0]

	// Resources that need rollback (at or above failed layer)
	_needsRollback: [
		for name, r in Graph.resources
		if r._depth >= FailedAt {
			name:  name
			depth: r._depth
		},
	]

	// Sort by depth descending (deepest first = leaves first)
	_sorted: list.Sort(_needsRollback, {x: {}, y: {}, less: x.depth > y.depth})

	// Rollback sequence
	rollback_sequence: [for r in _sorted {r.name}]

	// Resources that are safe (below failed layer)
	safe_resources: [
		for name, r in Graph.resources
		if r._depth < FailedAt {name},
	]

	// Summary
	summary: {
		failed_at:      FailedAt
		rollback_count: len(rollback_sequence)
		safe_count:     len(safe_resources)
		total_layers:   _maxDepth + 1
		layers_affected: _maxDepth + 1 - FailedAt
	}

	// Generate markdown
	_header: """
		# Rollback Plan

		**Organization**: \(Config.organization | *"N/A")
		**Environment**: \(Config.environment | *"N/A")
		**Failure Point**: Layer \(FailedAt)

		---

		## Summary

		| Metric | Value |
		|--------|-------|
		| Failed At Layer | \(summary.failed_at) |
		| Resources to Rollback | \(summary.rollback_count) |
		| Safe Resources | \(summary.safe_count) |
		| Layers Affected | \(summary.layers_affected) |

		---

		## Rollback Procedure

		Stop resources in the following order (deepest layers first):

		\(strings.Join([for i, name in rollback_sequence {"\(i+1). [ ] Stop `\(name)`"}], "\n"))

		---

		## Verification

		After rollback, verify these resources are still healthy:

		\(strings.Join([for name in safe_resources {"- [ ] `\(name)` is healthy"}], "\n"))

		---

		## Post-Rollback Actions

		1. [ ] Document root cause of failure
		2. [ ] Update change request with rollback details
		3. [ ] Notify stakeholders of rollback
		4. [ ] Schedule review meeting

		"""

	markdown: _header

	// JSON output
	json: {
		summary:           summary
		rollback_sequence: rollback_sequence
		safe_resources:    safe_resources
	}
}

// #MaintenanceRunbook - Runbook for maintaining a specific resource
#MaintenanceRunbook: {
	// Infrastructure graph
	Graph: {
		resources: [string]: {
			name: string
			"@type": {[string]: true}
			_depth:     int
			_ancestors: {[string]: bool}
			depends_on?: {[string]: true}
			...
		}
		...
	}

	// Target resource for maintenance
	Target: string

	// Type of maintenance
	MaintenanceType: "restart" | "update" | "replace" | "remove" | *"restart"

	// Configuration
	Config?: {
		organization?: string
		environment?:  string
		...
	}

	// Target info
	_target: Graph.resources[Target]

	// All affected resources
	affected: [
		for name, r in Graph.resources
		if r._ancestors[Target] != _|_ {name},
	]

	// Build shutdown order (affected resources, deepest first)
	_affectedWithDepth: [
		for name in affected {
			name:  name
			depth: Graph.resources[name]._depth
		},
	]
	_sortedAffected: list.Sort(_affectedWithDepth, {x: {}, y: {}, less: x.depth > y.depth})

	// Pre-maintenance: stop affected resources (leaves to roots)
	pre_maintenance_stops: [for r in _sortedAffected {r.name}]

	// Post-maintenance: start target then affected (roots to leaves)
	post_maintenance_starts: list.Concat([[Target], list.Reverse(pre_maintenance_stops)])

	// Summary
	summary: {
		target:               Target
		maintenance_type:     MaintenanceType
		affected_count:       len(affected)
		estimated_duration:   "\(2 + len(affected)*2) minutes" // 2 min base + 2 min per resource
		downtime_scope:       "\(len(affected)+1) resources"
	}

	// Generate markdown
	markdown: """
		# Maintenance Runbook: \(Target)

		**Organization**: \(Config.organization | *"N/A")
		**Environment**: \(Config.environment | *"N/A")
		**Maintenance Type**: \(MaintenanceType)

		---

		## Summary

		| Metric | Value |
		|--------|-------|
		| Target Resource | `\(Target)` |
		| Maintenance Type | \(summary.maintenance_type) |
		| Affected Resources | \(summary.affected_count) |
		| Estimated Duration | \(summary.estimated_duration) |
		| Downtime Scope | \(summary.downtime_scope) |

		---

		## Pre-Maintenance

		**Stop affected resources** (in order, deepest first):

		\(strings.Join([for i, name in pre_maintenance_stops {"\(i+1). [ ] Stop `\(name)`"}], "\n"))

		---

		## Maintenance

		Perform \(MaintenanceType) on `\(Target)`:

		- [ ] Verify target is ready for maintenance
		- [ ] Perform \(MaintenanceType)
		- [ ] Verify \(MaintenanceType) completed successfully
		- [ ] Verify target is healthy

		---

		## Post-Maintenance

		**Start resources** (in order, target first, then affected):

		\(strings.Join([for i, name in post_maintenance_starts {"\(i+1). [ ] Start `\(name)`"}], "\n"))

		---

		## Verification Checklist

		- [ ] Target `\(Target)` is healthy
		\(strings.Join([for name in affected {"- [ ] `\(name)` is healthy"}], "\n"))
		- [ ] All monitoring systems show normal
		- [ ] No errors in logs
		- [ ] Users/stakeholders notified of completion

		"""

	json: {
		summary:               summary
		pre_maintenance_stops: pre_maintenance_stops
		post_maintenance_starts: post_maintenance_starts
		affected:              affected
	}
}
