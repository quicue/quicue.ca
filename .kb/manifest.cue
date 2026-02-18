// quicue.ca knowledge base manifest
//
// Declares this repo's knowledge topology: which semantic graphs
// it maintains, what types they contain, and which W3C vocabularies
// they map to. The directory structure IS the ontology.
package kb

import "quicue.ca/kg/ext@v0"

_project: ext.#Context & {
	"@id":       "https://quicue.ca/project/quicue-ca"
	name:        "quicue.ca"
	description: "CUE vocabulary for infrastructure as typed, queryable dependency graphs"
	module:      "quicue.ca@v0"
	repo:        "https://github.com/quicue/quicue.ca"
	license:     "Apache-2.0"
	status:      "active"
	cue_version: "v0.15.4"
	uses: [
		{"@id": "https://quicue.ca/pattern/three-layer"},
		{"@id": "https://quicue.ca/pattern/struct-as-set"},
		{"@id": "https://quicue.ca/pattern/compile-time-binding"},
		{"@id": "https://quicue.ca/pattern/execution-plan"},
	]
	knows: [
		{"@id": "https://quicue.ca/concept/cue-unification"},
		{"@id": "https://quicue.ca/concept/json-ld"},
		{"@id": "https://quicue.ca/concept/dependency-graph"},
	]
}

kb: ext.#KnowledgeBase & {
	context: _project
	graphs: {
		decisions: ext.#DecisionsGraph
		patterns:  ext.#PatternsGraph
		insights:  ext.#InsightsGraph
		rejected:  ext.#RejectedGraph
	}
}
