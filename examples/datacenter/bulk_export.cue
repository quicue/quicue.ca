// Bulk export — single CUE evaluation for all outputs.
//
// Instead of 10 separate `cue export -e X` calls (each re-evaluating the
// full 30-resource × 28-provider binding from scratch), this bundles ALL
// exports into one struct. One CUE evaluation, Python splits the result.
//
// Usage:
//   cue export ./examples/datacenter/ -e _bulk --out json \
//     -t timestamp="$(date -u +'%Y-%m-%d %H:%M UTC')" > /tmp/bulk.json
//   python3 operator/split_bulk.py /tmp/bulk.json operator/public/

package main

import "strings"

// Injected at export time: cue export -t timestamp="2026-02-01 12:00 UTC"
_timestamp: *"" | string @tag(timestamp)

_bulk: {
	plan:            execution.plan
	cluster_summary: execution.cluster.summary
	bound_commands:  output.commands
	notebook:        execution.notebook
	ops_tasks:       execution.ops
	graph_jsonld:       jsonld
	hydra:              datacenter_hydra
	hydra_entrypoint:   datacenter_hydra_entrypoint
	hydra_collection:   datacenter_hydra_collection
	skos_types:         datacenter_skos_types
	interaction:        interaction_summary
	wiki:            execution.wiki
	rundeck:         execution.rundeck
	script:          execution.script
	index_html:      _index_page
	stats:           _index_stats
}

// ═══════════════════════════════════════════════════════════════════════════════
// Build stats — computed from all projections at CUE evaluation time.
// Written to .build-stats.json by split_bulk.py.
// ═══════════════════════════════════════════════════════════════════════════════

_index_stats: {
	layers:          execution.plan.summary.total_layers
	resources:       execution.plan.summary.total_resources
	gates:           execution.plan.summary.gates_required
	providers:       execution.cluster.summary.total_providers
	resolved:        execution.cluster.summary.resolved_commands
	rc_count:        execution.cluster.summary.resolved_commands
	nb_cells:        len(execution.notebook.cells)
	rd_jobs:         len(execution.rundeck)
	wiki_files:      execution.wiki.stats.total_files
	script_lines:    strings.Count(execution.script, "\n") + 1
	ops_tasks:       execution.ops.stats.total_tasks
	ops_destructive: execution.ops.stats.destructive_count
	jsonld_nodes:    len(jsonld["@graph"])
}

// ═══════════════════════════════════════════════════════════════════════════════
// Index page — generated entirely by CUE, same pattern as execution.script.
// ═══════════════════════════════════════════════════════════════════════════════

_layer_cards_html: strings.Join([
	for l in execution.plan.layers {
		let _res = strings.Join(l.resources, ", ")
		let _count = len(l.resources)
		"    <div class=\"layer-card\"><h3>Layer \(l.layer)</h3><p class=\"gate\">Gate: \(l.gate)</p><p>\(_count) resources</p><p class=\"res-list\">\(_res)</p></div>"
	},
], "\n")

_s: _index_stats

