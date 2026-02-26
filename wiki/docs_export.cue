// Value file — wire registry data into #DocsProjection
//
// This file embeds registry data from .kb/ and vocab/ packages.
// Since .kb/ is an independent CUE module, data is copied here.
// A future sync script will keep this in sync with source registries.
//
// Usage:
//   cue export ./wiki/ -e docs --out json > /tmp/docs-bulk.json
//   cue export ./wiki/ -e docs.stats --out json
package wiki

docs: #DocsProjection & {
	Modules:    _modules
	Decisions:  _decisions
	Patterns:   _patterns
	Insights:   _insights
	Downstream: _downstream
	Sites:      _sites
	Types:      _types
	Prose:      _prose
}

// ════════════════════════════════════════════════════════════════════════
// Prose — hand-authored narrative sections spliced into generated pages
// ════════════════════════════════════════════════════════════════════════

_prose: #ProseSlots & {
	index: {
		what_this_is: """
			## What this is

			You declare resources — nodes in a graph — with types and dependencies. CUE computes the rest: dependency layers, transitive closure, blast radius, deployment plans, linked data exports. The gap between your constraints and your data IS the remaining work. When `cue vet` passes, you're done.

			```cue
			dns: #Resource & {
			    "@type":     {LXCContainer: true, DNSServer: true}
			    depends_on:  {router: true}
			    host:        "node-1"
			    container_id: 101
			}
			```

			No runtime. No state file. No plugins. CUE validates everything simultaneously, and the output is plain JSON.
			"""
		not_just_infra: """
			## Not just infrastructure

			The graph patterns are domain-agnostic. `#BlastRadius`, `#ImpactQuery`, `#SinglePointsOfFailure`, and `#DeploymentPlan` don't know what domain they're in. "What breaks if X goes down?" works whether X is a DNS server, a construction phase, or a research gene.

			| Domain | What the graph models | Live |
			|--------|----------------------|------|
			| IT infrastructure | 30 servers, containers, and services across 7 dependency layers | [datacenter example](example/index.md) |
			| Construction management | Deep retrofit work packages for 270-unit community housing program | [CMHC Retrofit](https://cmhc-retrofit.quicue.ca/) |
			| Energy efficiency | 17-service processing platform for Ontario Greener Homes | [Greener Homes](https://cmhc-retrofit.quicue.ca/#greener-homes) |
			| Real estate operations | Transaction pipelines, referral networks, compliance workflows | [maison-613](https://maison613.quicue.ca/) |
			"""
		what_it_computes: """
			## What it computes

			| Pattern | What it answers |
			|---------|-----------------|
			| `#InfraGraph` | Dependency layers, transitive closure, topology |
			| `#BindCluster` | Which providers match which resources, resolved commands |
			| `#ImpactQuery` | "What breaks if X goes down?" |
			| `#BlastRadius` | Change impact with rollback order |
			| `#SinglePointsOfFailure` | Resources with no redundancy |
			| `#HealthStatus` | Simulated failure propagation |
			| `#DeploymentPlan` | Ordered layers with gates |
			| `#ExecutionPlan` | All of the above, unified |
			| `#Charter` | What "done" looks like — scope, gates, completion |
			| `#GapAnalysis` | What's missing, what's next, which gates are satisfied |

			See the [Pattern Catalog](patterns.md) for the full list and [Charter](charter.md) for project planning.
			"""
		contract: """
			## Contract-via-unification

			Verification IS unification. You write CUE constraints that must merge with the computed graph. If they can't unify, `cue vet` rejects everything:

			```cue
			// This must merge with the computed graph output.
			// If docker isn't the root, or validation fails, cue vet rejects.
			validate: valid: true
			infra: roots: {"docker": true}
			deployment: layers: [{layer: 0, resources: ["docker"]}, ...]
			```

			No assertion framework. No test runner. The contract IS CUE values. Unification IS the enforcement.
			"""
	}
	architecture: {
		four_layer_model: """
			## Four-layer model

			```
			Definition (vocab/)          What things ARE and what you can DO to them
			    ↓
			Pattern (patterns/)          How to analyze, bind, plan, and export
			    ↓
			Template (template/*/)       Platform-specific action implementations
			    ↓
			Value (examples/, your code) Concrete infrastructure instances
			```

			Each layer imports only from the layer below it. CUE's type system enforces that values satisfy all constraints from every layer simultaneously — there is no runtime, no fallback, and no partial evaluation.
			"""
		resource: """
			## Definition layer: `vocab/`

			### `#Resource`

			The foundation. Every infrastructure component is a `#Resource`:

			```cue
			dns: vocab.#Resource & {
			    name:         "dns"
			    "@type":      {LXCContainer: true, DNSServer: true}
			    depends_on:   {router: true}
			    host:         "pve-node1"
			    container_id: 101
			    ip:           "198.51.100.211"
			}
			```

			Key design decisions:

			- **Struct-as-set for `@type` and `depends_on`.** `{LXCContainer: true}` gives O(1) membership checks. Patterns test `resource["@type"][SomeType] != _|_` instead of iterating a list.
			- **Generic field names.** `host` (not `node`), `container_id` (not `lxcid`). Providers map generic names to platform-specific commands.
			- **Open schema (`...`).** Resources can carry domain-specific fields without modifying vocab.
			- **ASCII-safe identifiers.** All resource names, `@type` keys, `depends_on` keys are constrained to ASCII via `#SafeID` and `#SafeLabel` regex patterns. This prevents zero-width unicode injection and homoglyph attacks at compile time.
			"""
		action: """
			### `#Action` and `#ActionDef`

			Actions are executable operations. Two schemas serve different purposes:

			- **`#Action`** — a resolved action with a concrete `command` string. This is what the binding layer produces.
			- **`#ActionDef`** — an action *definition* with typed parameters and a command template. Providers declare these; the binding layer resolves them against resources.

			```cue
			// ActionDef (provider declares this)
			ping: vocab.#ActionDef & {
			    name:             "Ping"
			    description:      "Test connectivity"
			    category:         "info"
			    params:           {ip: {from_field: "ip"}}
			    command_template: "ping -c 3 {ip}"
			    idempotent:       true
			}
			```

			The `from_field` key is what makes compile-time binding work. If a resource lacks the field a parameter needs, the action is silently omitted (not an error — the provider simply doesn't apply to that resource).
			"""
		bind_cluster: """
			## Pattern layer: `patterns/`

			### `#BindCluster` — command resolution

			Matches providers to resources by `@type` overlap and resolves command templates:

			```cue
			cluster: patterns.#BindCluster & {
			    resources: _resources
			    providers: {
			        proxmox: patterns.#ProviderDecl & {
			            types:    {LXCContainer: true, VirtualMachine: true}
			            registry: proxmox_patterns.#ProxmoxRegistry
			        }
			    }
			}
			// cluster.bound.dns.actions.proxmox.container_status.command = "pct status 101"
			```

			The binding algorithm:

			1. For each resource, iterate all providers
			2. If `provider.types ∩ resource["@type"] ≠ ∅`, the provider matches
			3. For each action in the provider's registry, check if all required parameters resolve from resource fields
			4. Resolve the command template with `#ResolveTemplate` (compile-time substitution, up to 8 parameters)
			5. Produce a concrete `vocab.#Action` with the resolved command
			"""
		execution_plan: """
			### `#ExecutionPlan` — the unifier

			Composes binding, graph analysis, and deployment planning over the same resource set:

			```cue
			execution: patterns.#ExecutionPlan & {
			    resources: _resources
			    providers: _providers
			}
			// execution.cluster.bound     — resources with resolved commands
			// execution.graph.topology    — dependency layers
			// execution.plan.layers       — ordered deployment with gates
			```

			CUE enforces that all three agree. If a resource's dependencies are inconsistent with its binding, evaluation fails — not at deploy time, at `cue vet` time.
			"""
		projections: """
			### Export projections

			The execution plan can be projected into multiple output formats:

			| Projection | Format | Target |
			|------------|--------|--------|
			| `notebook` | `.ipynb` JSON | Jupyter runbook with per-layer cells |
			| `rundeck` | YAML | Rundeck job definitions |
			| `http` | `.http` | RFC 9110 REST Client files |
			| `wiki` | Markdown | MkDocs site (index + per-resource pages) |
			| `script` | Bash | Self-contained deployment script with parallelism |
			| `ops` | JSON | Task list for `cue cmd` consumption |
			"""
		data_flow: """
			## Data flow summary

			```
			1. Define resources (CUE values with @type and depends_on)
			                    ↓
			2. Declare providers (type matching + action registries)
			                    ↓
			3. #ExecutionPlan unifies:
			   ├── #BindCluster  → resolved commands per resource per provider
			   ├── #InfraGraph   → depth, ancestors, topology, dependents
			   └── #DeploymentPlan → ordered layers with gates
			                    ↓
			4. CUE validates everything simultaneously:
			   - Missing fields → compile error
			   - Dangling dependencies → validation error
			   - Type mismatches → unification error
			                    ↓
			5. Export to any format:
			   - cue export -e output --out json          → full execution data
			   - cue export -e execution.notebook         → Jupyter runbook
			   - cue export -e execution.script --out text → deployment script
			   - cue export -e jsonld --out json          → JSON-LD graph
			```
			"""
		extension_modules: """
			## Extension modules

			### `ou/` — Role-scoped views

			Role-scoped views that filter resources and actions by role: `ops` (full access), `dev` (read-only monitoring), `readonly` (status queries only). Exports W3C Hydra JSON-LD for semantic API navigation.

			### `boot/` — Bootstrap sequencing

			Credential collection and bootstrap ordering for initial infrastructure setup. Handles the chicken-and-egg problem (e.g., you need DNS to reach the vault, but you need the vault to configure DNS).

			### `cab/` — Change Advisory Board

			Generates CAB reports from impact analysis: what's changing, what's affected, what's the rollback plan, who needs to approve.

			### `wiki/` — Documentation generation

			Produces MkDocs-compatible markdown from the resource graph: index page, per-layer views, per-resource detail pages.

			### `server/` — FastAPI gateway

			HTTP API for executing resolved commands. Reads the CUE-generated OpenAPI spec and exposes actions as REST endpoints. Live at [api.quicue.ca](https://api.quicue.ca/docs) (public, mock mode).

			### `kg/` — Knowledge graph

			The `.kb/` directory at the repo root is a multi-graph knowledge base with typed subdirectories (decisions/, patterns/, insights/, rejected/), each validated against its kg type.
			"""
	}
	patterns: {
		intro: """
			**Identifier safety:** All resource names, `@type` keys, and `depends_on` keys are constrained to ASCII via `#SafeID` and `#SafeLabel` in `vocab/resource.cue`. Patterns assume safe identifiers — `cue vet` enforces the constraints at compile time.
			"""
		schema_groups: """
			## Groups

			### Graph construction
			`#InfraGraph`, `#ValidateGraph`, `#CycleDetector`, `#ConnectedComponents`, `#Subgraph`, `#GraphDiff`

			### Impact analysis
			`#ImpactQuery`, `#BlastRadius`, `#CompoundRiskAnalysis`, `#GraphMetrics`, `#ImmediateDependents`, `#DependencyChain`

			### Ranking and classification
			`#CriticalityRank`, `#RiskScore`, `#GroupByType`, `#SinglePointsOfFailure`, `#SPOFWithRedundancy`

			### Health and operations
			`#HealthStatus`, `#DeploymentPlan`, `#RollbackPlan`

			### Compliance
			`#ComplianceCheck`, `#ComplianceRule`

			### Binding and execution
			`#BindCluster`, `#ExecutionPlan`, `#ResolveTemplate`

			### Visualization
			`#GraphvizDiagram`, `#MermaidDiagram`, `#VizData`, `#DependencyMatrix`

			### Export formats
			`#TOONExport`, `#OpenAPISpec`, `#SHACLShapes`, `#JustfileProjection`, `#ExportGraph`

			### Lifecycle
			`#BootstrapPlan`, `#DriftReport`, `#SmokeTest`, `#DeploymentLifecycle`

			### Critical path
			`#CriticalPath`, `#LifecyclePhasesSKOS`
			"""
	}
	templates: {
		parameter_binding: """
			## Parameter binding

			Each parameter declares `from_field` — the resource field it binds to:

			| `from_field` | Resolves from | Example value |
			|--------------|---------------|---------------|
			| `"ip"` | `resource.ip` | `"198.51.100.211"` |
			| `"host"` | `resource.host` | `"pve-alpha"` |
			| `"container_id"` | `resource.container_id` | `101` |
			| `"ssh_user"` | `resource.ssh_user` | `"root"` |

			Rules:

			- If a required parameter's field is missing from the resource, the entire action is silently omitted.
			- Optional parameters (`required: false`) with `default` values use the default when the field is absent.
			- All values are stringified for template substitution.
			- Up to 8 parameters per action (limitation of `#ResolveTemplate`).
			"""
		conventions: """
			## Conventions

			1. **Use generic field names.** `host` not `node`, `container_id` not `lxcid`.
			2. **One registry per provider.** Name it `#<Name>Registry`.
			3. **Idempotent by default.** Mark read-only actions as `idempotent: true`. Mark state-changing actions as `destructive: true`.
			4. **SSH wrapping.** For remote actions, use `ssh {host} '<command>'` in the template.
			5. **Package naming.** `meta/meta.cue` uses `package meta`. `patterns/<name>.cue` uses `package patterns`. `examples/demo.cue` uses `package demo`.
			"""
	}
	charter: {
		scope_constraints: """
			## Scope constraints

			The `scope` block supports five constraint types, all optional:

			| Constraint | Type | Meaning |
			|-----------|------|---------|
			| `total_resources` | `int & >0` | Minimum resource count |
			| `root` | `string \\| {[string]: true}` | Named root(s) that must exist as graph roots |
			| `required_resources` | `{[string]: true}` | Resources that must exist by name |
			| `required_types` | `{[string]: true}` | Types that must be represented |
			| `min_depth` | `int & >=0` | Minimum graph depth |
			"""
		live_integrations: """
			## Live integrations

			Charter is used across five downstream projects, each a different domain shape:

			| Project | Graph | Nodes | Gates | Domain |
			|---------|-------|-------|-------|--------|
			| cmhc-retrofit NHCF | Project delivery | 18 | 5 | Construction PM |
			| cmhc-retrofit Greener Homes | Service topology | 17 | 5 | IT platform |
			| maison-613 Transaction | Deal phases | 16 | 6 | Real estate |
			| maison-613 Compliance | Obligation graph | 12 | 4 | Regulatory |
			| grdn | Infrastructure | 50 | 2 | Homelab |
			"""
	}
	federation: {
		kb_pattern: """
			## The .kb/ pattern

			Each project that uses quicue.ca can maintain a `.kb/` directory — a multi-graph knowledge base tracking decisions, patterns, insights, and rejected approaches:

			```
			your-project/
			  .kb/
			    cue.mod/module.cue       # Root module
			    manifest.cue              # #KnowledgeBase — declares graph topology
			    decisions/
			      cue.mod/module.cue      # Independent CUE module
			      decisions.cue           # core.#Decision entries
			    patterns/
			      patterns.cue            # core.#Pattern entries
			    insights/
			      insights.cue            # core.#Insight entries
			    rejected/
			      rejected.cue            # core.#Rejected entries
			```

			Each subdirectory validates independently with `cue vet .` — directory structure IS the ontology.
			"""
		dependency_tracking: """
			## Dependency tracking

			A downstream project's `deps.cue` records every definition it imports from quicue.ca:

			```cue
			_pattern_deps: {
			    "#InfraGraph": {
			        source:  "quicue.ca/patterns@v0"
			        used_in: ["graph.cue"]
			        purpose: "Dependency graph computation"
			    }
			    "#BlastRadius": {
			        source:  "quicue.ca/patterns@v0"
			        used_in: ["projections.cue"]
			        purpose: "Transitive impact scope"
			    }
			}
			```

			This is documentation. The enforcement comes from CUE itself — if `#InfraGraph` changes a field name, every file that imports it fails to unify.
			"""
		rejected_type: """
			## The #Rejected type

			`#Rejected` requires an `alternative` field — you can't record "we tried X and it failed" without saying where to go instead. In a federated setup, a failed experiment in one team's repo becomes a navigational signpost for another team.

			```cue
			rejected_001: core.#Rejected & {
			    id:          "rejected-001"
			    title:       "VizExport pattern for graph rendering"
			    date:        "2025-12-10"
			    description: "Attempted #VizExport wrapper — CUE exports ALL public fields, causing 4x JSON bloat"
			    reason:      "Public field leak: Graph field exported entire input struct (75KB vs 17KB)"
			    alternative: "Use hidden _viz wrapper + explicit viz: {data: _viz.data, resources: ...}"
			}
			```
			"""
	}
	modules: {
		vocab: """
			## Key Definitions

			| Schema | Purpose |
			|--------|---------|
			| `#Resource` | Foundation type — every infrastructure component is a resource with `@type`, `depends_on`, and provider-specific fields |
			| `#Action` | A resolved action with a concrete `command` string (output of binding) |
			| `#ActionDef` | An action *definition* with typed parameters and a command template (provider declares these) |
			| `#TypeRegistry` | The 57 semantic types that classify what resources ARE |
			| `#SafeID` | ASCII-safe identifier constraint — prevents unicode injection at compile time |

			## Design Decisions

			- **Struct-as-set** for `@type` and `depends_on` — `{LXCContainer: true}` gives O(1) membership
			- **Open schema (`...`)** — resources carry domain-specific fields without modifying vocab
			- **Generic field names** — `host` not `node`, `container_id` not `lxcid`

			See [ADR-002](../decisions/adr-002.md) (struct-as-set) and [ADR-014](../decisions/adr-014.md) (ASCII-safe identifiers).
			"""
		boot: """
			## Purpose

			Handles the bootstrap chicken-and-egg problem: you need DNS to reach the vault, but you need the vault to configure DNS. `boot/` models this as a sequenced plan with credential collection phases.

			## Key Concepts

			- **`#BootstrapResource`** — a resource with additional bootstrap metadata (credential requirements, first-run commands)
			- **`#BootstrapPlan`** — ordered bootstrap phases with dependency gates
			- **Credential collectors** — typed declarations of what secrets are needed before a resource can start

			Bootstrap runs once to bring infrastructure from zero to a state where normal orchestration (`orche/`) can take over.
			"""
		cab: """
			## Purpose

			Generates Change Advisory Board reports from the graph's impact analysis. When you change a resource, `cab/` computes who needs to know and what could break.

			## What It Produces

			| Output | Description |
			|--------|-------------|
			| Impact summary | Which resources are affected, direct and transitive |
			| Blast radius | How far the change propagates through dependency layers |
			| Rollback plan | Reverse-order steps to undo the change |
			| Runbook | Step-by-step execution plan for the change |

			Input is an `#ExecutionPlan` — the same unified structure that powers deployment, visualization, and documentation.
			"""
		ci: """
			## Purpose

			Reusable GitLab CI job templates that any downstream project can include. Each template runs a specific CUE operation and reports results as pipeline artifacts.

			## Templates

			| Template | What It Does |
			|----------|-------------|
			| `validate` | `cue vet` on all CUE packages |
			| `export` | `cue export` to JSON for downstream consumption |
			| `topology` | Graph analysis — depth, layers, critical path |
			| `impact` | Blast radius and SPOF analysis |

			Usage: include the templates in your `.gitlab-ci.yml` and override the `CUE_PACKAGE` variable.
			"""
		wiki: """
			## Purpose

			Generates MkDocs-compatible markdown documentation from any `#ExecutionPlan`. Given a resource graph with resolved bindings, `wiki/` produces a complete documentation site: index page, per-layer views, per-resource detail pages.

			This is the same module that powers `docs.quicue.ca` — the `#DocsProjection` in this directory is a sibling projection that consumes registry data instead of resource graphs.

			## Key Schema

			`#WikiProjection` takes:
			- `Resources` — the resource graph
			- `Bound` — resolved bindings from `#BindCluster`
			- `Graph` — topology from `#InfraGraph`
			- `Plan` — deployment layers from `#DeploymentPlan`

			And produces `files: {[path]: content}` + `stats` + `mkdocs` nav fragment.
			"""
		ou: """
			## Purpose

			Role-scoped views that filter the full `#ExecutionPlan` down to what a specific user should see and do. Three built-in roles:

			| Role | Access | Use Case |
			|------|--------|----------|
			| `ops` | Full — all resources, all actions | Infrastructure operators |
			| `dev` | Read-only monitoring — status, logs, metrics | Developers |
			| `readonly` | Status queries only — no mutations | Dashboards, auditors |

			## W3C Hydra Export

			`ou/` also exports a [W3C Hydra](http://www.hydra-cg.com/spec/latest/core/) JSON-LD API description. Each resource type becomes a `hydra:Class` with `supportedOperation` entries — enabling semantic API navigation for frontends that understand linked data.
			"""
		server: """
			## Purpose

			HTTP API gateway that executes resolved commands from CUE-generated action plans. Reads the OpenAPI spec produced by `#OpenAPISpec` and exposes each action as a REST endpoint.

			## Architecture

			```
			CUE export → OpenAPI spec → FastAPI routes → command execution
			```

			The server never interprets CUE directly. It reads the pre-computed JSON output. This means the server is stateless and the CUE evaluation is a build step, not a runtime dependency.

			**Live demo:** [api.quicue.ca/docs](https://api.quicue.ca/docs) (public, mock mode — no real infrastructure commands execute)
			"""
	}
}

