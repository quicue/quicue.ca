// Self-hosting: quicue.ca tracks its own patterns-v2 work as a typed
// dependency graph. #CriticalPath computes the ordering. #GapAnalysis
// computes what's left. GitLab issues are just another projection.
//
// Single-graph pattern (tag-based):
//   All tasks live in one graph with a schema:actionStatus tag.
//   Progress = comprehension filter on status == "done".
//   The gap between charter constraints and done tasks IS the remaining work.
//
// W3C alignment:
//   schema:actionStatus  — task lifecycle (PotentialAction → CompletedAction)
//   dcterms:requires     — dependency relationships (ISO 15836-2:2019)
//   prov:wasDerivedFrom  — tasks link to INSIGHT-010
//   sh:ValidationReport  — compliance + gap results as SHACL reports
//
// Concepts exercised:
//   CUE:    fixpoint recursion, comprehension-as-query, tag-filtered views
//   quicue: everything-is-a-projection, @type unification, struct-as-set
//   ITIL:   change management (planned state → current → gap)
//   SHACL:  Charter gates ≈ structural shape constraints on typed graph
//
// Run:
//   cue eval  ./examples/patterns-v2/ -e gaps.summary      # what's left
//   cue eval  ./examples/patterns-v2/ -e cpm.summary        # scheduling
//   cue eval  ./examples/patterns-v2/ -e cpm.critical_sequence  # ordering
//   cue eval  ./examples/patterns-v2/ -e compliance.summary # meta-rules
//   cue export ./examples/patterns-v2/ -e gitlab_issues     # project to GitLab

package main

import (
	"strings"
	"quicue.ca/patterns@v0"
	"quicue.ca/charter@v0"
)

// ═══════════════════════════════════════════════════════════════════════════
// TASK GRAPH — planned work as typed resources
// ═══════════════════════════════════════════════════════════════════════════
//
// Each task is a resource in a dependency graph. The @type field works
// exactly like infrastructure types: Test, Audit, Wiring, Documentation.
// depends_on uses struct-as-set: {[string]: true}.
//
// derived_from links to INSIGHT/ADR IDs (PROV-O wasDerivedFrom pattern).
// status maps to schema:actionStatus — flip in progress.cue as work completes.

// schema:actionStatus constraint — every task gets a lifecycle tag.
_tasks: [string]: {
	status: *"pending" | "active" | "done" | "failed"
	...
}

