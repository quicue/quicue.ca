// Foreman - Bare metal provisioning and lifecycle via hammer CLI
//
// Requires: hammer CLI (foreman-cli package)
//   hammer defaults add --param-name organization --param-value "My Org"
//
// Usage:
//   import "quicue.ca/template/foreman/patterns"

package patterns

import "quicue.ca/vocab"

#ForemanRegistry: {
	host_list: vocab.#ActionDef & {
		name:             "host_list"
		description:      "List all managed hosts"
		category:         "info"
		params: {}
		command_template: "hammer host list"
		idempotent:       true
	}

	host_info: vocab.#ActionDef & {
		name:             "host_info"
		description:      "Detailed host information"
		category:         "info"
		params: host_name: {from_field: "fqdn"}
		command_template: "hammer host info --name {host_name}"
		idempotent:       true
	}

	host_power: vocab.#ActionDef & {
		name:             "host_power"
		description:      "Control host power (on/off/cycle/status)"
		category:         "admin"
		params: {
			host_name:   {from_field: "fqdn"}
			power_action: {}
		}
		command_template: "hammer host start --name {host_name}"
	}

	hostgroup_list: vocab.#ActionDef & {
		name:             "hostgroup_list"
		description:      "List host groups"
		category:         "info"
		params: {}
		command_template: "hammer hostgroup list"
		idempotent:       true
	}

	compute_resources: vocab.#ActionDef & {
		name:             "compute_resources"
		description:      "List compute resources (VMware, Proxmox, etc.)"
		category:         "info"
		params: {}
		command_template: "hammer compute-resource list"
		idempotent:       true
	}

	provisioning_templates: vocab.#ActionDef & {
		name:             "provisioning_templates"
		description:      "List provisioning templates"
		category:         "info"
		params: {}
		command_template: "hammer template list"
		idempotent:       true
	}

	architecture_list: vocab.#ActionDef & {
		name:             "architecture_list"
		description:      "List supported architectures"
		category:         "info"
		params: {}
		command_template: "hammer architecture list"
		idempotent:       true
	}

	errata_list: vocab.#ActionDef & {
		name:             "errata_list"
		description:      "List available errata for host"
		category:         "info"
		params: host_name: {from_field: "fqdn"}
		command_template: "hammer host errata list --host {host_name}"
		idempotent:       true
	}

	content_views: vocab.#ActionDef & {
		name:             "content_views"
		description:      "List content views"
		category:         "info"
		params: {}
		command_template: "hammer content-view list"
		idempotent:       true
	}

	fact_list: vocab.#ActionDef & {
		name:             "fact_list"
		description:      "List facts reported by host"
		category:         "info"
		params: host_name: {from_field: "fqdn"}
		command_template: "hammer fact list --search 'host={host_name}'"
		idempotent:       true
	}

	...
}
