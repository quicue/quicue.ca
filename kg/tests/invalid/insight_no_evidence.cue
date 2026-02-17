package invalid

import "quicue.ca/kg/core@v0"

// This SHOULD fail: evidence list is empty (must have at least one)
i_bad: core.#Insight & {
	id:          "INSIGHT-001"
	statement:   "Something with no evidence"
	evidence:    []
	method:      "observation"
	confidence:  "high"
	discovered:  "2026-02-15"
	implication: "test"
}
