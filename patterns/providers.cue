// Example provider implementations for common platforms
//
// These are reference implementations showing how to build providers.
// For production use, providers can be implemented in their own repos
// (e.g., quicue-proxmox, quicue-kubernetes) with full feature sets.
//
// Each provider:
// - Satisfies an interface (#ContainerActions, #VMActions, etc.)
// - Takes UPPERCASE parameters (unification-friendly)
// - Generates concrete commands when params are bound
//
// Usage:
//   import "quicue.ca/patterns@v0"
//
//   actions: {
//       patterns.#ProxmoxLXC & {LXCID: 100, Node: "pve-node-1"}
//       patterns.#SSH & {IP: "198.51.100.10", User: "root"}
//   }

package patterns

import ( "quicue.ca/vocab"

	// ============================================================================
	// ACTION TEMPLATES - Generic parameterized actions
	// ============================================================================
)

// #ActionTemplates - UPPERCASE params for cross-package visibility
// Uses defaults (*value) to allow overrides
#ActionTemplates: {
	info: vocab.#Action & {
		Name:        string
		name:        *"Info" | string
		description: *"Show resource \(Name) information" | string
		command:     *"echo 'Resource: \(Name)'" | string
		category:    *"info" | string
	}

	ping: vocab.#Action & {
		IP:          string
		name:        *"Ping" | string
		description: *"Test network connectivity to \(IP)" | string
		command:     *"ping -c 3 \(IP)" | string
		category:    *"connect" | string
		idempotent:  *true | bool
	}

	ssh: vocab.#Action & {
		IP:          string
		User:        string
		name:        *"SSH" | string
		description: *"SSH to \(User)@\(IP)" | string
		command:     *"ssh \(User)@\(IP)" | string
		category:    *"connect" | string
	}

	// LXC container actions
	pct_status: vocab.#Action & {
		LXCID:       int
		Node:        string
		name:        *"Container Status" | string
		description: *"Check LXC \(LXCID) status on \(Node)" | string
		command:     *"ssh \(Node) 'pct status \(LXCID)'" | string
		category:    *"monitor" | string
		idempotent:  *true | bool
	}

	pct_console: vocab.#Action & {
		LXCID:       int
		Node:        string
		name:        *"Console" | string
		description: *"Attach to LXC \(LXCID) console" | string
		command:     *"ssh -t \(Node) 'pct enter \(LXCID)'" | string
		category:    *"connect" | string
	}

	// Docker host actions
	docker_ps: vocab.#Action & {
		IP:          string
		User:        string
		name:        *"Docker Containers" | string
		description: *"List running containers on \(IP)" | string
		command:     *"ssh \(User)@\(IP) 'docker ps --format \"table {{.Names}}\t{{.Status}}\t{{.Ports}}\"'" | string
		category:    *"info" | string
		idempotent:  *true | bool
	}

	disk_usage: vocab.#Action & {
		IP:          string
		User:        string
		name:        *"Disk Usage" | string
		description: *"Check disk usage on \(IP)" | string
		command:     *"ssh \(User)@\(IP) 'df -h'" | string
		category:    *"monitor" | string
		idempotent:  *true | bool
	}

	// Allow extension
	...
}

// ============================================================================
// PROXMOX
// ============================================================================

// #ProxmoxLXC - LXC container actions via pct
#ProxmoxLXC: #ContainerActions & {
	LXCID: int
	Node:  string

	status: {
		name:        "Container Status"
		description: "Check LXC status via pct"
		command:     "ssh \(Node) 'pct status \(LXCID)'"
		category:    "monitor"
	}
	console: {
		name:        "Console"
		description: "Attach to LXC console"
		command:     "ssh -t \(Node) 'pct enter \(LXCID)'"
		category:    "connect"
	}
	logs: {
		name:        "Logs"
		description: "View container journal"
		command:     "ssh \(Node) 'pct exec \(LXCID) -- journalctl -n 100'"
		category:    "info"
	}
}

