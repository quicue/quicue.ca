// Action templates for Proxmox-based infrastructure
// These are pure data templates - consuming projects apply conditionals
//
// IMPORTANT: Template parameters use UPPERCASE names (IP, User, Name, etc.)
// because CUE hidden fields (_foo) are package-scoped and don't unify
// across import boundaries. Uppercase fields are visible and unify correctly.
//
// Fields use `| *` defaults so consumers can override specific values
// while keeping other fields from the template.
package patterns

// #ActionTemplates - Building blocks for action generation
// Usage:
//   import "quicue.ca/proxmox/patterns"
//   _T: patterns.#ActionTemplates
//   actions: { ping: _T.ping & {IP: "10.0.0.1"} }
#ActionTemplates: {
	// =========================================================================
	// Connectivity actions (generic)
	// =========================================================================
	ping: {
		IP:          string
		name:        string | *"Ping"
		description: string | *"Test network connectivity to \(IP)"
		command:     string | *"ping -c 3 \(IP)"
		icon:        string | *"[ping]"
		category:    string | *"connect"
	}

	ssh: {
		IP:          string
		USER:        string
		name:        string | *"SSH"
		description: string | *"SSH into resource as \(USER)"
		command:     string | *"ssh \(USER)@\(IP)"
		icon:        string | *"[ssh]"
		category:    string | *"connect"
	}

	info: {
		NAME:        string
		name:        string | *"Info from Graph"
		description: string | *"Show this resource's data from semantic graph"
		command:     string | *"cue export -e 'infraGraph[\"\(NAME)\"]'"
		icon:        string | *"[info]"
		category:    string | *"info"
	}

	// =========================================================================
	// Proxmox LXC actions (pct)
	// =========================================================================
	pct_status: {
		CTID:        int
		NODE:        string
		NODE_HOST:   string | *NODE // IP or hostname of the Proxmox node
		name:        string | *"Container Status"
		description: string | *"Check LXC \(CTID) on \(NODE)"
		command:     string | *"ssh \(NODE_HOST) 'pct status \(CTID)'"
		icon:        string | *"[status]"
		category:    string | *"monitor"
	}

	pct_console: {
		CTID:        int
		NODE:        string
		NODE_HOST:   string | *NODE
		name:        string | *"Console"
		description: string | *"Attach to LXC console"
		command:     string | *"ssh -t \(NODE_HOST) 'pct enter \(CTID)'"
		icon:        string | *"[console]"
		category:    string | *"connect"
	}

	pct_start: {
		CTID:        int
		NODE:        string
		NODE_HOST:   string | *NODE
		name:        string | *"Start"
		description: string | *"Start LXC \(CTID)"
		command:     string | *"ssh \(NODE_HOST) 'pct start \(CTID)'"
		icon:        string | *"[start]"
		category:    string | *"admin"
	}

	pct_stop: {
		CTID:        int
		NODE:        string
		NODE_HOST:   string | *NODE
		name:        string | *"Stop"
		description: string | *"Stop LXC \(CTID)"
		command:     string | *"ssh \(NODE_HOST) 'pct shutdown \(CTID)'"
		icon:        string | *"[stop]"
		category:    string | *"admin"
	}

	pct_config: {
		CTID:        int
		NODE:        string
		NODE_HOST:   string | *NODE
		name:        string | *"Configuration"
		description: string | *"Show LXC \(CTID) configuration"
		command:     string | *"ssh \(NODE_HOST) 'pct config \(CTID)'"
		icon:        string | *"[config]"
		category:    string | *"info"
	}

	// =========================================================================
	// Proxmox VM actions (qm)
	// =========================================================================
	qm_status: {
		VMID:        int
		NODE:        string
		NODE_HOST:   string | *NODE
		name:        string | *"VM Status"
		description: string | *"Check VM \(VMID) status on \(NODE)"
		command:     string | *"ssh \(NODE_HOST) 'qm status \(VMID)'"
		icon:        string | *"[status]"
		category:    string | *"monitor"
	}

	qm_config: {
		VMID:        int
		NODE:        string
		NODE_HOST:   string | *NODE
		name:        string | *"VM Config"
		description: string | *"Show VM \(VMID) configuration"
		command:     string | *"ssh \(NODE_HOST) 'qm config \(VMID)'"
		icon:        string | *"[config]"
		category:    string | *"info"
	}

	qm_console: {
		VMID:        int
		NODE:        string
		NODE_HOST:   string | *NODE
		name:        string | *"Console"
		description: string | *"Open VM console (qm terminal)"
		command:     string | *"ssh -t \(NODE_HOST) 'qm terminal \(VMID)'"
		icon:        string | *"[console]"
		category:    string | *"connect"
	}

	qm_start: {
		VMID:        int
		NODE:        string
		NODE_HOST:   string | *NODE
		name:        string | *"Start"
		description: string | *"Start VM \(VMID)"
		command:     string | *"ssh \(NODE_HOST) 'qm start \(VMID)'"
		icon:        string | *"[start]"
		category:    string | *"admin"
	}

	qm_stop: {
		VMID:        int
		NODE:        string
		NODE_HOST:   string | *NODE
		name:        string | *"Stop"
		description: string | *"Shutdown VM \(VMID)"
		command:     string | *"ssh \(NODE_HOST) 'qm shutdown \(VMID)'"
		icon:        string | *"[stop]"
		category:    string | *"admin"
	}

	// =========================================================================
	// Proxmox node actions (hypervisor)
	// =========================================================================
	list_vms: {
		IP:          string
		USER:        string | *"root"
		name:        string | *"List VMs"
		description: string | *"Show all virtual machines"
		command:     string | *"ssh \(USER)@\(IP) 'qm list'"
		icon:        string | *"[vms]"
		category:    string | *"info"
	}

	list_containers: {
		IP:          string
		USER:        string | *"root"
		name:        string | *"List Containers"
		description: string | *"Show all LXC containers"
		command:     string | *"ssh \(USER)@\(IP) 'pct list'"
		icon:        string | *"[containers]"
		category:    string | *"info"
	}

	cluster_status: {
		IP:          string
		USER:        string | *"root"
		name:        string | *"Cluster Status"
		description: string | *"Show Proxmox cluster status"
		command:     string | *"ssh \(USER)@\(IP) 'pvecm status'"
		icon:        string | *"[cluster]"
		category:    string | *"monitor"
	}

	storage_status: {
		IP:          string
		USER:        string | *"root"
		name:        string | *"Storage Status"
		description: string | *"Show storage pool status"
		command:     string | *"ssh \(USER)@\(IP) 'pvesm status'"
		icon:        string | *"[storage]"
		category:    string | *"monitor"
	}

	// =========================================================================
	// Service-specific actions (commonly used with Proxmox infra)
	// =========================================================================
	check_dns: {
		IP:          string
		name:        string | *"Check DNS"
		description: string | *"Verify DNS resolution"
		command:     string | *"dig @\(IP) SOA"
		icon:        string | *"[dns]"
		category:    string | *"monitor"
	}

	query_zones: {
		IP:          string
		name:        string | *"Query DNS Zones"
		description: string | *"List all DNS zones configured"
		command:     string | *"dig @\(IP) axfr"
		icon:        string | *"[zones]"
		category:    string | *"info"
	}

	verify_resolution: {
		IP:          string
		name:        string | *"Verify DNS Resolution"
		description: string | *"Test DNS resolution for common domains"
		command:     string | *"dig @\(IP) google.com +short"
		icon:        string | *"[resolve]"
		category:    string | *"monitor"
	}

	proxy_health: {
		IP:          string
		name:        string | *"Proxy Health"
		description: string | *"Test reverse proxy"
		command:     string | *"curl -I http://\(IP)"
		icon:        string | *"[proxy]"
		category:    string | *"monitor"
	}

	reload_config: {
		IP:          string
		USER:        string | *"root"
		name:        string | *"Reload Proxy Config"
		description: string | *"Reload reverse proxy configuration"
		command:     string | *"ssh \(USER)@\(IP) 'caddy reload || nginx -s reload'"
		icon:        string | *"[reload]"
		category:    string | *"admin"
	}

	test_config: {
		IP:          string
		USER:        string | *"root"
		name:        string | *"Test Config"
		description: string | *"Validate proxy configuration"
		command:     string | *"ssh \(USER)@\(IP) 'caddy validate || nginx -t'"
		icon:        string | *"[test]"
		category:    string | *"admin"
	}

	gpu_info: {
		IP:          string
		USER:        string
		name:        string | *"GPU Info"
		description: string | *"Show GPU details"
		command:     string | *"ssh \(USER)@\(IP) 'lspci | grep -i vga'"
		icon:        string | *"[gpu]"
		category:    string | *"monitor"
	}

	docker_ps: {
		IP:          string
		USER:        string
		name:        string | *"List Containers"
		description: string | *"Show running containers/VMs"
		command:     string | *"ssh \(USER)@\(IP) 'docker ps || podman ps'"
		icon:        string | *"[docker]"
		category:    string | *"info"
	}

	disk_usage: {
		IP:          string
		USER:        string
		name:        string | *"Disk Usage"
		description: string | *"Check disk space usage"
		command:     string | *"ssh \(USER)@\(IP) 'df -h | grep -v tmpfs'"
		icon:        string | *"[disk]"
		category:    string | *"monitor"
	}

	list_active_sessions: {
		IP:          string
		USER:        string
		name:        string | *"Active SSH Sessions"
		description: string | *"Show currently active SSH sessions"
		command:     string | *"ssh \(USER)@\(IP) 'w'"
		icon:        string | *"[sessions]"
		category:    string | *"monitor"
	}

	check_auth_log: {
		IP:          string
		USER:        string
		name:        string | *"Check Auth Log"
		description: string | *"View recent authentication attempts"
		command:     string | *"ssh \(USER)@\(IP) 'sudo tail -n 50 /var/log/auth.log'"
		icon:        string | *"[auth]"
		category:    string | *"security"
	}

	check_vault: {
		IP:          string
		name:        string | *"Check Vault Status"
		description: string | *"Verify vault service is running"
		command:     string | *"curl -sf http://\(IP)/api/alive"
		icon:        string | *"[vault]"
		category:    string | *"monitor"
	}

	git_health: {
		IP:          string
		name:        string | *"Git Health Check"
		description: string | *"Verify Git service health"
		command:     string | *"curl -sf http://\(IP)/-/health | jq"
		icon:        string | *"[git]"
		category:    string | *"monitor"
	}

	list_repos: {
		IP:          string
		USER:        string | *"root"
		name:        string | *"List Repositories"
		description: string | *"Show all Git repositories"
		command:     string | *"ssh \(USER)@\(IP) 'find /var/lib -name \"*.git\" -type d 2>/dev/null | head -20'"
		icon:        string | *"[repos]"
		category:    string | *"info"
	}

	prometheus_targets: {
		IP:          string
		name:        string | *"Prometheus Targets"
		description: string | *"Show monitoring targets"
		command:     string | *"curl -s http://\(IP):9090/api/v1/targets | jq '.data.activeTargets[] | {job:.labels.job, health:.health}'"
		icon:        string | *"[targets]"
		category:    string | *"info"
	}
}
