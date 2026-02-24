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

i011: core.#Insight & {
	id:        "INSIGHT-011"
	statement: "W3C vocabulary alignment is mostly projection work — CUE's typed data already has the structure, it just needs the right IRIs"
	evidence: [
		"depends_on mapped from quicue:dependsOn to dcterms:requires — zero code change, just one IRI swap in context.cue",
		"#ComplianceCheck results already have the structure of sh:ValidationReport — adding the projection was 20 lines",
		"#SmokeTest checks map 1:1 to earl:Assertion — each check is one assertion with an outcome",
		"#CriticalPath scheduling maps to time:Interval — the CUE computation is the same, output gains W3C IRIs",
		"#GapAnalysis missing resources are exactly sh:ValidationResult entries — the semantics were already SHACL-shaped",
		"schema:actionStatus has exactly the 4 states needed for task lifecycle (PotentialAction, Active, Completed, Failed)",
	]
	method:     "cross_reference"
	confidence: "high"
	discovered: "2026-02-19"
	implication: "When your data model is already typed and validated by CUE, W3C compliance is a thin projection layer — not a rewrite. The investment is in choosing the right vocabulary mapping, not in restructuring data. CUE's struct-as-set and typed fields map naturally to RDF predicates."
	action_items: [
		"Add @context entries for time:, earl:, skos:, schema: to vocab/context.cue",
		"Document W3C vocabulary mapping table in docs/patterns.md",
		"Consider publishing a formal OWL ontology for quicue: namespace",
	]
	related: {"INSIGHT-006": true, "INSIGHT-007": true}
}

i012: core.#Insight & {
	id:        "INSIGHT-012"
	statement: "ASCII-safe identifier constraints catch unicode injection at compile time with zero runtime cost"
	evidence: [
		"Cyrillic 'а' (U+0430) vs Latin 'a' (U+0061) creates distinct CUE keys that look identical — unification silently fails to match",
		"Zero-width space (U+200B) embedded in 'dns​server' creates a valid CUE string key that never matches 'dnsserver' in depends_on",
		"RTL override (U+202E) in type names can disguise what a resource claims to be",
		"#SafeID regex =~'^[a-zA-Z][a-zA-Z0-9_.-]*$' rejects all non-ASCII at cue vet time",
		"Applied to vocab, patterns, viz-contract, actions, and boot across both apercue.ca and quicue.ca",
	]
	method:     "cross_reference"
	confidence: "high"
	discovered: "2026-02-19"
	implication: "CUE's type system can enforce input validation at compile time. Unicode safety is not a runtime concern — it's a schema constraint. The regex costs nothing at runtime because there IS no runtime. This pattern generalizes: any string field that participates in unification or struct key lookup should be constrained to a safe alphabet."
	action_items: [
		"Add CI test fixtures with intentional unicode violations to verify rejection",
		"Consider extending SafeID to provider template parameter names",
	]
	related: {"ADR-014": true, "INSIGHT-005": true}
}

