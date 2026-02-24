// Public showcase — quicue.ca surfaces modeled as a dependency graph.
//
// Each deliverable is a resource. Types categorize the work.
// Dependencies encode the actual build order. The graph grows
// as deliverables complete; the charter gap shrinks to zero.
//
// Run:
//   cue vet  ./examples/showcase/
//   cue eval ./examples/showcase/ -e gaps
//   cue eval ./examples/showcase/ -e gaps.complete
//   cue eval ./examples/showcase/ -e gaps.next_gate
//   cue eval ./examples/showcase/ -e gaps.unsatisfied_gates

package main

import (
	"quicue.ca/charter@v0"
	"quicue.ca/patterns@v0"
)

// ── Resource types ──────────────────────────────────────────────
// Struct-as-set: membership is O(1), unification merges cleanly.

// ── Completed deliverables ──────────────────────────────────────
// Add resources here as they complete. The gap analysis shows
// what's left. When gaps.complete == true, the showcase is done.

_resources: {
	// Gate 0: Schema validation
	"schema-validation": {
		name: "schema-validation"
		"@type": {CI: true}
	}

	// Gate 1: Binding CI
	"binding-ci": {
		name: "binding-ci"
		"@type": {CI: true}
		depends_on: {"schema-validation": true}
	}

	// Gate 2: Server integration CI
	"server-ci": {
		name: "server-ci"
		"@type": {CI: true}
		depends_on: {"binding-ci": true}
	}

	// Security audit (root — no deps)
	"github-audit": {
		name: "github-audit"
		"@type": {Security: true}
	}

	// Gate 3 deliverables (public surfaces with safe data)
	"cat-public": {
		name: "cat-public"
		"@type": {Deployment: true}
		depends_on: {"schema-validation": true}
	}

	"kg-public": {
		name: "kg-public"
		"@type": {Deployment: true}
		depends_on: {"schema-validation": true}
	}

	"cmhc-public": {
		name: "cmhc-public"
		"@type": {Deployment: true}
		depends_on: {"schema-validation": true}
	}

	"imp-safe-data": {
		name: "imp-safe-data"
		"@type": {Deployment: true, Security: true}
		depends_on: {"server-ci": true, "github-audit": true}
	}

	"api-safe-data": {
		name: "api-safe-data"
		"@type": {Deployment: true, Security: true}
		depends_on: {"server-ci": true, "github-audit": true}
	}

	// ── Uncomment as deliverables complete ──────────────────────
	// Gate 3 final: CF Access removal
	// "imp-public": {
	// 	name:   "imp-public"
	// 	"@type": {Deployment: true}
	// 	depends_on: {"imp-safe-data": true}
	// }
	// "api-public": {
	// 	name:   "api-public"
	// 	"@type": {Deployment: true}
	// 	depends_on: {"api-safe-data": true}
	// }

	// Gate 4: Interactive catalogue
	// "interactive-upload": {
	// 	name:   "interactive-upload"
	// 	"@type": {Interactive: true}
	// 	depends_on: {"cat-public": true}
	// }
	// "graph-editor": {
	// 	name:   "graph-editor"
	// 	"@type": {Interactive: true}
	// 	depends_on: {"interactive-upload": true}
	// }

	// Gate 5: SPARQL
	// "oxigraph": {
	// 	name:   "oxigraph"
	// 	"@type": {Semantic: true}
	// 	depends_on: {"api-public": true}
	// }
}

// ── Graph ───────────────────────────────────────────────────────
// #InfraGraph computes topology, roots, layers from dependencies.
infra: patterns.#InfraGraph & {Input: _resources}

// ── Charter ─────────────────────────────────────────────────────
// Declares what "done" looks like. Gates form a DAG.
_charter: charter.#Charter & {
	name: "Public Showcase"
	scope: {
		total_resources: 14
		root: {"schema-validation": true, "github-audit": true}
		required_resources: {
			"schema-validation":  true
			"binding-ci":         true
			"server-ci":          true
			"github-audit":       true
			"cat-public":         true
			"kg-public":          true
			"cmhc-public":        true
			"imp-safe-data":      true
			"api-safe-data":      true
			"imp-public":         true
			"api-public":         true
			"interactive-upload": true
			"graph-editor":       true
			"oxigraph":           true
		}
		required_types: {
			CI:          true
			Security:    true
			Deployment:  true
			Interactive: true
			Semantic:    true
		}
	}
	gates: {
		"schema": {
			phase:       0
			description: "CUE schemas validate — cue vet passes on all packages"
			requires: {"schema-validation": true}
		}
		"binding": {
			phase:       1
			description: "CI validates 28+ providers bind with no unresolved placeholders"
			requires: {"binding-ci": true}
			depends_on: {"schema": true}
		}
		"server": {
			phase:       2
			description: "CI validates 654 routes via real FastAPI server in mock mode"
			requires: {"server-ci": true}
			depends_on: {"binding": true}
		}
		"public-showcase": {
			phase:       3
			description: "All surfaces public with safe data — zero real IPs"
			requires: {
				"cat-public":    true
				"kg-public":     true
				"cmhc-public":   true
				"imp-public":    true
				"api-public":    true
				"github-audit":  true
				"imp-safe-data": true
				"api-safe-data": true
			}
			depends_on: {"server": true}
		}
		"interactive": {
			phase:       4
			description: "Upload JSON-LD and edit graphs in the catalogue"
			requires: {
				"interactive-upload": true
				"graph-editor":       true
			}
			depends_on: {"public-showcase": true}
		}
		"sparql": {
			phase:       5
			description: "Oxigraph SPARQL endpoint — execute bound actions from queries"
			requires: {"oxigraph": true}
			depends_on: {"interactive": true}
		}
	}
}

// ── Gap analysis ────────────────────────────────────────────────
// The gap between _charter and infra IS the remaining work.
gaps: charter.#GapAnalysis & {
	Charter: _charter
	Graph:   infra
}
