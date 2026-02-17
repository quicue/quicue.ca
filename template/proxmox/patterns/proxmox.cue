// Proxmox Provider - Action implementations for Proxmox VE
// Uses qm (QEMU/KVM), pct (LXC), pvecm (cluster) commands
//
// Usage:
//   import "quicue.ca/proxmox/patterns"
//   vm_actions: patterns.#VMActions & {VMID: 100, NODE: "pve1"}
package patterns

import "quicue.ca/vocab"

// #VMActions - VM actions via qm commands
#VMActions: vocab.#VMActions & {
	VMID: int
	NODE: string

	status: {
		name:        "VM Status"
		description: "Check VM \(VMID) status on \(NODE)"
		command:     "ssh \(NODE) 'qm status \(VMID)'"
	}
	console: {
		name:        "Console"
		description: "Open VM \(VMID) console"
		command:     "ssh -t \(NODE) 'qm terminal \(VMID)'"
	}
	config: {
		name:        "Configuration"
		description: "Show VM \(VMID) configuration"
		command:     "ssh \(NODE) 'qm config \(VMID)'"
	}
}

// #VMLifecycle - VM power operations via qm
#VMLifecycle: vocab.#LifecycleActions & {
	VMID: int
	NODE: string

	start: {
		name:        "Start"
		description: "Start VM \(VMID) on \(NODE)"
		command:     "ssh \(NODE) 'qm start \(VMID)'"
	}
	stop: {
		name:        "Stop"
		description: "Shutdown VM \(VMID) gracefully"
		command:     "ssh \(NODE) 'qm shutdown \(VMID)'"
	}
	stop_hard: vocab.#Action & {
		name:        "Force Stop"
		description: "Force stop VM \(VMID)"
		command:     "ssh \(NODE) 'qm stop \(VMID)'"
		icon:        "[stop]"
		category:    "admin"
	}
	restart: {
		name:        "Restart"
		description: "Reboot VM \(VMID)"
		command:     "ssh \(NODE) 'qm reboot \(VMID)'"
	}
	suspend: vocab.#Action & {
		name:        "Suspend"
		description: "Suspend VM \(VMID) to disk"
		command:     "ssh \(NODE) 'qm suspend \(VMID)'"
		icon:        "[suspend]"
		category:    "admin"
	}
	resume: vocab.#Action & {
		name:        "Resume"
		description: "Resume VM \(VMID)"
		command:     "ssh \(NODE) 'qm resume \(VMID)'"
		icon:        "[resume]"
		category:    "admin"
	}
	reset: vocab.#Action & {
		name:        "Reset"
		description: "Hard reset VM \(VMID)"
		command:     "ssh \(NODE) 'qm reset \(VMID)'"
		icon:        "[reset]"
		category:    "admin"
	}
}

// #VMSnapshots - VM snapshot management
#VMSnapshots: vocab.#SnapshotActions & {
	VMID:          int
	NODE:          string
	SNAPSHOT_NAME: string | *"snap-$(date +%Y%m%d-%H%M%S)"

	list: {
		name:        "List Snapshots"
		description: "Show snapshots for VM \(VMID)"
		command:     "ssh \(NODE) 'qm listsnapshot \(VMID)'"
	}
	create: {
		name:        "Create Snapshot"
		description: "Create snapshot of VM \(VMID)"
		command:     "ssh \(NODE) 'qm snapshot \(VMID) \(SNAPSHOT_NAME)'"
	}
	revert: {
		name:        "Revert Snapshot"
		description: "Revert VM \(VMID) to snapshot \(SNAPSHOT_NAME)"
		command:     "ssh \(NODE) 'qm rollback \(VMID) \(SNAPSHOT_NAME)'"
	}
	remove: vocab.#Action & {
		name:        "Remove Snapshot"
		description: "Delete snapshot \(SNAPSHOT_NAME) from VM \(VMID)"
		command:     "ssh \(NODE) 'qm delsnapshot \(VMID) \(SNAPSHOT_NAME)'"
		icon:        "[delete]"
		category:    "admin"
	}
}

// #ContainerActions - LXC container actions via pct
#ContainerActions: vocab.#ContainerActions & {
	CTID: int
	NODE: string

	status: {
		name:        "Container Status"
		description: "Check LXC \(CTID) status on \(NODE)"
		command:     "ssh \(NODE) 'pct status \(CTID)'"
	}
	console: {
		name:        "Console"
		description: "Attach to LXC \(CTID) console"
		command:     "ssh -t \(NODE) 'pct enter \(CTID)'"
	}
	logs: {
		name:        "Logs"
		description: "View LXC \(CTID) journal logs"
		command:     "ssh \(NODE) 'pct exec \(CTID) -- journalctl -n 100'"
	}
	config: vocab.#Action & {
		name:        "Configuration"
		description: "Show LXC \(CTID) configuration"
		command:     "ssh \(NODE) 'pct config \(CTID)'"
		icon:        "[config]"
		category:    "info"
	}
}

// #ContainerLifecycle - LXC power operations
#ContainerLifecycle: vocab.#LifecycleActions & {
	CTID: int
	NODE: string

	start: {
		name:        "Start"
		description: "Start LXC \(CTID) on \(NODE)"
		command:     "ssh \(NODE) 'pct start \(CTID)'"
	}
	stop: {
		name:        "Stop"
		description: "Shutdown LXC \(CTID) gracefully"
		command:     "ssh \(NODE) 'pct shutdown \(CTID)'"
	}
	stop_hard: vocab.#Action & {
		name:        "Force Stop"
		description: "Force stop LXC \(CTID)"
		command:     "ssh \(NODE) 'pct stop \(CTID)'"
		icon:        "[stop]"
		category:    "admin"
	}
	restart: {
		name:        "Restart"
		description: "Reboot LXC \(CTID)"
		command:     "ssh \(NODE) 'pct reboot \(CTID)'"
	}
}

