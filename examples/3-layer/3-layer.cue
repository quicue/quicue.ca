// 3-layer: interface (quicue.ca) → provider → instance
// Run: cue eval ./examples/3-layer/ -e output
//
// LAYER 1: Interface (quicue.ca/vocab)
//   Provides #Action schema - the shape of an executable operation
//   vocab.#Action: { name, description, command, icon?, category?, ... }
//
// LAYER 2: Provider (e.g., proxmox)
//   Maps generic resource fields to platform-specific commands
//
// LAYER 3: Instance (your infrastructure)
//   Binds concrete values to provider templates

package main

import (
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
)

// Proxmox LXC action templates
// Generic params: CONTAINER_ID, HOST (mapped from resource.container_id, resource.host)
#ProxmoxLXC: {
	CONTAINER_ID: int
	HOST:         string

	console: vocab.#Action & {
		name:        "Console"
		description: "Enter LXC container console"
		command:     "ssh -t \(HOST) 'pct enter \(CONTAINER_ID)'"
		category:    "connect"
	}
	logs: vocab.#Action & {
		name:        "Logs"
		description: "View container logs"
		command:     "ssh \(HOST) 'pct exec \(CONTAINER_ID) -- journalctl -n 50'"
		category:    "info"
		idempotent:  true
	}
	config: vocab.#Action & {
		name:        "Config"
		description: "Get LXC container config"
		command:     "ssh \(HOST) 'pct config \(CONTAINER_ID)'"
		category:    "info"
		idempotent:  true
	}
	status: vocab.#Action & {
		name:        "Status"
		description: "Get LXC container status"
		command:     "ssh \(HOST) 'pct status \(CONTAINER_ID)'"
		category:    "monitor"
		idempotent:  true
	}
}

// Connectivity action templates
#Connectivity: {
	IP:   string
	USER: string

	ping: vocab.#Action & {
		name:        "Ping"
		description: "Test network connectivity"
		command:     "ping -c 3 \(IP)"
		category:    "connect"
		idempotent:  true
	}
	ssh: vocab.#Action & {
		name:        "SSH"
		description: "SSH to resource"
		command:     "ssh \(USER)@\(IP)"
		category:    "connect"
	}
}

// ============================================================================
// LAYER 3: Instance (your infrastructure)
// Uses generic field names; provider maps to platform-specific commands
// ============================================================================

resources: {
	"dns-server": {
		name:         "dns-server"
		ip:           "198.51.100.10"
		host:         "pve-node-1" // generic: hypervisor host
		container_id: 100          // generic: container identifier
		"@type": {DNSServer: true, LXCContainer: true}

		// Provider maps generic fields to platform-specific commands
		actions: {
			#ProxmoxLXC & {CONTAINER_ID: container_id, HOST: host}
			#Connectivity & {IP: ip, USER: "root"}
		}
	}

	"git-server": {
		name:         "git-server"
		ip:           "198.51.100.20"
		host:         "pve-node-2"
		container_id: 200
		"@type": {SourceControlManagement: true, LXCContainer: true}

		actions: {
			#ProxmoxLXC & {CONTAINER_ID: container_id, HOST: host}
			#Connectivity & {IP: ip, USER: "git"}
		}
	}
}

// ============================================================================
// Output: Show generated actions
// ============================================================================

output: {
	for name, r in resources {
		"\(name)": {
			resource: name
			"@type":  r["@type"]
			actions: {
				// Only include fields that have a command (filter out UPPERCASE params)
				for aname, action in r.actions if action.command != _|_ {
					"\(aname)": action.command
				}
			}
		}
	}
}

// ============================================================================
// Visualization data for graph explorer
// ============================================================================

_resources: {
	"dns-server": resources["dns-server"] & {depends_on: {"pve-node-1": true}}
	"git-server": resources["git-server"] & {depends_on: {"dns-server": true}}
	"pve-node-1": {
		name: "pve-node-1"
		"@type": {VirtualizationPlatform: true}
	}
}

infra: patterns.#InfraGraph & {Input: _resources}
_viz: patterns.#VizData & {Graph: infra, Resources: _resources}
vizData: _viz.data
