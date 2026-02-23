// Charter — constraint-first project planning via CUE unification.
//
// Declare what "done" looks like. Build the graph incrementally.
// cue vet tells you what's missing. When it passes, the charter is satisfied.
//
// The gap between constraints and data IS the remaining work.
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

// Re-export apercue base types — downstream consumers (cmhc-retrofit,
// maison-613) import quicue.ca/charter@v0 unchanged.
#Charter: apercue_charter.#Charter
#Gate:    apercue_charter.#Gate

// #InfraCharter — type-safe charter for infrastructure graphs.
//
// Constrains required_types keys to vocab.#TypeNames — the same
// type vocabulary that providers match on and JSON-LD exports as
// typed IRIs. A typo in required_types becomes a cue vet error.
//
// Usage:
//   charter: charter.#InfraCharter & {
//       name: "Example Datacenter"
//       scope: {
//           total_resources: 30
//           required_types: {DNSServer: true, VirtualizationPlatform: true}
//       }
//   }
#InfraCharter: #Charter & {
	scope: required_types?: {[vocab.#TypeNames]: true}
}

// #GapAnalysis — extends apercue base with EARL report projection.
//
// Base analysis (missing resources, types, gates, SHACL report) comes
// from apercue.ca/charter. EARL report is a quicue.ca extension.
//
// Usage:
//   gaps: #GapAnalysis & {Charter: myCharter, Graph: infra}
//   // gaps.complete          — true when charter is fully satisfied
//   // gaps.missing_resources — names in scope not yet in graph
//   // gaps.missing_types     — types required but not represented
//   // gaps.gate_status       — per-gate satisfaction with missing lists
//   // gaps.next_gate         — nearest unsatisfied gate (by phase)
//   // gaps.shacl_report      — W3C SHACL ValidationReport (from apercue)
//   // gaps.earl_report       — W3C EARL EvaluationReport (quicue extension)
#GapAnalysis: apercue_charter.#GapAnalysis

// #EARLReport — W3C EARL projection from gap analysis results.
//
// W3C EARL (Working Group Note, 2017-02-02): express gap analysis
// as evaluation assertions. Each charter constraint becomes an
// earl:Assertion with pass/fail outcome.
//
// Complements GapAnalysis.shacl_report: SHACL reports WHAT failed
// (validation), EARL reports WHETHER requirements are met (evaluation).
//
// Usage:
//   gaps: #GapAnalysis & {Charter: myCharter, Graph: infra}
//   earl: #EARLReport & {Gaps: gaps}
//   // cue export -e earl.report --out json
#EARLReport: {
	Gaps: #GapAnalysis

	report: {
		"@type":          "earl:EvaluationReport"
		"dct:conformsTo": {"@id": "http://www.w3.org/TR/EARL10-Schema/"}
		"earl:assertion": list.Concat([
			// Overall completion
			[{
				"@type": "earl:Assertion"
				"earl:test": {
					"@type":         "earl:TestCriterion"
					"dcterms:title": "Charter complete"
				}
				"earl:result": {
					"@type":        "earl:TestResult"
					"earl:outcome": {"@id": "earl:" + ([if Gaps.complete {"passed"}, "failed"][0])}
				}
			}],
			// Resource count constraint
			[{
				"@type": "earl:Assertion"
				"earl:test": {
					"@type":         "earl:TestCriterion"
					"dcterms:title": "All required resources present"
				}
				"earl:result": {
					"@type":        "earl:TestResult"
					"earl:outcome": {"@id": "earl:" + ([if Gaps.missing_resource_count == 0 {"passed"}, "failed"][0])}
				}
			}],
			// Type coverage constraint
			[{
				"@type": "earl:Assertion"
				"earl:test": {
					"@type":         "earl:TestCriterion"
					"dcterms:title": "All required types represented"
				}
				"earl:result": {
					"@type":        "earl:TestResult"
					"earl:outcome": {"@id": "earl:" + ([if Gaps.missing_type_count == 0 {"passed"}, "failed"][0])}
				}
			}],
			// Gate assertions
			[for gname, gs in Gaps.gate_status {
				"@type": "earl:Assertion"
				"earl:test": {
					"@type":         "earl:TestCriterion"
					"dcterms:title": "Gate: " + gname
				}
				"earl:result": {
					"@type":        "earl:TestResult"
					"earl:outcome": {"@id": "earl:" + ([if gs.satisfied {"passed"}, "failed"][0])}
					if !gs.satisfied {
						"earl:info": "Missing: " + strings.Join([for m, _ in gs.missing {m}], ", ")
					}
				}
			}],
		])
	}
}

// #Milestone — re-export apercue base type.
#Milestone: apercue_charter.#Milestone