// ════════════════════════════════════════════════════════════════════════
// Registry data — sourced from .kb/modules.cue
// ════════════════════════════════════════════════════════════════════════

_modules: {
	vocab: {
		path:        "vocab/"
		module:      "quicue.ca@v0"
		layer:       "definition"
		description: "Core schemas: #Resource, #Action, #TypeRegistry, #ActionDef"
		status:      "active"
	}
	patterns: {
		path:        "patterns/"
		module:      "quicue.ca@v0"
		layer:       "definition"
		description: "Algorithms: graph, bind, deploy, health, SPOF, viz, TOON, OpenAPI, validation"
		status:      "active"
		schemas: [
			"#InfraGraph", "#BindCluster", "#ExecutionPlan",
			"#ImpactQuery", "#BlastRadius", "#SinglePointsOfFailure",
			"#CriticalityRank", "#HealthStatus", "#RollbackPlan",
			"#DeploymentPlan", "#TOONExport", "#ExportGraph",
			"#ValidateGraph", "#ValidateTypes", "#GroupByType", "#GraphMetrics",
			"#ImmediateDependents", "#DependencyChain",
			"#CycleDetector", "#ConnectedComponents", "#Subgraph",
			"#GraphDiff", "#CriticalPath", "#ComplianceCheck",
			"#LifecyclePhasesSKOS",
		]
	}
	templates: {
		path:        "template/*/"
		layer:       "template"
		description: "29 platform-specific providers, each a self-contained CUE module"
		status:      "active"
		count:       29
		categories: {
			compute:      ["proxmox", "govc", "powercli", "kubevirt"]
			container:    ["docker", "incus", "k3d", "kubectl", "argocd"]
			cicd:         ["dagger", "gitlab"]
			networking:   ["vyos", "caddy", "nginx"]
			dns:          ["cloudflare", "powerdns", "technitium"]
			identity:     ["vault", "keycloak"]
			database:     ["postgresql"]
			dcim:         ["netbox"]
			provisioning: ["foreman"]
			automation:   ["ansible", "awx"]
			monitoring:   ["zabbix"]
			iac:          ["terraform", "opentofu"]
			backup:       ["restic", "pbs"]
		}
	}
	orche: {
		path:        "orche/"
		module:      "quicue.ca@v0"
		layer:       "orchestration"
		description: "Orchestration schemas: execution steps, federation, drift detection, Docker site bootstrap"
		status:      "active"
		packages:    ["orchestration", "bootstrap", "schema"]
		depends:     ["patterns"]
	}
	boot: {
		path:        "boot/"
		module:      "quicue.ca@v0"
		layer:       "orchestration"
		description: "Bootstrap schemas: #BootstrapResource, #BootstrapPlan, credential collectors"
		status:      "active"
	}
	wiki: {
		path:        "wiki/"
		module:      "quicue.ca@v0"
		layer:       "projection"
		description: "#WikiProjection — MkDocs site generation from resource graphs"
		status:      "active"
	}
	cab: {
		path:        "cab/"
		module:      "quicue.ca@v0"
		layer:       "reporting"
		description: "Change Advisory Board reports: impact, blast radius, runbooks"
		status:      "active"
	}
	ou: {
		path:        "ou/"
		module:      "quicue.ca@v0"
		layer:       "interaction"
		description: "Role-scoped views: #InteractionCtx narrows #ExecutionPlan by role, type, name, layer. Hydra W3C JSON-LD export."
		status:      "active"
		depends:     ["patterns"]
	}
	ci: {
		path:        "ci/gitlab/"
		layer:       "ci"
		description: "Reusable GitLab CI templates for CUE validation, export, topology, impact"
		status:      "active"
	}
	server: {
		path:     "server/"
		layer:    "operations"
		description: "FastAPI execution gateway for running infrastructure commands"
		status:   "active"
		optional: true
		notes:    "Standalone. Consumes CUE-generated specs but does not depend on CUE at build time."
	}
	charter: {
		path:        "charter/"
		module:      "quicue.ca@v0"
		layer:       "constraint"
		description: "Constraint-first project planning: declare scope, evaluate gaps, track gates. SHACL gap report projection."
		status:      "active"
		schemas:     ["#Charter", "#Gate", "#GapAnalysis", "#Milestone", "#InfraCharter"]
		depends:     ["patterns"]
	}
	examples: {
		path:        "examples/"
		layer:       "value"
		description: "17 working examples from minimal 3-layer to full 30-resource datacenter"
		status:      "active"
		entries: [
			"datacenter", "homelab", "devbox", "graph-patterns",
			"drift-detection", "federation", "type-composition",
			"3-layer", "docker-bootstrap", "wiki-projection",
			"toon-export", "patterns-v2", "reconciliation",
			"showcase", "sbom", "ci", "universal-platform",
		]
	}
}

