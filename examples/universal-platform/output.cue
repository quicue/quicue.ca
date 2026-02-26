// Per-tier output — VizData, commands, deployment plan, impact, SPOF
//
// Graph analysis is topology-invariant: computed once, shared by all tiers.
// Only provider binding and VizData (which carries per-tier @type) differ.

package platform

import (
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
)

// ═══════════════════════════════════════════════════════════════════════
// SHARED — topology analysis computed once (any tier works, edges are identical)
// ═══════════════════════════════════════════════════════════════════════

_infra:      patterns.#InfraGraph & {Input: _desktop_resources, Precomputed: _precomputed}
_spof:       patterns.#SinglePointsOfFailure & {Graph: _infra}
_deployment: patterns.#DeploymentPlan & {Graph: _infra}
_metrics:    patterns.#GraphMetrics & {Graph: _infra}

// Shared analysis injected into every tier
_analysis: {
	// Closure data — already computed in precomputed.cue, just exported
	closure: _precomputed

	deployment_plan: {layers: _deployment.layers, summary: _deployment.summary}

	// Full impact for every resource — derived from precomputed.dependents
	impact: {
		for name, deps in _precomputed.dependents {
			(name): {
				affected:       deps
				affected_count: len(deps)
				ancestors:       _precomputed.ancestors[name]
				ancestor_count:  len(_precomputed.ancestors[name])
				depth:           _precomputed.depth[name]
			}
		}
	}

	spof: _spof.risks
	summary: {
		total_resources: _metrics.total_resources
		max_depth:       _metrics.max_depth
		total_edges:     _metrics.total_edges
	}
}

// ═══════════════════════════════════════════════════════════════════════
// JSON-LD HELPER — same @context for all tiers, @graph varies by resources
// ═══════════════════════════════════════════════════════════════════════

_jsonld: {
	_resources: {...}
	out: {
		"@context": vocab.context["@context"] & {
			"@base": _site.base_id
		}
		"@graph": [
			for _, r in _resources {{
				"@id":   r."@id"
				"@type": [for t, _ in r."@type" {t}]
				name:    r.name
				if r.ip != _|_ {ip: r.ip}
				if r.host != _|_ {host: r.host}
				if r.description != _|_ {description: r.description}
				if r.depends_on != _|_ {depends_on: [for d, _ in r.depends_on {d}]}
			}},
		]
	}
}

// ═══════════════════════════════════════════════════════════════════════
// PER-TIER — binding (inherently different) + VizData (carries @type) + JSON-LD
// ═══════════════════════════════════════════════════════════════════════

desktop: _analysis & {
	_execution: patterns.#ExecutionPlan & {resources: _desktop_resources, providers: _desktop_providers}
	_viz:       patterns.#VizData & {Graph: patterns.#InfraGraph & {Input: _desktop_resources, Precomputed: _precomputed}, Resources: _desktop_resources}
	vizData:    _viz.data
	jsonld:     (_jsonld & {_resources: _desktop_resources}).out
	commands: {
		for rname, r in _execution.cluster.bound {
			(rname): {for pname, pactions in r.actions {for aname, a in pactions if a.command != _|_ {"\(pname)/\(aname)": a.command}}}
		}
	}
	summary: binding: _execution.cluster.summary
}

node: _analysis & {
	_execution: patterns.#ExecutionPlan & {resources: _node_resources, providers: _node_providers}
	_viz:       patterns.#VizData & {Graph: patterns.#InfraGraph & {Input: _node_resources, Precomputed: _precomputed}, Resources: _node_resources}
	vizData:    _viz.data
	jsonld:     (_jsonld & {_resources: _node_resources}).out
	commands: {
		for rname, r in _execution.cluster.bound {
			(rname): {for pname, pactions in r.actions {for aname, a in pactions if a.command != _|_ {"\(pname)/\(aname)": a.command}}}
		}
	}
	summary: binding: _execution.cluster.summary
}

cluster: _analysis & {
	_execution: patterns.#ExecutionPlan & {resources: _cluster_resources, providers: _cluster_providers}
	_viz:       patterns.#VizData & {Graph: patterns.#InfraGraph & {Input: _cluster_resources, Precomputed: _precomputed}, Resources: _cluster_resources}
	vizData:    _viz.data
	jsonld:     (_jsonld & {_resources: _cluster_resources}).out
	commands: {
		for rname, r in _execution.cluster.bound {
			(rname): {for pname, pactions in r.actions {for aname, a in pactions if a.command != _|_ {"\(pname)/\(aname)": a.command}}}
		}
	}
	summary: binding: _execution.cluster.summary
}

enterprise: _analysis & {
	_execution: patterns.#ExecutionPlan & {resources: _enterprise_resources, providers: _enterprise_providers}
	_viz:       patterns.#VizData & {Graph: patterns.#InfraGraph & {Input: _enterprise_resources, Precomputed: _precomputed}, Resources: _enterprise_resources}
	vizData:    _viz.data
	jsonld:     (_jsonld & {_resources: _enterprise_resources}).out
	commands: {
		for rname, r in _execution.cluster.bound {
			(rname): {for pname, pactions in r.actions {for aname, a in pactions if a.command != _|_ {"\(pname)/\(aname)": a.command}}}
		}
	}
	summary: binding: _execution.cluster.summary
}