_tasks: {
	// ── Phase 1: Exercising tests ────────────────────────────────────
	// All new patterns must be exercised against real graph data.
	// Independent of each other — can run in parallel.

	"exercise-cycle-detector": {
		name: "exercise-cycle-detector"
		"@type": {Test: true, Analysis: true}
		description: "Exercise #CycleDetector against 3-layer and datacenter examples — verify acyclic detection and cycle reporting"
		gate:        "exercising-tests"
		derived_from: ["INSIGHT-010"]
		weight: 2
	}
	"exercise-connected-components": {
		name: "exercise-connected-components"
		"@type": {Test: true, Analysis: true}
		description: "Exercise #ConnectedComponents — find orphans, verify is_connected, test isolated detection"
		gate:        "exercising-tests"
		derived_from: ["INSIGHT-010"]
		weight: 2
	}
	"exercise-subgraph": {
		name: "exercise-subgraph"
		"@type": {Test: true, Analysis: true}
		description: "Exercise #Subgraph extraction — roots mode, target+radius mode, both directions"
		gate:        "exercising-tests"
		derived_from: ["INSIGHT-010"]
		weight: 3
	}
	"exercise-graph-diff": {
		name: "exercise-graph-diff"
		"@type": {Test: true, Analysis: true}
		description: "Exercise #GraphDiff with before/after datacenter pair — added nodes, removed edges, type changes"
		gate:        "exercising-tests"
		derived_from: ["INSIGHT-010"]
		weight: 3
	}
	"exercise-critical-path": {
		name: "exercise-critical-path"
		"@type": {Test: true, Analysis: true}
		description: "Exercise #CriticalPath against datacenter with realistic weights — verify slack and critical sequence"
		gate:        "exercising-tests"
		derived_from: ["INSIGHT-010"]
		weight: 2
	}
	"exercise-compliance-check": {
		name: "exercise-compliance-check"
		"@type": {Test: true, Validation: true}
		description: "Exercise #ComplianceCheck with structural rules — databases need monitoring, no orphan load balancers"
		gate:        "exercising-tests"
		derived_from: ["INSIGHT-010"]
		weight: 3
	}
	"exercise-bootstrap-plan": {
		name: "exercise-bootstrap-plan"
		"@type": {Test: true, Lifecycle: true}
		description: "Exercise fixed #BootstrapPlan against non-trivial topology — verify correct layer ordering"
		gate:        "exercising-tests"
		derived_from: ["INSIGHT-010"]
		weight: 2
	}

	// ── Phase 1: Rename audit ────────────────────────────────────────
	// #ValidateGraph→#ValidateTypes rename must propagate to all consumers.

	"audit-validate-rename": {
		name: "audit-validate-rename"
		"@type": {Audit: true}
		description: "Update #ValidateGraph→#ValidateTypes across consumers: datacenter.cue, devbox.cue, homelab.cue, cue-topology.yml, nightly-validation.yml, cli.cue, docs/patterns.md"
		gate:        "rename-audit"
		derived_from: ["INSIGHT-010"]
		weight: 2
	}

	// ── Phase 2: Compliance wiring ───────────────────────────────────
	// #ComplianceCheck integration into real examples and CI.

	"wire-compliance-datacenter": {
		name: "wire-compliance-datacenter"
		"@type": {Wiring: true, Validation: true}
		description: "Define meaningful compliance rules for datacenter example — databases need backup, services need monitoring, no orphan resources"
		depends_on: {"exercise-compliance-check": true}
		gate:   "compliance-wiring"
		weight: 3
	}
	"wire-compliance-ci": {
		name: "wire-compliance-ci"
		"@type": {Wiring: true, CI: true}
		description: "Add #ComplianceCheck evaluation to GitLab CI pipeline — fail on critical violations"
		depends_on: {"wire-compliance-datacenter": true}
		gate:   "compliance-wiring"
		weight: 2
	}

	// ── Phase 3: Documentation ───────────────────────────────────────
	// Docs lag implementation — update after patterns are exercised.

	"update-patterns-docs": {
		name: "update-patterns-docs"
		"@type": {Documentation: true}
		description: "Update docs/patterns.md — add analysis patterns, compliance checking, lifecycle types, critical path"
		depends_on: {
			"exercise-cycle-detector":       true
			"exercise-connected-components": true
			"exercise-subgraph":             true
			"exercise-graph-diff":           true
			"exercise-critical-path":        true
			"exercise-compliance-check":     true
		}
		gate:   "docs-update"
		weight: 3
	}
	"update-graph-patterns-readme": {
		name: "update-graph-patterns-readme"
		"@type": {Documentation: true}
		description: "Update examples/graph-patterns/README.md with new analysis and compliance patterns"
		depends_on: {"exercise-cycle-detector": true}
		gate:   "docs-update"
		weight: 1
	}

	// ── Phase 2: Projection ──────────────────────────────────────────
	// The GitLab projection itself is a deliverable.

	"create-gitlab-projection": {
		name: "create-gitlab-projection"
		"@type": {Projection: true}
		description: "Write CUE→GitLab issue projection — cue export produces glab-compatible JSON"
		gate:        "gitlab-projection"
		weight:      2
	}
}

// Validate: every task references a valid gate
_gate_check: {
	for name, t in _tasks {
		(name): _charter.gates[t.gate]
	}
}

// ═══════════════════════════════════════════════════════════════════════════
// PLANNED GRAPH — all tasks, for scheduling and analysis
// ═══════════════════════════════════════════════════════════════════════════

plan: patterns.#InfraGraph & {Input: _tasks}

// Critical path: which tasks are on the longest chain?
cpm: patterns.#CriticalPath & {
	Graph: plan
	Weights: {for name, t in _tasks {(name): t.weight}}
}

// ═══════════════════════════════════════════════════════════════════════════
// CHARTER — what "done" looks like
// ═══════════════════════════════════════════════════════════════════════════

