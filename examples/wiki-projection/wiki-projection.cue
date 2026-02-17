// Wiki Projection: generate MkDocs site from infrastructure graph
// Run: cue eval ./examples/wiki-projection/ -e output
//
// Demonstrates:
//   - wiki.#WikiProjection transforms resource graphs into markdown
//   - Auto-generated pages: index, per-resource, per-type, per-host
//   - Mermaid dependency diagrams
//   - MkDocs configuration generation
//   - Stats computation from graph topology

package main

import "quicue.ca/wiki"

// Small infrastructure to project into a wiki
_resources: {
	"router-core": {
		name:        "router-core"
		description: "VyOS core router"
		"@type":     {Router: true}
		ip:          "198.51.100.1"
		host:        "pve-node-1"
		depends_on:  {}
	}
	"dns-internal": {
		name:        "dns-internal"
		description: "PowerDNS internal resolver"
		"@type":     {DNSServer: true, LXCContainer: true}
		ip:          "198.51.100.10"
		host:        "pve-node-1"
		depends_on:  {"router-core": true}
	}
	"caddy-proxy": {
		name:        "caddy-proxy"
		description: "Caddy reverse proxy with automatic HTTPS"
		"@type":     {ReverseProxy: true, LXCContainer: true}
		ip:          "198.51.100.11"
		host:        "pve-node-1"
		depends_on:  {"dns-internal": true}
	}
	"gitlab-scm": {
		name:        "gitlab-scm"
		description: "GitLab source control and CI/CD"
		"@type":     {SourceControlManagement: true, LXCContainer: true}
		ip:          "198.51.100.20"
		host:        "pve-node-2"
		depends_on:  {"dns-internal": true, "caddy-proxy": true}
	}
	"postgres-main": {
		name:        "postgres-main"
		description: "Primary PostgreSQL database"
		"@type":     {Database: true}
		ip:          "198.51.100.30"
		host:        "pve-node-2"
		depends_on:  {"dns-internal": true}
	}
}

// Project into a wiki
projection: wiki.#WikiProjection & {
	Resources:       _resources
	SiteTitle:       "Homelab Wiki"
	SiteDescription: "Auto-generated from quicue infrastructure graph"
	SiteURL:         "https://wiki.example.com"
}

output: {
	// How many pages would be generated
	stats: projection.stats

	// List of all files that would be created
	file_list: projection.file_list

	// Preview: index page content (first 30 lines)
	index_preview: projection.files["docs/index.md"].content

	// Preview: dependency graph with Mermaid
	graph_preview: projection.files["docs/graph.md"].content

	// MkDocs config
	mkdocs_config: projection.files["mkdocs.yml"].content
}