// ════════════════════════════════════════════════════════════════════════
// Registry data — sourced from .kb/decisions/decisions.cue
// ════════════════════════════════════════════════════════════════════════

_decisions: {
	d001: {
		id:        "ADR-001"
		title:     "Three-layer architecture: definition, template, value"
		status:    "accepted"
		date:      "2025-01-01"
		context:   "Infrastructure modeling requires separating universal concepts from platform-specific implementations from concrete instances."
		decision:  "Use a 3-layer architecture: vocab/ + patterns/ (definition), template/*/ (template), examples/ (value). Each layer constrains the next via CUE unification."
		rationale: "CUE's unification model naturally supports layered constraints. Definitions are provider-agnostic, templates add platform specifics, values bind concrete data. Violations are compile-time errors."
		consequences: [
			"Every provider must implement interfaces from patterns/",
			"Generic field names map to platform-specific commands",
			"New providers add template/*/ modules without touching definition or value layers",
		]
	}
	d002: {
		id:        "ADR-002"
		title:     "Struct-as-set: {key: true} over arrays for types and dependencies"
		status:    "accepted"
		date:      "2025-01-01"
		context:   "Resources need type membership and dependency declarations. Arrays require list.Contains (O(n)) and produce duplicates on unification."
		decision:  "Use struct-as-set pattern: {@type: {DNSServer: true, LXCContainer: true}} and {depends_on: {dns: true}}. O(1) membership, clean CUE unification, no duplicates."
		rationale: "CUE unifies structs by merging keys. {A: true} & {B: true} = {A: true, B: true}. Arrays would need explicit dedup. Struct keys are unique by construction."
		consequences: [
			"All @type fields use {[string]: true} not [...string]",
			"JSON-LD export converts to arrays: [for t, _ in @type {t}]",
			"Provider matching uses resource[@type][providerType] != _|_ (O(1))",
		]
	}
	d003: {
		id:        "ADR-003"
		title:     "Compile-time provider binding: all parameters resolve at cue eval"
		status:    "accepted"
		date:      "2025-06-01"
		context:   "Provider templates define commands with parameters ({host}, {container_id}). These could be resolved at runtime or at CUE evaluation time."
		decision:  "#BindCluster matches providers to resources by @type overlap, then #ResolveTemplate substitutes all {param} placeholders from resource fields at cue eval time."
		rationale: "Compile-time resolution means CUE catches missing fields before anything runs. A missing container_id is a type error, not a runtime 'undefined variable'."
		consequences: [
			"Resources must declare all fields their bound providers reference",
			"Provider templates use {param} syntax with explicit from_field bindings",
			"The output of cue export is fully resolved — ready to execute",
			"No runtime templating engine needed",
		]
	}
	d004: {
		id:        "ADR-004"
		title:     "Layer 4 interaction: ou/ scopes #ExecutionPlan by role, type, name, and layer"
		status:    "accepted"
		date:      "2026-01-31"
		context:   "The 3-layer model produces complete execution plans. Different operators need narrowed views: ops sees everything, dev sees DNS only, readonly sees info actions only."
		decision:  "Add ou/ package (Layer 4) with #InteractionCtx that narrows #ExecutionPlan via CUE comprehensions."
		rationale: "CUE comprehensions are the natural filtering mechanism — no runtime logic, just struct narrowing."
		consequences: [
			"Architecture becomes 4 layers: definition, template, value, interaction",
			"#InteractionCtx consumes #ExecutionPlan — no direct dependency on vocab/ or template/",
			"Operator roles use struct-as-set for visible_categories",
			"Hydra JSON-LD generation is explicit: consumer passes scoped view to #ApiDocumentation",
		]
	}
	d005: {
		id:        "ADR-005"
		title:     "Charter: constraint schema with computed gap analysis"
		status:    "accepted"
		date:      "2026-02-17"
		context:   "Downstream projects each have verify.cue files with identical patterns. The pattern is ad-hoc — no shared vocabulary, no intermediate checkpoints."
		decision:  "Charter defines #Charter (scope + gates), #Gate (DAG checkpoint), #GapAnalysis (computed missing resources, types, gate status), and #Milestone (single gate evaluation)."
		rationale: "Raw cue vet errors are unstructured text. #GapAnalysis produces typed CUE output consumable programmatically."
		consequences: [
			"Downstream projects use #GapAnalysis to compute structured backlog from charter + graph",
			"Gate DAG subsumes linear phases — a chain is a degenerate DAG",
			"#Milestone provides focused per-gate evaluation without full gap analysis",
			"Gap analysis output is typed and exportable as JSON",
		]
	}
	d006: {
		id:        "ADR-006"
		title:     "Public showcase data sourced exclusively from example datacenter"
		status:    "accepted"
		date:      "2026-02-18"
		context:   "Public surfaces were originally built from production infrastructure data containing real 172.20.x.x IPs."
		decision:  "All public-facing data is generated from examples/datacenter/ which uses RFC 5737 TEST-NET IPs (198.51.100.x). CI validates no real IPs leak."
		rationale: "A single source of safe data eliminates the risk of production IP leakage."
		consequences: [
			"All public surfaces serve data from examples/datacenter/ only",
			"CI validates no 172.x.x.x IPs in generated files",
			"Deploy scripts are parameterized — no hardcoded infrastructure hostnames",
			"Production data stays behind CF Access on apercue.ca surfaces",
		]
	}
	d007: {
		id:        "ADR-007"
		title:     "CUE conditional branches for optional charter scope fields"
		status:    "accepted"
		date:      "2026-02-18"
		context:   "Charter #GapAnalysis used count_satisfied: true as a default — in CUE, this is a hard constraint, not a default."
		decision:  "Use mutually exclusive conditional branches with a bool type constraint instead of a hard true default."
		rationale: "CUE unification makes foo: true into an immutable constraint. The only way to conditionally set a field is via mutually exclusive if branches."
		consequences: [
			"depth_satisfied and count_satisfied now use bool type + conditional branches",
			"Charter gap analysis works correctly when graph has fewer resources than scope requires",
			"cue vet on public fields catches conflicts that hidden-field tests miss",
		]
	}
	d008: {
		id:        "ADR-008"
		title:     "Domain-general framing: 'things that depend on other things'"
		status:    "accepted"
		date:      "2026-02-18"
		context:   "Public surfaces framed quicue.ca as 'infrastructure as typed dependency graphs.' This undersells the framework."
		decision:  "Frame as 'CUE framework for modeling any domain where things depend on other things.' The entry point is two fields: @type and depends_on."
		rationale: "The core requirement is: typed nodes with directed dependency edges. That's domain-independent."
		consequences: [
			"GitHub profile, repo descriptions, and docs all use domain-general language",
			"Downstream table replaces domain-specific prose as the credibility signal",
			"'Infrastructure' appears only when describing the IT domain specifically",
		]
	}
	d009: {
		id:        "ADR-009"
		title:     "SPARQL is external federation only — CUE comprehensions are the query layer"
		status:    "accepted"
		date:      "2026-02-18"
		context:   "Docs framed SPARQL as a primary query mechanism. This misrepresents the architecture."
		decision:  "SPARQL is for external federation only. Inside CUE, comprehensions ARE the query layer."
		rationale: "CUE unification IS a query engine for the closed world. SPARQL adds runtime dependency that doesn't exist."
		consequences: [
			"Oxigraph reclassified from 'optional infrastructure' to 'external federation only'",
			"Docs distinguish 'inside CUE' (comprehensions) from 'outside CUE' (SPARQL/triplestore)",
			"Profile README no longer implies SPARQL is the primary query method",
		]
	}
	d010: {
		id:        "ADR-010"
		title:     "Game design projects tracked separately from quicue.ca"
		status:    "accepted"
		date:      "2026-02-18"
		context:   "mud-futurama and fing-mod use quicue.ca/kg but listing them as downstream dilutes the message."
		decision:  "Remove game design projects from quicue.ca's downstream registry and all public documentation."
		rationale: "Including game projects alongside CMHC retrofit and production datacenter management undermines credibility."
		consequences: [
			"mud-futurama and fing-mod removed from .kb/downstream.cue",
			"Downstream count: 4 projects across 4 domains",
			"Game projects maintain their own .kb/ independently",
			"No game/MUD references on any quicue.ca public surface",
		]
	}
	d011: {
		id:        "ADR-011"
		title:     "lacuene is not a downstream consumer"
		status:    "accepted"
		date:      "2026-02-18"
		context:   "lacuene was listed as a downstream project but does not import quicue.ca/patterns or quicue.ca/vocab."
		decision:  "Remove lacuene from all downstream claims. Only projects that import quicue.ca are listed."
		rationale: "Listing a project that doesn't use the framework as a consumer is inaccurate."
		consequences: [
			"lacuene removed from README, docs, and all docs",
			"Downstream criteria: must import quicue.ca/patterns or quicue.ca/vocab",
			"'Biomedical research' removed from domain list",
		]
	}
	d012: {
		id:        "ADR-012"
		title:     "Static-first showcase: all public surfaces on Cloudflare Pages"
		status:    "accepted"
		date:      "2026-02-18"
		context:   "Public showcases were served by Caddy behind a Cloudflare Tunnel. The tunnel depends on port 7844 which ISP equipment blocks."
		decision:  "Deploy all static showcases to Cloudflare Pages. The static API serves the same endpoints as pre-computed JSON files."
		rationale: "CUE comprehensions pre-compute all possible API responses at eval time. If every answer is known at build time, a web server adds latency without capability."
		consequences: [
			"7 CF Pages projects replace Caddy vhosts",
			"All API examples use GET (POST returns 405 on static hosting)",
			"Tunnel only needed for dynamic services: MUDs, live execution",
			"Deploy workflow: cue export, build-static-api.sh, wrangler pages deploy",
		]
	}
	d013: {
		id:        "ADR-013"
		title:     "Lifecycle management in patterns/, not a separate orche/ package"
		status:    "accepted"
		date:      "2026-02-19"
		context:   "boot/ and orche/ reference packages that don't exist. patterns/ already has lifecycle-adjacent definitions."
		decision:  "Absorb lifecycle management into patterns/lifecycle.cue. No separate orche/ package."
		rationale: "CUE's strength is type composition via unification. Types that compose belong together."
		consequences: [
			"patterns/lifecycle.cue created with #BootstrapPlan, #DriftReport, #SmokeTest, #DeploymentLifecycle",
			"boot/ types refactored into patterns/",
			"examples/drift-detection/ updated to import patterns/ instead of orche/",
			"No orche/ module to publish or version separately",
		]
	}
	d014: {
		id:        "ADR-014"
		title:     "ASCII-safe identifiers (#SafeID, #SafeLabel) on all graph surfaces"
		status:    "accepted"
		date:      "2026-02-19"
		context:   "CUE unification treats string values as opaque byte sequences. Cyrillic 'a' and Latin 'a' are different CUE values that look identical."
		decision:  "Constrain all graph identifiers to ASCII via regex. #SafeID for resource names, #SafeLabel for type keys."
		rationale: "Constraining identifiers to ASCII eliminates the entire class of unicode-based confusion attacks."
		consequences: [
			"All resource names, @type keys, depends_on keys must be ASCII",
			"patterns/graph.cue defines hidden mirrors (_#SafeID, _#SafeLabel)",
			"boot/resource.cue uses inline regex (no cross-package hidden field access)",
			"Downstream repos inherit constraints via quicue.ca symlink",
			"apercue.ca has identical constraints — both layers enforce independently",
		]
	}
}

