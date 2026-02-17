// Type Composition with Type Contracts
//
// Demonstrates how declaring @type automatically:
//   1. Validates required fields exist (CUE eval-time)
//   2. Grants appropriate actions from #TypeRegistry
//   3. Infers structural dependencies (host -> depends_on)
//
// Run: cue eval ./examples/type-composition/ -e output
// Run: cue eval ./examples/type-composition/ -e validationDemo

package main

import (
	"strings"
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
)

// =============================================================================
// Resources - Just declare @type and required fields
// =============================================================================
// Type contracts handle the rest:
//   - DNSServer requires: {ip: string}
//   - LXCContainer requires: {container_id: int, host: string}
//   - LXCContainer has structural_deps: ["host"] -> auto depends_on

resources: {
	"pve-node": {
		name:     "pve-node"
		ip:       "10.0.1.1"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true}
	}

	"technitium": {
		name:         "technitium"
		ip:           "10.0.1.10"
		container_id: 101
		host:         "pve-node" // structural_dep -> auto depends_on
		"@type": {LXCContainer: true, DNSServer: true, CriticalInfra: true}
	}

	"caddy": {
		name:         "caddy"
		ip:           "10.0.1.50"
		container_id: 102
		host:         "pve-node"
		"@type": {LXCContainer: true, ReverseProxy: true}
	}

	"multi-role": {
		name: "multi-role"
		ip:   "10.0.1.99"
		// Note: No container_id or host - this is NOT an LXC
		// It's just a DNS server and reverse proxy (maybe bare metal)
		depends_on: {technitium: true}
		"@type": {DNSServer: true, ReverseProxy: true}
	}
}

// =============================================================================
// Apply Type Contracts - Validate and derive
// =============================================================================
// Apply contracts to each resource, keeping the full result for grants access

_contracts: {
	for rname, res in resources {
		(rname): patterns.#ApplyTypeContracts & {Input: res}
	}
}

// Extract validated outputs
validatedResources: {
	for rname, c in _contracts {
		(rname): c.Output
	}
}

// =============================================================================
// Build Actions from Grants
// =============================================================================
// Each type grants actions. Use #ActionRegistry to bind parameters.

_buildActions: {
	for rname, res in validatedResources {
		(rname): {
			// Get granted actions from type contracts
			let grants = _contracts[rname].grants

			// Build action instances from registry
			for actionName, _ in grants if vocab.#ActionRegistry[actionName] != _|_ {
				let def = vocab.#ActionRegistry[actionName]

				(actionName): vocab.#Action & {
					name:        def.name
					description: def.description
					category:    def.category

					// Bind parameters from resource fields
					let _cmd = def.command_template
					command: strings.Replace(
						strings.Replace(
							strings.Replace(
								strings.Replace(_cmd, "{ip}", "\(*res.ip | "")", -1),
								"{user}", "\(*res.ssh_user | "")", -1),
							"{container_id}", "\(*res.container_id | 0)", -1),
						"{host}", "\(*res.host | "")", -1)
				}
			}

			// Universal ping for anything with an IP
			if res.ip != _|_ {
				ping: vocab.#Action & {
					name:        "Ping"
					description: "Test connectivity"
					command:     "ping -c 3 \(res.ip)"
					category:    "info"
				}
			}
		}
	}
}

// =============================================================================
// Output: Final Infrastructure Graph
// =============================================================================

infraGraph: {
	for rname, res in validatedResources {
		(rname): res & {
			actions: _buildActions[rname]
		}
	}
}

// Summary output
output: {
	for name, r in infraGraph {
		(name): {
			types: r["@type"]
			// depends_on was auto-inferred from structural_deps (host field)
			if r.depends_on != _|_ {
				depends_on: r.depends_on
			}
			actions: [for aname, _ in r.actions {aname}]
			grants:  _contracts[name].grants
		}
	}
}

// =============================================================================
// Validation Demo - Show what type contracts do
// =============================================================================

validationDemo: {
	// Show structural dependency inference
	// technitium and caddy have host="pve-node" -> auto depends_on
	structuralDepsDemo: {
		for name, res in validatedResources if res.depends_on != _|_ {
			(name): {
				host:       *res.host | null
				depends_on: res.depends_on
				note:       "depends_on was auto-inferred from host field"
			}
		}
	}

	// Show granted actions from type contracts
	grantsDemo: {
		for name, _ in resources {
			(name): {
				types:  resources[name]["@type"]
				grants: _contracts[name].grants
			}
		}
	}

	// Show what happens if you omit a required field (would fail CUE eval)
	// Uncomment to see validation error:
	// invalidResource: (patterns.#ApplyTypeContracts & {Input: {
	//     name: "broken"
	//     "@type": {DNSServer: true}
	//     // Missing: ip field required by DNSServer
	// }}).Output
}

// =============================================================================
// Visualization (for graph explorer)
// =============================================================================

_graphResources: {
	for rname, r in validatedResources {
		(rname): {
			name:    rname
			"@type": r["@type"]
			if r.depends_on != _|_ {
				depends_on: r.depends_on
			}
		}
	}
}

infra: patterns.#InfraGraph & {Input: _graphResources}
_viz:  patterns.#VizData & {Graph: infra, Resources: _graphResources}

// Action data per resource (for explorer sidebar)
_actionData: {
	for rname, r in infraGraph {
		(rname): {
			names: [for aname, action in r.actions if action.command != _|_ {aname}]
			commands: {for aname, action in r.actions if action.command != _|_ {(aname): action.command}}
		}
	}
}

// Merge actions into viz nodes
vizData: _viz.data & {
	nodes: [
		for n in _viz.data.nodes {
			n & {
				if _actionData[n.id] != _|_ {
					actions:  _actionData[n.id].names
					commands: _actionData[n.id].commands
				}
			}
		},
	]
}
