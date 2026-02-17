// Architecture decisions for quicue.ca
package kg

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
