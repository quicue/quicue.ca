package kg

import "quicue.ca/kg/core@v0"

patterns: {
	"struct-as-set": core.#Pattern & {
		name:     "Struct-as-Set"
		category: "data"
		problem:  "Arrays allow duplicates and require O(n) membership checks."
		solution: "Use {[string]: true} for sets. O(1) membership, automatic dedup via CUE unification."
		context:  "Any field representing membership, tags, categories, or dependency sets."
		example:  "quicue.ca/vocab/resource.cue — depends_on, @type, provides"
		used_in: {
			"quicue.ca": true
			"quicue-kg": true
		}
		related: {adr_as_cue: true}
	}

	adr_as_cue: core.#Pattern & {
		name:     "ADR as CUE Struct"
		category: "knowledge"
		problem:  "Architecture Decision Records in markdown are not queryable or type-checked."
		solution: "Encode decisions as CUE structs with validated fields: id, status, date, context, decision, rationale, consequences."
		context:  "Project knowledge management where decisions should be queryable and validated."
		used_in: {
			"quicue.ca": true
			"quicue-kg": true
		}
		related: {"struct-as-set": true, comprehension_index: true}
	}

	comprehension_index: core.#Pattern & {
		name:     "Comprehension-Derived Index"
		category: "cue"
		problem:  "Manually maintained indexes drift from source data."
		solution: "CUE comprehensions compute indexes (by_category, by_project, summary) from data. Indexes are derived, never maintained."
		context:  "Any CUE model where aggregation views must stay synchronized with source data."
		example:  "#KGIndex.by_status and by_confidence views derived from entry data"
		used_in: {
			"quicue-kg": true
		}
		related: {adr_as_cue: true}
	}
}
