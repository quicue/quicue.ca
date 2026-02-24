// Demo: Ansible provider usage with enhanced generators
package example

import "quicue.ca/template/ansible"

// Sample resources (mimicking a real quicue graph)
_resources: {
	"dns-server": {
		ip:           "198.51.100.10"
		host:         "pve-node-1"
		container_id: 100
		ssh_user:     "root"
		tags: {DNSServer: true, CriticalInfra: true}
		monitoring: exporters: {
			node: port: 9100
			bind: port: 9119
		}
	}
	"git-server": {
		ip:       "198.51.100.20"
		host:     "pve-node-2"
		vm_id:    200
		ssh_user: "git"
		tags: {SourceControlManagement: true}
		monitoring: exporters: {
			node: port:   9100
			gitlab: port: 9168
		}
	}
	"web-proxy": {
		ip:           "198.51.100.30"
		host:         "pve-node-1"
		container_id: 300
		ssh_user:     "root"
		tags: {ReverseProxy: true, CriticalInfra: true}
		owner: "infra-team"
	}
	"dev-workstation": {
		ip:       "198.51.100.50"
		host:     "pve-node-3"
		vm_id:    500
		ssh_user: "dev"
		ssh_port: 2222
		tags: {DevelopmentWorkstation: true}
		owner:          "dev-team"
		ansible_become: true
		monitoring: enabled: false
	}
	"monitoring": {
		ip:           "198.51.100.60"
		host:         "pve-node-2"
		container_id: 600
		ssh_user:     "root"
		tags: {Monitoring: true, CriticalInfra: true}
		owner: "infra-team"
		monitoring: exporters: {
			node: port:       9100
			prometheus: port: 9090
		}
	}
}

// Generate Ansible inventory
inventory: ansible.#AnsibleInventory & {Resources: _resources}

// Generate Prometheus targets
prometheus: ansible.#PrometheusTargets & {
	Resources: _resources
	Job:       "homelab"
	ExtraLabels: environment: "homelab"
}

// Generate AlertManager config
alertmanager: ansible.#AlertManagerRoutes & {
	Resources: _resources
	Receivers: {
		"infra-team": webhook_url: "https://ntfy.example.com/infra-alerts"
		"dev-team": email:         "dev@example.com"
	}
}

// Generate Grafana dashboard
grafana: ansible.#GrafanaDashboard & {
	Resources: _resources
	Title:     "Home Lab Overview"
}

// Export commands:
//   cue export ./template/ansible/examples -e inventory.all --out yaml
//   cue export ./template/ansible/examples -e prometheus.targets --out json
//   cue export ./template/ansible/examples -e alertmanager.config --out yaml
//   cue export ./template/ansible/examples -e grafana.dashboard --out json