_charter: charter.#Charter & {
	name: "patterns-v2"

	scope: {
		total_resources: len(_tasks)
		required_resources: {for name, _ in _tasks {(name): true}}
		required_types: {
			Test:          true
			Audit:         true
			Wiring:        true
			Documentation: true
			Projection:    true
		}
	}

	gates: {
		"exercising-tests": {
			phase:       1
			description: "All new patterns exercised against real graph data"
			requires: {for name, t in _tasks if t.gate == "exercising-tests" {(name): true}}
		}
		"rename-audit": {
			phase:       1
			description: "All #ValidateGraph→#ValidateTypes references updated"
			requires: {"audit-validate-rename": true}
		}
		"compliance-wiring": {
			phase:       2
			description: "#ComplianceCheck integrated into datacenter and CI"
			requires: {for name, t in _tasks if t.gate == "compliance-wiring" {(name): true}}
			depends_on: {"exercising-tests": true}
		}
		"docs-update": {
			phase:       3
			description: "Documentation reflects all new patterns"
			requires: {for name, t in _tasks if t.gate == "docs-update" {(name): true}}
			depends_on: {"exercising-tests": true, "rename-audit": true}
		}
		"gitlab-projection": {
			phase:       2
			description: "Task graph projects to GitLab issues via cue export"
			requires: {"create-gitlab-projection": true}
		}
	}
}

// ═══════════════════════════════════════════════════════════════════════════
// PROGRESS — tag-filtered view for gap analysis
// ═══════════════════════════════════════════════════════════════════════════
//
// Flip status to "done" in progress.cue as work is completed.
// This comprehension extracts done tasks with deps stripped
// (progress graph is a flat set of accomplishments — topology is in plan).

_done_tasks: {
	for name, t in _tasks if t.status == "done" {
		(name): {
			name:    t.name
			"@type": t["@type"]
		}
	}
}
progress: patterns.#InfraGraph & {Input: _done_tasks}

// Gap analysis against progress
gaps: charter.#GapAnalysis & {
	Charter: _charter
	Graph:   progress
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPLIANCE — meta-rules about the task graph itself
// ═══════════════════════════════════════════════════════════════════════════

_compliance_summary: compliance.summary

compliance: patterns.#ComplianceCheck & {
	Graph: plan
	Rules: [
		{
			name:        "docs-need-tests"
			description: "Documentation tasks must depend on at least one Test"
			match_types: {Documentation: true}
			must_not_be_root: true // must depend on something
			severity:         "warning"
		},
		{
			name:        "wiring-needs-exercise"
			description: "Wiring tasks must depend on exercising tests"
			match_types: {Wiring: true}
			must_not_be_root: true
			severity:         "critical"
		},
	]
}

// schema:actionStatus IRI mapping
_status_iri: {
	"pending": "schema:PotentialActionStatus"
	"active":  "schema:ActiveActionStatus"
	"done":    "schema:CompletedActionStatus"
	"failed":  "schema:FailedActionStatus"
}

// ═══════════════════════════════════════════════════════════════════════════
// GITLAB PROJECTION — cue export -e gitlab_issues --out json
// ═══════════════════════════════════════════════════════════════════════════
//
// Produces JSON compatible with: glab issue create --title ... --description ...
// Pipe through jq + xargs glab to batch-create when GitLab is available.

gitlab_issues: [
	for name, t in _tasks {
		title: t.description
		_derived: {
			if t.derived_from != _|_ {
				text: strings.Join(t.derived_from, ", ")
			}
			if t.derived_from == _|_ {
				text: "n/a"
			}
		}
		description: """
			**Task:** \(name)
			**Gate:** \(t.gate)
			**Weight:** \(t.weight)
			**Status:** \(t.status)
			**Derived from:** \(_derived.text)

			Part of the patterns-v2 charter.
			"""
		labels: [for typeName, _ in t["@type"] {typeName}]
		weight: t.weight
		status: t.status
	},
]

// ═══════════════════════════════════════════════════════════════════════════
// SUMMARY — quick overview
// ═══════════════════════════════════════════════════════════════════════════

summary: {
	charter: _charter.name
	total:   len(_tasks)
	phases: [1, 2, 3]
	gap: {
		complete:               gaps.complete
		missing_resource_count: gaps.missing_resource_count
		missing_type_count:     gaps.missing_type_count
		next_gate:              gaps.next_gate
	}
	scheduling:       cpm.summary
	compliance_check: _compliance_summary
}
