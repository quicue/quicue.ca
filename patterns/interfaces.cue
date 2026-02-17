// Action interfaces - provider-agnostic contracts for resource actions.
//
// These define WHAT actions should exist, not HOW they're implemented.
// Provider implementations satisfy these interfaces with concrete commands.
//
// OPEN DEFINITIONS: All interfaces use `...` to allow:
// - Provider-specific parameters (VMID, Node, VMPath, CVM, etc.)
// - Additional fields (provider, requires, etc.)
// - Custom actions beyond the interface contract
//
// Usage:
//   import "quicue.ca/patterns@v0"
//
//   #MyProxmoxLXC: patterns.#ContainerActions & {
//       CONTAINER_ID: int
//       HOST: string
//       status: { command: "ssh \(HOST) 'pct status \(CONTAINER_ID)'" }
//       console: { command: "ssh -t \(HOST) 'pct enter \(CONTAINER_ID)'" }
//       logs: { command: "ssh \(HOST) 'pct exec \(CONTAINER_ID) -- journalctl -n 50'" }
//   }

package patterns

import "quicue.ca/vocab"

// #VMActions - Standard actions any VM should support
// Providers implement these with their specific tooling (qm, govc, acli, etc.)
#VMActions: {
	status: vocab.#Action & {
		name:     string | *"VM Status"
		category: string | *"monitor"
		...
	}
	console: vocab.#Action & {
		name:     string | *"Console"
		category: string | *"connect"
		...
	}
	config: vocab.#Action & {
		name:     string | *"Configuration"
		category: string | *"info"
		...
	}
	...
}

// #ContainerActions - Standard actions for containers (LXC, Docker, etc.)
#ContainerActions: {
	status: vocab.#Action & {
		name:     string | *"Container Status"
		category: string | *"monitor"
		...
	}
	console: vocab.#Action & {
		name:     string | *"Console"
		category: string | *"connect"
		...
	}
	logs: vocab.#Action & {
		name:     string | *"Logs"
		category: string | *"info"
		...
	}
	...
}

// #ConnectivityActions - Universal network connectivity actions
#ConnectivityActions: {
	ping: vocab.#Action & {
		name:     string | *"Ping"
		category: string | *"connect"
		...
	}
	ssh: vocab.#Action & {
		name:     string | *"SSH"
		category: string | *"connect"
		...
	}
	...
}

// #ServiceActions - Actions for managed services
#ServiceActions: {
	health: vocab.#Action & {
		name:     string | *"Health Check"
		category: string | *"monitor"
		...
	}
	restart: vocab.#Action & {
		name:     string | *"Restart"
		category: string | *"admin"
		...
	}
	logs: vocab.#Action & {
		name:     string | *"View Logs"
		category: string | *"info"
		...
	}
	...
}

// #SnapshotActions - Snapshot/backup management
#SnapshotActions: {
	list: vocab.#Action & {
		name:     string | *"List Snapshots"
		category: string | *"info"
		...
	}
	create: vocab.#Action & {
		name:     string | *"Create Snapshot"
		category: string | *"admin"
		...
	}
	revert: vocab.#Action & {
		name:     string | *"Revert Snapshot"
		category: string | *"admin"
		...
	}
	...
}

// #HypervisorActions - Actions for hypervisor nodes themselves
#HypervisorActions: {
	list_vms: vocab.#Action & {
		name:     string | *"List VMs"
		category: string | *"info"
		...
	}
	list_containers: vocab.#Action & {
		name:     string | *"List Containers"
		category: string | *"info"
		...
	}
	cluster_status: vocab.#Action & {
		name:     string | *"Cluster Status"
		category: string | *"monitor"
		...
	}
	storage_status: vocab.#Action & {
		name:     string | *"Storage Status"
		category: string | *"monitor"
		...
	}
	...
}

// #DatabaseActions - Database-specific actions
#DatabaseActions: {
	status: vocab.#Action & {
		name:     string | *"Database Status"
		category: string | *"monitor"
		...
	}
	connections: vocab.#Action & {
		name:     string | *"Active Connections"
		category: string | *"info"
		...
	}
	...
}

// #CostActions - Cost tracking and analysis (enterprise)
#CostActions: {
	breakdown: vocab.#Action & {
		name:     string | *"Cost Breakdown"
		category: string | *"cost"
		...
	}
	forecast: vocab.#Action & {
		name:     string | *"Cost Forecast"
		category: string | *"cost"
		...
	}
	...
}
