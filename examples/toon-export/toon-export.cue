// TOON Export Example
//
// Demonstrates TOON (Token Oriented Object Notation) compact export.
// Reduces payload size by ~55% compared to JSON for tabular infrastructure data.
//
// Commands:
//   cue eval ./examples/toon-export -e toon --out text
//   cue eval ./examples/toon-export -e compare
//   cue export ./examples/toon-export -e jsonOutput --out json

package main

import (
	"encoding/json"
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
)

// Base URI for resource IRIs
_base: "https://infra.example.com/resources/"

// Infrastructure resources using vocab.#Resource schema
_resources: [Name=string]: vocab.#Resource & {"@id": _base + Name, name: Name}
_resources: {
	// DNS servers
	"dns-primary": {
		"@type": {DNSServer: true, LXCContainer: true}
		ip:           "198.51.100.10"
		host:         "pve-node-1"
		container_id: 100
	}
	"dns-secondary": {
		"@type": {DNSServer: true, LXCContainer: true}
		ip:           "198.51.100.11"
		host:         "pve-node-2"
		container_id: 101
		depends_on: {"dns-primary": true}
	}

	// Web tier
	"web-server": {
		"@type": {WebServer: true, LXCContainer: true}
		ip:           "198.51.100.20"
		host:         "pve-node-2"
		container_id: 102
		depends_on: {"dns-primary": true}
	}
	"proxy": {
		"@type": {ReverseProxy: true, DockerContainer: true}
		ip:   "198.51.100.30"
		host: "docker-host"
		depends_on: {"web-server": true, "dns-primary": true}
	}

	// Database tier (VMs)
	"db-primary": {
		"@type": {Database: true, VM: true, CriticalInfra: true}
		ip:    "198.51.100.50"
		host:  "pve-node-1"
		vm_id: 200
		depends_on: {"dns-primary": true}
	}
	"db-replica": {
		"@type": {Database: true, VM: true}
		ip:    "198.51.100.51"
		host:  "pve-node-3"
		vm_id: 201
		depends_on: {"db-primary": true, "dns-primary": true}
	}

	// Monitoring (no container_id or vm_id)
	"monitoring": {
		"@type": {MonitoringServer: true}
		ip:   "198.51.100.100"
		host: "obs-host"
		depends_on: {"dns-primary": true}
	}
}

// =============================================================================
// TOON Export - Compact tabular format
// =============================================================================

// Default TOON export (groups by field signature)
toon: (patterns.#TOONExport & {
	Input: _resources
	Fields: ["name", "types", "ip", "host", "container_id", "vm_id"]
}).TOON

// TOON without dependencies table
toon_nodeps: (patterns.#TOONExport & {
	Input: _resources
	Fields: ["name", "types", "ip", "host"]
	IncludeDeps: false
}).TOON

// Minimal TOON (just name and IP)
toon_minimal: (patterns.#TOONExport & {
	Input: _resources
	Fields: ["name", "ip"]
	IncludeDeps: false
}).TOON

// =============================================================================
// Comparison: TOON vs JSON
// =============================================================================

// JSON output for comparison
jsonOutput: {
	resources: [
		for _, r in _resources {{
			"@id": r."@id"
			"@type": [for t, _ in r."@type" {t}]
			name: r.name
			if r.ip != _|_ {ip: r.ip}
			if r.host != _|_ {host: r.host}
			if r.container_id != _|_ {container_id: r.container_id}
			if r.vm_id != _|_ {vm_id: r.vm_id}
			if r.depends_on != _|_ {depends_on: [for d, _ in r.depends_on {d}]}
		}},
	]
}

// Token comparison metrics
_jsonStr: json.Marshal(jsonOutput)
compare: {
	toon_chars:     len(toon)
	json_chars:     len(_jsonStr)
	savings_pct:    ((json_chars - toon_chars) * 100) / json_chars
	resource_count: len(_resources)
	note:           "TOON reduces tokens by \(savings_pct)% for this dataset"
}