// ════════════════════════════════════════════════════════════════════════
// Registry data — sourced from .kb/patterns/patterns.cue
// ════════════════════════════════════════════════════════════════════════

_patterns: {
	p_struct_as_set: {
		name:     "Struct-as-Set"
		category: "data"
		problem:  "Arrays allow duplicates, require O(n) membership checks, and collide on unification."
		solution: "Use {[string]: true} for sets. O(1) membership, automatic dedup, clean unification via CUE lattice."
		context:  "Any field representing membership, tags, categories, or dependency sets."
		example:  "apercue/.kb/decisions/002-struct-as-set.cue"
		used_in: {
			apercue:     true
			datacenter:  true
			"quicue.ca": true
		}
		related: {
			bidirectional_deps:    true
			referential_integrity: true
		}
	}
	p_three_layer: {
		name:     "Three-Layer Architecture"
		category: "architecture"
		problem:  "Infrastructure models mix universal concepts with platform-specific implementations and concrete instances."
		solution: "Separate into definition, template, and value layers. Each layer constrains the next via CUE unification."
		context:  "Infrastructure-as-code projects where the same resource model applies across multiple platforms."
		used_in: {"quicue.ca": true}
		related: {compile_time_binding: true}
	}
	p_compile_time_binding: {
		name:     "Compile-Time Binding"
		category: "architecture"
		problem:  "Command templates with runtime placeholders can fail at execution time if a field is missing."
		solution: "Resolve all template parameters at CUE evaluation time using #ResolveTemplate. No placeholders survive."
		context:  "Provider action templates where parameters come from resource fields."
		used_in: {"quicue.ca": true}
		related: {struct_as_set: true}
	}
	p_hidden_wrapper: {
		name:     "Hidden Wrapper for Exports"
		category: "cue"
		problem:  "CUE exports all public fields. Definitions with large input as public fields leak that data."
		solution: "Use hidden fields (_prefix) for intermediate computation. Expose only the final projection."
		context:  "Any CUE definition that produces export-ready JSON from larger input data."
		example:  "_viz holds computation, viz: {data: _viz.data} exposes output only"
		used_in: {"quicue.ca": true}
	}
	p_contract_via_unification: {
		name:     "Contract-via-Unification"
		category: "verification"
		problem:  "Projects need to verify graph invariants but traditional assertion frameworks add a separate test layer."
		solution: "Write CUE constraints as plain struct values that must unify with computed output. The language IS the test harness."
		context:  "Any project with a dependency graph where structural invariants must hold."
		used_in: {
			"quicue.ca":       true
			"cmhc-retrofit":   true
			"maison-613":      true
			grdn:              true
		}
		related: {
			struct_as_set:  true
			hidden_wrapper: true
			gap_as_backlog: true
		}
	}
	p_gap_as_backlog: {
		name:     "Gap-as-Backlog"
		category: "planning"
		problem:  "Project planning tools track work items separately from the system. The backlog drifts."
		solution: "Declare 'done' as CUE constraints on an incomplete graph. The gap IS the remaining work."
		context:  "Any project built incrementally where completion criteria can be expressed as graph properties."
		used_in: {"quicue.ca": true}
		related: {
			contract_via_unification: true
			struct_as_set:            true
		}
	}
	p_universe_cheatsheet: {
		name:     "Universe Cheat Sheet"
		category: "architecture"
		problem:  "Read-only APIs backed by CUE graphs still deploy a web server, adding latency and failure modes."
		solution: "Run cue export once to produce all possible API responses as static JSON files. Deploy to CDN."
		context:  "Any CUE-backed API where the query universe is finite and data changes only at build time."
		used_in: {"quicue.ca": true}
		related: {
			compile_time_binding: true
			safe_deploy:          true
		}
	}
	p_safe_deploy: {
		name:     "Safe Deploy Pipeline"
		category: "operations"
		problem:  "Public surfaces built from production data leak real IPs and internal topology."
		solution: "Source all public data from a single safe example (RFC 5737 TEST-NET IPs). Delete all existing files before deploying."
		context:  "Any project deploying generated artifacts to public web surfaces."
		used_in: {"quicue.ca": true}
		related: {compile_time_binding: true}
	}
	p_hidden_intermediary: {
		name:     "Hidden Intermediary for Nested Structs"
		category: "cue"
		problem:  "CUE field references inside nested structs resolve to the nearest enclosing scope, causing self-references."
		solution: "Define hidden intermediaries at the outer scope: _total: total. Then reference them inside the nested struct."
		context:  "Any CUE definition that copies outer field values into a nested summary or output struct."
		used_in: {
			"quicue.ca":     true
			"cmhc-retrofit": true
			charter:         true
		}
		related: {
			hidden_wrapper:          true
			contract_via_unification: true
		}
	}
	p_graph_projection: {
		name:     "Graph Projection from Existing Config"
		category: "adoption"
		problem:  "Existing CUE codebases don't use @type or depends_on. Rewriting is invasive."
		solution: "Write a single additive file (graph.cue) that reads from existing config fields and produces a flat resource map."
		context:  "Any existing CUE project considering adoption of quicue.ca patterns."
		used_in: {grdn: true}
		related: {
			struct_as_set: true
			three_layer:   true
		}
	}
	p_everything_is_projection: {
		name:     "Everything-is-a-Projection"
		category: "architecture"
		problem:  "Adding new output formats requires writing new code in each target language, duplicating graph traversal."
		solution: "Maintain one canonical CUE graph. Every output format is a CUE comprehension over that graph."
		context:  "Any CUE project that produces multiple output formats from the same source data."
		used_in: {
			"quicue.ca": true
			apercue:     true
		}
		related: {
			compile_time_binding: true
			universe_cheatsheet:  true
			hidden_wrapper:       true
		}
	}
	p_idempotent_by_construction: {
		name:     "Idempotent-by-Construction"
		category: "operations"
		problem:  "Deployment scripts accumulate state. Re-running a partially-failed deployment is risky."
		solution: "CUE evaluation is deterministic — same inputs always produce identical outputs. The deployment artifact is immutable."
		context:  "Any deployment pipeline where re-runnability matters."
		used_in: {"quicue.ca": true}
		related: {
			compile_time_binding:     true
			contract_via_unification: true
		}
	}
	p_types_compose: {
		name:     "Types-Compose-Scripts-Don't"
		category: "architecture"
		problem:  "Adding new deployment capabilities typically means writing new bash scripts that duplicate graph traversal."
		solution: "Express new capabilities as CUE types that compose with existing types via unification."
		context:  "Any extension to the deployment lifecycle where the new capability needs access to the resource graph."
		used_in: {"quicue.ca": true}
		related: {
			three_layer:              true
			everything_is_projection: true
		}
	}
	p_static_first: {
		name:     "Static-First"
		category: "architecture"
		problem:  "Web servers introduce failure modes even when serving read-only data that changes only at build time."
		solution: "Pre-compute everything possible at cue export time. Read-only API surfaces are directories of JSON files served by CDN."
		context:  "Deployment dashboards, API documentation, graph visualization, risk reports."
		used_in: {"quicue.ca": true}
		related: {
			universe_cheatsheet:      true
			everything_is_projection: true
			safe_deploy:              true
		}
	}
	p_airgapped_bundle: {
		name:     "Airgapped Bundle"
		category: "operations"
		problem:  "Deploying to air-gapped or restricted networks fails because package managers (apt, pip, docker pull) require internet access. Partial offline solutions miss transitive dependencies or version conflicts."
		solution: "Define a #Bundle CUE schema declaring all artifacts needed for offline deployment: git repos, Docker images (app + base), Python wheels (including pip bootstrap), static binaries, and system packages with recursive dependencies. A #Gotcha registry captures known deployment traps with tested workarounds. bundle.sh reads the manifest and collects everything. install-airgapped.sh deploys on the target."
		context:  "Any deployment to networks with restricted internet access: institutional data centers, classified environments, factory floors, or POC demonstrations that must work reliably without external dependencies."
		example:  "operator/airgap-bundle.cue defines #Bundle + #Gotcha. E2E proven: 284MB bundle → fresh Ubuntu 24.04 VM → 37/37 smoke tests on completely airgapped machine."
		used_in: {"quicue.ca": true}
		related: {
			idempotent_by_construction: true
			types_compose:              true
			safe_deploy:                true
		}
	}
	p_ascii_safe_identifiers: {
		name:     "ASCII-Safe Identifiers"
		category: "security"
		problem:  "CUE unification treats strings as opaque byte sequences. Unicode homoglyphs (Cyrillic 'а' vs Latin 'a'), zero-width characters (U+200B), and RTL overrides (U+202E) create visually identical but structurally distinct keys."
		solution: "Constrain all graph identifiers to ASCII via regex at the definition layer. #SafeID for resource names and dependency references. #SafeLabel for type names, tags, and registry keys. cue vet enforces at compile time with zero runtime cost."
		context:  "Any CUE schema where string values participate in struct key lookup, unification, or cross-reference. Especially critical for @type (provider matching), depends_on (graph edges), and name (identity)."
		example:  "#SafeID: =~\"^[a-zA-Z][a-zA-Z0-9_.-]*$\"; #SafeLabel: =~\"^[a-zA-Z][a-zA-Z0-9_-]*$\""
		used_in: {"apercue": true, "quicue.ca": true, "cmhc-retrofit": true, "grdn": true, "maison-613": true}
		related: {
			struct_as_set:            true
			contract_via_unification: true
		}
	}
}

