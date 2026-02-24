// Charter — constraint-first project planning via CUE unification.
//
// Core definitions (#Charter, #Gate, #Milestone) are re-exported from
// apercue — the domain-agnostic upstream. #GapAnalysis is kept local
// to preserve the EARL report projection. #InfraCharter remains local
// as infrastructure-specific type constraint.
//
// Usage:
//   charter: charter.#Charter & {
//       name: "NHCF Deep Retrofit"
//       scope: {
//           total_resources: 18
//           root: "nhcf-agreement"
//           required_types: {Assessment: true, Design: true, Retrofit: true}
//       }
//       gates: {
//           "design-complete": {
//               phase: 3
//               requires: {"rideau-design": true, "gladstone-design": true}
//           }
//       }
//   }
//
//   gaps: charter.#GapAnalysis & {Charter: charter, Graph: infra}
//   // gaps.complete == false → gaps.missing tells you what's left

package charter

import (
	"list"
	"strings"
	"quicue.ca/vocab@v0"
	apercue_charter "apercue.ca/charter@v0"
)

// ═══════════════════════════════════════════════════════════════════════════
// CORE DEFINITIONS — re-exported from apercue
// ═══════════════════════════════════════════════════════════════════════════

#Charter: apercue_charter.#Charter
#Gate:    apercue_charter.#Gate

#Milestone: apercue_charter.#Milestone

// ═══════════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE-SPECIFIC
// ═══════════════════════════════════════════════════════════════════════════

