// Demo: VyOS provider usage — targets the quicue.ca VyOS router
package examples

import "quicue.ca/template/vyos/patterns"

actions: patterns.#VyOSRegistry

// Example targeting 198.51.100.1 (infra.example.com VyOS router)
output: {
	example_commands: {
		show_interfaces: "ssh vyos@198.51.100.1 'show interfaces'"
		show_route:      "ssh vyos@198.51.100.1 'show ip route'"
		show_bgp:        "ssh vyos@198.51.100.1 'show bgp summary'"
		show_firewall:   "ssh vyos@198.51.100.1 'show firewall'"
		show_config:     "ssh vyos@198.51.100.1 'show configuration'"
		show_version:    "ssh vyos@198.51.100.1 'show version'"
	}
}