// ════════════════════════════════════════════════════════════════════════
// Registry data — sourced from .kb/insights/insights.cue
// ════════════════════════════════════════════════════════════════════════

_insights: {
	i001: {
		id:        "INSIGHT-001"
		statement: "CUE transitive closure performance is topology-sensitive, not node-count-limited"
		evidence: [
			"NHCF scenario with 25 nodes timed out — but due to wide fan-in, not node count",
			"Reducing to 18 nodes brought eval under 4 seconds by reducing fan-in",
		]
		method:      "experiment"
		confidence:  "high"
		discovered:  "2025-12-01"
		implication: "Minimize edge density and fan-in for large graphs; Python precompute is a fallback for high-fan-in topologies"
		related: {"ADR-001": true}
	}
	i002: {
		id:        "INSIGHT-002"
		statement: "CUE exports ALL public (capitalized) fields, causing unexpected JSON bloat"
		evidence: [
			"#VizExport with public Graph field exported the entire input graph (75KB vs 17KB expected)",
		]
		method:      "observation"
		confidence:  "high"
		discovered:  "2025-11-15"
		implication: "Export-facing definitions must use hidden fields (_prefix) for intermediate data"
		related: {"ADR-002": true}
	}
	i003: {
		id:        "INSIGHT-003"
		statement: "CUE packages are directory-scoped — multi-graph knowledge bases leverage this for independent validation"
		evidence: [
			".kb/ subdirectories create separate package instances — each graph validates independently",
		]
		method:      "experiment"
		confidence:  "high"
		discovered:  "2026-02-15"
		implication: "Knowledge bases use typed subdirectories: each graph is an independent CUE package with its own cue.mod/"
		related: {"ADR-001": true}
	}
	i004: {
		id:        "INSIGHT-004"
		statement: "Production data leaks through generated artifacts, not just source code"
		evidence: [
			"cat.quicue.ca had 98 real 172.20.x.x IPs in generated JSON",
			"Deploying safe data missed pre-existing files with different naming conventions",
		]
		method:      "observation"
		confidence:  "high"
		discovered:  "2026-02-18"
		implication: "When replacing data on public surfaces, grep -rl for real IPs across the ENTIRE web root"
		related: {"ADR-006": true}
	}
	i005: {
		id:        "INSIGHT-005"
		statement: "cue vet does not fully evaluate hidden fields — test assertions on hidden values give false confidence"
		evidence: [
			"charter_test.cue asserts on a hidden field — cue vet passed even with conflicting values",
		]
		method:      "experiment"
		confidence:  "high"
		discovered:  "2026-02-18"
		implication: "For critical invariants, use public fields or run cue eval -e to force evaluation"
		related: {"ADR-005": true, "ADR-007": true}
	}
	i006: {
		id:        "INSIGHT-006"
		statement: "Everything is a projection of the same typed dependency graph — 72+ projections exist"
		evidence: [
			"Terraform, Ansible, Rundeck, Jupyter, MkDocs, bash, HTTP, OpenAPI, Justfile, JSON-LD, Graphviz, Mermaid, TOON, N-Triples, DCAT — all from the same graph",
		]
		method:      "cross_reference"
		confidence:  "high"
		discovered:  "2026-02-18"
		implication: "The graph is the single source of truth. Every artifact is a derived projection."
		related: {"INSIGHT-002": true}
	}
	i007: {
		id:        "INSIGHT-007"
		statement: "CUE unification obviates SPARQL — precomputed comprehensions ARE the query layer"
		evidence: [
			"8 query patterns implemented as CUE definitions, no triplestore needed",
		]
		method:      "experiment"
		confidence:  "high"
		discovered:  "2026-02-18"
		implication: "SPARQL is unnecessary for the primary use case. CUE comprehensions precompute all graph queries at eval time."
		related: {"INSIGHT-006": true}
	}
	i008: {
		id:        "INSIGHT-008"
		statement: "When CUE comprehensions pre-compute all possible answers, the API is just a file server"
		evidence: [
			"727 static JSON files replace FastAPI with zero server runtime",
		]
		method:      "experiment"
		confidence:  "high"
		discovered:  "2026-02-18"
		implication: "If your domain model is a closed world and CUE comprehensions compute all queries at eval time, a CDN is the optimal runtime."
		related: {"INSIGHT-007": true, "ADR-012": true}
	}
	i009: {
		id:        "INSIGHT-009"
		statement: "Airgapped deployment has 8 reproducible traps"
		evidence: [
			"E2E deployment on fresh Ubuntu 24.04 VM hit all 8 traps: ensurepip, typing_extensions, raptor2, cue.mod symlinks, Docker bind-mount, Caddy TLS, CUE OOM, grep pipefail",
		]
		method:      "experiment"
		confidence:  "high"
		discovered:  "2026-02-19"
		implication: "Every package manager assumes internet access. Airgapped deployment has its own failure modes."
		related: {"ADR-013": true}
	}
	i010: {
		id:        "INSIGHT-010"
		statement: "Three latent bugs in patterns/ went undetected because CUE's lax evaluation hides struct iteration errors"
		evidence: [
			"#BootstrapPlan used len(depends_on) as depth proxy — wrong for peer resources",
			"#ValidateGraph was defined in BOTH graph.cue and type-contracts.cue — CUE silently unified them",
			"#DependencyValidation iterated depends_on as an array but the codebase uses struct-as-set",
		]
		method:      "observation"
		confidence:  "high"
		discovered:  "2026-02-19"
		implication: "CUE's lazy evaluation means bugs hide in definitions that are syntactically valid but semantically wrong. Critical patterns need exercising examples."
		related: {"INSIGHT-003": true}
	}
	i011: {
		id:        "INSIGHT-011"
		statement: "W3C vocabulary alignment is mostly projection work — CUE's typed data already has the structure"
		evidence: [
			"depends_on mapped from quicue:dependsOn to dcterms:requires — zero code change, just one IRI swap",
			"#ComplianceCheck results already have the structure of sh:ValidationReport — 20 lines to project",
		]
		method:      "cross_reference"
		confidence:  "high"
		discovered:  "2026-02-19"
		implication: "When your data model is already typed and validated by CUE, W3C compliance is a thin projection layer."
		related: {"INSIGHT-006": true, "INSIGHT-007": true}
	}
	i012: {
		id:        "INSIGHT-012"
		statement: "ASCII-safe identifier constraints catch unicode injection at compile time"
		evidence: [
			"Cyrillic 'a' vs Latin 'a' creates distinct CUE keys that look identical",
			"Zero-width space in 'dnsserver' never matches 'dnsserver' in depends_on",
		]
		method:      "cross_reference"
		confidence:  "high"
		discovered:  "2026-02-19"
		implication: "CUE's type system can enforce input validation at compile time. Unicode safety is a schema constraint."
		related: {"ADR-014": true, "INSIGHT-005": true}
	}
	i013: {
		id:        "INSIGHT-013"
		statement: "Export-facing CUE definitions systematically lack W3C @context and @id"
		evidence: [
			"7 files producing structured output without proper JSON-LD framing",
			"Files WITH proper alignment were added intentionally, not systematically",
		]
		method:      "cross_reference"
		confidence:  "high"
		discovered:  "2026-02-20"
		implication: "W3C compliance must be architectural, not ad-hoc. Every export-facing definition should include @context, @type, and dct:conformsTo."
		related: {"INSIGHT-011": true, "INSIGHT-006": true}
	}
	i014: {
		id:        "INSIGHT-014"
		statement: "Cloudflare API tokens are stored in ~/.ssh/ — the working token is cf-tk.token, not ~/.cf_env"
		evidence: [
			"~/.cf_env exports CF_API_KEY — wrangler rejects it",
			"~/.ssh/cf-tk.token contains working CLOUDFLARE_API_TOKEN",
		]
		method:      "observation"
		confidence:  "high"
		discovered:  "2026-02-20"
		implication: "Token management needs a single source of truth. CF_API_KEY vs CLOUDFLARE_API_TOKEN naming mismatch caused repeated deploy failures."
		related: {"INSIGHT-004": true}
	}
}

