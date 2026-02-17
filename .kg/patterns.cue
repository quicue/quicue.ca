// Reusable patterns identified and applied in quicue.ca
package kg

import "quicue.ca/kg/core@v0"

p_struct_as_set: core.#Pattern & {
	name:     "Struct-as-Set"
	category: "data"
	problem:  "Arrays allow duplicates, require O(n) membership checks, and collide on unification."
	solution: "Use {[string]: true} for sets. O(1) membership, automatic dedup, clean unification via CUE lattice."
	context:  "Any field representing membership, tags, categories, or dependency sets."
	example:  "apercue/.kg/decisions/002-struct-as-set.cue"
	used_in: {
		"apercue":    true
		"datacenter": true
		"infra-graph": true
		"quicue.ca":  true
		"quicue-kg":  true
	}
	related: {
		"bidirectional_deps":    true
		"referential_integrity": true
	}
}

p_three_layer: core.#Pattern & {
	name:     "Three-Layer Architecture"
	category: "architecture"
	problem:  "Infrastructure models mix universal concepts with platform-specific implementations and concrete instances, making reuse difficult."
	solution: "Separate into definition (vocab/ + patterns/), template (template/*/), and value (examples/) layers. Each layer constrains the next via CUE unification."
	context:  "Infrastructure-as-code projects where the same resource model applies across multiple platforms."
	used_in: {
		"quicue.ca": true
	}
	related: {"compile_time_binding": true}
}

p_compile_time_binding: core.#Pattern & {
	name:     "Compile-Time Binding"
	category: "architecture"
	problem:  "Command templates with runtime placeholders ({host}, {container_id}) can fail at execution time if a field is missing or misspelled."
	solution: "Resolve all template parameters at CUE evaluation time using #ResolveTemplate. The output of cue export contains fully resolved commands — no placeholders survive."
	context:  "Provider action templates where parameters come from resource fields."
	used_in: {
		"quicue.ca": true
	}
	related: {"struct_as_set": true}
}

p_hidden_wrapper: core.#Pattern & {
	name:     "Hidden Wrapper for Exports"
	category: "cue"
	problem:  "CUE exports all public (capitalized) fields. Definitions that hold large input data as public fields leak that data into JSON export."
	solution: "Use hidden fields (_prefix) for intermediate computation. Expose only the final projection as a public field."
	context:  "Any CUE definition that produces export-ready JSON from larger input data."
	example:  "_viz holds computation, viz: {data: _viz.data} exposes output only"
	used_in: {
		"quicue.ca": true
	}
}
