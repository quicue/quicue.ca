// Action generation pattern for Proxmox infrastructure
// Generates actions based on resource capabilities and semantic types
//
// Usage:
//   import proxmox "quicue.ca/proxmox/patterns"
//
//   infraGraph: proxmox.#InfraGraph & {
//       Templates: proxmox.#ActionTemplates
//       Nodes: nodes           // Map of node name -> node config (for IP resolution)
//       Resources: _allResources
//   }
package patterns

import "list"

// #InfraGraph - Generate actions for all resources based on capabilities
// This is the bridge between #ActionTemplates and instance data
#InfraGraph: {
	// Input: Action templates (from templates.cue)
	Templates: #ActionTemplates

	// Input: Map of host names to their configs (need .ip field)
	// Keys should match the 'host' field in resources
	Nodes: [string]: {ip: string, ...}

	// Input: Map of all resources (nodes, VMs, LXCs)
	Resources: [string]: {...}

	// Output: Resources with generated actions
	Output: {
		for name, res in Resources {
			"\(name)": res & {
				actions: _generateActions & {
					_name:  name
					_res:   res
					_T:     Templates
					_nodes: Nodes
				}
			}
		}
	}
}

// _generateActions - Internal action generation logic
// Generates actions based on resource fields and semantic types
_generateActions: {
	_name: string
	_res: {...}
	_T: #ActionTemplates
	_nodes: [string]: {ip: string, ...}

	// Universal: info action for all resources
	info: _T.info & {NAME: _name}

	// Connectivity: ping if IP exists
	if _res.ip != _|_ {
		ping: _T.ping & {IP: _res.ip}
	}

	// Connectivity: SSH if IP and ssh_user exist
	if _res.ip != _|_ && _res.ssh_user != _|_ {
		ssh: _T.ssh & {IP: _res.ip, USER: _res.ssh_user}
	}

	// LXC: pct actions if container_id and host exist
	// Uses vocab field names: container_id (not ctid), host (not node)
	if _res.container_id != _|_ && _res.host != _|_ {
		let nodeIP = _nodes[_res.host].ip
		pct_status: _T.pct_status & {CTID: _res.container_id, NODE: _res.host, NODE_HOST: nodeIP}
		pct_console: _T.pct_console & {CTID: _res.container_id, NODE: _res.host, NODE_HOST: nodeIP}
	}

	// VM: qm actions if vm_id and host exist
	// Uses vocab field names: vm_id (not vmid), host (not node)
	if _res.vm_id != _|_ && _res.host != _|_ {
		let nodeIP = _nodes[_res.host].ip
		qm_status: _T.qm_status & {VMID: _res.vm_id, NODE: _res.host, NODE_HOST: nodeIP}
		qm_config: _T.qm_config & {VMID: _res.vm_id, NODE: _res.host, NODE_HOST: nodeIP}
		qm_console: _T.qm_console & {VMID: _res.vm_id, NODE: _res.host, NODE_HOST: nodeIP}
	}

	// Semantic @type: DNSServer
	if _res["@type"] != _|_ && _res.ip != _|_ {
		if list.Contains(_res["@type"], "DNSServer") {
			check_dns: _T.check_dns & {IP: _res.ip}
			query_zones: _T.query_zones & {IP: _res.ip}
			verify_resolution: _T.verify_resolution & {IP: _res.ip}
		}
	}

	// Semantic @type: ReverseProxy
	if _res["@type"] != _|_ && _res.ip != _|_ {
		if list.Contains(_res["@type"], "ReverseProxy") {
			proxy_health: _T.proxy_health & {IP: _res.ip}
			reload_config: _T.reload_config & {IP: _res.ip}
			test_config: _T.test_config & {IP: _res.ip}
		}
	}

	// Semantic @type: VirtualizationPlatform
	if _res["@type"] != _|_ && _res.ip != _|_ {
		if list.Contains(_res["@type"], "VirtualizationPlatform") {
			list_vms: _T.list_vms & {IP: _res.ip}
			list_containers: _T.list_containers & {IP: _res.ip}
			cluster_status: _T.cluster_status & {IP: _res.ip}
		}
	}

	// Semantic @type: DevelopmentWorkstation
	if _res["@type"] != _|_ && _res.ip != _|_ && _res.ssh_user != _|_ {
		if list.Contains(_res["@type"], "DevelopmentWorkstation") {
			docker_ps: _T.docker_ps & {IP: _res.ip, USER: _res.ssh_user}
			disk_usage: _T.disk_usage & {IP: _res.ip, USER: _res.ssh_user}
		}
	}

	// Semantic @type: Bastion (CIM-aligned)
	if _res["@type"] != _|_ && _res.ip != _|_ && _res.ssh_user != _|_ {
		if list.Contains(_res["@type"], "Bastion") {
			list_active_sessions: _T.list_active_sessions & {IP: _res.ip, USER: _res.ssh_user}
			check_auth_log: _T.check_auth_log & {IP: _res.ip, USER: _res.ssh_user}
		}
	}

	// Semantic @type: Vault (CIM-aligned)
	if _res["@type"] != _|_ && _res.ip != _|_ {
		if list.Contains(_res["@type"], "Vault") {
			check_vault: _T.check_vault & {IP: _res.ip}
		}
	}

	// Semantic @type: SourceControlManagement
	if _res["@type"] != _|_ && _res.ip != _|_ {
		if list.Contains(_res["@type"], "SourceControlManagement") {
			git_health: _T.git_health & {IP: _res.ip}
			list_repos: _T.list_repos & {IP: _res.ip}
		}
	}

	// GPU: if hardware.gpu exists
	if _res.hardware != _|_ {
		if _res.hardware.gpu != _|_ && _res.ip != _|_ && _res.ssh_user != _|_ {
			gpu_info: _T.gpu_info & {IP: _res.ip, USER: _res.ssh_user}
		}
	}

	// Purpose-based: DNS
	if _res.purpose != _|_ && _res.ip != _|_ {
		if _res.purpose =~ "(?i)dns|technitium" {
			check_dns: _T.check_dns & {IP: _res.ip}
		}
	}

	// Purpose-based: Git
	if _res.purpose != _|_ && _res.ip != _|_ {
		if _res.purpose =~ "(?i)git|forgejo|gitlab" {
			git_health: _T.git_health & {IP: _res.ip}
		}
	}

	// Purpose-based: Proxy
	if _res.purpose != _|_ && _res.ip != _|_ {
		if _res.purpose =~ "(?i)proxy|caddy|reverse" {
			proxy_health: _T.proxy_health & {IP: _res.ip}
		}
	}

	// Purpose-based: Monitoring
	if _res.purpose != _|_ && _res.ip != _|_ {
		if _res.purpose =~ "(?i)monitor|prometheus|grafana" {
			prometheus_targets: _T.prometheus_targets & {IP: _res.ip}
		}
	}

	// Allow custom actions from instance layer
	...
}
