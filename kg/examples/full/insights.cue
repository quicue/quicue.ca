package kg

import "quicue.ca/kg/core@v0"

insights: {
	"INSIGHT-001": core.#Insight & {
		id:         "INSIGHT-001"
		statement:  "CUE unification is the same operation for validation and federation"
		evidence:   ["Federating two .kg/ dirs via CUE import catches conflicting decision statuses as type errors"]
		method:     "experiment"
		confidence: "high"
		discovered: "2026-02-15"
		implication: "No separate federation mechanism needed — CUE's core semantics already provide it"
		action_items: ["Document federation-as-unification as a key differentiator"]
		related: {"ADR-002": true}
	}

	// Example: an insight discovered by surveying existing usage
	"INSIGHT-002": core.#Insight & {
		id:         "INSIGHT-002"
		statement:  "Informal .kg/ directories appear organically in projects before a formal schema exists"
		evidence: [
			"Multiple projects independently created .kg/ directories with ADRs and module registries",
			"Teams used ad-hoc CUE structs for the same entry types (decisions, patterns, rejected)",
		]
		method:      "cross_reference"
		confidence:  "medium"
		discovered:  "2026-02-15"
		implication: "Formalization adds compile-time validation to a pattern teams already follow informally"
	}
}
