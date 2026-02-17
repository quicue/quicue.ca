package kg

import "quicue.ca/kg/core@v0"

decisions: {
	"ADR-001": core.#Decision & {
		id:     "ADR-001"
		title:  "Minimal core with optional extensions"
		status: "accepted"
		date:   "2026-02-15"

		context:   "The framework must serve projects from infrastructure to bioinformatics to game development."
		decision:  "4 core types (Decision, Pattern, Insight, Rejected) plus optional extension types (Derivation, Workspace, Context)."
		rationale: "Core types are universal. Extensions are domain-specific. Projects import only what they need."
		consequences: [
			"Core types have zero external dependencies",
			"Extension types may import from core but not vice versa",
		]
		related: {"ADR-002": true}
	}

	"ADR-002": core.#Decision & {
		id:     "ADR-002"
		title:  "CUE-native federation over SPARQL"
		status: "accepted"
		date:   "2026-02-15"

		context:      "Cross-project knowledge querying could use SPARQL (external infra) or CUE unification (zero infra)."
		decision:     "Use CUE unification for federation. No external database or query engine."
		rationale:    "CUE's lattice model gives conflict detection for free. SPARQL requires infrastructure. Zero-infra means adoption friction is zero."
		consequences: ["Federation is a CUE import, not a service call"]
		related: {"ADR-001": true, "struct-as-set": true}
	}

	"ADR-003": core.#Decision & {
		id:     "ADR-003"
		title:  "Struct-as-set for all set-valued fields"
		status: "accepted"
		date:   "2026-02-15"

		context:      "Pattern.used_in and related fields represent sets. Arrays allow duplicates."
		decision:     "Use {[string]: true} for all set-valued fields."
		rationale:    "O(1) membership, clean unification, no duplicates. Struct keys are unique by construction."
		consequences: ["All set fields use struct syntax, not array syntax"]
	}
}
