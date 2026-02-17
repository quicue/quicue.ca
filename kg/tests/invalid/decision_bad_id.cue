package invalid

import "quicue.ca/kg/core@v0"

// This SHOULD fail: id doesn't match ADR-NNN pattern
d_bad: core.#Decision & {
	id:           "DECISION-1"
	title:        "Bad ID format"
	status:       "accepted"
	date:         "2026-02-15"
	context:      "test"
	decision:     "test"
	rationale:    "test"
	consequences: ["test"]
}
