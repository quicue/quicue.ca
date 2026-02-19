// Architecture decisions for quicue.ca
package decisions

import "quicue.ca/kg/core@v0"

d001: core.#Decision & {
	id:        "ADR-001"
	title:     "Three-layer architecture: definition, template, value"
	status:    "accepted"
	date:      "2025-01-01"
	context:   "Infrastructure modeling requires separating universal concepts from platform-specific implementations from concrete instances."
	decision:  "Use a 3-layer architecture: vocab/ + patterns/ (definition), template/*/ (template), examples/ (value). Each layer constrains the next via CUE unification."
	rationale: "CUE's unification model naturally supports layered constraints. Definitions are provider-agnostic, templates add platform specifics, values bind concrete data. Violations are compile-time errors."
	consequences: [
		"Every provider must implement interfaces from patterns/",
		"Generic field names (container_id, vm_id, host) map to platform-specific commands",
		"New providers add template/*/ modules without touching definition or value layers",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d002: core.#Decision & {
	id:        "ADR-002"
	title:     "Struct-as-set: {key: true} over arrays for types and dependencies"
	status:    "accepted"
	date:      "2025-01-01"
	context:   "Resources need type membership and dependency declarations. Arrays require list.Contains (O(n)) and produce duplicates on unification."
	decision:  "Use struct-as-set pattern: {@type: {DNSServer: true, LXCContainer: true}} and {depends_on: {dns: true}}. O(1) membership, clean CUE unification, no duplicates."
	rationale: "CUE unifies structs by merging keys. {A: true} & {B: true} = {A: true, B: true}. Arrays would need explicit dedup. Struct keys are unique by construction."
	consequences: [
		"All @type fields use {[string]: true} not [...string]",
		"JSON-LD export converts to arrays: [for t, _ in @type {t}]",
		"Provider matching uses resource[@type][providerType] != _|_ (O(1))",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d003: core.#Decision & {
	id:        "ADR-003"
	title:     "Compile-time provider binding: all parameters resolve at cue eval"
	status:    "accepted"
	date:      "2025-06-01"
	context:   "Provider templates define commands with parameters ({host}, {container_id}). These could be resolved at runtime (string interpolation) or at CUE evaluation time."
	decision:  "#BindCluster matches providers to resources by @type overlap, then #ResolveTemplate substitutes all {param} placeholders from resource fields at cue eval time. No unresolved placeholders survive evaluation."
	rationale: "Compile-time resolution means CUE catches missing fields before anything runs. A missing container_id on a Proxmox resource is a type error, not a runtime 'undefined variable'. This eliminates an entire class of deployment failures."
	consequences: [
		"Resources must declare all fields their bound providers reference",
		"Provider templates use {param} syntax with explicit from_field bindings",
		"The output of cue export is fully resolved — ready to execute",
		"No runtime templating engine needed",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d004: core.#Decision & {
	id:        "ADR-004"
	title:     "Layer 4 interaction: ou/ scopes #ExecutionPlan by role, type, name, and layer"
	status:    "accepted"
	date:      "2026-01-31"
	context:   "The 3-layer model (definition, template, value) produces complete execution plans. Different operators need narrowed views: ops sees everything, dev sees DNS only, readonly sees info actions only."
	decision:  "Add ou/ package (Layer 4) with #InteractionCtx that narrows #ExecutionPlan via CUE comprehensions. Scoping dimensions: operator role (visible_categories), resource type filter, resource name filter, deployment layer filter. Hydra W3C JSON-LD export is a pure derivation of the scoped view."
	rationale: "CUE comprehensions are the natural filtering mechanism — no runtime logic, just struct narrowing. The scoped view is itself a valid CUE value that downstream projections can consume."
	consequences: [
		"Architecture becomes 4 layers: definition, template, value, interaction",
		"#InteractionCtx consumes #ExecutionPlan — no direct dependency on vocab/ or template/",
		"Operator roles use struct-as-set for visible_categories (ADR-002 applied to action filtering)",
		"Hydra JSON-LD generation is explicit: consumer passes scoped view to #ApiDocumentation",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d005: core.#Decision & {
	id:        "ADR-005"
	title:     "Charter: constraint schema with computed gap analysis"
	status:    "accepted"
	date:      "2026-02-17"
	context:   "Downstream projects each have verify.cue files with identical patterns: validate structure, assert roots, assert cardinality. The pattern is ad-hoc — field names vary by domain, there's no shared vocabulary, and no support for intermediate checkpoints. Initial design favored thin constraints only (cue vet errors as gap reports), but structured gap reporting proved more useful for programmatic consumption."
	decision:  "Charter defines four definitions: #Charter (scope + gates), #Gate (DAG checkpoint), #GapAnalysis (computed missing resources, types, gate status, next gate, completion), and #Milestone (single gate evaluation). ~240 lines total. Gates form a DAG (resources + gate dependencies). Gap analysis produces structured output consumable by downstream tools, not just cue vet error messages."
	rationale: "Raw cue vet errors report what didn't unify, but they're unstructured text. #GapAnalysis produces typed CUE output (missing_resources, gate_status, next_gate, complete) that downstream projects can consume programmatically. The gap engine doesn't replace cue vet — it adds a structured layer on top. Contract-via-unification remains the enforcement mechanism; gap analysis is the reporting mechanism."
	consequences: [
		"Downstream projects use #GapAnalysis to compute structured backlog from charter + graph",
		"Gate DAG subsumes linear phases — a chain is a degenerate DAG",
		"#Milestone provides focused per-gate evaluation without full gap analysis",
		"Gap analysis output (complete, missing_resources, next_gate) is typed and exportable as JSON",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d006: core.#Decision & {
	id:        "ADR-006"
	title:     "Public showcase data sourced exclusively from example datacenter"
	status:    "accepted"
	date:      "2026-02-18"
	context:   "Public surfaces (imp.quicue.ca, api.quicue.ca, cat.quicue.ca) were originally built from production infrastructure data containing real 172.20.x.x IPs. Making these public required regenerating all data from a safe source."
	decision:  "All public-facing data is generated from examples/datacenter/ which uses RFC 5737 TEST-NET IPs (198.51.100.x). CI validates no real IPs leak into generated artifacts via grep-based checks. Deploy scripts use env vars (DEPLOY_HOST, DEPLOY_CT) instead of hardcoded hostnames."
	rationale: "A single source of safe data eliminates the risk of production IP leakage. The example datacenter exercises all 28 providers and produces 654 bound commands — the same fidelity as production without the exposure. CI enforcement prevents regression."
	consequences: [
		"All public surfaces serve data from examples/datacenter/ only",
		"CI workflow validates no 172.x.x.x IPs in generated openapi.json or bound_commands.json",
		"Deploy scripts are parameterized — no hardcoded infrastructure hostnames in version control",
		"Production data stays behind CF Access on apercue.ca surfaces",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d007: core.#Decision & {
	id:        "ADR-007"
	title:     "CUE conditional branches for optional charter scope fields"
	status:    "accepted"
	date:      "2026-02-18"
	context:   "Charter #GapAnalysis used count_satisfied: true as a default when total_resources was unset, with a conditional override. In CUE, this is a hard constraint (true), not a default — when the conditional evaluates to false, true & false produces bottom (_|_). The bug was latent because charter tests use hidden fields that cue vet does not fully evaluate."
	decision:  "Use mutually exclusive conditional branches with a bool type constraint instead of a hard true default. Same pattern already used correctly by _root_satisfied in the same file."
	rationale: "CUE unification makes foo: true into an immutable constraint. The only way to conditionally set a field to true or false is via mutually exclusive if branches, each setting a concrete value. This is idiomatic CUE — the _root_satisfied field already demonstrated the correct pattern."
	consequences: [
		"depth_satisfied and count_satisfied now use bool type + conditional branches",
		"Charter gap analysis works correctly when the graph has fewer resources than the charter scope requires",
		"cue vet on public gap analysis fields catches conflicts that hidden-field tests miss",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d008: core.#Decision & {
	id:        "ADR-008"
	title:     "Domain-general framing: 'things that depend on other things'"
	status:    "accepted"
	date:      "2026-02-18"
	context:   "Public surfaces (GitHub profile, repo descriptions, docs) originally framed quicue.ca as 'infrastructure as typed dependency graphs.' This undersells the framework — the same patterns serve 4 domains (IT, construction, energy, real estate). 'Infrastructure' anchors perception to one domain and obscures the core abstraction."
	decision:  "Frame as 'CUE framework for modeling any domain where things depend on other things.' The entry point is two fields: @type (what it is) and depends_on (what it needs). Everything else is a projection."
	rationale: "The core requirement is: typed nodes with directed dependency edges. That's domain-independent. The downstream table (4 domains, same patterns) proves it generalizes. Leading with 'infrastructure' makes construction PMs and energy efficiency engineers think it's not for them."
	consequences: [
		"GitHub profile, repo descriptions, and docs all use domain-general language",
		"Downstream table replaces domain-specific prose as the credibility signal",
		"'Infrastructure' appears only when describing the IT infrastructure domain specifically",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d009: core.#Decision & {
	id:        "ADR-009"
	title:     "SPARQL is external federation only — CUE comprehensions are the query layer"
	status:    "accepted"
	date:      "2026-02-18"
	context:   "Docs and profile README framed SPARQL as a primary query mechanism ('A SPARQL query can join infrastructure state with decisions'). This misrepresents the architecture. Inside CUE, comprehensions precompute every query at eval time — #ImpactQuery, #BlastRadius, #CriticalityRank, etc. The W3C exports (JSON-LD, N-Triples, Turtle) are projections, not inputs to a query engine."
	decision:  "SPARQL is for external federation only — when exports leave the CUE closed world and join external systems via a triplestore. Inside CUE, comprehensions ARE the query layer. Docs say: 'Inside CUE, comprehensions precompute every query at eval time.'"
	rationale: "CUE unification IS a query engine for the closed world. Claiming SPARQL is needed misrepresents the architecture and implies a runtime dependency that doesn't exist. The W3C formats are first-class projections (like deployment plans), not an exit ramp."
	consequences: [
		"Oxigraph reclassified from 'optional infrastructure' to 'external federation only'",
		"Docs distinguish 'inside CUE' (comprehensions) from 'outside CUE' (SPARQL/triplestore)",
		"Profile README no longer implies SPARQL is the primary query method",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d010: core.#Decision & {
	id:        "ADR-010"
	title:     "Game design projects tracked separately from quicue.ca"
	status:    "accepted"
	date:      "2026-02-18"
	context:   "mud-futurama and fing-mod use quicue.ca/kg for knowledge graph features. Listing them as downstream consumers alongside IT infrastructure and construction PM projects dilutes the message — game design is distracting when communicating the framework's value to the CUE community, leadership, or technical peers."
	decision:  "Remove game design projects from quicue.ca's downstream registry and all public documentation. The MUD repos continue to exist independently and import kg on their own terms. quicue.ca's public surface focuses on the 4 core domains: IT infrastructure, construction PM, energy efficiency, real estate."
	rationale: "The game projects are real and use kg legitimately. But including them in the same downstream list as CMHC retrofit and production datacenter management undermines credibility. Different audiences, different contexts."
	consequences: [
		"mud-futurama and fing-mod removed from .kb/downstream.cue",
		"Downstream count: 4 projects across 4 domains",
		"Game projects maintain their own .kb/ and import kg independently",
		"No game/MUD references on any quicue.ca public surface",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d012: core.#Decision & {
	id:        "ADR-012"
	title:     "Static-first showcase: all public surfaces on Cloudflare Pages"
	status:    "accepted"
	date:      "2026-02-18"
	context:   "Public showcases (demo, API, catalogue, KG spec, CMHC retrofit, maison-613) were originally served by Caddy on container 612 behind a Cloudflare Tunnel. The tunnel depends on port 7844 outbound, which ISP equipment (Bell Giga Hub) blocks intermittently. Dynamic features (WebSocket MUDs, live execution) are unused in read-only showcases."
	decision:  "Deploy all static showcases to Cloudflare Pages. The static API (727 pre-computed JSON files from cue export) serves the same endpoints as the original FastAPI server, but as GET-only static files. No servers, no tunnels, no containers for the public showcase surface."
	rationale: "CUE comprehensions pre-compute all possible API responses at eval time. If every answer is known at build time, a web server adds latency and failure modes without adding capability. CF Pages provides global CDN, zero-downtime deploys, and eliminates the tunnel dependency entirely."
	consequences: [
		"7 CF Pages projects replace Caddy vhosts on container 612",
		"All API examples use GET (POST returns 405 on static hosting)",
		"Tunnel is only needed for dynamic services: MUDs (WebSocket), live execution",
		"Deploy workflow: cue export → build-static-api.sh → wrangler pages deploy",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d013: core.#Decision & {
	id:        "ADR-013"
	title:     "Lifecycle management in patterns/, not a separate orche/ package"
	status:    "accepted"
	date:      "2026-02-19"
	context:   "The boot/ package defines #BootstrapResource and credential collection types. The examples/drift-detection/ example imports orche/orchestration for state reconciliation. Both reference an orche/ package that doesn't exist in the repo. Meanwhile, patterns/ already has #ExecutionPlan, #DeploymentPlan, #RollbackPlan, and #HealthStatus — all lifecycle-adjacent."
	decision:  "Absorb lifecycle management into patterns/lifecycle.cue. #BootstrapPlan, #DriftReport, #SmokeTest, and the composed #DeploymentLifecycle live in patterns/ alongside #ExecutionPlan. The boot/ skeleton types are refactored into patterns/. No separate orche/ package."
	rationale: "CUE's strength is type composition via unification. #BootstrapPlan needs to compose with #InfraGraph. #DriftReport needs the same resource graph as #ExecutionPlan. Splitting these into separate packages forces import gymnastics rather than direct unification. The principle is: types compose, packages separate. These types compose, so they belong together."
	consequences: [
		"patterns/lifecycle.cue created with #BootstrapPlan, #DriftReport, #SmokeTest, #DeploymentLifecycle",
		"boot/ types refactored into patterns/ (boot/ remains as a thin re-export or is removed)",
		"examples/drift-detection/ updated to import patterns/ instead of orche/",
		"No orche/ module to publish or version separately",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}

d011: core.#Decision & {
	id:        "ADR-011"
	title:     "lacuene is not a downstream consumer"
	status:    "accepted"
	date:      "2026-02-18"
	context:   "lacuene was listed in docs and README as a downstream project ('Biomedical research — 95 genes x 16 databases'). However, lacuene does not import quicue.ca/patterns or quicue.ca/vocab. It has its own graph structure but doesn't use the framework."
	decision:  "Remove lacuene from all downstream claims. Only projects that import quicue.ca/patterns or quicue.ca/vocab are listed as downstream consumers."
	rationale: "Listing a project that doesn't use the framework as a consumer is inaccurate. The downstream registry should reflect actual import relationships, not conceptual similarity."
	consequences: [
		"lacuene removed from README, docs/index.md, and all ~/.mthdn/ docs",
		"Downstream criteria: must import quicue.ca/patterns or quicue.ca/vocab",
		"'Biomedical research' removed from domain list",
	]
	appliesTo: [{"@id": "https://quicue.ca/project/quicue-ca"}]
}
