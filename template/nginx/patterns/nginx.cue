// Nginx - Web server and reverse proxy management
//
// Requires: nginx installed, config directory access
//   Remote: ssh {user}@{host} 'nginx ...'
//
// Usage:
//   import "quicue.ca/template/nginx/patterns"

package patterns

import "quicue.ca/vocab"

#NginxRegistry: {
	test_config: vocab.#ActionDef & {
		name:        "test_config"
		description: "Test nginx configuration syntax"
		category:    "info"
		params: {}
		command_template: "nginx -t"
		idempotent:       true
	}

	reload: vocab.#ActionDef & {
		name:        "reload"
		description: "Reload nginx configuration"
		category:    "admin"
		params: {}
		command_template: "nginx -s reload"
	}

	status: vocab.#ActionDef & {
		name:        "status"
		description: "Check nginx service status"
		category:    "info"
		params: {}
		command_template: "systemctl status nginx"
		idempotent:       true
	}

	version: vocab.#ActionDef & {
		name:        "version"
		description: "Show nginx version and build info"
		category:    "info"
		params: {}
		command_template: "nginx -V"
		idempotent:       true
	}

	list_sites: vocab.#ActionDef & {
		name:        "list_sites"
		description: "List enabled site configurations"
		category:    "info"
		params: {}
		command_template: "ls -la /etc/nginx/sites-enabled/"
		idempotent:       true
	}

	stub_status: vocab.#ActionDef & {
		name:        "stub_status"
		description: "Active connections and request stats"
		category:    "monitor"
		params: status_url: {from_field: "nginx_status_url", required: false}
		command_template: "curl -s {status_url}"
		idempotent:       true
	}

	access_log: vocab.#ActionDef & {
		name:        "access_log"
		description: "Tail recent access log entries"
		category:    "monitor"
		params: {}
		command_template: "tail -50 /var/log/nginx/access.log"
		idempotent:       true
	}

	error_log: vocab.#ActionDef & {
		name:        "error_log"
		description: "Tail recent error log entries"
		category:    "monitor"
		params: {}
		command_template: "tail -50 /var/log/nginx/error.log"
		idempotent:       true
	}

	ssl_check: vocab.#ActionDef & {
		name:        "ssl_check"
		description: "Check SSL certificate expiry for domain"
		category:    "info"
		params: domain: {from_field: "fqdn"}
		command_template: "echo | openssl s_client -servername {domain} -connect {domain}:443 2>/dev/null | openssl x509 -noout -dates"
		idempotent:       true
	}

	...
}
