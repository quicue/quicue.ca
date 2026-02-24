// Cloudflare - DNS, tunnels, WAF via API
//
// Requires: curl, CF_API_TOKEN (or pass api_token param)
//
// Usage:
//   import "quicue.ca/template/cloudflare/patterns"

package patterns

import "quicue.ca/vocab"

#CloudflareRegistry: {
	zone_list: vocab.#ActionDef & {
		name:        "zone_list"
		description: "List all DNS zones in account"
		category:    "info"
		params: api_token: {from_field: "cf_api_token"}
		command_template: "curl -s -H 'Authorization: Bearer {api_token}' https://api.cloudflare.com/client/v4/zones"
		idempotent:       true
	}

	dns_list: vocab.#ActionDef & {
		name:        "dns_list"
		description: "List DNS records for a zone"
		category:    "info"
		params: {
			api_token: {from_field: "cf_api_token"}
			zone_id: {from_field: "zone_id"}
		}
		command_template: "curl -s -H 'Authorization: Bearer {api_token}' https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records"
		idempotent:       true
	}

	dns_create: vocab.#ActionDef & {
		name:        "dns_create"
		description: "Create a DNS record"
		category:    "admin"
		params: {
			api_token: {from_field: "cf_api_token"}
			zone_id: {from_field: "zone_id"}
			record_json: {}
		}
		command_template: "curl -s -X POST -H 'Authorization: Bearer {api_token}' -H 'Content-Type: application/json' -d '{record_json}' https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records"
	}

	dns_delete: vocab.#ActionDef & {
		name:        "dns_delete"
		description: "Delete a DNS record"
		category:    "admin"
		params: {
			api_token: {from_field: "cf_api_token"}
			zone_id: {from_field: "zone_id"}
			record_id: {}
		}
		command_template: "curl -s -X DELETE -H 'Authorization: Bearer {api_token}' https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{record_id}"
		destructive:      true
	}

	tunnel_list: vocab.#ActionDef & {
		name:        "tunnel_list"
		description: "List Cloudflare tunnels"
		category:    "info"
		params: {
			api_token: {from_field: "cf_api_token"}
			account_id: {from_field: "cf_account_id"}
		}
		command_template: "curl -s -H 'Authorization: Bearer {api_token}' https://api.cloudflare.com/client/v4/accounts/{account_id}/cfd_tunnel"
		idempotent:       true
	}

	cache_purge: vocab.#ActionDef & {
		name:        "cache_purge"
		description: "Purge entire zone cache"
		category:    "admin"
		params: {
			api_token: {from_field: "cf_api_token"}
			zone_id: {from_field: "zone_id"}
		}
		command_template: "curl -s -X POST -H 'Authorization: Bearer {api_token}' -H 'Content-Type: application/json' -d '{\"purge_everything\":true}' https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache"
		destructive:      true
	}

	firewall_rules: vocab.#ActionDef & {
		name:        "firewall_rules"
		description: "List firewall rules for zone"
		category:    "info"
		params: {
			api_token: {from_field: "cf_api_token"}
			zone_id: {from_field: "zone_id"}
		}
		command_template: "curl -s -H 'Authorization: Bearer {api_token}' https://api.cloudflare.com/client/v4/zones/{zone_id}/firewall/rules"
		idempotent:       true
	}

	ssl_status: vocab.#ActionDef & {
		name:        "ssl_status"
		description: "Check SSL/TLS settings for zone"
		category:    "info"
		params: {
			api_token: {from_field: "cf_api_token"}
			zone_id: {from_field: "zone_id"}
		}
		command_template: "curl -s -H 'Authorization: Bearer {api_token}' https://api.cloudflare.com/client/v4/zones/{zone_id}/settings/ssl"
		idempotent:       true
	}

	analytics: vocab.#ActionDef & {
		name:        "analytics"
		description: "Zone analytics dashboard data"
		category:    "monitor"
		params: {
			api_token: {from_field: "cf_api_token"}
			zone_id: {from_field: "zone_id"}
		}
		command_template: "curl -s -H 'Authorization: Bearer {api_token}' https://api.cloudflare.com/client/v4/zones/{zone_id}/analytics/dashboard"
		idempotent:       true
	}

	...
}
