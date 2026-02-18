// Knowledge graph index — comprehension-derived, never hand-maintained
package kg

import "quicue.ca/kg/aggregate@v0"

_index: aggregate.#KGIndex & {
	project: "quicue.ca"

	decisions: {
		"ADR-001": d001
		"ADR-002": d002
		"ADR-003": d003
		"ADR-004": d004
		"ADR-005": d005
	}

	insights: {
		"INSIGHT-001": i001
		"INSIGHT-002": i002
		"INSIGHT-003": i003
	}
	rejected: {
		"REJ-001": r001
		"REJ-002": r002
		"REJ-003": r003
		"REJ-004": r004
	}
	patterns: {
		struct_as_set:              p_struct_as_set
		three_layer:                p_three_layer
		compile_time_binding:       p_compile_time_binding
		hidden_wrapper:             p_hidden_wrapper
		contract_via_unification:   p_contract_via_unification
		gap_as_backlog:             p_gap_as_backlog
	}
}

// W3C projections — export via: cue export . -e provenance.graph
_provenance:  aggregate.#Provenance & {index:   _index}
_annotations: aggregate.#Annotations & {index:  _index}
_catalog: aggregate.#DatasetEntry & {index: _index, context: project}
