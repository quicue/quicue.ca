// Graph patterns: topology, impact, criticality, grouping
// Run: cue eval ./examples/graph-patterns/ -e output

package main

import (
	"list"
	"strings"
	"quicue.ca/patterns@v0"
)

// Sample infrastructure with dependencies
_resources: {
	"pve-node": {
		name: "pve-node"
		"@type": {VirtualizationPlatform: true}
	}
	"dns-primary": {
		name: "dns-primary"
		"@type": {DNSServer: true, CriticalInfra: true}
		depends_on: {"pve-node": true}
	}
	"reverse-proxy": {
		name: "reverse-proxy"
		"@type": {ReverseProxy: true}
		depends_on: {"dns-primary": true}
	}
	"git-server": {
		name: "git-server"
		"@type": {SourceControlManagement: true}
		depends_on: {"dns-primary": true, "reverse-proxy": true}
	}
	"monitoring": {
		name: "monitoring"
		"@type": {MonitoringServer: true}
		depends_on: {"dns-primary": true}
	}
}

// Build the graph
infra: patterns.#InfraGraph & {Input: _resources}

// Queries
dns_impact: patterns.#ImpactQuery & {Graph: infra, Target: "dns-primary"}
criticality: patterns.#CriticalityRank & {Graph: infra}
by_type: patterns.#GroupByType & {Graph: infra}
metrics: patterns.#GraphMetrics & {Graph: infra}

// Output
output: {
	topology: infra.topology
	roots:    infra.roots
	leaves:   infra.leaves

	"impact_if_dns_fails": {
		affected: dns_impact.affected
		count:    dns_impact.affected_count
	}

	criticality_ranking: criticality.ranked
	resources_by_type:   by_type.groups

	summary: {
		total_resources: metrics.total_resources
		max_depth:       metrics.max_depth
		total_edges:     metrics.total_edges
	}
}

// Mermaid diagram
_mermaidNodes: [
	for rname, r in _resources {
		let types = strings.Join([for t, _ in r["@type"] {t}], ", ")
		"    \(rname)[\"\(rname)<br/><small>\(types)</small>\"]"
	},
]
_edgesNested: [
	for rname, r in _resources if r.depends_on != _|_ {
		[for dep, _ in r.depends_on {"    \(dep) --> \(rname)"}]
	},
]
_edges: list.FlattenN(_edgesNested, 1)

mermaid: "graph TD\n" + strings.Join(_mermaidNodes, "\n") + "\n\n" + strings.Join(_edges, "\n")

// Visualization data for quicue.ca graph explorer
// Export: cue export ./examples/graph-patterns/ -e vizData --out json
_viz: patterns.#VizData & {Graph: infra, Resources: _resources}
vizData: _viz.data
