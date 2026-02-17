// Smallest possible .kg/ — one decision, validates with cue vet
package kg

import "quicue.ca/kg/core@v0"

decisions: {
	"ADR-001": core.#Decision & {
		id:           "ADR-001"
		title:        "Use CUE for configuration"
		status:       "accepted"
		date:         "2026-02-15"
		context:      "Need a type-safe configuration language."
		decision:     "Use CUE for all configuration and schema definitions."
		rationale:    "CUE provides compile-time validation, unification, and a lattice-based type system."
		consequences: ["All config files are .cue, validated with cue vet"]
	}
}
