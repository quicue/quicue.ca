// Caddy Provider - Reverse proxy management via admin API
//
// Caddy admin API defaults to localhost:2019.
// For remote access, SSH tunnel or configure admin listener.
//
// Usage:
//   import "quicue.ca/template/caddy/patterns"

package patterns

import "quicue.ca/vocab"

// #CaddyRegistry - Caddy admin API action definitions
#CaddyRegistry: {
	// ========== Config Actions ==========

	config_get: vocab.#ActionDef & {
		name:             "Get Config"
		description:      "Retrieve full Caddy JSON configuration"
		category:         "info"
		params: admin_url: {from_field: "admin_url"}
		command_template: "curl -s {admin_url}/config/"
		idempotent:       true
	}

	config_apps: vocab.#ActionDef & {
		name:             "List Apps"
		description:      "List configured Caddy apps (http, tls, etc.)"
		category:         "info"
		params: admin_url: {from_field: "admin_url"}
		command_template: "curl -s {admin_url}/config/apps/"
		idempotent:       true
	}

	// ========== HTTP Server / Routes ==========

	routes_list: vocab.#ActionDef & {
		name:             "List Routes"
		description:      "List HTTP server routes"
		category:         "info"
		params: admin_url: {from_field: "admin_url"}
		command_template: "curl -s {admin_url}/config/apps/http/servers/"
		idempotent:       true
	}

	// ========== TLS Actions ==========

	tls_certs: vocab.#ActionDef & {
		name:             "TLS Certificates"
		description:      "List managed TLS certificates"
		category:         "info"
		params: admin_url: {from_field: "admin_url"}
		command_template: "curl -s {admin_url}/config/apps/tls/certificates/"
		idempotent:       true
	}

	tls_automation: vocab.#ActionDef & {
		name:             "TLS Automation"
		description:      "Show ACME/ZeroSSL automation config"
		category:         "info"
		params: admin_url: {from_field: "admin_url"}
		command_template: "curl -s {admin_url}/config/apps/tls/automation/"
		idempotent:       true
	}

	// ========== Admin / Lifecycle ==========

	reload: vocab.#ActionDef & {
		name:             "Reload Config"
		description:      "Load new configuration from Caddyfile or JSON"
		category:         "admin"
		params: {
			admin_url:   {from_field: "admin_url"}
			config_path: {required: false, default: "/etc/caddy/Caddyfile"}
		}
		command_template: "caddy reload --config {config_path}"
	}

	adapt: vocab.#ActionDef & {
		name:             "Adapt Caddyfile"
		description:      "Convert Caddyfile to JSON config"
		category:         "info"
		params: config_path: {required: false, default: "/etc/caddy/Caddyfile"}
		command_template: "caddy adapt --config {config_path}"
		idempotent:       true
	}

	validate: vocab.#ActionDef & {
		name:             "Validate Config"
		description:      "Validate Caddy configuration"
		category:         "info"
		params: config_path: {required: false, default: "/etc/caddy/Caddyfile"}
		command_template: "caddy validate --config {config_path}"
		idempotent:       true
	}

	reverse_proxy_upstreams: vocab.#ActionDef & {
		name:             "Reverse Proxy Upstreams"
		description:      "List reverse proxy upstream health"
		category:         "monitor"
		params: admin_url: {from_field: "admin_url"}
		command_template: "curl -s {admin_url}/reverse_proxy/upstreams"
		idempotent:       true
	}

	// Allow provider extensions
	...
}
