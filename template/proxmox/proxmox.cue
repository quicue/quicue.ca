// Proxmox VE provider for quicue
//
// Provides action implementations for:
// - LXC containers (pct commands)
// - QEMU/KVM VMs (qm commands)
// - Proxmox nodes (pvecm, pvesm commands)
//
// Usage:
//   import "quicue.ca/proxmox"
//
//   actions: proxmox.#LXC & {LXCID: 100, Node: "pve-node-1"}

package proxmox

import patterns "quicue.ca/patterns"

// #LXC - Actions for Proxmox LXC containers
// Satisfies patterns.#ContainerActions
#LXC: patterns.#ContainerActions & {
	LXCID: int
	Node:  string

	status: {
		name:        "Container Status"
		description: "Check LXC container status via pct"
		command:     "ssh \(Node) 'pct status \(LXCID)'"
		category:    "monitor"
		idempotent:  true
	}
	console: {
		name:        "Console"
		description: "Attach to LXC container console"
		command:     "ssh -t \(Node) 'pct enter \(LXCID)'"
		category:    "connect"
	}
	logs: {
		name:        "Logs"
		description: "View container journal logs"
		command:     "ssh \(Node) 'pct exec \(LXCID) -- journalctl -n 100'"
		category:    "info"
		idempotent:  true
	}
	config: {
		name:        "Configuration"
		description: "Show LXC container configuration"
		command:     "ssh \(Node) 'pct config \(LXCID)'"
		category:    "info"
		idempotent:  true
	}
}

// #LXCExtended - LXC with snapshot support
#LXCExtended: #LXC & patterns.#SnapshotActions & {
	LXCID: int
	Node:  string

	list: {
		name:        "List Snapshots"
		description: "Show container snapshots"
		command:     "ssh \(Node) 'pct listsnapshot \(LXCID)'"
		category:    "info"
	}
	create: {
		name:        "Create Snapshot"
		description: "Create container snapshot"
		command:     "ssh \(Node) 'pct snapshot \(LXCID) snap-$(date +%Y%m%d-%H%M%S)'"
		category:    "admin"
	}
	revert: {
		name:        "Revert Snapshot"
		description: "Revert to latest snapshot"
		command:     "ssh \(Node) 'pct rollback \(LXCID) $(pct listsnapshot \(LXCID) | tail -1 | awk \"{print $2}\")'"
		category:    "admin"
	}
}

// #VM - Actions for Proxmox QEMU/KVM VMs
// Satisfies patterns.#VMActions
#VM: patterns.#VMActions & {
	VMID: int
	Node: string

	status: {
		name:        "VM Status"
		description: "Check VM status via qm"
		command:     "ssh \(Node) 'qm status \(VMID)'"
		category:    "monitor"
		idempotent:  true
	}
	console: {
		name:        "Console"
		description: "Open VM terminal"
		command:     "ssh -t \(Node) 'qm terminal \(VMID)'"
		category:    "connect"
	}
	config: {
		name:        "Configuration"
		description: "Show VM configuration"
		command:     "ssh \(Node) 'qm config \(VMID)'"
		category:    "info"
		idempotent:  true
	}
	vnc: {
		name:        "VNC Console"
		description: "Get VNC connection info"
		command:     "ssh \(Node) 'qm vncproxy \(VMID)'"
		category:    "connect"
	}
}

// #VMExtended - VM with snapshot support
#VMExtended: #VM & patterns.#SnapshotActions & {
	VMID: int
	Node: string

	list: {
		name:        "List Snapshots"
		description: "Show VM snapshots"
		command:     "ssh \(Node) 'qm listsnapshot \(VMID)'"
		category:    "info"
	}
	create: {
		name:        "Create Snapshot"
		description: "Create VM snapshot"
		command:     "ssh \(Node) 'qm snapshot \(VMID) snap-$(date +%Y%m%d-%H%M%S)'"
		category:    "admin"
	}
	revert: {
		name:        "Revert Snapshot"
		description: "Revert to latest snapshot"
		command:     "ssh \(Node) 'qm rollback \(VMID) $(qm listsnapshot \(VMID) | tail -1 | awk \"{print $2}\")'"
		category:    "admin"
	}
}

// #Node - Actions for Proxmox hypervisor nodes
// Satisfies patterns.#HypervisorActions
#Node: patterns.#HypervisorActions & {
	IP:   string
	User: string | *"root"

	list_vms: {
		name:        "List VMs"
		description: "List all QEMU/KVM VMs on this node"
		command:     "ssh \(User)@\(IP) 'qm list'"
		category:    "info"
	}
	list_containers: {
		name:        "List Containers"
		description: "List all LXC containers on this node"
		command:     "ssh \(User)@\(IP) 'pct list'"
		category:    "info"
	}
	cluster_status: {
		name:        "Cluster Status"
		description: "Show Proxmox cluster status"
		command:     "ssh \(User)@\(IP) 'pvecm status'"
		category:    "monitor"
	}
	storage_status: {
		name:        "Storage Status"
		description: "Show storage pool status"
		command:     "ssh \(User)@\(IP) 'pvesm status'"
		category:    "monitor"
	}
	node_status: {
		name:        "Node Status"
		description: "Show node resource usage"
		command:     "ssh \(User)@\(IP) 'pvesh get /nodes/$(hostname)/status'"
		category:    "monitor"
	}
}

// #Connectivity - Standard network connectivity actions
#Connectivity: patterns.#ConnectivityActions & {
	IP:   string
	User: string

	ping: {
		name:        "Ping"
		description: "Test network connectivity"
		command:     "ping -c 3 \(IP)"
		category:    "connect"
		idempotent:  true
	}
	ssh: {
		name:        "SSH"
		description: "SSH to resource"
		command:     "ssh \(User)@\(IP)"
		category:    "connect"
	}
}
