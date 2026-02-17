// Action Schema
//
// Usage:
//   import "quicue.ca/vocab@v0"
//
//   myAction: vocab.#Action & {
//       name: "Ping"
//       description: "Test connectivity"
//       command: "ping -c3 \(IP)"
//   }
//
// PARAMETER CONVENTIONS:
// - Use UPPERCASE for template parameters (NODE, VMID, IP, USER)
// - Parameters are interpolated into command strings
//
// SECURITY WARNING:
// - Command strings use direct interpolation without escaping
// - Do NOT pass untrusted user input as parameters
// - Validate/sanitize at the provider or CLI layer

package vocab

// #Action - Base schema for all actions
#Action: {
	name:         string
	description?: string
	command?:     string
	icon?:        string
	category?:    string // connect|info|monitor|admin (for UI grouping)

	// Operational metadata
	timeout_seconds?:       int  // Expected max duration (0 = no timeout)
	requires_confirmation?: bool // Prompt before executing?
	idempotent?:            bool // Safe to retry?
	destructive?:           bool // Modifies state permanently?
	requires?: {[string]: true} // Prerequisites (e.g., {ssh_access: true, guest_agent: true})
	...
}

// =============================================================================
// Action Interfaces - Providers implement these with concrete commands
// =============================================================================

// #VMActions - Virtual machine status and inspection
#VMActions: {
	status:   #Action
	console?: #Action
	config?:  #Action
	...
}

// #LifecycleActions - Power state management
#LifecycleActions: {
	start:    #Action
	stop:     #Action
	restart?: #Action
	...
}

// #SnapshotActions - Point-in-time capture/restore
#SnapshotActions: {
	list:    #Action
	create:  #Action
	revert?: #Action
	...
}

// #ContainerActions - Container status and access
#ContainerActions: {
	status:  #Action
	console: #Action
	logs?:   #Action
	...
}

// #HypervisorActions - Host/node level operations
#HypervisorActions: {
	list_vms:        #Action
	list_containers: #Action
	cluster_status?: #Action
	...
}

// #ConnectivityActions - Network connectivity
#ConnectivityActions: {
	ping: #Action
	ssh:  #Action
	...
}

// #GuestActions - Guest agent operations
#GuestActions: {
	exec:      #Action
	upload?:   #Action
	download?: #Action
	...
}

// =============================================================================
// Action Registry - Typed parameter contracts (replaces UPPERCASE convention)
// =============================================================================
//
// The registry defines actions with explicit parameter binding.
// Instead of:
//   command: "ping \(IP)"  // IP is UPPERCASE convention
// Use:
//   params: { ip: {from_field: "ip"} }
//   command_template: "ping {ip}"
//
// Benefits:
//   - Explicit field binding (no convention to remember)
//   - Type safety for parameters
//   - Self-documenting parameter sources
//   - Validation that required fields exist

// #ActionParam - Parameter definition for actions
#ActionParam: {
	type:        "string" | "int" | "bool" | *"string"
	from_field?: string // Auto-bind from resource field (e.g., "ip" → resource.ip)
	required:    bool | *true
	default?:    string // Compile-time default when from_field is absent or field missing
}

// #ActionDef - Action definition with typed parameters
#ActionDef: {
	name:        string
	description: string
	category:    "info" | "connect" | "admin" | "monitor"

	// Explicit parameter contracts
	params: {
		[paramName=string]: #ActionParam
	}

	// Command template with {param} placeholders
	command_template: string

	// Operational metadata
	idempotent?:  bool
	destructive?: bool | *false
}

// #ProviderMatch - Declares what resource types a provider serves
#ProviderMatch: {
	// Provider matches if ANY type overlaps with resource @type
	types: {[string]: true}
	// Provider name (used for action namespacing)
	provider: string
}

