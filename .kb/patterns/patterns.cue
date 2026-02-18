// Reusable patterns identified and applied in quicue.ca
package patterns

import "quicue.ca/kg/core@v0"

p_struct_as_set: core.#Pattern & {
	name:     "Struct-as-Set"
	category: "data"
	problem:  "Arrays allow duplicates, require O(n) membership checks, and collide on unification."
	solution: "Use {[string]: true} for sets. O(1) membership, automatic dedup, clean unification via CUE lattice."
	context:  "Any field representing membership, tags, categories, or dependency sets."
	example:  "apercue/.kb/decisions/002-struct-as-set.cue"
	used_in: {
		"apercue":     true
		"datacenter":  true
		"infra-graph": true
		"quicue.ca":   true
		"quicue-kg":   true
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

p_contract_via_unification: core.#Pattern & {
	name:     "Contract-via-Unification"
	category: "verification"
	problem:  "Projects need to verify graph invariants (expected roots, resource counts, deployment ordering) but traditional assertion frameworks add a separate test layer disconnected from the data."
	solution: "Write CUE constraints as plain struct values that must unify with computed graph output. The constraint IS a CUE value. cue vet failure = invariant violation. No assertion framework needed — the language IS the test harness."
	context:  "Any project with a dependency graph where structural invariants must hold. The verify.cue pattern. Generalized by charter/ into #Charter + #GapAnalysis."
	example:  "validate: valid: true; infra: roots: {\"docker\": true}; summary: total_resources: 18"
	used_in: {
		"quicue.ca":  true
		"cmhc-retrofit": true
		"maison-613": true
		"grdn":       true
	}
	related: {
		"struct_as_set":  true
		"hidden_wrapper": true
		"gap_as_backlog": true
	}
}

p_gap_as_backlog: core.#Pattern & {
	name:     "Gap-as-Backlog"
	category: "planning"
	problem:  "Project planning tools track work items separately from the system they describe. The backlog drifts from reality because it's maintained by hand."
	solution: "Declare what 'done' looks like as CUE constraints on an incomplete graph. The gap between constraints and data IS the remaining work. #GapAnalysis computes missing resources, unsatisfied gates, and the next milestone — all derived from unification."
	context:  "Any project built incrementally where completion criteria can be expressed as graph properties: resource counts, required types, named roots, depth constraints, phase gates."
	example:  "charter.#GapAnalysis & {Charter: _charter, Graph: _graph} → complete: false, missing_resources: {monitoring: true}"
	used_in: {
		"quicue.ca": true
	}
	related: {
		"contract_via_unification": true
		"struct_as_set":            true
	}
}

p_universe_cheatsheet: core.#Pattern & {
	name:     "Universe Cheat Sheet"
	category: "architecture"
	problem:  "Read-only APIs backed by CUE graphs still deploy a web server (FastAPI, Express, etc.) to handle requests at runtime, adding latency, failure modes, and operational overhead."
	solution: "Run cue export once at build time to produce all possible API responses as static JSON files. Deploy to a CDN (CF Pages, S3, GitHub Pages). The API is a directory of pre-computed answers — no server, no runtime, no state."
	context:  "Any CUE-backed API where the query universe is finite and the data changes only at build time. The pattern works because CUE comprehensions precompute all queries — the response to every possible request is already a field in the export."
	example:  "cue export ./examples/datacenter/ -e _bulk | build-static-api.sh → 727 JSON files → CF Pages at api.quicue.ca"
	used_in: {
		"quicue.ca": true
	}
	related: {
		"compile_time_binding": true
		"safe_deploy":         true
	}
}

p_safe_deploy: core.#Pattern & {
	name:     "Safe Deploy Pipeline"
	category: "operations"
	problem:  "Public surfaces built from production data leak real IPs, hostnames, and internal topology. Deploying safe replacements over contaminated files misses old artifacts with different naming conventions."
	solution: "Source all public data from a single safe example (RFC 5737 TEST-NET IPs). Delete all existing files before deploying. Verify with grep -rl for real IP patterns as the final step. CI enforces no real IPs in generated artifacts."
	context:  "Any project deploying generated artifacts to public web surfaces where the source data may have originated from production infrastructure."
	example:  "cue export ./examples/datacenter/ -e _bulk | split → deploy to imp.quicue.ca; grep -rl 172.20 → must be empty"
	used_in: {
		"quicue.ca": true
	}
	related: {
		"compile_time_binding": true
	}
}
