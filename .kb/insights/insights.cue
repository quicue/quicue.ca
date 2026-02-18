// Validated discoveries from building quicue.ca
package insights

import "quicue.ca/kg/core@v0"

i001: core.#Insight & {
	id:        "INSIGHT-001"
	statement: "CUE transitive closure performance is topology-sensitive, not node-count-limited"
	evidence: [
		"NHCF scenario with 25 nodes timed out — but due to wide fan-in, not node count",
		"Reducing to 18 nodes (merging procurement, simplifying audit deps) brought eval under 4 seconds by reducing fan-in",
		"cmhc-retrofit greener-homes validates 17 nodes/25 edges without issue",
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
	statement: "CUE packages are directory-scoped — multi-graph knowledge bases leverage this for independent validation"
	evidence: [
		".kb/ subdirectories create separate package instances — each graph validates independently",
		"Directory name IS the routing constraint: agents put decisions in decisions/, patterns in patterns/",
		"Each graph maps to a W3C vocabulary via #KnowledgeBase manifest",
	]
	method:     "experiment"
	confidence: "high"
	discovered: "2026-02-15"
	implication: "Knowledge bases use typed subdirectories: each graph is an independent CUE package with its own cue.mod/. The root .kb/ holds the manifest (#KnowledgeBase) declaring the topology."
	related: {"ADR-001": true}
}

i004: core.#Insight & {
	id:        "INSIGHT-004"
	statement: "Production data leaks through generated artifacts, not just source code"
	evidence: [
		"cat.quicue.ca .bound_commands.json and openapi.json contained 98 real 172.20.x.x IPs each — generated from production, not example data",
		"imp.quicue.ca had real IPs in exec.js (placeholder text), imperator.json (349KB data file), and 40+ wiki HTML files (MkDocs build)",
		"Deploying safe JSON data files missed pre-existing files with different naming conventions (.bound_commands.json vs bound-commands.json)",
		"GitHub repo history contained real IP maps from old homelab.cue files — required force-push to clean",
	]
	method:     "observation"
	confidence: "high"
	discovered: "2026-02-18"
	implication: "When replacing data on public surfaces, grep -rl for real IPs across the ENTIRE web root as a final verification step. Never assume safe data files replace all contaminated ones — old files with different names persist."
	action_items: [
		"CI validates no 172.x.x.x IPs in generated files (ADR-006)",
		"Deploy scripts should delete old files before copying new ones, not overlay",
		"git filter-repo or orphan branch force-push to clean history when real data leaked into commits",
	]
	related: {"ADR-006": true}
}

i005: core.#Insight & {
	id:        "INSIGHT-005"
	statement: "cue vet does not fully evaluate hidden fields — test assertions on hidden values give false confidence"
	evidence: [
		"charter_test.cue asserts _incomplete_gaps: count_satisfied: false on a hidden field",
		"charter.cue had count_satisfied: true (hard constraint) conflicting with computed false, but cue vet passed because the field was hidden",
		"The bug was only exposed when examples/showcase/ used a public gaps field, triggering full evaluation",
	]
	method:     "experiment"
	confidence: "high"
	discovered: "2026-02-18"
	implication: "CUE test assertions on hidden (_prefixed) fields are not validated by cue vet. For critical invariants, use public fields or run cue eval -e to force evaluation."
	action_items: [
		"Consider adding public assertion fields to charter_test.cue for critical properties",
		"Use cue eval -e for targeted validation of hidden fields in CI",
	]
	related: {"ADR-005": true, "ADR-007": true}
}