// #ActionRegistry - All known actions with their contracts
// Providers can extend this with their own implementations
#ActionRegistry: {
	// ========== Connectivity Actions ==========

	ping: #ActionDef & {
		name:        "Ping"
		description: "Test network connectivity"
		category:    "info"
		params: {
			ip: {type: "string", from_field: "ip"}
		}
		command_template: "ping -c 3 {ip}"
		idempotent:       true
	}

	ssh: #ActionDef & {
		name:        "SSH"
		description: "Open SSH session"
		category:    "connect"
		params: {
			ip:   {type: "string", from_field: "ip"}
			user: {type: "string", from_field: "ssh_user", required: false}
		}
		command_template: "ssh {user}@{ip}"
	}

	// ========== DNS Actions ==========

	check_dns: #ActionDef & {
		name:        "Check DNS"
		description: "Query DNS server SOA record"
		category:    "info"
		params: {
			ip: {type: "string", from_field: "ip"}
		}
		command_template: "dig @{ip} SOA"
		idempotent:       true
	}

	dns_zone_list: #ActionDef & {
		name:        "List DNS Zones"
		description: "List DNS zones via zone transfer"
		category:    "info"
		params: {
			ip: {type: "string", from_field: "ip"}
		}
		command_template: "dig @{ip} AXFR"
		idempotent:       true
	}

	// ========== Container Actions ==========

	container_status: #ActionDef & {
		name:        "Container Status"
		description: "Get container status"
		category:    "info"
		params: {
			host:         {type: "string", from_field: "host"}
			container_id: {type: "int", from_field: "container_id"}
		}
		command_template: "pct status {container_id}" // Provider overrides
		idempotent:       true
	}

	container_console: #ActionDef & {
		name:        "Container Console"
		description: "Open container console"
		category:    "connect"
		params: {
			host:         {type: "string", from_field: "host"}
			container_id: {type: "int", from_field: "container_id"}
		}
		command_template: "pct enter {container_id}"
	}

	container_logs: #ActionDef & {
		name:        "Container Logs"
		description: "View container logs"
		category:    "info"
		params: {
			host:         {type: "string", from_field: "host"}
			container_id: {type: "int", from_field: "container_id"}
		}
		command_template: "pct exec {container_id} -- journalctl -n 100"
		idempotent:       true
	}

	// ========== Hypervisor Actions ==========

	list_vms: #ActionDef & {
		name:        "List VMs"
		description: "List virtual machines on node"
		category:    "info"
		params: {
			ip:   {type: "string", from_field: "ip"}
			user: {type: "string", from_field: "ssh_user"}
		}
		command_template: "ssh {user}@{ip} 'qm list'"
		idempotent:       true
	}

	list_containers: #ActionDef & {
		name:        "List Containers"
		description: "List containers on node"
		category:    "info"
		params: {
			ip:   {type: "string", from_field: "ip"}
			user: {type: "string", from_field: "ssh_user"}
		}
		command_template: "ssh {user}@{ip} 'pct list'"
		idempotent:       true
	}

	node_status: #ActionDef & {
		name:        "Node Status"
		description: "Get hypervisor node status"
		category:    "info"
		params: {
			ip:   {type: "string", from_field: "ip"}
			user: {type: "string", from_field: "ssh_user"}
		}
		command_template: "ssh {user}@{ip} 'pvesh get /nodes/localhost/status'"
		idempotent:       true
	}

	// ========== Proxy Actions ==========

	proxy_status: #ActionDef & {
		name:        "Proxy Status"
		description: "Check reverse proxy health"
		category:    "info"
		params: {
			ip: {type: "string", from_field: "ip"}
		}
		command_template: "curl -sf http://{ip}/health"
		idempotent:       true
	}

	proxy_routes: #ActionDef & {
		name:        "Proxy Routes"
		description: "List proxy routes"
		category:    "info"
		params: {
			ip: {type: "string", from_field: "ip"}
		}
		command_template: "curl -sf http://{ip}/api/routes"
		idempotent:       true
	}

	// ========== Critical Infrastructure Actions ==========

	alert_status: #ActionDef & {
		name:        "Alert Status"
		description: "Check alerting system status"
		category:    "monitor"
		params: {
			ip: {type: "string", from_field: "ip"}
		}
		command_template: "curl -sf http://{ip}:9093/api/v1/alerts"
		idempotent:       true
	}

	backup_status: #ActionDef & {
		name:        "Backup Status"
		description: "Check backup status"
		category:    "monitor"
		params: {}
		command_template: "echo 'Backup status check'"
		idempotent:       true
	}

	// Allow provider extensions
	...
}
