// Validated discoveries from building quicue.ca
package kg

import "quicue.ca/kg/core@v0"

i001: core.#Insight & {
	id:        "INSIGHT-001"
	statement: "CUE transitive closure performance is topology-sensitive, not node-count-limited"
	evidence: [
		"NHCF scenario with 25 nodes timed out — but due to wide fan-in, not node count",
		"Reducing to 18 nodes (merging procurement, simplifying audit deps) brought eval under 4 seconds by reducing fan-in",
		"CJLQ greener-homes validates 17 nodes/25 edges without issue",
		"Wide fan-in (many deps per node) is the actual bottleneck, not graph size",
	]
	method:     "experiment"
	confidence: "high"
	discovered: "2025-12-01"
	implication: "Minimize edge density and fan-in for large graphs; Python precompute is a fallback for high-fan-in topologies, not a hard ceiling"
	action_items: [
		"Provide hybrid-demo example with Python precompute fallback for high-fan-in graphs",
	]
	related: {"ADR-001": true}
}

i002: core.#Insight & {
	id:        "INSIGHT-002"
	statement: "CUE exports ALL public (capitalized) fields, causing unexpected JSON bloat"
	evidence: [
		"#VizExport definition with public Graph field exported the entire input graph (75KB vs 17KB expected)",
		"4x JSON size increase traced to public field leak in export-facing definitions",
	]
	method:     "observation"
	confidence: "high"
	discovered: "2025-11-15"
	implication: "Export-facing definitions must use hidden fields (_prefix) for intermediate data; only expose the final projection as public"
	action_items: [
		"Use hidden _viz wrapper pattern for all export definitions",
		"Never expose large input structs as public fields in export-facing definitions",
	]
	related: {"ADR-002": true}
}

i003: core.#Insight & {
	id:        "INSIGHT-003"
	statement: "CUE packages are directory-scoped, not hierarchically scoped"
	evidence: [
		".kg/ subdirectories create separate package instances even with same package name",
		"Cannot cross-reference between .kg/project.cue and .kg/decisions/001.cue",
		"./... recursive pattern does not traverse into .kg/ for validation",
	]
	method:     "experiment"
	confidence: "high"
	discovered: "2026-02-15"
	implication: ".kg/ directories must be flat — all .cue files at root level with one package declaration"
	related: {"ADR-001": true}
}
