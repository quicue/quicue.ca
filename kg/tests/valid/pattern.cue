package valid

import "quicue.ca/kg/core@v0"

p001: core.#Pattern & {
	name:     "Struct-as-Set"
	category: "data"
	problem:  "Arrays allow duplicates and require O(n) membership checks."
	solution: "Use {[string]: true} for sets. O(1) membership, automatic dedup."
	context:  "Any field representing membership, tags, or dependency sets."
	example:  "quicue.ca/vocab/resource.cue"
	used_in: {
		"quicue.ca":   true
		"infra-graph": true
		datacenter:    true
	}
	related: {referential_integrity: true}
}
