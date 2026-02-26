// #DocsProjection — generate MkDocs documentation from registry data
//
// Consumes: modules, decisions, patterns, insights, downstream, sites, types
// Produces: files map (path → content), stats, mkdocs nav fragment
//
// Pattern: same as #WikiProjection — pre-compute groupings, string template
// markdown, files: {path: content} + stats.
//
// Prose slots: Each generated page has optional _prose sections for hand-authored
// narrative. Structure is computed from registries; narrative is authored by humans.
// Both coexist in the same page.
//
// Usage:
//   cue export ./wiki/ -e docs --out json > /tmp/docs-bulk.json
//   python3 wiki/split_docs.py /tmp/docs-bulk.json docs/
package wiki

import "strings"

// ════════════════════════════════════════════════════════════════════════
// Input types — minimal shapes needed for page generation
// ════════════════════════════════════════════════════════════════════════

#ModuleEntry: {
	path:        string
	module?:     string
	layer:       string
	description: string
	status:      string
	depends?: [...string]
	schemas?: [...string]
	packages?: [...string]
	count?:      int
	categories?: {[string]: [...string]}
	entries?: [...string]
	optional?: bool
	notes?:    string
}

#DecisionEntry: {
	id:       string
	title:    string
	status:   string
	date:     string
	context:  string
	decision: string
	rationale: string
	consequences: [...string]
}

#KBPatternEntry: {
	name:     string
	category: string
	problem:  string
	solution: string
	context:  string
	example?: string
	used_in: {[string]: true}
	related?: {[string]: true}
}

#InsightEntry: {
	id:        string
	statement: string
	evidence: [...string]
	method:     string
	confidence: string
	discovered: string
	implication: string
	related?: {[string]: true}
}

#DownstreamEntry: {
	"@id":   string
	module:  string
	description: string
	imports: [...string]
	pattern_count: int
	status:        string
	has_kb?:       bool
}

#SiteEntry: {
	url:         string
	description: string
	deploy:      string
	status:      string
}

// ════════════════════════════════════════════════════════════════════════
// Prose slots — hand-authored narrative sections for generated pages
// ════════════════════════════════════════════════════════════════════════

#ProseSlots: {
	index: {
		what_this_is:     *"" | string
		not_just_infra:   *"" | string
		what_it_computes: *"" | string
		contract:         *"" | string
	}
	architecture: {
		four_layer_model:  *"" | string
		resource:          *"" | string
		action:            *"" | string
		type_registry:     *"" | string
		bind_cluster:      *"" | string
		execution_plan:    *"" | string
		deployment_plan:   *"" | string
		projections:       *"" | string
		data_flow:         *"" | string
		extension_modules: *"" | string
	}
	patterns: {
		intro:         *"" | string
		schema_groups: *"" | string
	}
	templates: {
		parameter_binding: *"" | string
		conventions:       *"" | string
	}
	charter: {
		scope_constraints: *"" | string
		live_integrations: *"" | string
	}
	federation: {
		kb_pattern:          *"" | string
		dependency_tracking: *"" | string
		rejected_type:       *"" | string
	}
	// Per-module prose: keyed by module name
	modules: {[string]: string}
}

// ════════════════════════════════════════════════════════════════════════
// #DocsProjection — the projection definition
// ════════════════════════════════════════════════════════════════════════

