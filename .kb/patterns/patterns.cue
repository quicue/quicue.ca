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
	example:  "bash operator/build.sh → cue export + split + IP safety check; wrangler pages deploy operator/public → demo.quicue.ca; check-ips.sh blocks RFC 1918"
	used_in: {
		"quicue.ca": true
	}
	related: {
		"compile_time_binding": true
	}
}

p_hidden_intermediary: core.#Pattern & {
	name:     "Hidden Intermediary for Nested Structs"
	category: "cue"
	problem:  "CUE field references inside nested structs resolve to the nearest enclosing scope. summary: { total: total } creates a self-reference — the inner 'total' shadows the outer 'total'. CUE treats this as a tautology or produces 'field not allowed' errors."
	solution: "Define hidden intermediaries at the outer scope: _total: total. Then reference them inside the nested struct: summary: { total: _total }. Hidden fields with _ prefix are exempt from name collision because they're scoped differently."
	context:  "Any CUE definition that copies outer field values into a nested summary or output struct. Especially common with summary, output, export patterns."
	example:  "_total_dur: total_duration; _crit_count: len(critical); summary: { total_duration: _total_dur, critical_count: _crit_count }"
	used_in: {
		"quicue.ca":       true
		"cmhc-retrofit":   true
		"charter":         true
		"patterns-v2":     true
	}
	related: {
		"hidden_wrapper":          true
		"contract_via_unification": true
	}
}

p_graph_projection: core.#Pattern & {
	name:     "Graph Projection from Existing Config"
	category: "adoption"
	problem:  "Existing CUE codebases have their own schemas (custom structs, nested clusters, domain-specific fields) that don't use @type or depends_on. Rewriting to conform to quicue.ca resource shape is invasive and risks breaking working code."
	solution: "Write a single additive file (graph.cue) that reads from existing config fields via CUE comprehensions and produces a flat resource map with @type and depends_on. The original code is untouched. The projection file is the only new artifact."
	context:  "Any existing CUE project considering adoption of quicue.ca patterns. The projection file maps domain concepts (proxmox_cluster.nodes, k8s_cluster.nodes) into generic typed resources."
	example:  "grdn/graph.cue: 65 lines, reads proxmox_cluster and k8s_cluster, produces 9 resources across 5 layers. Original config.cue, schemas/, and CI are unmodified."
	used_in: {
		"grdn": true
	}
	related: {
		"struct_as_set":   true
		"three_layer":     true
	}
}

// --- Deployment Lifecycle Principles ---
// The following patterns codify the deployment philosophy
// derived from the quicue.ca ecosystem and validated by the
// airgapped E2E proof on VM 201 (2026-02-19).

p_everything_is_projection: core.#Pattern & {
	name:     "Everything-is-a-Projection"
	category: "architecture"
	problem:  "Adding new output formats (Rundeck, Jupyter, OpenAPI, justfile, DCAT, N-Triples) requires writing new code in each target language, duplicating graph traversal logic and risking divergence between outputs."
	solution: "Maintain one canonical CUE graph. Every output format is a CUE comprehension over that graph. Adding bash, Rundeck, Jupyter, or JSON-LD output requires zero Python, zero bash — just a new CUE expression. All projections are structurally identical because they derive from the same data."
	context:  "Any CUE project that produces multiple output formats from the same source data. The #ExecutionPlan already demonstrates 7 projections (script, notebook, rundeck, http, wiki, ops, OpenAPI) from one graph."
	example:  "#ExecutionPlan.notebook, .rundeck, .script, .wiki, .http — all derived from the same resolved command graph. Also: #DCAT3Catalog, #NTriplesExport, #OpenAPISpec."
	used_in: {
		"quicue.ca": true
		"apercue":   true
	}
	related: {
		"compile_time_binding": true
		"universe_cheatsheet":  true
		"hidden_wrapper":       true
	}
}

p_idempotent_by_construction: core.#Pattern & {
	name:     "Idempotent-by-Construction"
	category: "operations"
	problem:  "Deployment scripts accumulate state: environment variables, conditional branches, error recovery paths. Re-running a partially-failed deployment is risky because the script's behavior depends on the current system state."
	solution: "CUE evaluation is deterministic — same inputs always produce identical outputs. The deployment script is a pure function of the declared state. There is no system state to read, no conditional logic to diverge on. Running cue export twice produces byte-identical output. The deployment artifact is immutable once generated."
	context:  "Any deployment pipeline where re-runnability matters. The #DeploymentPlan layer-gated script is idempotent because each layer's commands are fully resolved at compile time — they don't check 'current state' to decide what to do."
	example:  "cue export -e execution.script produces identical bash output on every run. The operator confirms each layer gate, but the commands themselves are fixed."
	used_in: {
		"quicue.ca": true
	}
	related: {
		"compile_time_binding":      true
		"contract_via_unification":  true
		"everything_is_projection":  true
	}
}