// ════════════════════════════════════════════════════════════════════════
// Registry data — sourced from .kb/downstream.cue
// ════════════════════════════════════════════════════════════════════════

_downstream: {
	grdn: {
		"@id":       "https://quicue.ca/project/grdn"
		module:      "grdn.quicue.ca"
		description: "Production infrastructure graph — multi-node cluster with ZFS storage, networking, and container orchestration"
		imports: ["quicue.ca/vocab@v0", "quicue.ca/patterns@v0"]
		pattern_count: 14
		status:        "active"
	}
	"cmhc-retrofit": {
		"@id":       "https://quicue.ca/project/cmhc-retrofit"
		module:      "quicue.ca/cmhc-retrofit@v0"
		description: "Construction program management (NHCF deep retrofit, Greener Homes processing platform)"
		imports: ["quicue.ca/patterns@v0"]
		pattern_count: 15
		has_kb:        true
		status:        "active"
	}
	"maison-613": {
		"@id":       "https://rfam.cc/project/maison-613"
		module:      "rfam.cc/maison-613@v0"
		description: "Real estate operations — 7 graphs (transaction, referral, compliance, listing, operations, onboarding, client)"
		imports: ["quicue.ca/patterns@v0"]
		pattern_count: 14
		has_kb:        true
		status:        "active"
	}
}

