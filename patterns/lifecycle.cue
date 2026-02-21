// patterns/lifecycle.cue — Deployment lifecycle types
//
// Composable types for the full deployment lifecycle:
//   Bundle → Bootstrap → Execute → Verify → Drift
//
// Each type unifies with #InfraGraph and #ExecutionPlan via shared
// resource/provider schemas. New lifecycle phases are added by defining
// a new type here, not by writing a new script.
//
// ADR-013: Lifecycle management belongs in patterns/, not a separate package.
// INSIGHT-009: Airgapped deployment gotchas documented in #Gotcha registry.
//
// See also:
//   operator/airgap-bundle.cue — #Bundle and #Gotcha for portable packaging
//   patterns/deploy.cue — #ExecutionPlan composition
//   patterns/graph.cue — #InfraGraph, #DeploymentPlan, #RollbackPlan

package patterns

import (
	"list"
	"strings"
)

// #LifecyclePhase enumerates the ordered phases of a deployment lifecycle.
#LifecyclePhase: "package" | "bootstrap" | "bind" | "deploy" | "verify" | "drift"

// Ordered list for SKOS export (CUE can't iterate disjunctions).
_lifecyclePhaseList: ["package", "bootstrap", "bind", "deploy", "verify", "drift"]

// #LifecyclePhasesSKOS — W3C SKOS OrderedCollection projection.
// Exports lifecycle phases as machine-readable ordered concepts.
//
// Export: cue export ./patterns/ -e #LifecyclePhasesSKOS --out json
#LifecyclePhasesSKOS: {
	"@type":          "skos:OrderedCollection"
	"skos:prefLabel": "Deployment Lifecycle Phases"
	"skos:memberList": {
		"@list": [
			for i, p in _lifecyclePhaseList {
				"@type":          "skos:Concept"
				"@id":            "quicue:lifecycle/" + p
				"skos:prefLabel": p
				"skos:notation":  "\(i)"
			},
		]
	}
}

// --- Bootstrap (absorbed from boot/) ---

// #BootstrapResource adds lifecycle commands and health checks to a resource.
// Open schema — unifies with any resource shape via CUE lattice.
#BootstrapResource: {
	name: string
	...

	lifecycle?: {
		create?:  string
		start?:   string
		stop?:    string
		restart?: string
		destroy?: string
		status?:  string
	}

	health?: {
		command:  string
		timeout?: string | *"30s"
		retries?: int | *3
	}

	depends_on?: {[string]: true}
}

// #BootstrapPlan computes layered creation order from dependency topology.
// Composes with #InfraGraph: the same resources feed both graphs.
#BootstrapPlan: {
	resources: [string]: #BootstrapResource

	// Compute correct topological depth via recursive fixpoint (same as #InfraGraph._depth).
	// Base case: no deps → 0. Recursive: max(dep depths) + 1.
	_depths: {
		for name, res in resources {
			let _deps = *res.depends_on | {}
			(name): [
				if len([for d, _ in _deps if resources[d] != _|_ {d}]) > 0 {
					list.Max([for d, _ in _deps if resources[d] != _|_ {_depths[d]}]) + 1
				},
				0,
			][0]
		}
	}

	// Computed: resources grouped by their dependency depth
	_by_layer: {
		for name, res in resources {
			"\(_depths[name])": (name): res
		}
	}

	// Output: create script with layer gates (same pattern as #DeploymentPlan)
	script: string | *strings.Join([
		"#!/usr/bin/env bash",
		"set -euo pipefail",
		"",
		for layer_str, layer_resources in _by_layer {
			let cmds = [for name, res in layer_resources if res.lifecycle != _|_ && res.lifecycle.create != _|_ {
				"echo \"Creating \(name)...\"\n\(res.lifecycle.create)"
			}]
			if len(cmds) > 0 {
				strings.Join(["echo \"=== Layer \(layer_str) ===\""] + cmds + [
					"echo \"Layer \(layer_str) complete.\"",
					"",
				], "\n")
			}
		},
	], "\n")

	// ── PROV-O projection ────────────────────────────────────────
	// Bootstrap is a prov:Activity that creates resources in
	// topological order. Each resource creation is a sub-activity.
	//
	// Export: cue export -e bootstrap.prov_report --out json
	prov_report: {
		"@type":      "prov:Activity"
		"prov:type":  "quicue:Bootstrap"
		"prov:generated": [
			for name, res in resources {
				"@type":     "prov:Entity"
				"@id":       "quicue:resource/" + name
				"prov:type": "quicue:BootstrapResource"
				"dcterms:title": name
				if res.lifecycle != _|_ if res.lifecycle.create != _|_ {
					"prov:wasGeneratedBy": {
						"@type":     "prov:Activity"
						"prov:type": "quicue:CreateResource"
						"prov:atLocation": "layer-\(_depths[name])"
					}
				}
			},
		]
	}
}

// --- Drift Detection ---

// #DriftEntry captures a single declared-vs-live divergence.
#DriftEntry: {
	resource: string
	field:    string
	declared: _
	observed: _
	severity: *"warning" | "critical" | "info"
	action?:  string // remediation command if available
}