// #InfraCharter — type-safe charter for infrastructure graphs.
//
// Constrains required_types keys to vocab.#TypeNames — the same
// type vocabulary that providers match on and JSON-LD exports as
// typed IRIs. A typo in required_types becomes a cue vet error.
#InfraCharter: #Charter & {
	scope: required_types?: {[vocab.#TypeNames]: true}
}

// ═══════════════════════════════════════════════════════════════════════════
// GAP ANALYSIS — local definition with EARL projection
// ═══════════════════════════════════════════════════════════════════════════

// #GapAnalysis — given a charter and a graph, compute what's missing.
//
// Kept local to preserve the EARL report projection (W3C EARL is
// quicue-specific; apercue only provides SHACL). Uses the same generic
// graph interface as apercue — accepts any graph with resources, roots,
// and topology.
//
// Usage:
//   gaps: #GapAnalysis & {Charter: myCharter, Graph: infra}
//   // gaps.complete          — true when charter is fully satisfied
//   // gaps.missing_resources — names in scope not yet in graph
//   // gaps.missing_types     — types required but not represented
//   // gaps.gate_status       — per-gate satisfaction with missing lists
//   // gaps.next_gate         — nearest unsatisfied gate (by phase)
#GapAnalysis: {
	Charter: #Charter
	Graph: {
		resources: {[string]: {name: string, "@type": {[string]: true}, ...}}
		roots: {[string]: true}
		topology: {...}
		...
	}

	// ── Present state ────────────────────────────────────────────
	_present: {for name, _ in Graph.resources {(name): true}}
	_types_present: {
		for _, r in Graph.resources {
			for t, _ in r["@type"] {(t): true}
		}
	}

	resource_count: len(Graph.resources)

	// ── Missing resources ────────────────────────────────────────
	missing_resources: {
		if Charter.scope.required_resources != _|_ {
			for name, _ in Charter.scope.required_resources
			if _present[name] == _|_ {(name): true}
		}
	}
	missing_resource_count: len([for _, _ in missing_resources {1}])

	// ── Missing types ────────────────────────────────────────────
	missing_types: {
		if Charter.scope.required_types != _|_ {
			for t, _ in Charter.scope.required_types
			if _types_present[t] == _|_ {(t): true}
		}
	}
	missing_type_count: len([for _, _ in missing_types {1}])

	// ── Root check ───────────────────────────────────────────────
	_root_satisfied: bool
	if Charter.scope.root == _|_ {
		_root_satisfied: true
	}
	if (Charter.scope.root & string) != _|_ {
		_root_satisfied: Graph.roots[Charter.scope.root] != _|_
	}
	if (Charter.scope.root & {[string]: true}) != _|_ {
		let _root_struct = Charter.scope.root & {[string]: true}
		_root_satisfied: len([
			for name, _ in _root_struct
			if Graph.roots[name] == _|_ {name},
		]) == 0
	}

	// ── Depth check ──────────────────────────────────────────────
	depth_satisfied: bool
	if Charter.scope.min_depth == _|_ {
		depth_satisfied: true
	}
	if Charter.scope.min_depth != _|_ {
		depth_satisfied: len(Graph.topology)-1 >= Charter.scope.min_depth
	}

	// ── Resource count check ─────────────────────────────────────
	count_satisfied: bool
	if Charter.scope.total_resources == _|_ {
		count_satisfied: true
	}
	if Charter.scope.total_resources != _|_ {
		count_satisfied: resource_count >= Charter.scope.total_resources
	}

	// ── Gate status ──────────────────────────────────────────────
	gate_status: {
		if Charter.gates != _|_ {
			for gname, gate in Charter.gates {
				(gname): {
					_missing: {
						for rname, _ in gate.requires
						if _present[rname] == _|_ {(rname): true}
					}
					missing: _missing
					satisfied: len([for _, _ in _missing {1}]) == 0

					// Check gate dependencies (DAG ordering)
					_deps_met: *true | bool
					if gate.depends_on != _|_ {
						_deps_met: len([
							for dep, _ in gate.depends_on
							if gate_status[dep].satisfied != true {dep},
						]) == 0
					}
					ready: _deps_met && satisfied
				}
			}
		}
	}

	// ── Unsatisfied gates ────────────────────────────────────────
	unsatisfied_gates: {
		for gname, gs in gate_status
		if !gs.satisfied {(gname): gs.missing}
	}

	// ── Next gate (lowest phase among unsatisfied) ───────────────
	_unsatisfied_with_phase: [
		for gname, gs in gate_status
		if !gs.satisfied && Charter.gates[gname].phase != _|_ {
			name:  gname
			phase: Charter.gates[gname].phase
		},
	]
	_sorted_unsatisfied: list.Sort(_unsatisfied_with_phase, {x: {}, y: {}, less: x.phase < y.phase})
	next_gate: *"" | string
	if len(_sorted_unsatisfied) > 0 {
		next_gate: _sorted_unsatisfied[0].name
	}

	// ── Overall completion ───────────────────────────────────────
	complete: missing_resource_count == 0 &&
		missing_type_count == 0 &&
		_root_satisfied &&
		depth_satisfied &&
		count_satisfied &&
		len([for _, _ in unsatisfied_gates {1}]) == 0

	// ── SHACL ValidationReport projection ──────────────────────
	// W3C SHACL (Recommendation, 2017-07-20): express gap analysis
	// results as sh:ValidationReport.
	shacl_report: {
		"@context":    vocab.context["@context"]
		"@type":       "sh:ValidationReport"
		"sh:conforms": complete
		"dcterms:conformsTo": {"@id": "charter:" + Charter.name}
		"sh:result": list.Concat([[
			for name, _ in missing_resources {
				"@type": "sh:ValidationResult"
				"sh:focusNode": {"@id": name}
				"sh:resultSeverity": {"@id": "sh:Violation"}
				"sh:resultMessage": "Required resource '" + name + "' not present in graph"
				"sh:sourceConstraintComponent": {"@id": "quicue:RequiredResource"}
			},
		], [
			for t, _ in missing_types {
				"@type": "sh:ValidationResult"
				"sh:focusNode": {"@id": t}
				"sh:resultSeverity": {"@id": "sh:Violation"}
				"sh:resultMessage": "Required type '" + t + "' not represented in graph"
				"sh:sourceConstraintComponent": {"@id": "quicue:RequiredType"}
			},
		]])
	}

	// ── EARL report projection ────────────────────────────────────
	// W3C EARL (Working Group Note, 2017-02-02): express gap analysis
	// as evaluation assertions. Complements shacl_report: SHACL reports
	// WHAT failed (validation), EARL reports WHETHER requirements are
	// met (evaluation).
	//
	// Export: cue export -e gaps.earl_report --out json
	earl_report: {
		"@type": "earl:EvaluationReport"
		"dct:conformsTo": {"@id": "http://www.w3.org/TR/EARL10-Schema/"}
		"earl:assertion": list.Concat([
			// Root constraint
			[{
				"@type": "earl:Assertion"
				"earl:test": {
					"@type":         "earl:TestCriterion"
					"dcterms:title": "Required roots present"
				}
				"earl:result": {
					"@type": "earl:TestResult"
					"earl:outcome": {"@id": "earl:" + ([if _root_satisfied {"passed"}, "failed"][0])}
				}
			}],
			// Depth constraint
			if Charter.scope.min_depth != _|_ {[{
				"@type": "earl:Assertion"
				"earl:test": {
					"@type":         "earl:TestCriterion"
					"dcterms:title": "Minimum depth >= \(Charter.scope.min_depth)"
				}
				"earl:result": {
					"@type": "earl:TestResult"
					"earl:outcome": {"@id": "earl:" + ([if depth_satisfied {"passed"}, "failed"][0])}
				}
			}]},
			// Resource count constraint
			if Charter.scope.total_resources != _|_ {[{
				"@type": "earl:Assertion"
				"earl:test": {
					"@type":         "earl:TestCriterion"
					"dcterms:title": "Resource count >= \(Charter.scope.total_resources)"
				}
				"earl:result": {
					"@type": "earl:TestResult"
					"earl:outcome": {"@id": "earl:" + ([if count_satisfied {"passed"}, "failed"][0])}
				}
			}]},
			// Gate assertions
			[for gname, gs in gate_status {
				"@type": "earl:Assertion"
				"earl:test": {
					"@type":         "earl:TestCriterion"
					"dcterms:title": "Gate: " + gname
				}
				"earl:result": {
					"@type": "earl:TestResult"
					"earl:outcome": {"@id": "earl:" + ([if gs.satisfied {"passed"}, "failed"][0])}
					if !gs.satisfied {
						"earl:info": "Missing: " + strings.Join([for m, _ in gs.missing {m}], ", ")
					}
				}
			}],
		])
	}
}