_index_page: strings.Join([
	"""
	<!DOCTYPE html>
	<html lang="en">
	<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>Operator — Execution Surface</title>
	<style>
	@import url('https://fonts.googleapis.com/css2?family=Atkinson+Hyperlegible+Next:ital,wght@0,400;0,700;1,400&family=Atkinson+Hyperlegible+Mono:wght@400;700&display=swap');
	:root {
	  --bg: #0d1117; --surface: #161b22; --elevated: #21262d; --border: #30363d;
	  --text: #e6edf3; --text-sec: #8b949e; --text-dim: #6e7681;
	  --accent: #58a6ff; --green: #3fb950; --red: #f85149; --warning: #d29922; --purple: #a371f7;
	  --font-ui: 'Atkinson Hyperlegible Next', system-ui, sans-serif;
	  --font-mono: 'Atkinson Hyperlegible Mono', monospace;
	  --radius: 8px;
	}
	*, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }
	body { font-family: var(--font-ui); background: var(--bg); color: var(--text); line-height: 1.6; max-width: 1200px; margin: 0 auto; padding: 2rem 1.5rem; }
	a { color: var(--accent); text-decoration: none; }
	a:hover { text-decoration: underline; }
	header { text-align: center; padding: 3rem 0 2rem; }
	header h1 { font-size: 2.5rem; font-weight: 700; letter-spacing: -0.02em; }
	.tagline { color: var(--text-sec); font-size: 1.15rem; margin-top: 0.5rem; }
	.stats { display: flex; justify-content: center; gap: 3rem; margin-top: 2rem; }
	.stat { display: flex; flex-direction: column; align-items: center; }
	.stat-num { font-size: 2rem; font-weight: 700; color: var(--accent); font-family: var(--font-mono); }
	.stat-label { font-size: 0.8rem; color: var(--text-sec); text-transform: uppercase; letter-spacing: 0.06em; }
	h2 { font-size: 1.2rem; margin: 2rem 0 1rem; color: var(--text-sec); border-bottom: 1px solid var(--border); padding-bottom: 0.5rem; }
	.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1rem; }
	.layer-card, .export-card {
	  background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 1.2rem;
	}
	.layer-card h3 { font-size: 1.05rem; margin-bottom: 0.3rem; }
	.layer-card .gate { font-size: 0.85rem; color: var(--warning); font-family: var(--font-mono); }
	.layer-card .res-list { font-size: 0.8rem; color: var(--text-sec); font-family: var(--font-mono); word-break: break-word; }
	.export-card { display: flex; flex-direction: column; }
	.export-card h3 { font-size: 1.05rem; }
	.export-card p { color: var(--text-sec); font-size: 0.9rem; margin: 0.5rem 0; flex: 1; }
	.export-card .dl { display: inline-block; margin-top: 0.5rem; padding: 0.3rem 0.8rem; background: var(--elevated); border: 1px solid var(--border); border-radius: var(--radius); font-size: 0.85rem; font-family: var(--font-mono); }
	.export-card .dl:hover { border-color: var(--accent); text-decoration: none; }
	.nav-links { display: flex; gap: 1rem; justify-content: center; margin-top: 1rem; }
	footer { margin-top: 4rem; padding-top: 1rem; border-top: 1px solid var(--border); color: var(--text-sec); font-size: 0.85rem; text-align: center; }
	@media (max-width: 600px) { .stats { gap: 1.5rem; flex-wrap: wrap; } .grid { grid-template-columns: 1fr; } }
	</style>
	</head>
	<body>
	<header>
	  <h1>Operator</h1>
	  <p class="tagline">Execution surface for infrastructure deployment plans</p>
	  <div class="nav-links">
	    <a href="graph.html">Graph</a>
	    <a href="planner.html">Planner</a>
	    <a href="browse.html">Browse</a>
	    <a href="explore.html">Explore</a>
	    <a href="https://api.quicue.ca/docs/">API Docs</a>
	  </div>
	  <div class="stats">
	""",
	"    <div class=\"stat\"><span class=\"stat-num\">\(_s.layers)</span><span class=\"stat-label\">Layers</span></div>",
	"    <div class=\"stat\"><span class=\"stat-num\">\(_s.resources)</span><span class=\"stat-label\">Resources</span></div>",
	"    <div class=\"stat\"><span class=\"stat-num\">\(_s.gates)</span><span class=\"stat-label\">Gates</span></div>",
	"    <div class=\"stat\"><span class=\"stat-num\">\(_s.providers)</span><span class=\"stat-label\">Providers</span></div>",
	"    <div class=\"stat\"><span class=\"stat-num\">\(_s.resolved)</span><span class=\"stat-label\">Resolved Commands</span></div>",
	"""
	  </div>
	</header>
	<main>
	<section>
	  <h2>Interactive Views</h2>
	  <div class="grid">
	    <div class="export-card">
	      <h3>Dependency Graph</h3>
	      <p>Interactive D3 visualization. Click nodes to explore dependencies, types, and bound commands.</p>
	      <a href="graph.html" class="dl">Open graph</a>
	    </div>
	    <div class="export-card">
	      <h3>Execution Planner</h3>
	      <p>Select resources, see computed deploy order. Cascading dependency selection.</p>
	      <a href="planner.html" class="dl">Open planner</a>
	    </div>
	    <div class="export-card">
	      <h3>Resource Browser</h3>
	""",
	"      <p>Search and filter all \(_s.resources) resources and \(_s.rc_count) resolved commands. Copy commands to clipboard.</p>",
	"""
	      <a href="browse.html" class="dl">Open browser</a>
	    </div>
	    <div class="export-card">
	      <h3>Hydra Explorer</h3>
	      <p>Navigate the JSON-LD resource graph. Click dependencies to traverse, view operations per resource class.</p>
	      <a href="explore.html" class="dl">Open explorer</a>
	    </div>
	  </div>
	</section>
	<section>
	  <h2>Deployment Layers</h2>
	  <div class="grid">
	""",
	_layer_cards_html,
	"""
	  </div>
	</section>
	<section>
	  <h2>Exports</h2>
	  <div class="grid">
	    <div class="export-card">
	      <h3>Jupyter Notebook</h3>
	""",
	"      <p>\(_s.nb_cells) cells — executable deployment runbook with gate checkpoints per layer.</p>",
	"""
	      <a href="notebook.ipynb" class="dl" download>notebook.ipynb</a>
	    </div>
	    <div class="export-card">
	      <h3>Rundeck Jobs</h3>
	""",
	"      <p>\(_s.rd_jobs) jobs grouped by layer/provider — import into Rundeck for scheduled execution.</p>",
	"""
	      <a href="rundeck-jobs.yaml" class="dl" download>rundeck-jobs.yaml</a>
	    </div>
	    <div class="export-card">
	      <h3>Wiki (MkDocs)</h3>
	""",
	"      <p>\(_s.wiki_files) markdown pages — per-layer, per-resource auto-documentation with resolved commands.</p>",
	"""
	      <a href="wiki/docs/index.md" class="dl">Browse wiki/</a>
	    </div>
	    <div class="export-card">
	      <h3>Deploy Script</h3>
	""",
	"      <p>\(_s.script_lines) lines — self-contained bash with per-layer parallelism and gate prompts.</p>",
	"""
	      <a href="deploy.sh" class="dl" download>deploy.sh</a>
	    </div>
	    <div class="export-card">
	      <h3>Ops Tasks</h3>
	""",
	"      <p>\(_s.ops_tasks) tasks (\(_s.ops_destructive) destructive) — structured data for cue cmd and cockpit views.</p>",
	"""
	      <a href="ops.json" class="dl" download>ops.json</a>
	    </div>
	    <div class="export-card">
	      <h3>Execution Plan JSON</h3>
	      <p>Raw plan data — layers, resources, gates. Machine-readable for CI pipelines.</p>
	      <a href="plan.json" class="dl" download>plan.json</a>
	    </div>
	  </div>
	</section>
	<section>
	  <h2>Semantic Web</h2>
	  <div class="grid">
	    <div class="export-card">
	      <h3>JSON-LD Graph</h3>
	""",
	"      <p>\(_s.jsonld_nodes) resources as W3C JSON-LD with typed IRIs, dependencies, and provider bindings.</p>",
	"""
	      <a href="graph.jsonld" class="dl" download>graph.jsonld</a>
	    </div>
	    <div class="export-card">
	      <h3>Hydra API Documentation</h3>
	      <p>W3C Hydra core vocabulary — describes available operations, supported classes, and entrypoints.</p>
	      <a href="hydra.jsonld" class="dl" download>hydra.jsonld</a>
	    </div>
	    <div class="export-card">
	      <h3>Interaction Contexts</h3>
	      <p>Role-scoped views (ops, dev, readonly) — what each operator role can see and do.</p>
	      <a href="interaction.json" class="dl" download>interaction.json</a>
	    </div>
	  </div>
	</section>
	</main>
	<footer>
	  <p>Generated by <code>operator/build.sh</code> from <code>#ExecutionPlan</code></p>
	""",
	"  <p>\(_timestamp)</p>",
	"""
	</footer>
	</body>
	</html>
	""",
], "\n")
