// Proxmox Provider - #ActionDef registry for cluster binding
//
// Complements proxmox.cue (UPPERCASE templates for direct CUE unification)
// with from_field bindings for automatic #BindCluster resolution.
//
// Resource fields used:
//   host         → Proxmox node name or IP (ssh target)
//   vm_id        → QEMU VM ID
//   container_id → LXC container ID
//   ip           → Resource IP address
//   ssh_user     → SSH username (defaults to root)
//
// Usage:
//   import proxmox_patterns "quicue.ca/template/proxmox/patterns"
//   registry: proxmox_patterns.#ProxmoxRegistry

package patterns

import "quicue.ca/vocab"

#ProxmoxRegistry: {
	// ========== LXC Container Actions (pct) ==========

	pct_status: vocab.#ActionDef & {
		name:        "Container Status"
		description: "Check LXC container status"
		category:    "monitor"
		params: {
			node: {from_field: "host"}
			ctid: {type: "int", from_field: "container_id"}
		}
		command_template: "ssh {node} 'pct status {ctid}'"
		idempotent:       true
	}

	pct_console: vocab.#ActionDef & {
		name:        "Container Console"
		description: "Attach to LXC container console"
		category:    "connect"
		params: {
			node: {from_field: "host"}
			ctid: {type: "int", from_field: "container_id"}
		}
		command_template: "ssh -t {node} 'pct enter {ctid}'"
	}

	pct_logs: vocab.#ActionDef & {
		name:        "Container Logs"
		description: "View LXC container journal logs"
		category:    "info"
		params: {
			node: {from_field: "host"}
			ctid: {type: "int", from_field: "container_id"}
		}
		command_template: "ssh {node} 'pct exec {ctid} -- journalctl -n 100'"
		idempotent:       true
	}

	pct_config: vocab.#ActionDef & {
		name:        "Container Configuration"
		description: "Show LXC container configuration"
		category:    "info"
		params: {
			node: {from_field: "host"}
			ctid: {type: "int", from_field: "container_id"}
		}
		command_template: "ssh {node} 'pct config {ctid}'"
		idempotent:       true
	}

	pct_start: vocab.#ActionDef & {
		name:        "Start Container"
		description: "Start LXC container"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			ctid: {type: "int", from_field: "container_id"}
		}
		command_template: "ssh {node} 'pct start {ctid}'"
	}

	pct_stop: vocab.#ActionDef & {
		name:        "Stop Container"
		description: "Gracefully shutdown LXC container"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			ctid: {type: "int", from_field: "container_id"}
		}
		command_template: "ssh {node} 'pct shutdown {ctid}'"
	}

	pct_restart: vocab.#ActionDef & {
		name:        "Restart Container"
		description: "Reboot LXC container"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			ctid: {type: "int", from_field: "container_id"}
		}
		command_template: "ssh {node} 'pct reboot {ctid}'"
	}

	pct_snapshot_list: vocab.#ActionDef & {
		name:        "List Container Snapshots"
		description: "Show snapshots for LXC container"
		category:    "info"
		params: {
			node: {from_field: "host"}
			ctid: {type: "int", from_field: "container_id"}
		}
		command_template: "ssh {node} 'pct listsnapshot {ctid}'"
		idempotent:       true
	}

	// ========== VM Actions (qm) ==========

	qm_status: vocab.#ActionDef & {
		name:        "VM Status"
		description: "Check QEMU VM status"
		category:    "monitor"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh {node} 'qm status {vmid}'"
		idempotent:       true
	}

	qm_console: vocab.#ActionDef & {
		name:        "VM Console"
		description: "Open QEMU VM terminal"
		category:    "connect"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh -t {node} 'qm terminal {vmid}'"
	}

	qm_config: vocab.#ActionDef & {
		name:        "VM Configuration"
		description: "Show QEMU VM configuration"
		category:    "info"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh {node} 'qm config {vmid}'"
		idempotent:       true
	}

	qm_start: vocab.#ActionDef & {
		name:        "Start VM"
		description: "Start QEMU VM"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh {node} 'qm start {vmid}'"
	}

	qm_stop: vocab.#ActionDef & {
		name:        "Stop VM"
		description: "Gracefully shutdown QEMU VM"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh {node} 'qm shutdown {vmid}'"
	}

	qm_restart: vocab.#ActionDef & {
		name:        "Restart VM"
		description: "Reboot QEMU VM"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh {node} 'qm reboot {vmid}'"
	}

	qm_snapshot_list: vocab.#ActionDef & {
		name:        "List VM Snapshots"
		description: "Show snapshots for QEMU VM"
		category:    "info"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh {node} 'qm listsnapshot {vmid}'"
		idempotent:       true
	}

	// ========== Hypervisor Node Actions ==========

	node_list_vms: vocab.#ActionDef & {
		name:        "List VMs"
		description: "List all VMs on node"
		category:    "info"
		params: {
			ip:   {from_field: "ip"}
			user: {from_field: "ssh_user", required: false}
		}
		command_template: "ssh {user}@{ip} 'qm list'"
		idempotent:       true
	}

	node_list_containers: vocab.#ActionDef & {
		name:        "List Containers"
		description: "List all LXC containers on node"
		category:    "info"
		params: {
			ip:   {from_field: "ip"}
			user: {from_field: "ssh_user", required: false}
		}
		command_template: "ssh {user}@{ip} 'pct list'"
		idempotent:       true
	}

	node_cluster_status: vocab.#ActionDef & {
		name:        "Cluster Status"
		description: "Show Proxmox cluster status"
		category:    "monitor"
		params: {
			ip:   {from_field: "ip"}
			user: {from_field: "ssh_user", required: false}
		}
		command_template: "ssh {user}@{ip} 'pvecm status'"
		idempotent:       true
	}

	node_storage_status: vocab.#ActionDef & {
		name:        "Storage Status"
		description: "Show storage pool status"
		category:    "monitor"
		params: {
			ip:   {from_field: "ip"}
			user: {from_field: "ssh_user", required: false}
		}
		command_template: "ssh {user}@{ip} 'pvesm status'"
		idempotent:       true
	}

	node_status: vocab.#ActionDef & {
		name:        "Node Status"
		description: "Show node resource usage"
		category:    "monitor"
		params: {
			ip:   {from_field: "ip"}
			user: {from_field: "ssh_user", required: false}
		}
		command_template: "ssh {user}@{ip} 'pveversion && pvesh get /nodes/localhost/status'"
		idempotent:       true
	}

	// ========== LXC Lifecycle (destructive) ==========

	pct_force_stop: vocab.#ActionDef & {
		name:        "Force Stop Container"
		description: "Force stop LXC container (immediate, no graceful shutdown)"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			ctid: {type: "int", from_field: "container_id"}
		}
		command_template: "ssh {node} 'pct stop {ctid}'"
		destructive:      true
	}

	pct_destroy: vocab.#ActionDef & {
		name:        "Destroy Container"
		description: "Permanently destroy LXC container and its data"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			ctid: {type: "int", from_field: "container_id"}
		}
		command_template: "ssh {node} 'pct destroy {ctid}'"
		destructive:      true
	}

	// ========== VM Lifecycle (destructive) ==========

	qm_force_stop: vocab.#ActionDef & {
		name:        "Force Stop VM"
		description: "Force stop QEMU VM (immediate power off)"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh {node} 'qm stop {vmid}'"
		destructive:      true
	}

	qm_destroy: vocab.#ActionDef & {
		name:        "Destroy VM"
		description: "Permanently destroy QEMU VM and its disks"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh {node} 'qm destroy {vmid}'"
		destructive:      true
	}

	qm_suspend: vocab.#ActionDef & {
		name:        "Suspend VM"
		description: "Suspend QEMU VM to disk"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh {node} 'qm suspend {vmid}'"
	}

	qm_resume: vocab.#ActionDef & {
		name:        "Resume VM"
		description: "Resume suspended QEMU VM"
		category:    "admin"
		params: {
			node: {from_field: "host"}
			vmid: {type: "int", from_field: "vm_id"}
		}
		command_template: "ssh {node} 'qm resume {vmid}'"
	}

	// ========== Connectivity ==========

	ping: vocab.#ActionDef & {
		name:             "Ping"
		description:      "Test network connectivity"
		category:         "connect"
		params: ip: {from_field: "ip"}
		command_template: "ping -c 3 {ip}"
		idempotent:       true
	}

	ssh: vocab.#ActionDef & {
		name:        "SSH"
		description: "SSH into resource"
		category:    "connect"
		params: {
			ip:   {from_field: "ip"}
			user: {from_field: "ssh_user", required: false}
		}
		command_template: "ssh {user}@{ip}"
	}

	// Allow provider extensions
	...
}