p_types_compose: core.#Pattern & {
	name:     "Types-Compose-Scripts-Don't"
	category: "architecture"
	problem:  "Adding new deployment capabilities (drift detection, bootstrap, smoke testing) typically means writing new bash scripts or Python modules that duplicate graph traversal and resource handling logic."
	solution: "Express new capabilities as CUE types that compose with existing types via unification. #BootstrapPlan composes with #InfraGraph. #DriftReport composes with #ExecutionPlan. #SmokeTest composes with #Bundle. The composition is automatic — CUE's lattice semantics merge the types. Bash and Python exist only as thin execution layers over fully-resolved CUE output."
	context:  "Any extension to the deployment lifecycle where the new capability needs access to the resource graph, resolved commands, or topology data."
	example:  "#DeploymentLifecycle: { execution: #ExecutionPlan & {...}, drift: #DriftReport & {declared: execution.cluster.resources}, verify: #SmokeTest & {checks: [...]} }"
	used_in: {
		"quicue.ca": true
	}
	related: {
		"three_layer":              true
		"everything_is_projection": true
	}
}

p_static_first: core.#Pattern & {
	name:     "Static-First"
	category: "architecture"
	problem:  "Web servers introduce failure modes (process crashes, memory leaks, port conflicts, dependency rot) even when serving read-only data that changes only at build time."
	solution: "Pre-compute everything possible at cue export time. Read-only API surfaces are directories of JSON files served by a CDN. The FastAPI server exists only for live command execution (SSH, API calls) where runtime interaction is inherently required. Every piece of data that CAN be pre-computed SHOULD be."
	context:  "Deployment dashboards, API documentation, graph visualization, risk reports — anything that reads from the CUE graph without modifying it."
	example:  "demo.quicue.ca serves 727 pre-computed JSON files from CF Pages. The server at api.quicue.ca handles only live execution. Zero overlap."
	used_in: {
		"quicue.ca": true
	}
	related: {
		"universe_cheatsheet":       true
		"everything_is_projection":  true
		"safe_deploy":               true
	}
}

p_ascii_safe_identifiers: core.#Pattern & {
	name:     "ASCII-Safe Identifiers"
	category: "security"
	problem:  "CUE unification treats strings as opaque byte sequences. Unicode homoglyphs (Cyrillic 'а' vs Latin 'a'), zero-width characters (U+200B), and RTL overrides (U+202E) create visually identical but structurally distinct keys. A depends_on reference with an invisible character silently fails to match its target."
	solution: "Constrain all graph identifiers to ASCII via regex at the definition layer. #SafeID for resource names and dependency references. #SafeLabel for type names, tags, and registry keys. cue vet enforces at compile time with zero runtime cost."
	context:  "Any CUE schema where string values participate in struct key lookup, unification, or cross-reference. Especially critical for @type (provider matching), depends_on (graph edges), and name (identity)."
	example:  "#SafeID: =~\"^[a-zA-Z][a-zA-Z0-9_.-]*$\"; #SafeLabel: =~\"^[a-zA-Z][a-zA-Z0-9_-]*$\""
	used_in: {
		"apercue":       true
		"quicue.ca":     true
		"cmhc-retrofit": true
		"grdn":          true
		"maison-613":    true
	}
	related: {
		"struct_as_set":            true
		"contract_via_unification": true
	}
}

p_airgapped_bundle: core.#Pattern & {
	name:     "Airgapped Bundle"
	category: "operations"
	problem:  "Deploying to air-gapped or restricted networks fails because package managers (apt, pip, docker pull) require internet access. Partial offline solutions miss transitive dependencies or version conflicts."
	solution: "Define a #Bundle CUE schema declaring all artifacts needed for offline deployment: git repos, Docker images (app + base), Python wheels (including pip bootstrap), static binaries, and system packages with recursive dependencies. A #Gotcha registry captures known deployment traps with tested workarounds. bundle.sh reads the manifest and collects everything. install-airgapped.sh deploys on the target."
	context:  "Any deployment to networks with restricted internet access: institutional data centers, classified environments, factory floors, or POC demonstrations that must work reliably without external dependencies."
	example:  "operator/airgap-bundle.cue defines #Bundle + #Gotcha. E2E proven: 284MB bundle → fresh Ubuntu 24.04 VM → 37/37 smoke tests on completely airgapped machine."
	used_in: {
		"quicue.ca": true
	}
	related: {
		"idempotent_by_construction": true
		"types_compose":              true
		"safe_deploy":                true
	}
}
