// InfraGraph pattern for Proxmox VE
//
// Generates actions for all resources based on their fields and types.
// Supports both old (lxcid/vmid/node) and new (container_id/vm_id/host) field names.
//
// Usage:
//   import "quicue.ca/proxmox"
//
//   _graph: proxmox.#InfraGraph & {
//       Templates: proxmox.#ActionTemplates
//       Nodes:     nodes
//       Resources: _allResources
//   }
//   infraGraph: _graph.Output

package proxmox

import (
	"quicue.ca/vocab"
)

// #InfraGraph - Generate actions for Proxmox resources
#InfraGraph: {
	// Input: action templates with UPPERCASE params
	Templates: #ActionTemplates

	// Input: Proxmox nodes (hypervisors)
	Nodes: [string]: {...}

	// Input: All resources (nodes, LXCs, VMs, services)
	Resources: [string]: {...}

	// Output: Resources with computed actions
	Output: {
		for rname, res in Resources {
			"\(rname)": res & {
				actions: {
					// Info action (always available)
					info: Templates.info & {Name: rname}

					// Connectivity actions (require ip)
					if res.ip != _|_ {
						ping: Templates.ping & {IP: res.ip}
					}

					// SSH action (require ip + ssh_user)
					if res.ip != _|_ {
						let _user = res.ssh_user | *"root"
						ssh: Templates.ssh & {IP: res.ip, User: _user}
					}

					// LXC actions (require container_id OR lxcid, AND host OR node)
					if (res.container_id != _|_ || res.lxcid != _|_) && (res.host != _|_ || res.node != _|_) {
						let _id = res.container_id | *res.lxcid
						let _host = res.host | *res.node
						pct_status: Templates.pct_status & {LXCID: _id, Node: _host}
						pct_console: Templates.pct_console & {LXCID: _id, Node: _host}
					}

					// VM actions (require vm_id OR vmid, AND host OR node)
					if (res.vm_id != _|_ || res.vmid != _|_) && (res.host != _|_ || res.node != _|_) {
						let _id = res.vm_id | *res.vmid
						let _host = res.host | *res.node
						qm_status: Templates.qm_status & {VMID: _id, Node: _host}
						qm_console: Templates.qm_console & {VMID: _id, Node: _host}
						qm_config: Templates.qm_config & {VMID: _id, Node: _host}
					}

					// Node/hypervisor actions (for VirtualizationPlatform type)
					if res["@type"] != _|_ && res["@type"].VirtualizationPlatform != _|_ {
						if res.ip != _|_ {
							let _user = res.ssh_user | *"root"
							list_vms: Templates.list_vms & {IP: res.ip, User: _user}
							list_containers: Templates.list_containers & {IP: res.ip, User: _user}
							cluster_status: Templates.cluster_status & {IP: res.ip, User: _user}
							storage_status: Templates.storage_status & {IP: res.ip, User: _user}
						}
					}

					// Allow custom actions to merge (from actions-specific.cue)
					...
				}
			}
		}
	}
}

// #ActionTemplates - UPPERCASE params unify with resource fields
// Uses defaults (*value) so actions-specific.cue can override
#ActionTemplates: {
	info: vocab.#Action & {
		Name: string
		name:        *"Info" | string
		description: *"Show resource \(Name) information" | string
		command:     *"echo 'Resource: \(Name)'" | string
		category:    *"info" | string
	}

	ping: vocab.#Action & {
		IP: string
		name:        *"Ping" | string
		description: *"Test network connectivity to \(IP)" | string
		command:     *"ping -c 3 \(IP)" | string
		category:    *"connect" | string
		idempotent:  *true | bool
	}

	ssh: vocab.#Action & {
		IP:   string
		User: string
		name:        *"SSH" | string
		description: *"SSH to \(User)@\(IP)" | string
		command:     *"ssh \(User)@\(IP)" | string
		category:    *"connect" | string
	}

	// LXC container actions
	pct_status: vocab.#Action & {
		LXCID: int
		Node:  string
		name:        *"Container Status" | string
		description: *"Check LXC \(LXCID) status on \(Node)" | string
		command:     *"ssh \(Node) 'pct status \(LXCID)'" | string
		category:    *"monitor" | string
		idempotent:  *true | bool
	}

	pct_console: vocab.#Action & {
		LXCID: int
		Node:  string
		name:        *"Console" | string
		description: *"Attach to LXC \(LXCID) console" | string
		command:     *"ssh -t \(Node) 'pct enter \(LXCID)'" | string
		category:    *"connect" | string
	}

	// VM actions
	qm_status: vocab.#Action & {
		VMID: int
		Node: string
		name:        *"VM Status" | string
		description: *"Check VM \(VMID) status on \(Node)" | string
		command:     *"ssh \(Node) 'qm status \(VMID)'" | string
		category:    *"monitor" | string
		idempotent:  *true | bool
	}

	qm_console: vocab.#Action & {
		VMID: int
		Node: string
		name:        *"Console" | string
		description: *"Open VM \(VMID) console" | string
		command:     *"ssh -t \(Node) 'qm terminal \(VMID)'" | string
		category:    *"connect" | string
	}

	qm_config: vocab.#Action & {
		VMID: int
		Node: string
		name:        *"Configuration" | string
		description: *"Show VM \(VMID) configuration" | string
		command:     *"ssh \(Node) 'qm config \(VMID)'" | string
		category:    *"info" | string
		idempotent:  *true | bool
	}

	// Hypervisor/node actions
	list_vms: vocab.#Action & {
		IP:   string
		User: string
		name:        *"List VMs" | string
		description: *"List all VMs on this node" | string
		command:     *"ssh \(User)@\(IP) 'qm list'" | string
		category:    *"info" | string
		idempotent:  *true | bool
	}

	list_containers: vocab.#Action & {
		IP:   string
		User: string
		name:        *"List Containers" | string
		description: *"List all LXC containers on this node" | string
		command:     *"ssh \(User)@\(IP) 'pct list'" | string
		category:    *"info" | string
		idempotent:  *true | bool
	}

	cluster_status: vocab.#Action & {
		IP:   string
		User: string
		name:        *"Cluster Status" | string
		description: *"Show Proxmox cluster status" | string
		command:     *"ssh \(User)@\(IP) 'pvecm status'" | string
		category:    *"monitor" | string
		idempotent:  *true | bool
	}

	storage_status: vocab.#Action & {
		IP:   string
		User: string
		name:        *"Storage Status" | string
		description: *"Show storage pool status" | string
		command:     *"ssh \(User)@\(IP) 'pvesm status'" | string
		category:    *"monitor" | string
		idempotent:  *true | bool
	}

	// Allow extension
	...
}
