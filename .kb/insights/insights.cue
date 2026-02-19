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

i006: core.#Insight & {
	id:        "INSIGHT-006"
	statement: "Everything is a projection of the same typed dependency graph — 72+ projections exist"
	evidence: [
		"Terraform state, Ansible playbooks, Rundeck YAML, Jupyter notebooks, MkDocs wiki, bash deploy scripts, HTTP requests, OpenAPI specs, Justfile recipes, JSON-LD, Graphviz DOT, Mermaid, TOON, N-Triples, DCAT catalogue — all generated from the same #InfraGraph",
		"projections.cue alone produces 6 output formats; visualization.cue adds 2 more; each template/ provider adds resolved commands",
		"29 providers × multiple actions × datacenter resources = 654 resolved commands from one graph",
		"CMHC retrofit, maison-613, grdn all consume the same patterns and produce domain-specific projections",
		"The quicue.ca site renders 7 D3 visualizations from one VizData payload",
	]
	method:     "cross_reference"
	confidence: "high"
	discovered: "2026-02-18"
	implication: "The graph is the single source of truth. Every artifact — config files, deployment scripts, documentation, visualizations, linked data exports — is a derived projection. Adding a new projection means writing one more CUE definition, not building a new pipeline."
	action_items: [
		"Document the full projection inventory in patterns/README.md",
		"Track projection count as a metric in showcase charter",
	]
	related: {"INSIGHT-002": true}
}

i008: core.#Insight & {
	id:        "INSIGHT-008"
	statement: "When CUE comprehensions pre-compute all possible answers, the API is just a file server — the 'universe cheat sheet' pattern"
	evidence: [
		"build-static-api.sh runs cue export once, then splits the output into 727 static JSON files",
		"654 mock action responses, Swagger UI, OpenAPI spec, graph.jsonld, hydra entrypoint — all pre-computed",
		"Replacing FastAPI with CF Pages static hosting produces identical API responses with zero server runtime",
		"The same pattern that makes SPARQL unnecessary (INSIGHT-007) makes a web server unnecessary for read-only APIs",
	]
	method:     "experiment"
	confidence: "high"
	discovered: "2026-02-18"
	implication: "If your domain model is a closed world and CUE comprehensions compute all queries at eval time, the entire API surface is known at build time. A static file server (CDN) is the optimal runtime — zero latency, zero failure modes, global distribution."
	action_items: [
		"Document the universe cheat sheet pattern in patterns/",
		"Consider extending to other read-only API surfaces (catalogue, kg spec)",
	]
	related: {"INSIGHT-007": true, "ADR-012": true}
}

i007: core.#Insight & {
	id:        "INSIGHT-007"
	statement: "CUE unification obviates SPARQL — precomputed comprehensions ARE the query layer"
	evidence: [
		"quicue.ca implements 8 query patterns: ImpactQuery, DependencyChain, PathFinder, ImmediateDependents, CriticalityRank, GroupByType, topology, validation",
		"Each pattern is a CUE definition that takes Graph: #InfraGraph and produces computed results at eval time",
		"A SPARQL query like 'SELECT ?x WHERE { ?x dependsOn ?y }' is equivalent to a CUE comprehension: {for name, r in resources if r.depends_on[y] != _|_ {(name): true}}",
		"No triplestore runtime needed — the entire query universe is precomputed by cue export",
		"N-Triples export exists for W3C interop, not for querying",
	]
	method:     "experiment"
	confidence: "high"
	discovered: "2026-02-18"
	implication: "SPARQL is unnecessary for the primary use case. CUE comprehensions precompute all graph queries at evaluation time. A triplestore adds value only for cross-dataset federation with external linked data sources — not for querying your own graph."
	action_items: [
		"Reclassify Oxigraph from 'required' to 'optional interop' in showcase plan",
		"Document CUE-vs-SPARQL equivalence table for the 8 query patterns",
	]
	related: {"INSIGHT-006": true}
}

i009: core.#Insight & {
	id:        "INSIGHT-009"
	statement: "Airgapped deployment has 8 reproducible traps — each is a gap between package manager assumptions and offline reality"
	evidence: [
		"E2E deployment on fresh Ubuntu 24.04 VM (VM 201 on clover, 172.20.1.32) hit all 8 traps",
		"ensurepip stripped from cloud images — python3 -m ensurepip returns 'No module named ensurepip'",
		"typing_extensions installed by debian apt — pip cannot uninstall (no RECORD file) without --ignore-installed",
		"raptor2-utils depends on libyajl2 — not visible from apt-cache depends without --recurse",
		"CUE module resolution via cue.mod/pkg/ symlinks not preserved in git clone — must recreate post-clone",
		"Docker bind-mount of newer app.py over older image causes ImportError when image scripts are stale",
		"Caddy tls internal generates cert for SITE_ADDRESS hostname — curl to localhost fails TLS verification",
		"CUE export on datacenter example OOM-killed on 8GB VM — must generate specs on build host",
		"grep with pipefail returns exit 1 on no match, killing bash scripts — use { grep || true; }",
	]
	method:     "experiment"
	confidence: "high"
	discovered: "2026-02-19"
	implication: "Every package manager assumes internet access. Airgapped deployment is not 'deployment minus internet' — it's a different environment with its own failure modes. The #Gotcha registry in operator/airgap-bundle.cue captures these systematically so install scripts can check proactively rather than fail reactively."
	action_items: [
		"Maintain #Gotcha registry in operator/airgap-bundle.cue as new traps are discovered",
		"install-airgapped.sh should check for each gotcha before attempting the corresponding install step",
		"CI should verify bundle completeness: all transitive deps present, all Docker base images included",
	]
	related: {"ADR-013": true}
}