// ════════════════════════════════════════════════════════════════════════
// Registry data — sites
// ════════════════════════════════════════════════════════════════════════

_sites: {
	docs: {
		url:         "https://docs.quicue.ca"
		description: "MkDocs Material documentation site"
		deploy:      "github-pages"
		status:      "active"
	}
	demo: {
		url:         "https://demo.quicue.ca"
		description: "Operator dashboard — D3 graph, planner, resource browser"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
	api: {
		url:         "https://api.quicue.ca"
		description: "Static API showcase — 727 pre-computed JSON endpoints"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
	cat: {
		url:         "https://cat.quicue.ca"
		description: "DCAT 3 data catalogue"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
	kg: {
		url:         "https://kg.quicue.ca"
		description: "Knowledge graph framework spec"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
	"cmhc-retrofit": {
		url:         "https://cmhc-retrofit.quicue.ca"
		description: "Construction program management showcase"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
	maison613: {
		url:         "https://maison613.quicue.ca"
		description: "Real estate operations showcase"
		deploy:      "cloudflare-pages"
		status:      "active"
	}
}

// ════════════════════════════════════════════════════════════════════════
// Registry data — type names and descriptions from vocab/types.cue
// ════════════════════════════════════════════════════════════════════════

_types: {
	LXCContainer:           {description: "Proxmox LXC container"}
	DockerContainer:        {description: "Docker container"}
	ComposeStack:           {description: "Docker Compose application stack"}
	VirtualMachine:         {description: "Virtual machine (Proxmox QEMU, VMware, etc.)"}
	DockerHost:             {description: "Docker daemon host"}
	KubernetesService:      {description: "Kubernetes workload"}
	VMwareCluster:          {description: "VMware vSphere / vCenter cluster"}
	Router:                 {description: "Network router/firewall"}
	KubernetesCluster:      {description: "Kubernetes cluster (k3s, k8s, OpenShift)"}
	DNSServer:              {description: "DNS/name resolution server"}
	ReverseProxy:           {description: "HTTP/HTTPS reverse proxy"}
	VirtualizationPlatform: {description: "Hypervisor node (Proxmox, VMware)"}
	SourceControlManagement: {description: "Git server (Forgejo, GitLab, Gitea)"}
	Bastion:                {description: "SSH jump host / bastion server"}
	Vault:                  {description: "Secrets management"}
	MonitoringServer:       {description: "Metrics/alerting server"}
	LogAggregator:          {description: "Log collection and aggregation"}
	DevelopmentWorkstation: {description: "Developer machine"}
	GPUCompute:             {description: "GPU-enabled compute node"}
	AuthServer:             {description: "Authentication/identity provider"}
	LoadBalancer:           {description: "Load balancer / traffic distribution"}
	MessageQueue:           {description: "Message broker (RabbitMQ, Kafka, NATS)"}
	CacheCluster:           {description: "Distributed cache (Redis, Memcached)"}
	Database:               {description: "Database server (PostgreSQL, MySQL, MongoDB)"}
	SearchIndex:            {description: "Search engine (Elasticsearch, Meilisearch)"}
	HomeAutomation:         {description: "Home automation platform"}
	ObjectStorage:          {description: "S3-compatible object storage"}
	ContainerRegistry:      {description: "OCI/Docker registry"}
	TracingBackend:         {description: "Distributed tracing (Jaeger, Zipkin, Tempo)"}
	StatusMonitor:          {description: "Uptime/status monitoring"}
	CIRunner:               {description: "CI/CD job runner"}
	MediaServer:            {description: "Media streaming server"}
	PhotoManagement:        {description: "Photo library management"}
	AudiobookLibrary:       {description: "Audiobook server"}
	EbookLibrary:           {description: "Ebook server"}
	RecipeManager:          {description: "Recipe/meal planning"}
	TunnelEndpoint:         {description: "Network tunnel (Cloudflared, WireGuard, Tailscale)"}
	Network:                {description: "Network zone / address space"}
	EdgeNode:               {description: "Edge/remote site node"}
	APIServer:              {description: "API backend service"}
	WebFrontend:            {description: "Web frontend / UI server"}
	Worker:                 {description: "Background job processor"}
	ScheduledJob:           {description: "Cron/scheduled task runner"}
	Region:                 {description: "Geographic region / data center location"}
	AvailabilityZone:       {description: "Availability zone within a region"}
	SoftwareApplication:    {description: "Software application or service binary"}
	SoftwareLibrary:        {description: "Software library or package dependency"}
	SoftwareFramework:      {description: "Software framework (Spring, Django, Rails)"}
	SoftwareContainer:      {description: "Container image artifact (OCI, Docker)"}
	SoftwarePlatform:       {description: "Runtime platform (JVM, Node.js, .NET CLR)"}
	SoftwareFirmware:       {description: "Embedded firmware component"}
	SoftwareFile:           {description: "Single file artifact in SBOM"}
	OperatingSystem:        {description: "Operating system (Ubuntu, Alpine, Windows)"}
	CIPipeline:             {description: "CI/CD pipeline definition"}
	CIStage:                {description: "Stage within a CI/CD pipeline"}
	CIJob:                  {description: "Individual job within a CI/CD stage"}
	CriticalInfra:          {description: "Critical infrastructure - extra monitoring/alerting"}
}