// #DriftReport compares declared state (from CUE) against observed state.
// The report is a projection: CUE declares what SHOULD be, the live state
// is injected as JSON, and the comprehension computes divergences.
#DriftReport: {
	// Declared state — typically from #ExecutionPlan.cluster.resources
	declared: [string]: {...}

	// Observed state — injected from runtime (cue export -t observed=@file.json)
	observed: [string]: {...}

	// Computed: resources in declared but not observed
	missing: {
		for name, _ in declared if observed[name] == _|_ {
			(name): true
		}
	}

	// Computed: resources in observed but not declared
	extra: {
		for name, _ in observed if declared[name] == _|_ {
			(name): true
		}
	}

	// Drift entries are provided by the consumer — CUE can't generically
	// diff arbitrary structs, so the consumer writes field-specific comparisons.
	drifts: [...#DriftEntry]

	// Summary
	summary: {
		total_declared: len(declared)
		total_observed: len(observed)
		total_missing:  len(missing)
		total_extra:    len(extra)
		total_drifted:  len(drifts)
		in_sync:        total_missing == 0 && total_extra == 0 && total_drifted == 0
	}

	// ── PROV-O projection ────────────────────────────────────────
	// Drift detection is a prov:Activity: it compares declared state
	// (prov:used) against observed state and generates a report.
	//
	// Export: cue export -e drift.prov_report --out json
	prov_report: {
		"@type":        "prov:Activity"
		"prov:type":    "quicue:DriftDetection"
		"prov:used": [
			{"@type": "prov:Entity", "prov:type": "quicue:DeclaredState", "prov:value": summary.total_declared},
			{"@type": "prov:Entity", "prov:type": "quicue:ObservedState", "prov:value": summary.total_observed},
		]
		"prov:generated": {
			"@type":       "prov:Entity"
			"prov:type":   "quicue:DriftReport"
			"prov:value": {
				missing: summary.total_missing
				extra:   summary.total_extra
				drifted: summary.total_drifted
				in_sync: summary.in_sync
			}
		}
		"schema:actionStatus": {
			if summary.in_sync {"@id": "schema:CompletedActionStatus"}
			if !summary.in_sync {"@id": "schema:FailedActionStatus"}
		}
	}
}

// --- Smoke Test ---

// #Check is a single verification assertion.
// Reused by operator/airgap-bundle.cue#Bundle.checks.
#Check: {
	label:    string
	command:  string
	expected: string
}

// #SmokeTest runs a list of checks and produces a pass/fail report.
#SmokeTest: {
	checks: [...#Check]

	// Output: bash script that runs all checks
	script: string | *strings.Join([
		"#!/usr/bin/env bash",
		"PASS=0; FAIL=0",
		"check() { local label=\"$1\" cmd=\"$2\" exp=\"$3\"; result=$(eval \"$cmd\" 2>&1); if echo \"$result\" | grep -q \"$exp\"; then echo \"  PASS: $label\"; PASS=$((PASS+1)); else echo \"  FAIL: $label\"; FAIL=$((FAIL+1)); fi; }",
		"",
	] + [
		for c in checks {
			"check \"\(c.label)\" \"\(c.command)\" \"\(c.expected)\""
		},
	] + [
		"",
		"echo \"\"",
		"echo \"Results: $PASS passed, $FAIL failed\"",
		"[ $FAIL -eq 0 ]",
	], "\n")

	// ── EARL report projection ────────────────────────────────────
	// W3C EARL (Working Group Note, 2017-02-02): express test plans
	// as earl:Assertion for interoperability with accessibility and
	// conformance testing frameworks.
	//
	// Outcome is earl:untested at CUE eval time (actual results come
	// from running the script). The test PLAN is the linked data.
	//
	// Export: cue export -e verify.earl_report --out json
	earl_report: [
		for c in checks {
			"@type": "earl:Assertion"
			"earl:test": {
				"@type":        "earl:TestCriterion"
				"dcterms:title": c.label
				"earl:command":  c.command
			}
			"earl:result": {
				"@type":        "earl:TestResult"
				"earl:outcome": {"@id": "earl:untested"}
				"earl:expected": c.expected
			}
		},
	]
}

// --- Deployment Lifecycle (composition) ---

// #DeploymentLifecycle composes all lifecycle phases into a single type.
// Each phase is optional — a project can use any subset.
//
// Usage:
//   lifecycle: #DeploymentLifecycle & {
//     execution: #ExecutionPlan & { resources: _resources, providers: _providers }
//     verify: #SmokeTest & { checks: [...] }
//     drift: #DriftReport & { declared: execution.cluster.resources }
//   }
#DeploymentLifecycle: {
	// Phase 1: Bootstrap — create resources in dependency order
	bootstrap?: #BootstrapPlan

	// Phase 2: Bind + Execute — resolve commands and generate deployment plan
	execution?: #ExecutionPlan

	// Phase 3: Verify — run smoke tests
	verify?: #SmokeTest

	// Phase 4: Drift — compare declared vs. live state
	drift?: #DriftReport

	// Metadata
	name:    string
	version: string | *"0.1.0"
	phases:  [...#LifecyclePhase]
}
