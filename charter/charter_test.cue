// Test — exercise charter definitions against a minimal graph.
//
// Uses a small graph to verify gap analysis, gate evaluation,
// and completion detection.

package charter

import "quicue.ca/patterns@v0"

// ── Test graph (5 nodes, 2 layers) ─────────────────────────────
_test_resources: {
	"docker": {
		name:    "docker"
		"@type": {DockerHost: true}
	}
	"postgres": {
		name:    "postgres"
		"@type": {Database: true}
		depends_on: {"docker": true}
	}
	"redis": {
		name:    "redis"
		"@type": {Cache: true}
		depends_on: {"docker": true}
	}
	"api": {
		name:    "api"
		"@type": {AppWorkload: true}
		depends_on: {"postgres": true, "redis": true}
	}
	"frontend": {
		name:    "frontend"
		"@type": {AppWorkload: true}
		depends_on: {"api": true}
	}
}

// #GapAnalysis now accepts any graph with {resources, roots, topology}.
// patterns.#InfraGraph satisfies this interface.
_test_graph: patterns.#InfraGraph & {Input: _test_resources}

// ── Test 1: Complete charter (all resources present) ────────────
_complete_charter: #Charter & {
	name: "Test complete"
	scope: {
		total_resources: 5
		root:            "docker"
		required_resources: {"docker": true, "postgres": true, "api": true}
		required_types: {Database: true, AppWorkload: true}
		min_depth: 2
	}
	gates: {
		"db-ready": {
			phase:    1
			requires: {"docker": true, "postgres": true}
		}
		"api-ready": {
			phase:    2
			requires: {"api": true, "redis": true}
			depends_on: {"db-ready": true}
		}
	}
}

_complete_gaps: #GapAnalysis & {
	Charter: _complete_charter
	Graph:   _test_graph
}

// Assertions: everything should be satisfied
_complete_gaps: complete:               true
_complete_gaps: missing_resource_count: 0
_complete_gaps: missing_type_count:     0
_complete_gaps: count_satisfied:        true
_complete_gaps: depth_satisfied:        true

// ── Test 2: Incomplete charter (missing resources) ──────────────
_incomplete_charter: #Charter & {
	name: "Test incomplete"
	scope: {
		total_resources: 8 // only 5 exist
		required_resources: {"docker": true, "monitoring": true, "logging": true}
		required_types: {Database: true, MonitoringStack: true}
	}
	gates: {
		"monitoring-ready": {
			phase:    1
			requires: {"monitoring": true, "logging": true}
		}
	}
}

_incomplete_gaps: #GapAnalysis & {
	Charter: _incomplete_charter
	Graph:   _test_graph
}

// Assertions: should report gaps
_incomplete_gaps: complete:               false
_incomplete_gaps: missing_resource_count: 2 // monitoring, logging
_incomplete_gaps: missing_type_count:     1 // MonitoringStack
_incomplete_gaps: count_satisfied:        false
_incomplete_gaps: missing_resources: {monitoring: true, logging: true}
_incomplete_gaps: missing_types: {MonitoringStack: true}
_incomplete_gaps: next_gate: "monitoring-ready"

// ── Test 3: Milestone evaluation ────────────────────────────────
_test_milestone: #Milestone & {
	Charter: _complete_charter
	Gate:    "db-ready"
	Graph:   _test_graph
}

_test_milestone: satisfied: true
_test_milestone: summary: missing_count: 0
