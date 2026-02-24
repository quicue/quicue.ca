// Technitium DNS - DNS management via REST API
//
// Requires: curl, Technitium DNS web API enabled, API token
//
// Usage:
//   import "quicue.ca/template/technitium/patterns"

package patterns

import "quicue.ca/vocab"

#TechnitiumRegistry: {
	zone_list: vocab.#ActionDef & {
		name:        "zone_list"
		description: "List all DNS zones"
		category:    "info"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
		}
		command_template: "curl -s '{api_url}/api/zones/list?token={token}'"
		idempotent:       true
	}

	zone_create: vocab.#ActionDef & {
		name:        "zone_create"
		description: "Create a new primary DNS zone"
		category:    "admin"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
			zone_name: {from_field: "zone_name"}
		}
		command_template: "curl -s '{api_url}/api/zones/create?token={token}&zone={zone_name}&type=Primary'"
	}

	zone_delete: vocab.#ActionDef & {
		name:        "zone_delete"
		description: "Delete a DNS zone"
		category:    "admin"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
			zone_name: {from_field: "zone_name"}
		}
		command_template: "curl -s '{api_url}/api/zones/delete?token={token}&zone={zone_name}'"
		destructive:      true
	}

	zone_disable: vocab.#ActionDef & {
		name:        "zone_disable"
		description: "Disable a DNS zone"
		category:    "admin"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
			zone_name: {from_field: "zone_name"}
		}
		command_template: "curl -s '{api_url}/api/zones/disable?token={token}&zone={zone_name}'"
	}

	zone_enable: vocab.#ActionDef & {
		name:        "zone_enable"
		description: "Enable a DNS zone"
		category:    "admin"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
			zone_name: {from_field: "zone_name"}
		}
		command_template: "curl -s '{api_url}/api/zones/enable?token={token}&zone={zone_name}'"
	}

	record_add: vocab.#ActionDef & {
		name:        "record_add"
		description: "Add a DNS record to a zone"
		category:    "admin"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
			zone_name: {from_field: "zone_name"}
			domain: {}
			record_type: {}
			value: {}
			ttl: {default: "3600"}
		}
		command_template: "curl -s '{api_url}/api/zones/records/add?token={token}&zone={zone_name}&domain={domain}&type={record_type}&value={value}&ttl={ttl}'"
	}

	record_get: vocab.#ActionDef & {
		name:        "record_get"
		description: "Get DNS records for a zone"
		category:    "info"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
			zone_name: {from_field: "zone_name"}
		}
		command_template: "curl -s '{api_url}/api/zones/records/get?token={token}&zone={zone_name}&listZone=true'"
		idempotent:       true
	}

	record_delete: vocab.#ActionDef & {
		name:        "record_delete"
		description: "Delete a DNS record from a zone"
		category:    "admin"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
			zone_name: {from_field: "zone_name"}
			domain: {}
			record_type: {}
			value: {}
		}
		command_template: "curl -s '{api_url}/api/zones/records/delete?token={token}&zone={zone_name}&domain={domain}&type={record_type}&value={value}'"
		destructive:      true
	}

	conditional_forwarder_create: vocab.#ActionDef & {
		name:        "conditional_forwarder_create"
		description: "Create a conditional forwarder zone"
		category:    "admin"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
			zone_name: {from_field: "zone_name"}
			forwarder: {}
		}
		command_template: "curl -s '{api_url}/api/zones/create?token={token}&zone={zone_name}&type=Forwarder&protocol=Udp&forwarder={forwarder}'"
	}

	settings_get: vocab.#ActionDef & {
		name:        "settings_get"
		description: "Get DNS server settings"
		category:    "info"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
		}
		command_template: "curl -s '{api_url}/api/settings/get?token={token}'"
		idempotent:       true
	}

	stats: vocab.#ActionDef & {
		name:        "stats"
		description: "Get DNS server statistics"
		category:    "monitor"
		params: {
			api_url: {from_field: "technitium_api_url"}
			token: {from_field: "technitium_token"}
		}
		command_template: "curl -s '{api_url}/api/dashboard/stats/get?token={token}&type=LastHour'"
		idempotent:       true
	}

	...
}
