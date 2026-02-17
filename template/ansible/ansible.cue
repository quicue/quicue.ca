// Ansible provider for quicue
//
// Generates Ansible inventory, Prometheus targets, AlertManager config,
// and Grafana dashboards from quicue resource graphs.
//
// Usage:
//   import "quicue.ca/template/ansible"
//
//   inventory: ansible.#AnsibleInventory & {Resources: myResources}
//   targets:   ansible.#PrometheusTargets & {Resources: myResources}

package ansible

// #MonitoringConfig - Per-resource monitoring configuration
#MonitoringConfig: {
	enabled?: bool | *true
	exporters?: [string]: {
		port: int
		path?: string | *"/metrics"
	}
}

// #AnsibleResource - Expected resource shape for ansible generators.
// Not enforced (Resources uses open struct) but documents what fields
// the generators consume across all four outputs.
#AnsibleResource: {
	ip?:           string
	ssh_user?:     string
	user?:         string
	ssh_port?:     int
	tags?:         {[string]: true}
	vm_id?:        int
	vmid?:         int
	container_id?: int
	host?:         string
	node?:         string
	owner?:        string
	severity?:     string
	monitoring?:   #MonitoringConfig
	ansible_become?:             bool
	ansible_python_interpreter?: string
	...
}