#DocsProjection: {
	Modules:    {[string]: #ModuleEntry}
	Decisions:  {[string]: #DecisionEntry}
	Patterns:   {[string]: #KBPatternEntry}
	Insights:   {[string]: #InsightEntry}
	Downstream: {[string]: #DownstreamEntry}
	Sites:      {[string]: #SiteEntry}
	Types: {[string]: {description: string, ...}}
	Prose:    #ProseSlots
	DocsPath: string | *"docs"

	// ── Pre-compute: layers ──────────────────────────────────────────
	_layers: {
		for _, mod in Modules {
			"\(mod.layer)": true
		}
	}
	_layer_order: ["definition", "template", "orchestration", "constraint",
		"projection", "reporting", "interaction", "ci", "operations", "value"]

	_by_layer: {
		for layer, _ in _layers {
			"\(layer)": [for name, mod in Modules if mod.layer == layer {name}]
		}
	}

	// ── Pre-compute: pattern categories ──────────────────────────────
	_pattern_categories: {
		for _, pat in Patterns {
			"\(pat.category)": true
		}
	}

	_by_pattern_cat: {
		for cat, _ in _pattern_categories {
			"\(cat)": [for key, pat in Patterns if pat.category == cat {key}]
		}
	}

	// ── Pre-compute: module dep edges for Mermaid ────────────────────
	_mermaid_nodes: strings.Join([
		for name, mod in Modules {
			"    \(name)[\"\(name)<br/><i>\(mod.layer)</i>\"]"
		},
	], "\n")

	_mermaid_edges: strings.Join([
		for name, mod in Modules if mod.depends != _|_ {
			strings.Join([for dep in mod.depends {
				"    \(name) --> \(dep)"
			}], "\n")
		},
	], "\n")

	// ── Pre-compute: slugs ───────────────────────────────────────────
	_dec_slug: {
		for key, dec in Decisions {
			"\(key)": strings.ToLower(dec.id)
		}
	}

	_pat_slug: {
		for key, pat in Patterns {
			"\(key)": strings.Replace(strings.ToLower(pat.name), " ", "-", -1)
		}
	}

	_ins_slug: {
		for key, ins in Insights {
			"\(key)": strings.ToLower(ins.id)
		}
	}

	// ── Pre-compute: cross-reference links ───────────────────────────
	// Build lookup from pattern key → markdown link for "See Also" sections.
	// Index by both full key (p_struct_as_set) and short key (struct_as_set)
	// since related fields use the short form.
	_pat_link: {
		for key, pat in Patterns {
			"\(key)": "[\(pat.name)](\(_pat_slug[key]).md)"
			if strings.HasPrefix(key, "p_") {
				"\(strings.TrimPrefix(key, "p_"))": "[\(pat.name)](\(_pat_slug[key]).md)"
			}
		}
	}

	// ── Pre-compute: template data ───────────────────────────────────
	_templateCount: int | *0
	if Modules["templates"] != _|_ if Modules["templates"].count != _|_ {
		_templateCount: Modules["templates"].count
	}

	_templateCats: {
		if Modules["templates"] != _|_ if Modules["templates"].categories != _|_ {
			Modules["templates"].categories
		}
	}
	_templateCatCount: len(_templateCats)

	// ════════════════════════════════════════════════════════════════════
	// File map
	// ════════════════════════════════════════════════════════════════════

	files: {
		// ── Replaced hand-written pages ──────────────────────────────
		"\(DocsPath)/index.md":        _mkIndex
		"\(DocsPath)/architecture.md": _mkArchitecture
		"\(DocsPath)/patterns.md":     _mkPatterns
		"\(DocsPath)/templates.md":    _mkTemplates
		"\(DocsPath)/charter.md":      _mkCharter
		"\(DocsPath)/federation.md":   _mkFederation

		// ── New: module pages ────────────────────────────────────────
		"\(DocsPath)/modules/index.md": _mkModulesIndex
		for name, _ in Modules {
			"\(DocsPath)/modules/\(name).md": _mkModulePage[name]
		}

		// ── New: decision pages ──────────────────────────────────────
		"\(DocsPath)/decisions/index.md": _mkDecisionsIndex
		for key, _ in Decisions {
			"\(DocsPath)/decisions/\(_dec_slug[key]).md": _mkDecisionPage[key]
		}

		// ── New: KB pattern pages ────────────────────────────────────
		"\(DocsPath)/patterns-kb/index.md": _mkPatternsKBIndex
		for key, _ in Patterns {
			"\(DocsPath)/patterns-kb/\(_pat_slug[key]).md": _mkPatternKBPage[key]
		}

		// ── New: insights index ──────────────────────────────────────
		"\(DocsPath)/insights/index.md": _mkInsightsIndex

		// ── New: type registry ───────────────────────────────────────
		"\(DocsPath)/types/index.md": _mkTypesIndex

		// ── New: example output ──────────────────────────────────────
		"\(DocsPath)/example/index.md": _mkExampleIndex
	}

	file_list: [for p, _ in files {p}]

	stats: {
		total_modules:    len(Modules)
		total_decisions:  len(Decisions)
		total_patterns:   len(Patterns)
		total_insights:   len(Insights)
		total_downstream: len(Downstream)
		total_sites:      len(Sites)
		total_types:      len(Types)
		total_files:      len(files)
	}

	// ════════════════════════════════════════════════════════════════════
	// Page templates
	// ════════════════════════════════════════════════════════════════════

	// ── Index page ───────────────────────────────────────────────────

	_mkIndex: """
		# quicue.ca

		Model it in CUE. Validate by unification. Export to whatever the world expects.

		\(Prose.index.what_this_is)

		## Overview

		| Metric | Count |
		|--------|-------|
		| Modules | \(len(Modules)) |
		| Decisions (ADRs) | \(len(Decisions)) |
		| KB Patterns | \(len(Patterns)) |
		| Insights | \(len(Insights)) |
		| Semantic Types | \(len(Types)) |
		| Downstream Consumers | \(len(Downstream)) |
		| Deployed Sites | \(len(Sites)) |

		## Modules

		| Module | Layer | Description |
		|--------|-------|-------------|
		\(_indexModuleRows)

		\(Prose.index.not_just_infra)

		\(Prose.index.what_it_computes)

		## Downstream Consumers

		| Project | Domain | Patterns Used |
		|---------|--------|---------------|
		\(_indexDownstreamRows)

		## Ecosystem Sites

		| Site | Description |
		|------|-------------|
		\(_indexSiteRows)

		\(Prose.index.contract)

		## Quick Start

		```bash
		git clone https://github.com/quicue/quicue.ca.git
		cd quicue.ca

		# Validate schemas
		cue vet ./vocab/ ./patterns/

		# Run the datacenter example
		cue eval ./examples/datacenter/ -e output.summary

		# What breaks if the router goes down?
		cue eval ./examples/datacenter/ -e output.impact.\"router-core\"

		# Export as JSON-LD
		cue export ./examples/datacenter/ -e jsonld --out json
		```

		## License

		Apache 2.0
		"""

	_indexModuleRows: strings.Join([
		for name, mod in Modules {
			"| [\(name)](modules/\(name).md) | `\(mod.layer)` | \(mod.description) |"
		},
	], "\n")

	_indexDownstreamRows: strings.Join([
		for name, ds in Downstream {
			"| [\(name)](\(ds["@id"])) | \(ds.description) | \(ds.pattern_count) |"
		},
	], "\n")

	_indexSiteRows: strings.Join([
		for name, site in Sites {
			"| [\(name)](\(site.url)) | \(site.description) |"
		},
	], "\n")

	// ── Architecture page ────────────────────────────────────────────

	_mkArchitecture: """
		# Architecture

		quicue.ca models any domain as typed dependency graphs in CUE. This document explains how the layers compose, what each module does, and how data flows from resource definitions to executable plans.

		\(Prose.architecture.four_layer_model)

		## Module Dependency Graph

		```mermaid
		graph TD
		\(_mermaid_nodes)
		\(_mermaid_edges)
		```

		## Layers

		\(_archLayerSections)

		\(Prose.architecture.resource)
		\(Prose.architecture.action)
		\(Prose.architecture.type_registry)
		\(Prose.architecture.bind_cluster)
		\(Prose.architecture.execution_plan)
		\(Prose.architecture.deployment_plan)
		\(Prose.architecture.projections)
		\(Prose.architecture.extension_modules)
		\(Prose.architecture.data_flow)

		## Key Invariants

		1. **No runtime template resolution.** Every `{param}` placeholder is resolved at `cue vet` time. If a command has an unresolved placeholder, it won't compile.
		2. **The graph is the source of truth.** Deployment plans, rollback sequences, blast radius, documentation, and visualizations are all computed from the same unified constraint set.
		3. **Struct-as-set everywhere.** `@type`, `depends_on`, `provides`, and `tags` all use `{key: true}` structs for O(1) membership testing.
		4. **Hidden fields for export control.** CUE exports all public fields. Intermediate computation uses hidden fields (`_depth`, `_ancestors`, `_graph`) to prevent JSON bloat.
		5. **Topology-sensitive transitive closure.** CUE's fixpoint computation for `_ancestors` is bottlenecked by fan-in (edge density), not node count.
		"""

	_archLayerSections: strings.Join([
		for layer in _layer_order if _by_layer[layer] != _|_ {
			let mods = _by_layer[layer]
			let modList = strings.Join([for name in mods {
				"- **[\(name)](modules/\(name).md)** — \(Modules[name].description)"
			}], "\n")
			"### \(layer)\n\n\(modList)\n"
		},
	], "\n")

	// ── Patterns page (from module schemas) ──────────────────────────

	_mkPatterns: """
		# Pattern Catalog

		Reference for all computational patterns in `quicue.ca/patterns@v0`. Every pattern is a CUE definition that takes typed inputs and produces computed outputs. Patterns compose — most accept `Graph: #InfraGraph` and can be combined freely.

		\(Prose.patterns.intro)

		## Schema Index

		\(_patternsSchemaList)

		\(Prose.patterns.schema_groups)

		See [KB Patterns](patterns-kb/index.md) for the \(len(Patterns)) validated problem/solution pairs that inform these schemas.
		"""

	_patternsSchemaList: strings.Join([
		if Modules["patterns"] != _|_ if Modules["patterns"].schemas != _|_ {
			strings.Join([for s in Modules["patterns"].schemas {
				"- `\(s)`"
			}], "\n")
		},
	], "\n")

	// ── Templates page ───────────────────────────────────────────────

	_mkTemplates: """
		# Template Authoring Guide

		\(_templateCount) provider templates across \(_templateCatCount) categories. Each template teaches the system how to manage a specific platform — what resource types it serves, what actions it can perform, and how those actions translate to concrete commands.

		## Categories

		| Category | Providers |
		|----------|-----------|
		\(_templateCatSections)

		## Directory Structure

		```
		template/<name>/
		  meta/meta.cue          # Provider metadata and type matching
		  patterns/<name>.cue    # Action registry
		  examples/demo.cue      # Working example
		  README.md
		```

		\(Prose.templates.parameter_binding)

		\(Prose.templates.conventions)
		"""

	_templateCatSections: strings.Join([
		for cat, providers in _templateCats {
			let provList = strings.Join([for p in providers {"`\(p)`"}], ", ")
			"| \(cat) | \(provList) |"
		},
	], "\n")

	// ── Charter page ─────────────────────────────────────────────────

	_mkCharter: """
		# Charter

		`quicue.ca/charter` — constraint-first project planning via CUE unification.

		Declare what "done" looks like. Build the graph incrementally. `cue vet` tells you what's missing. When it passes, the charter is satisfied.

		The gap between constraints and data IS the remaining work.

		## Schemas

		\(_charterSchemaList)

		## How It Works

		A charter is a set of CUE constraints that the project graph must eventually satisfy. You declare scope (what must exist), gates (checkpoints along the way), and let CUE compute the delta.

		```cue
		import "quicue.ca/charter"

		_charter: charter.#Charter & {
		    name: "NHCF Deep Retrofit"
		    scope: {
		        total_resources: 18
		        root:            "nhcf-agreement"
		        required_resources: {"rideau-design": true, "gladstone-design": true}
		        required_types: {Assessment: true, Design: true, Retrofit: true}
		        min_depth: 3
		    }
		    gates: {
		        "assessment-complete": {
		            phase: 1
		            requires: {"site-audit": true, "energy-model": true}
		        }
		        "design-complete": {
		            phase: 3
		            requires: {"rideau-design": true, "gladstone-design": true}
		            depends_on: {"assessment-complete": true}
		        }
		    }
		}
		```

		## Gap Analysis

		`#GapAnalysis` takes a charter and a graph, and computes what's missing:

		| Field | Type | Description |
		|-------|------|-------------|
		| `complete` | `bool` | `true` when all constraints are satisfied |
		| `missing_resources` | `{[string]: true}` | Named resources not yet in the graph |
		| `missing_types` | `{[string]: true}` | Required types not represented |
		| `depth_satisfied` | `bool` | Graph reaches `min_depth` |
		| `gate_status` | `{[name]: {satisfied, missing, ready}}` | Per-gate evaluation |
		| `unsatisfied_gates` | `{[name]: {missing}}` | Gates not yet met |
		| `next_gate` | `string` | Lowest-phase unsatisfied gate |

		When `gaps.complete == true`, the charter is satisfied. When it's `false`, the missing fields tell you exactly what to build next.

		\(Prose.charter.scope_constraints)

		\(Prose.charter.live_integrations)

		## Validation

		```bash
		cue vet ./charter/
		```
		"""

	_charterSchemaList: strings.Join([
		if Modules["charter"] != _|_ if Modules["charter"].schemas != _|_ {
			strings.Join([for s in Modules["charter"].schemas {
				"- `\(s)`"
			}], "\n")
		},
	], "\n")

	// ── Federation page ──────────────────────────────────────────────

	_mkFederation: """
		# Federation

		quicue.ca projects federate knowledge through CUE's type system and W3C linked data standards. No external triplestore, no SPARQL endpoint, no contract test framework. CUE unification already is one.

		\(Prose.federation.kb_pattern)

		## Downstream Consumers

		| Project | Module | Patterns | Status | Has KB |
		|---------|--------|----------|--------|--------|
		\(_fedDownstreamRows)

		\(Prose.federation.dependency_tracking)

		## How Federation Works

		Multiple teams maintain independent `.kb/` directories in their own repos. "Federating" them is just importing and letting CUE unify. If two teams assert contradictory values for the same field, `cue vet` produces a unification error. Conflicts are caught at build time, not discovered in a meeting six months later.

		CUE struct unification is:

		- **Commutative** — order of import doesn't matter
		- **Idempotent** — importing the same fact twice is harmless
		- **Conflict-detecting** — contradictory values fail loudly

		No merge strategy. No conflict resolution policy. The lattice handles it.

		\(Prose.federation.rejected_type)

		## Cross-References

		SKOS vocabulary alignment enables cross-namespace navigation:

		- `skos:exactMatch` — "See also" links between equivalent concepts across registries
		- `skos:closeMatch` — "Related" links between similar concepts in different domains
		- `skos:broader` / `skos:narrower` — hierarchical breadcrumbs within a concept scheme

		The `make check-downstream` target runs `cue vet` on all registered consumers. Renaming a field in `#InfraGraph` produces a unification error in any consumer that references it, caught at build time rather than discovered in production.
		"""

	_fedDownstreamRows: strings.Join([
		for name, ds in Downstream {
			let _hasKB = strings.Join([
				if ds.has_kb != _|_ if ds.has_kb == true {"yes"},
				if ds.has_kb == _|_ {"no"},
			], "")
			"| [\(name)](\(ds["@id"])) | `\(ds.module)` | \(ds.pattern_count) | \(ds.status) | \(_hasKB) |"
		},
	], "\n")

	// ── Modules index ────────────────────────────────────────────────

	_mkModulesIndex: """
		# Modules

		\(len(Modules)) modules organized by architectural layer.

		## By Layer

		\(_modulesLayerSections)

		## All Modules

		| Module | Layer | Status | Description |
		|--------|-------|--------|-------------|
		\(_modulesIndexRows)
		"""

	_modulesLayerSections: strings.Join([
		for layer in _layer_order if _by_layer[layer] != _|_ {
			let mods = _by_layer[layer]
			let modList = strings.Join([for name in mods {
				"- [\(name)](\(name).md) — \(Modules[name].description)"
			}], "\n")
			"### \(layer)\n\n\(modList)\n"
		},
	], "\n")

	_modulesIndexRows: strings.Join([
		for name, mod in Modules {
			"| [\(name)](\(name).md) | `\(mod.layer)` | \(mod.status) | \(mod.description) |"
		},
	], "\n")

	// ── Per-module page ──────────────────────────────────────────────

	_mkModulePage: {
		for name, mod in Modules {
			let _deps_section = strings.Join([
				if mod.depends != _|_ if len(mod.depends) > 0 {
					"\n## Dependencies\n\n" + strings.Join([for dep in mod.depends {
						"- [\(dep)](../modules/\(dep).md)"
					}], "\n")
				},
			], "")

			let _schemas_section = strings.Join([
				if mod.schemas != _|_ if len(mod.schemas) > 0 {
					"\n## Schemas\n\n" + strings.Join([for s in mod.schemas {
						"- `\(s)`"
					}], "\n")
				},
			], "")

			let _packages_section = strings.Join([
				if mod.packages != _|_ if len(mod.packages) > 0 {
					"\n## Packages\n\n" + strings.Join([for p in mod.packages {
						"- `\(p)`"
					}], "\n")
				},
			], "")

			let _categories_section = strings.Join([
				if mod.categories != _|_ {
					"\n## Categories\n\n| Category | Entries |\n|----------|--------|\n" + strings.Join([
						for cat, items in mod.categories {
							let itemList = strings.Join([for i in items {"`\(i)`"}], ", ")
							"| \(cat) | \(itemList) |"
						},
					], "\n")
				},
			], "")

			let _entries_section = strings.Join([
				if mod.entries != _|_ if len(mod.entries) > 0 {
					"\n## Entries\n\n" + strings.Join([for e in mod.entries {
						"- `\(e)`"
					}], "\n")
				},
			], "")

			let _notes_section = strings.Join([
				if mod.notes != _|_ if mod.notes != "" {
					"\n!!! note\n    \(mod.notes)\n"
				},
			], "")

			let _prose_section = strings.Join([
				if Prose.modules != _|_ if Prose.modules[name] != _|_ {
					"\n\(Prose.modules[name])"
				},
			], "")

			"\(name)": """
				# \(name)

				\(mod.description)

				| Field | Value |
				|-------|-------|
				| Path | `\(mod.path)` |
				| Layer | `\(mod.layer)` |
				| Status | \(mod.status) |
				\(_deps_section)\(_schemas_section)\(_packages_section)\(_categories_section)\(_entries_section)\(_notes_section)\(_prose_section)
				"""
		}
	}

	// ── Decisions index ──────────────────────────────────────────────

	_mkDecisionsIndex: """
		# Architecture Decisions

		\(len(Decisions)) architecture decision records (ADRs).

		| ID | Title | Status | Date |
		|----|-------|--------|------|
		\(_decisionsIndexRows)
		"""

	_decisionsIndexRows: strings.Join([
		for key, dec in Decisions {
			"| [\(dec.id)](\(_dec_slug[key]).md) | \(dec.title) | \(dec.status) | \(dec.date) |"
		},
	], "\n")

	// ── Per-decision page ────────────────────────────────────────────

	_mkDecisionPage: {
		for key, dec in Decisions {
			let _consequences = strings.Join([for c in dec.consequences {
				"- \(c)"
			}], "\n")

			"\(key)": """
				# \(dec.id): \(dec.title)

				| Field | Value |
				|-------|-------|
				| Status | \(dec.status) |
				| Date | \(dec.date) |

				## Context

				\(dec.context)

				## Decision

				\(dec.decision)

				## Rationale

				\(dec.rationale)

				## Consequences

				\(_consequences)
				"""
		}
	}

	// ── KB Patterns index ────────────────────────────────────────────

	_mkPatternsKBIndex: """
		# Knowledge Base Patterns

		\(len(Patterns)) validated problem/solution pairs organized by category.

		## By Category

		\(_patternsKBCatSections)

		## All Patterns

		| Pattern | Category | Used In |
		|---------|----------|---------|
		\(_patternsKBAllRows)
		"""

	_patternsKBCatSections: strings.Join([
		for cat, keys in _by_pattern_cat {
			let items = strings.Join([for key in keys {
				"- [\(Patterns[key].name)](\(_pat_slug[key]).md)"
			}], "\n")
			"### \(cat)\n\n\(items)\n"
		},
	], "\n")

	_patternsKBAllRows: strings.Join([
		for key, pat in Patterns {
			let usedIn = strings.Join([for proj, _ in pat.used_in {proj}], ", ")
			"| [\(pat.name)](\(_pat_slug[key]).md) | \(pat.category) | \(usedIn) |"
		},
	], "\n")

	// ── Per-KB-pattern page ──────────────────────────────────────────

	_mkPatternKBPage: {
		for key, pat in Patterns {
			let _usedIn = strings.Join([for proj, _ in pat.used_in {
				"- \(proj)"
			}], "\n")

			let _related_section = strings.Join([
				if pat.related != _|_ {
					let relList = strings.Join([
						for rel, _ in pat.related if _pat_link[rel] != _|_ {
							"- \(_pat_link[rel])"
						},
						for rel, _ in pat.related if _pat_link[rel] == _|_ {
							let display = strings.Replace(rel, "_", " ", -1)
							"- \(display)"
						},
					], "\n")
					"\n## See Also\n\n\(relList)"
				},
			], "")

			let _example_section = strings.Join([
				if pat.example != _|_ if pat.example != "" {
					"\n## Example\n\n`\(pat.example)`"
				},
			], "")

			"\(key)": """
				# \(pat.name)

				**Category:** \(pat.category)

				## Problem

				\(pat.problem)

				## Solution

				\(pat.solution)

				## Context

				\(pat.context)
				\(_example_section)

				## Used In

				\(_usedIn)
				\(_related_section)
				"""
		}
	}

	// ── Insights index ───────────────────────────────────────────────

	_mkInsightsIndex: """
		# Insights

		\(len(Insights)) validated discoveries from building the quicue ecosystem.

		| ID | Statement | Confidence | Method |
		|----|-----------|------------|--------|
		\(_insightsSummaryRows)

		\(_insightsContent)
		"""

	_insightsSummaryRows: strings.Join([
		for key, ins in Insights {
			"| \(ins.id) | \(ins.statement) | \(ins.confidence) | \(ins.method) |"
		},
	], "\n")

	_insightsContent: strings.Join([
		for key, ins in Insights {
			let evidence = strings.Join([for e in ins.evidence {
				"- \(e)"
			}], "\n")

			let _related = strings.Join([
				if ins.related != _|_ {
					let relList = strings.Join([for rel, _ in ins.related {
						if strings.HasPrefix(rel, "ADR-") {
							"[\(rel)](../decisions/\(strings.ToLower(rel)).md)"
						}
						if strings.HasPrefix(rel, "INSIGHT-") {
							"\(rel)"
						}
						if !strings.HasPrefix(rel, "ADR-") if !strings.HasPrefix(rel, "INSIGHT-") {
							"\(rel)"
						}
					}], ", ")
					"\n**Related:** \(relList)"
				},
			], "")

			"""
			## \(ins.id): \(ins.statement)

			**Method:** \(ins.method) | **Confidence:** \(ins.confidence) | **Discovered:** \(ins.discovered)

			### Evidence

			\(evidence)

			### Implication

			\(ins.implication)
			\(_related)

			"""
		},
	], "\n---\n\n")

	// ── Type registry ────────────────────────────────────────────────

	_mkTypesIndex: """
		# Type Registry

		\(len(Types)) semantic types for infrastructure resources. Types describe WHAT a resource IS, not what it can do. Actions are defined by providers, not by type declarations.

		## Types

		| Type | Description |
		|------|-------------|
		\(_typesRows)

		## Usage

		```cue
		import "quicue.ca/vocab@v0"

		myResource: vocab.#Resource & {
		    "@type": {LXCContainer: true, DNSServer: true}
		}
		```

		## Categories

		- **Implementation** (how it runs): `LXCContainer`, `VirtualMachine`, `DockerContainer`, `ComposeStack`, `DockerHost`
		- **Semantic** (what it does): `DNSServer`, `ReverseProxy`, `Database`, `Vault`, `MonitoringServer`
		- **Classification** (operational tier): `CriticalInfra`

		A resource can have multiple types. A Proxmox LXC running PowerDNS is `{LXCContainer: true, DNSServer: true}` — it gets both container management actions from the proxmox provider AND DNS-specific actions from the powerdns provider.
		"""

	_typesRows: strings.Join([
		for name, t in Types {
			"| `\(name)` | \(t.description) |"
		},
	], "\n")

	// ── Example output ──────────────────────────────────────────────

	_exampleCount: int | *0
	if Modules["examples"] != _|_ if Modules["examples"].entries != _|_ {
		_exampleCount: len(Modules["examples"].entries)
	}

	_mkExampleIndex: """
		# Example Output

		\(_exampleCount) working examples demonstrating quicue.ca patterns from minimal to production-scale.

		## Examples

		| Example | Path |
		|---------|------|
		\(_exampleRows)

		## Running an example

		```bash
		# Validate
		cue vet ./examples/datacenter/

		# Summary
		cue eval ./examples/datacenter/ -e output.summary

		# Impact analysis
		cue eval ./examples/datacenter/ -e output.impact."router-core"

		# JSON-LD export
		cue export ./examples/datacenter/ -e jsonld --out json
		```

		Each example is a self-contained CUE module under `examples/`. They import from `vocab/` and `patterns/` and can be evaluated independently.
		"""

	_exampleRows: strings.Join([
		if Modules["examples"] != _|_ if Modules["examples"].entries != _|_ {
			strings.Join([for e in Modules["examples"].entries {
				"| \(e) | `examples/\(e)/` |"
			}], "\n")
		},
	], "\n")
}
