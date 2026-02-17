// quicue.ca project identity
package kg

import "quicue.ca/kg/ext@v0"

project: ext.#Context & {
	"@id":        "https://quicue.ca/project/quicue-ca"
	name:         "quicue.ca"
	description:  "CUE vocabulary for infrastructure as typed, queryable dependency graphs"
	module:       "quicue.ca@v0"
	repo:         "https://github.com/quicue/quicue.ca"
	license:      "Apache-2.0"
	status:       "active"
	cue_version:  "v0.15.4"
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