// #ContainerSnapshots - LXC snapshot management
#ContainerSnapshots: vocab.#SnapshotActions & {
	CTID:          int
	NODE:          string
	SNAPSHOT_NAME: string | *"snap-$(date +%Y%m%d-%H%M%S)"

	list: {
		name:        "List Snapshots"
		description: "Show snapshots for LXC \(CTID)"
		command:     "ssh \(NODE) 'pct listsnapshot \(CTID)'"
	}
	create: {
		name:        "Create Snapshot"
		description: "Create snapshot of LXC \(CTID)"
		command:     "ssh \(NODE) 'pct snapshot \(CTID) \(SNAPSHOT_NAME)'"
	}
	revert: {
		name:        "Revert Snapshot"
		description: "Revert LXC \(CTID) to snapshot \(SNAPSHOT_NAME)"
		command:     "ssh \(NODE) 'pct rollback \(CTID) \(SNAPSHOT_NAME)'"
	}
	remove: vocab.#Action & {
		name:        "Remove Snapshot"
		description: "Delete snapshot \(SNAPSHOT_NAME) from LXC \(CTID)"
		command:     "ssh \(NODE) 'pct delsnapshot \(CTID) \(SNAPSHOT_NAME)'"
		icon:        "[delete]"
		category:    "admin"
	}
}

// #HypervisorActions - Node-level actions
#HypervisorActions: vocab.#HypervisorActions & {
	NODE: string
	USER: string | *"root"

	list_vms: {
		name:        "List VMs"
		description: "List all VMs on \(NODE)"
		command:     "ssh \(USER)@\(NODE) 'qm list'"
	}
	list_containers: {
		name:        "List Containers"
		description: "List all LXC containers on \(NODE)"
		command:     "ssh \(USER)@\(NODE) 'pct list'"
	}
	cluster_status: {
		name:        "Cluster Status"
		description: "Show Proxmox cluster status"
		command:     "ssh \(USER)@\(NODE) 'pvecm status'"
	}
	storage_status: vocab.#Action & {
		name:        "Storage Status"
		description: "Show storage pool status"
		command:     "ssh \(USER)@\(NODE) 'pvesm status'"
		icon:        "[storage]"
		category:    "monitor"
	}
	node_status: vocab.#Action & {
		name:        "Node Status"
		description: "Show node resource usage"
		command:     "ssh \(USER)@\(NODE) 'pveversion && pvesh get /nodes/$(hostname)/status'"
		icon:        "[node]"
		category:    "monitor"
	}
}

// #ConnectivityActions - Network connectivity
#ConnectivityActions: vocab.#ConnectivityActions & {
	IP:   string
	USER: string | *"root"

	ping: {
		name:        "Ping"
		description: "Test network connectivity to \(IP)"
		command:     "ping -c 3 \(IP)"
	}
	ssh: {
		name:        "SSH"
		description: "SSH into resource as \(USER)"
		command:     "ssh \(USER)@\(IP)"
	}
	mtr: vocab.#Action & {
		name:        "MTR"
		description: "Network path analysis to \(IP)"
		command:     "mtr -r -c 5 \(IP)"
		icon:        "[network]"
		category:    "connect"
	}
}

// #GuestAgent - QEMU guest agent operations
#GuestAgent: vocab.#GuestActions & {
	VMID: int
	NODE: string

	exec: {
		name:        "Run Command"
		description: "Execute command in VM \(VMID) via guest agent"
		command:     "ssh \(NODE) 'qm guest exec \(VMID) -- <command>'"
	}
	upload: {
		name:        "Upload File"
		description: "Upload file to VM \(VMID)"
		command:     "scp <local-file> \(NODE):/tmp/ && ssh \(NODE) 'qm guest exec \(VMID) -- cp /tmp/<file> <dest>'"
	}
	download: {
		name:        "Download File"
		description: "Download file from VM \(VMID)"
		command:     "ssh \(NODE) 'qm guest exec \(VMID) -- cat <file>' > <local-file>"
	}
	info: vocab.#Action & {
		name:        "Guest Info"
		description: "Get guest agent info for VM \(VMID)"
		command:     "ssh \(NODE) 'qm agent \(VMID) ping && qm agent \(VMID) get-osinfo'"
		icon:        "[info]"
		category:    "info"
	}
	network: vocab.#Action & {
		name:        "Guest Network"
		description: "Get network info from guest agent"
		command:     "ssh \(NODE) 'qm agent \(VMID) network-get-interfaces'"
		icon:        "[network]"
		category:    "info"
	}
}

// #BackupActions - Proxmox Backup Server integration
#BackupActions: {
	VMID:    int
	NODE:    string
	STORAGE: string | *"local"

	backup: vocab.#Action & {
		name:        "Backup"
		description: "Create backup of \(VMID)"
		command:     "ssh \(NODE) 'vzdump \(VMID) --storage \(STORAGE) --mode snapshot'"
		icon:        "[backup]"
		category:    "admin"
	}
	list_backups: vocab.#Action & {
		name:        "List Backups"
		description: "List backups for \(VMID)"
		command:     "ssh \(NODE) 'pvesm list \(STORAGE) | grep vzdump-qemu-\(VMID)'"
		icon:        "[list]"
		category:    "info"
	}
	...
}
