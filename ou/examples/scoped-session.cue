// Layer 4 scoped session — demonstrates #InteractionCtx narrowing.
//
// Takes the same 3-layer pattern (resources + providers → #ExecutionPlan)
// and adds Layer 4: operator role + scope → narrowed view + Hydra export.
//
// Run:
//   cue eval ./ou/examples/ -e summary
//   cue eval ./ou/examples/ -e ops_session.commands
//   cue eval ./ou/examples/ -e dev_session.commands
//   cue eval ./ou/examples/ -e ops_session.hydra
//   cue eval ./ou/examples/ -e comparison

package main

import (
	"quicue.ca/patterns@v0"
	"quicue.ca/vocab@v0"
	"quicue.ca/ou"
	vyos_patterns "quicue.ca/template/vyos/patterns"
	caddy_patterns "quicue.ca/template/caddy/patterns"
	powerdns_patterns "quicue.ca/template/powerdns/patterns"
)

// ============================================================================
// Layer 3: Resources + Providers → #ExecutionPlan
// ============================================================================

_resources: {
	"router-core": vocab.#Resource & {
		name: "router-core"
		"@type": {Router: true}
		ip:       "198.51.100.1"
		ssh_user: "vyos"
	}

	"dns-primary": vocab.#Resource & {
		name: "dns-primary"
		"@type": {DNSServer: true, LXCContainer: true}
		ip:           "198.51.100.10"
		host:         "pve-node-1"
		container_id: 100
		ssh_user:     "root"
		depends_on: {"router-core": true}
	}

	"caddy-proxy": vocab.#Resource & {
		name: "caddy-proxy"
		"@type": {ReverseProxy: true, LXCContainer: true}
		ip:        "198.51.100.212"
		host:      "pve-node-1"
		admin_url: "http://localhost:2019"
		ssh_user:  "root"
		depends_on: {"dns-primary": true}
	}

	"web-app": vocab.#Resource & {
		name: "web-app"
		"@type": {WebServer: true, LXCContainer: true}
		ip:       "198.51.100.50"
		host:     "pve-node-2"
		ssh_user: "deploy"
		depends_on: {"caddy-proxy": true, "dns-primary": true}
	}
}

_providers: {
	vyos: patterns.#ProviderDecl & {
		types: {Router: true}
		registry: vyos_patterns.#VyOSRegistry
	}
	caddy: patterns.#ProviderDecl & {
		types: {ReverseProxy: true}
		registry: caddy_patterns.#CaddyRegistry
	}
	powerdns: patterns.#ProviderDecl & {
		types: {DNSServer: true}
		registry: powerdns_patterns.#PowerDNSRegistry
	}
}

_plan: patterns.#ExecutionPlan & {
	resources: _resources
	providers: _providers
}

// ============================================================================
// Layer 4: Scoped interaction contexts
// ============================================================================

// ops — full access, all resources, all categories
ops_session: ou.#InteractionCtx & {
	bound: _plan.cluster.bound
	plan:  _plan.plan
	role:  ou.#Roles.ops
	position: {
		current_layer: 0
		gates: {"layer-0": "passed"}
	}
}

// dev — read-only, only DNS tier
dev_session: ou.#InteractionCtx & {
	bound: _plan.cluster.bound
	plan:  _plan.plan
	role:  ou.#Roles.dev
	scope: {
		include_types: {DNSServer: true}
	}
}

// readonly — info only, first 2 layers
readonly_session: ou.#InteractionCtx & {
	bound: _plan.cluster.bound
	plan:  _plan.plan
	role:  ou.#Roles.readonly
	scope: {
		include_layers: {"0": true, "1": true}
	}
}

// ============================================================================
// Hydra export — explicit generation from scoped context
// ============================================================================

ops_hydra: (ou.#ApiDocumentation & {ctx: {
	view:            ops_session.view
	role_name:       ops_session.summary.role_name
	total_resources: ops_session.summary.total_resources
	total_actions:   ops_session.summary.total_actions
}}).doc

// ============================================================================
// Outputs
// ============================================================================

summary: {
	layer3: {
		total_resources: _plan.cluster.summary.total_resources
		total_providers: _plan.cluster.summary.total_providers
		resolved_commands: _plan.cluster.summary.resolved_commands
		deployment_layers: _plan.plan.summary.total_layers
	}
	layer4: {
		ops: ops_session.summary
		dev: dev_session.summary
		readonly: readonly_session.summary
	}
}

// Side-by-side comparison: what each role can see
comparison: {
	for rname, _ in _resources {
		(rname): {
			if ops_session.commands[rname] != _|_ {
				ops_actions: len(ops_session.commands[rname])
			}
			if ops_session.commands[rname] == _|_ {
				ops_actions: 0
			}
			if dev_session.commands[rname] != _|_ {
				dev_actions: len(dev_session.commands[rname])
			}
			if dev_session.commands[rname] == _|_ {
				dev_actions: 0
			}
			if readonly_session.commands[rname] != _|_ {
				readonly_actions: len(readonly_session.commands[rname])
			}
			if readonly_session.commands[rname] == _|_ {
				readonly_actions: 0
			}
		}
	}
}