// #ProxmoxVM - QEMU/KVM VM actions via qm
#ProxmoxVM: #VMActions & {
	VMID: int
	Node: string

	status: {
		name:        "VM Status"
		description: "Check VM status via qm"
		command:     "ssh \(Node) 'qm status \(VMID)'"
		category:    "monitor"
	}
	console: {
		name:        "Console"
		description: "Open VM terminal"
		command:     "ssh -t \(Node) 'qm terminal \(VMID)'"
		category:    "connect"
	}
	config: {
		name:        "Configuration"
		description: "Show VM config"
		command:     "ssh \(Node) 'qm config \(VMID)'"
		category:    "info"
	}
}

// ============================================================================
// DOCKER
// ============================================================================

// #Docker - Local Docker container actions
#Docker: #ContainerActions & {
	Container: string

	status: {
		name:        "Container Status"
		description: "Check Docker container status"
		command:     "docker inspect --format={{.State.Status}} \(Container)"
		category:    "monitor"
	}
	console: {
		name:        "Console"
		description: "Attach to container shell"
		command:     "docker exec -it \(Container) /bin/sh"
		category:    "connect"
	}
	logs: {
		name:        "Logs"
		description: "View container logs"
		command:     "docker logs --tail 100 \(Container)"
		category:    "info"
	}
}

// #DockerRemote - Docker via SSH to remote host
#DockerRemote: #ContainerActions & {
	Container: string
	Host:      string
	User:      string | *"root"

	status: {
		name:        "Container Status"
		description: "Check container on \(Host)"
		command:     "ssh \(User)@\(Host) 'docker inspect --format={{.State.Status}} \(Container)'"
		category:    "monitor"
	}
	console: {
		name:        "Console"
		description: "Shell on \(Host)"
		command:     "ssh -t \(User)@\(Host) 'docker exec -it \(Container) /bin/sh'"
		category:    "connect"
	}
	logs: {
		name:        "Logs"
		description: "Logs from \(Host)"
		command:     "ssh \(User)@\(Host) 'docker logs --tail 100 \(Container)'"
		category:    "info"
	}
}

// ============================================================================
// VMWARE
// ============================================================================

// #VMware - vCenter/ESXi VM actions via govc
#VMware: #VMActions & {
	VMPath:     string
	Datacenter: string

	status: {
		name:        "VM Status"
		description: "Check VM power state via govc"
		command:     "govc vm.info -json /\(Datacenter)/vm/\(VMPath) | jq -r '.VirtualMachines[0].Runtime.PowerState'"
		category:    "monitor"
	}
	console: {
		name:        "Console"
		description: "Get VM console URL"
		command:     "govc vm.console /\(Datacenter)/vm/\(VMPath)"
		category:    "connect"
	}
	config: {
		name:        "Configuration"
		description: "Show VM config from vCenter"
		command:     "govc vm.info -json /\(Datacenter)/vm/\(VMPath)"
		category:    "info"
	}
}

// ============================================================================
// CONNECTIVITY
// ============================================================================

// #SSH - Standard SSH connectivity
#SSH: #ConnectivityActions & {
	IP:   string
	User: string

	ping: {
		name:        "Ping"
		description: "Test network connectivity"
		command:     "ping -c 3 \(IP)"
		category:    "connect"
	}
	ssh: {
		name:        "SSH"
		description: "SSH to host"
		command:     "ssh \(User)@\(IP)"
		category:    "connect"
	}
}

// #DockerPing - Connectivity via docker exec
#DockerPing: #ConnectivityActions & {
	Container: string
	TargetIP:  string

	ping: {
		name:        "Ping"
		description: "Test connectivity from container"
		command:     "docker exec \(Container) ping -c 3 \(TargetIP)"
		category:    "connect"
	}
	ssh: {
		name:        "Shell"
		description: "Shell into container"
		command:     "docker exec -it \(Container) /bin/sh"
		category:    "connect"
	}
}
