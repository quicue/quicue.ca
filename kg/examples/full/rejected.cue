package kg

import "quicue.ca/kg/core@v0"

rejected: {
	"REJ-001": core.#Rejected & {
		id:          "REJ-001"
		approach:    "Use SPARQL/Oxigraph as primary query mechanism"
		reason:      "Requires running infrastructure (triplestore, SPARQL endpoint). Adds deployment complexity that conflicts with zero-infrastructure design goal."
		date:        "2026-02-15"
		alternative: "CUE-native federation via import/unification. Zero infrastructure. cue vet is the only tool needed."
		related: {"ADR-002": true}
	}

	"REJ-002": core.#Rejected & {
		id:          "REJ-002"
		approach:    "Embed knowledge graph framework inside quicue.ca core"
		reason:      "quicue.ca should work without the KG framework. Embedding creates a hard dependency. Not all quicue users need knowledge graph types."
		date:        "2026-02-15"
		alternative: "Standalone module at quicue.ca/kg@v0 — optional dependency, same as provider templates."
	}
}
