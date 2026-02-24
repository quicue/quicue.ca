// Projections — unified into #ExecutionPlan.
//
// Each projection is a pure derivation of plan + cluster + resources.
// CUE defers comprehension evaluation until concrete values are unified in.
// Any value layer that uses #ExecutionPlan gets all projections for free:
//
//   cue export ./examples/datacenter/ -e execution.notebook --out json
//   cue export ./examples/datacenter/ -e execution.rundeck --out yaml
//   cue export ./examples/datacenter/ -e execution.wiki --out json

package patterns

import (
	"strings"
	"list"
)

#ExecutionPlan: {
	// Re-declare for per-file reference resolution.
	// CUE unifies these with the concrete definitions in deploy.cue.
	resources: _
	cluster:   _
	plan:      _

	// ═══════════════════════════════════════════════════════════════════
	// Jupyter Notebook (.ipynb)
	// ═══════════════════════════════════════════════════════════════════

	notebook: {
		nbformat:       4
		nbformat_minor: 5
		metadata: {
			kernelspec: {
				display_name: "Python 3"
				language:     "python"
				name:         "python3"
			}
			language_info: {
				name:    "python"
				version: "3.12.0"
			}
		}
		cells: list.Concat([[_nbTitle], list.FlattenN([for s in _nbSections {s.cells}], 1)])
	}

	_nbTitle: {
		cell_type: "markdown"
		source: [
			"# Deployment Runbook\n",
			"\n",
			"**Generated from quicue.ca `#ExecutionPlan`**\n",
			"\n",
			"| Metric | Value |\n",
			"|--------|-------|\n",
			"| Layers | \(plan.summary.total_layers) |\n",
			"| Resources | \(plan.summary.total_resources) |\n",
			"| Gates | \(plan.summary.gates_required) |\n",
			"| Resolved commands | \(cluster.summary.resolved_commands) |\n",
			"| Providers | \(cluster.summary.total_providers) |\n",
		]
		metadata: {}
	}

	_nbSections: [
		for l in plan.layers {
			_header: {
				cell_type: "markdown"
				source: [
					"## Layer \(l.layer)\n",
					"\n",
					"**Resources:** \(strings.Join(l.resources, ", "))\n",
					"\n",
					"**Gate:** \(l.gate)\n",
				]
				metadata: {}
			}

			_resourceCells: [
				for rname in l.resources
				let _bound = cluster.bound[rname]
				let _cmdLines = [
					for pname, pactions in _bound.actions
					for aname, a in pactions
					if a.command != _|_ {
						"# \(pname)/\(aname)\n! \(a.command)"
					},
				]
				if len(_cmdLines) > 0 {{
					cell_type: "code"
					source: [
						"# === \(rname) ===\n",
						strings.Join(_cmdLines, "\n\n") + "\n",
					]
					metadata: {}
					execution_count: null
					outputs: []
				}},
			]

			_gateCell: {
				cell_type: "code"
				source: [
					"# Gate check — verify layer \(l.layer) before proceeding\n",
					"print(\"Layer \(l.layer) complete: \(strings.Join(l.resources, ", "))\")\n",
					"# input(\"Press Enter to proceed to layer \(l.layer+1)...\")\n",
				]
				metadata: {}
				execution_count: null
				outputs: []
			}

			cells: list.Concat([[_header], _resourceCells, [_gateCell]])
		},
	]

	// ═══════════════════════════════════════════════════════════════════
	// Rundeck YAML Jobs
	// ═══════════════════════════════════════════════════════════════════

	rundeck: [
		for l in plan.layers
		for rname in l.resources
		let _bound = cluster.bound[rname]
		for pname, pactions in _bound.actions
		for aname, a in pactions
		if a.command != _|_ {
			let _safeName = strings.Replace(strings.Replace("\(rname)-\(pname)-\(aname)", ".", "_", -1), " ", "_", -1)
			name:        "\(rname) / \(pname) / \(aname)"
			description: a.description
			group:       "layer-\(l.layer)/\(pname)"
			loglevel:    "INFO"
			sequence: {
				keepgoing: false
				commands: [{
					exec: a.command
				}]
			}
			if a.category != _|_ {
				tags: a.category
			}
			uuid:     _safeName
			nodeStep: true
		},
	]

	// ═══════════════════════════════════════════════════════════════════
	// HTTP Request Files (.http)
	//
	// Generates .http files per deployment layer for use with Resterm,
	// VS Code REST Client, IntelliJ HTTP Client, or any RFC 9110 tool.
	//
	//   cue export ./examples/datacenter/ -e execution.http --out json
	//   # Writes files: layer-0.http, layer-1.http, ...
	// ═══════════════════════════════════════════════════════════════════

	http: {
		files: {
			for l in plan.layers {
				"layer-\(l.layer).http": strings.Join([
					"# Layer \(l.layer) — Deployment Requests",
					"# Gate: \(l.gate)",
					"# Generated from quicue.ca #ExecutionPlan",
					"",
					for rname in l.resources
					let _bound = cluster.bound[rname]
					for pname, pactions in _bound.actions
					for aname, a in pactions
					if a.command != _|_ {
						strings.Join([
							"### \(rname) / \(pname) / \(aname)",
							"# \(a.description)",
							if a.destructive != _|_ if a.destructive {
								"# @note DESTRUCTIVE — requires X-Confirm-Destructive: yes"
							},
							"POST {{host}}/api/v1/resources/\(rname)/\(pname)/\(aname)",
							"Content-Type: application/json",
							if a.destructive != _|_ if a.destructive {
								"X-Confirm-Destructive: yes"
							},
							"",
							"{}",
							"",
						], "\n")
					},
				], "\n")
			}
		}
		stats: {
			total_files: len(files)
			total_requests: len([
				for l in plan.layers
				for rname in l.resources
				let _bound = cluster.bound[rname]
				for pname, pactions in _bound.actions
				for aname, a in pactions
				if a.command != _|_ {true},
			])
		}
	}

	// ═══════════════════════════════════════════════════════════════════
	// Wiki (MkDocs markdown files)
	// ═══════════════════════════════════════════════════════════════════

	wiki: {
		files: {
			"docs/index.md": _wikiIndex
			"mkdocs.yml":    _wikiConfig
			_wikiLayerPages
			_wikiResourcePages
		}
		stats: {
			total_files:    len(files)
			layer_pages:    plan.summary.total_layers
			resource_pages: plan.summary.total_resources
		}
	}

	_wikiIndex: strings.Join([
		"# Deployment Wiki\n",
		"Auto-generated from `#ExecutionPlan`.\n",
		"## Summary\n",
		"| Metric | Value |",
		"|--------|-------|",
		"| Layers | \(plan.summary.total_layers) |",
		"| Resources | \(plan.summary.total_resources) |",
		"| Gates | \(plan.summary.gates_required) |",
		"| Providers | \(cluster.summary.total_providers) |",
		"| Resolved Commands | \(cluster.summary.resolved_commands) |\n",
		"## Deployment Layers\n",
		for l in plan.layers {
			"- [Layer \(l.layer)](layers/layer-\(l.layer).md) — \(strings.Join(l.resources, ", "))"
		},
		"",
	], "\n")

	_wikiConfig: strings.Join([
		"site_name: Deployment Wiki",
		"site_description: Auto-generated from quicue #ExecutionPlan",
		"theme:",
		"  name: material",
		"  palette:",
		"    scheme: slate",
		"    primary: blue",
		"  features:",
		"    - navigation.sections",
		"    - search.highlight",
		"plugins:",
		"  - search",
		"markdown_extensions:",
		"  - tables",
		"nav:",
		"  - Home: index.md",
		"  - Layers:",
		for l in plan.layers {
			"      - Layer \(l.layer): layers/layer-\(l.layer).md"
		},
		"  - Resources:",
		for l in plan.layers
		for rname in l.resources {
			"      - \(rname): resources/\(rname).md"
		},
		"",
	], "\n")

	_wikiLayerPages: {
		for l in plan.layers {
			"docs/layers/layer-\(l.layer).md": strings.Join([
				"# Layer \(l.layer)\n",
				"**Gate:** \(l.gate)\n",
				"## Resources\n",
				"| Resource | Providers | Actions |",
				"|----------|-----------|---------|",
				for rname in l.resources
				let _b = cluster.bound[rname]
				let _pnames = strings.Join([for pn, _ in _b.actions {pn}], ", ")
				let _acount = len([for pn, pa in _b.actions for _, _ in pa {true}]) {
					"| \(rname) | \(_pnames) | \(_acount) |"
				},
				"",
				for rname in l.resources
				let _b = cluster.bound[rname] {
					strings.Join([
						"### \(rname)\n",
						for pname, pactions in _b.actions
						for aname, a in pactions
						if a.command != _|_ {
							"- **\(pname)/\(aname)**: `\(a.command)`"
						},
						"",
					], "\n")
				},
			], "\n")
		}
	}

	_wikiResourcePages: {
		for rname, r in resources {
			let _b = cluster.bound[rname]
			let _types = strings.Join([for t, _ in r["@type"] {"`\(t)`"}], ", ")
			"docs/resources/\(rname).md": strings.Join([
				"# \(rname)\n",
				"| Field | Value |",
				"|-------|-------|",
				"| Types | \(_types) |",
				if r.ip != _|_ {"| IP | `\(r.ip)` |"},
				if r.hostname != _|_ {"| Hostname | `\(r.hostname)` |"},
				if r.host != _|_ {"| Host | \(r.host) |"},
				if r.depends_on != _|_ {
					let _deps = [for d, _ in r.depends_on {d}]
					"| Dependencies | \(strings.Join(_deps, ", ")) |"
				},
				"",
				if len(_b.actions) > 0 {
					strings.Join([
						"## Resolved Commands\n",
						"| Provider | Action | Category | Command |",
						"|----------|--------|----------|---------|",
						for pname, pactions in _b.actions
						for aname, a in pactions
						if a.command != _|_ {
							"| \(pname) | \(aname) | \(a.category) | `\(a.command)` |"
						},
						"",
					], "\n")
				},
			], "\n")
		}
	}

	// ═══════════════════════════════════════════════════════════════════
	// Bash Deployment Script (.script)
	//
	// Self-contained bash script with per-layer parallelism (background
	// jobs + wait) and interactive gate prompts between layers.
	//
	//   cue export ./examples/datacenter/ -e execution.script --out text
	// ═══════════════════════════════════════════════════════════════════

	script: strings.Join([
		"#!/bin/bash",
		"# Deployment script — generated from quicue.ca #ExecutionPlan",
		"# Layers: \(plan.summary.total_layers) | Resources: \(plan.summary.total_resources)",
		"set -euo pipefail",
		"",
		for l in plan.layers {
			strings.Join([
				"echo \"=== Layer \(l.layer) ===\"",
				for rname in l.resources
				let _bound = cluster.bound[rname]
				for pname, pactions in _bound.actions
				for aname, a in pactions
				if a.command != _|_ {
					"\(a.command) &  # \(rname)/\(pname)/\(aname)"
				},
				"wait",
				if l.layer < len(plan.layers)-1 {
					"read -p \"Gate: \(l.gate). Continue? [y/N] \" confirm"
				},
				if l.layer < len(plan.layers)-1 {
					"[[ \"$confirm\" =~ ^[Yy] ]] || exit 1"
				},
			], "\n")
		},
	], "\n\n")

	// ═══════════════════════════════════════════════════════════════════
	// Ops Task Data (.ops)
	//
	// Structured task list for cue cmd consumption and cockpit views.
	// Each task maps to a resource/provider/action triple with its
	// resolved command, category, and destructive flag.
	//
	//   cue export ./examples/datacenter/ -e execution.ops --out json
	// ═══════════════════════════════════════════════════════════════════

	ops: {
		layers: [
			for l in plan.layers {
				layer: l.layer
				gate:  l.gate
				tasks: [
					for rname in l.resources
					let _bound = cluster.bound[rname]
					for pname, pactions in _bound.actions
					for aname, a in pactions
					if a.command != _|_ {
						// Linked data identity: resource @id + action path
						if _bound["@id"] != _|_ {
							"@id": "\(_bound["@id"])/actions/\(pname)/\(aname)"
						}
						resource: rname
						provider: pname
						action:   aname
						command:  a.command
						// Propagate resource @type for unification-based filtering
						if _bound["@type"] != _|_ {
							"@type": _bound["@type"]
						}
						description: a.description
						category: [if a.category != _|_ {a.category}, "info"][0]
						destructive: [if a.destructive != _|_ {a.destructive}, false][0]
						if a.idempotent != _|_ {
							idempotent: a.idempotent
						}
					},
				]
			},
		]
		stats: {
			total_layers: len(layers)
			total_tasks: len([
				for l in layers
				for _ in l.tasks {1},
			])
			destructive_count: len([
				for l in layers
				for t in l.tasks
				if t.destructive {1},
			])
		}
	}
}
