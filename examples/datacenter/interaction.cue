// Layer 4 interaction contexts for the datacenter example.
//
// Adds operator-scoped views on top of the existing #ExecutionPlan.
// Three sessions: ops (full), dev (DNS + database only), readonly (layers 0-1).
//
// Run:
//   cue export ./examples/datacenter/ -e interaction_summary --out json
//   cue export ./examples/datacenter/ -e ops_session.commands --out json
//   cue export ./examples/datacenter/ -e dev_session.commands --out json
//   cue export ./examples/datacenter/ -e datacenter_hydra --out json

package main

import ( "quicue.ca/ou"

	// ============================================================================
	// Interaction Sessions
	// ============================================================================
)

// ops — full access, all resources, all categories
ops_session: ou.#InteractionCtx & {
	bound: execution.cluster.bound
	plan:  execution.plan
	role:  ou.#Roles.ops
	position: {
		current_layer: 0
		gates: {"layer-0": "passed"}
	}
}

// dev — read + connect only, just DNS and database resources
dev_session: ou.#InteractionCtx & {
	bound: execution.cluster.bound
	plan:  execution.plan
	role:  ou.#Roles.dev
	scope: {
		include_types: {DNSServer: true, Database: true}
	}
}

// readonly — info only, foundation layers (0-1)
readonly_session: ou.#InteractionCtx & {
	bound: execution.cluster.bound
	plan:  execution.plan
	role:  ou.#Roles.readonly
	scope: {
		include_layers: {"0": true, "1": true}
	}
}

// ============================================================================
// Hydra Export
// ============================================================================

datacenter_hydra: (ou.#ApiDocumentation & {ctx: {
	view:            ops_session.view
	role_name:       ops_session.summary.role_name
	total_resources: ops_session.summary.total_resources
	total_actions:   ops_session.summary.total_actions
}}).doc

datacenter_hydra_entrypoint: (ou.#HydraEntryPoint & {ctx: {
	total_resources: ops_session.summary.total_resources
}}).entrypoint

datacenter_hydra_collection: (ou.#HydraCollection & {ctx: {
	view:            ops_session.view
	total_resources: ops_session.summary.total_resources
}}).collection

// ============================================================================
// SKOS Type Vocabulary
// ============================================================================

datacenter_skos_types: (ou.#TypeVocabulary & {}).vocabulary

// ============================================================================
// Summary Output
// ============================================================================

interaction_summary: {
	ops:      ops_session.summary
	dev:      dev_session.summary
	readonly: readonly_session.summary
}
