// Demo: Caddy provider usage — targets container 100 (quicue.ca proxy)
package examples

import "quicue.ca/template/caddy/patterns"

actions: patterns.#CaddyRegistry

output: {
	example_commands: {
		config_get:  "curl -s http://localhost:2019/config/"
		routes_list: "curl -s http://localhost:2019/config/apps/http/servers/"
		tls_certs:   "curl -s http://localhost:2019/config/apps/tls/certificates/"
		upstreams:   "curl -s http://localhost:2019/reverse_proxy/upstreams"
		validate:    "caddy validate --config /etc/caddy/Caddyfile"
	}
	note: "Caddy admin API is localhost-only by default. Use SSH tunnel for remote: ssh -L 2019:localhost:2019 <caddy-host>"
}