i013: core.#Insight & {
	id:        "INSIGHT-013"
	statement: "Export-facing CUE definitions systematically lack W3C @context, @id, and dct:conformsTo — compliance is spotty not architectural"
	evidence: [
		"Full audit (2026-02-20) found 7 files producing structured output without proper JSON-LD framing: graph.cue (#ExportGraph), lifecycle.cue (#BootstrapPlan, #DriftReport), wiki.cue (#WikiProjection), openapi.cue (#OpenAPISpec), toon.cue (#TOONExport), visualization.cue (#GraphvizDiagram), boot/credentials.cue (#CredentialBundle)",
		"Files that DO have proper W3C alignment — dcat.cue, shacl.cue, ldes.cue, validation.cue (shacl_report), lifecycle.cue (earl_report for smoke tests) — were added intentionally, not systematically",
		"charter.cue has SHACL report but not EARL — gap analysis IS evaluation reporting (earl:Assertion) but only uses sh:ValidationReport",
		"analysis.cue #CriticalPath has time_report with OWL-Time but uses raw integers, not xsd:dateTime — technically invalid",
		"vocab/context.cue declares schema:, time:, earl: prefixes but these are unused in most output definitions",
	]
	method:     "cross_reference"
	confidence: "high"
	discovered: "2026-02-20"
	implication: "W3C compliance must be architectural, not ad-hoc. Every export-facing definition (#*Export, #*Report, #*Projection, #*Catalog) should include @context, @type, and dct:conformsTo as standard fields. Hookify rules now enforce this for new code; existing gaps need backfill."
	action_items: [
		"Add @context + dct:conformsTo to #ExportGraph, #OpenAPISpec, #WikiProjection",
		"Add PROV-O projections to #BootstrapPlan, #DriftReport, #CredentialBundle",
		"Add EARL projection to charter #GapAnalysis alongside existing SHACL report",
		"Fix #CriticalPath time_report to use xsd:dateTime instead of raw integers",
		"Add schema:DataVisualization typing to #GraphvizDiagram and #MermaidDiagram",
	]
	related: {"INSIGHT-011": true, "INSIGHT-006": true}
}

i014: core.#Insight & {
	id:        "INSIGHT-014"
	statement: "Cloudflare API tokens are stored in ~/.ssh/ alongside SSH keys — the working token is cf-tk.token, not ~/.cf_env"
	evidence: [
		"~/.cf_env exports CF_API_KEY=3YT66X... — wrangler rejects it with 'Invalid access token [code: 9109]'",
		"~/.ssh/cf-tk.token contains yKFDS... — wrangler pages deploy succeeds with this as CLOUDFLARE_API_TOKEN",
		"Memory file infrastructure.md had them swapped (cf-tk.token listed as broken, cf_env as working) — corrected 2026-02-20",
		"Wrangler requires CLOUDFLARE_API_TOKEN env var name, not CF_API_KEY — naming mismatch was the root cause of confusion",
	]
	method:     "observation"
	confidence: "high"
	discovered: "2026-02-20"
	implication: "Token management needs a single source of truth. The ~/.ssh/ directory is an unconventional but reasonable location (already permissioned for secrets). The CF_API_KEY vs CLOUDFLARE_API_TOKEN naming mismatch caused repeated deploy failures across sessions."
	action_items: [
		"Standardize on CLOUDFLARE_API_TOKEN=$(cat ~/.ssh/cf-tk.token) in all deploy scripts",
		"Remove or clearly mark ~/.cf_env as deprecated",
	]
	related: {"INSIGHT-004": true}
}

i010: core.#Insight & {
	id:        "INSIGHT-010"
	statement: "Three latent bugs in patterns/ went undetected because CUE's lax evaluation hides struct iteration errors and name collisions"
	evidence: [
		"#BootstrapPlan used len(depends_on) as depth proxy — a resource with 3 peers at depth 0 got 'depth 3'. No test caught this because the only BootstrapPlan consumer (lifecycle.cue) was never exercised against a non-trivial topology",
		"#ValidateGraph was defined in BOTH graph.cue and type-contracts.cue in the same package — CUE silently unified them, creating a chimera definition requiring fields from both",
		"#DependencyValidation iterated depends_on as an array ('for dep in') but the codebase uses struct-as-set ({[string]: true}) — the iteration silently produced wrong results",
	]
	method:     "observation"
	confidence: "high"
	discovered: "2026-02-19"
	implication: "CUE's lazy evaluation and open-struct defaults mean bugs can hide in definitions that are syntactically valid but semantically wrong. Critical patterns need exercising examples, not just cue vet."
	action_items: [
		"Add exercising tests for #BootstrapPlan, #ComplianceCheck, #CycleDetector, #ConnectedComponents, #Subgraph, #GraphDiff, #CriticalPath against the 3-layer and datacenter examples",
		"CI should run cue eval (not just cue vet) on patterns that compute outputs",
		"Audit remaining patterns for struct-as-set vs array iteration mismatches",
	]
	related: {"INSIGHT-003": true}
}
