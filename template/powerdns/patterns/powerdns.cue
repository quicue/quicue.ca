// PowerDNS - Authoritative DNS management via REST API
//
// Requires: curl, PowerDNS API enabled, api-key configured
//
// Usage:
//   import "quicue.ca/template/powerdns/patterns"

package patterns

import "quicue.ca/vocab"

#PowerDNSRegistry: {
	zone_list: vocab.#ActionDef & {
		name:        "zone_list"
		description: "List all authoritative zones"
		category:    "info"
		params: {
			api_url: {from_field: "pdns_api_url"}
			api_key: {from_field: "pdns_api_key"}
		}
		command_template: "curl -s -H 'X-API-Key: {api_key}' {api_url}/api/v1/servers/localhost/zones"
		idempotent:       true
	}

	zone_get: vocab.#ActionDef & {
		name:        "zone_get"
		description: "Get zone details and records"
		category:    "info"
		params: {
			api_url: {from_field: "pdns_api_url"}
			api_key: {from_field: "pdns_api_key"}
			zone_name: {from_field: "zone_name"}
		}
		command_template: "curl -s -H 'X-API-Key: {api_key}' {api_url}/api/v1/servers/localhost/zones/{zone_name}"
		idempotent:       true
	}

	zone_create: vocab.#ActionDef & {
		name:        "zone_create"
		description: "Create a new DNS zone"
		category:    "admin"
		params: {
			api_url: {from_field: "pdns_api_url"}
			api_key: {from_field: "pdns_api_key"}
			zone_json: {}
		}
		command_template: "curl -s -X POST -H 'X-API-Key: {api_key}' -H 'Content-Type: application/json' -d '{zone_json}' {api_url}/api/v1/servers/localhost/zones"
	}

	zone_delete: vocab.#ActionDef & {
		name:        "zone_delete"
		description: "Delete a DNS zone"
		category:    "admin"
		params: {
			api_url: {from_field: "pdns_api_url"}
			api_key: {from_field: "pdns_api_key"}
			zone_name: {from_field: "zone_name"}
		}
		command_template: "curl -s -X DELETE -H 'X-API-Key: {api_key}' {api_url}/api/v1/servers/localhost/zones/{zone_name}"
		destructive:      true
	}

	record_update: vocab.#ActionDef & {
		name:        "record_update"
		description: "Update records in a zone (PATCH rrsets)"
		category:    "admin"
		params: {
			api_url: {from_field: "pdns_api_url"}
			api_key: {from_field: "pdns_api_key"}
			zone_name: {from_field: "zone_name"}
			rrset_json: {}
		}
		command_template: "curl -s -X PATCH -H 'X-API-Key: {api_key}' -H 'Content-Type: application/json' -d '{rrset_json}' {api_url}/api/v1/servers/localhost/zones/{zone_name}"
	}

	server_config: vocab.#ActionDef & {
		name:        "server_config"
		description: "Show server configuration"
		category:    "info"
		params: {
			api_url: {from_field: "pdns_api_url"}
			api_key: {from_field: "pdns_api_key"}
		}
		command_template: "curl -s -H 'X-API-Key: {api_key}' {api_url}/api/v1/servers/localhost/config"
		idempotent:       true
	}

	server_stats: vocab.#ActionDef & {
		name:        "server_stats"
		description: "Show server statistics (queries, cache)"
		category:    "monitor"
		params: {
			api_url: {from_field: "pdns_api_url"}
			api_key: {from_field: "pdns_api_key"}
		}
		command_template: "curl -s -H 'X-API-Key: {api_key}' {api_url}/api/v1/servers/localhost/statistics"
		idempotent:       true
	}

	search: vocab.#ActionDef & {
		name:        "search"
		description: "Search for records across zones"
		category:    "info"
		params: {
			api_url: {from_field: "pdns_api_url"}
			api_key: {from_field: "pdns_api_key"}
			query: {}
		}
		command_template: "curl -s -H 'X-API-Key: {api_key}' '{api_url}/api/v1/servers/localhost/search-data?q={query}'"
		idempotent:       true
	}

	cache_flush: vocab.#ActionDef & {
		name:        "cache_flush"
		description: "Flush packet cache for domain"
		category:    "admin"
		params: {
			api_url: {from_field: "pdns_api_url"}
			api_key: {from_field: "pdns_api_key"}
			domain: {}
		}
		command_template: "curl -s -X PUT -H 'X-API-Key: {api_key}' {api_url}/api/v1/servers/localhost/cache/flush?domain={domain}"
	}

	...
}
