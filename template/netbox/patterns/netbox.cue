// NetBox - IPAM and DCIM via REST API
//
// Requires: curl, NetBox API token
//
// Usage:
//   import "quicue.ca/template/netbox/patterns"

package patterns

import "quicue.ca/vocab"

#NetBoxRegistry: {
	devices: vocab.#ActionDef & {
		name:             "devices"
		description:      "List DCIM devices"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' {api_url}/api/dcim/devices/"
		idempotent:       true
	}

	racks: vocab.#ActionDef & {
		name:             "racks"
		description:      "List datacenter racks"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' {api_url}/api/dcim/racks/"
		idempotent:       true
	}

	sites: vocab.#ActionDef & {
		name:             "sites"
		description:      "List physical sites (buildings, campuses)"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' {api_url}/api/dcim/sites/"
		idempotent:       true
	}

	prefixes: vocab.#ActionDef & {
		name:             "prefixes"
		description:      "List IP prefixes (subnets)"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' {api_url}/api/ipam/prefixes/"
		idempotent:       true
	}

	addresses: vocab.#ActionDef & {
		name:             "addresses"
		description:      "List IP addresses"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' {api_url}/api/ipam/ip-addresses/"
		idempotent:       true
	}

	vlans: vocab.#ActionDef & {
		name:             "vlans"
		description:      "List VLANs"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' {api_url}/api/ipam/vlans/"
		idempotent:       true
	}

	circuits: vocab.#ActionDef & {
		name:             "circuits"
		description:      "List network circuits"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' {api_url}/api/circuits/circuits/"
		idempotent:       true
	}

	tenants: vocab.#ActionDef & {
		name:             "tenants"
		description:      "List tenants (departments, faculties)"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' {api_url}/api/tenancy/tenants/"
		idempotent:       true
	}

	vms: vocab.#ActionDef & {
		name:             "vms"
		description:      "List virtual machines"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' {api_url}/api/virtualization/virtual-machines/"
		idempotent:       true
	}

	clusters: vocab.#ActionDef & {
		name:             "clusters"
		description:      "List virtualization clusters"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' {api_url}/api/virtualization/clusters/"
		idempotent:       true
	}

	search: vocab.#ActionDef & {
		name:             "search"
		description:      "Global search across all NetBox objects"
		category:         "info"
		params: {
			api_url:   {from_field: "netbox_url"}
			api_token: {from_field: "netbox_token"}
			query:     {}
		}
		command_template: "curl -s -H 'Authorization: Token {api_token}' '{api_url}/api/dcim/devices/?q={query}'"
		idempotent:       true
	}

	...
}
