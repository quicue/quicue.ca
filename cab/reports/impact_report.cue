// Impact Report Generator
//
// Generates impact analysis and blast radius reports for CAB review.
// Shows what breaks if specific resources fail.
//
// Usage:
//   import "quicue.ca/cab/reports"
//
//   impactReport: reports.#ImpactReport & {
//       Graph: infraGraph
//       ChangedResources: ["dns", "proxy"]
//   }

package reports

import (
	"strings"
	"list"
)

// #ImpactReport - Impact analysis for changed resources
#ImpactReport: {
	// Infrastructure graph (must have resources with _ancestors computed)
	Graph: {
		resources: [string]: {
			name: string
			"@type": {[string]: true}
			_depth:     int
			_ancestors: {[string]: bool}
			depends_on?: {[string]: true}
			...
		}
		roots:  [...string]
		leaves: [...string]
		...
	}

	// Resources that were changed
	ChangedResources: [...string]

	// Configuration
	Config?: {
		organization?: string
		environment?:  string
		...
	}

	// Calculate impact for each changed resource
	_impacts: {
		for target in ChangedResources {
			(target): {
				resource: target
				depth:    Graph.resources[target]._depth

				// Who depends on this resource (transitively)?
				affected: [
					for name, r in Graph.resources
					if r._ancestors[target] != _|_ {name},
				]

				affected_count: len(affected)

				// Direct dependents only
				direct_dependents: [
					for name, r in Graph.resources
					if r.depends_on != _|_
					if r.depends_on[target] != _|_ {name},
				]

				// Types of affected resources
				affected_types: {
					for name in affected {
						for t, _ in Graph.resources[name]["@type"] {
							(t): true
						}
					}
				}

				// Risk level based on affected count
				risk: [
					if len(affected) > 20 {"critical"},
					if len(affected) > 10 {"high"},
					if len(affected) > 5 {"medium"},
					if len(affected) > 0 {"low"},
					"none",
				][0]
			}
		}
	}

	// Aggregate impact
	impacts: [for _, i in _impacts {i}]

	// Total unique affected resources
	_allAffected: {
		for _, i in _impacts {
			for name in i.affected {
				(name): true
			}
		}
	}

	// Summary
	_impactCounts: [for i in impacts {i.affected_count}]
	summary: {
		changed_count:     len(ChangedResources)
		total_affected:    len([for _, _ in _allAffected {1}])
		max_single_impact: [if len(_impactCounts) > 0 {list.Max(_impactCounts)}, 0][0]
		critical_count:    len([for i in impacts if i.risk == "critical" {1}])
		high_risk_count:   len([for i in impacts if i.risk == "high" {1}])
	}

	// Overall risk assessment
	risk: {
		level: [
			if summary.critical_count > 0 {"critical"},
			if summary.high_risk_count > 0 {"high"},
			if summary.total_affected > 10 {"medium"},
			if summary.total_affected > 0 {"low"},
			"none",
		][0]

		// Resources to prioritize for review
		priority_review: [
			for i in impacts
			if i.risk == "critical" || i.risk == "high" {i.resource},
		]
	}

	// Generate markdown report
	_header: """
		# Impact Analysis Report

		**Organization**: \(Config.organization | *"N/A")
		**Environment**: \(Config.environment | *"N/A")
		**Changed Resources**: \(len(ChangedResources))

		---

		## Summary

		| Metric | Value |
		|--------|-------|
		| Resources Changed | \(summary.changed_count) |
		| Total Affected (unique) | \(summary.total_affected) |
		| Max Single Impact | \(summary.max_single_impact) |
		| Critical Impact Changes | \(summary.critical_count) |
		| High Risk Changes | \(summary.high_risk_count) |
		| **Overall Risk** | \(risk.level) |

		"""

	_impactDetails: strings.Join([
		for i in impacts {
			"""

			### \(i.resource)

			- **Depth**: Layer \(i.depth)
			- **Risk**: \(i.risk)
			- **Affected Count**: \(i.affected_count)
			- **Direct Dependents**: \(len(i.direct_dependents))

			**Affected Resources**:
			\(strings.Join([for a in i.affected {"- `\(a)`"}], "\n"))

			"""
		},
	], "\n")

	_prioritySection: [
		if len(risk.priority_review) > 0 {
			"""
			## Priority Review Required

			The following changed resources have high impact and require careful review:

			\(strings.Join([for p in risk.priority_review {"- `\(p)`"}], "\n"))

			"""
		},
		"",
	][0]

	markdown: strings.Join([_header, _prioritySection, _impactDetails], "\n")

	// JSON output
	json: {
		summary: summary
		risk:    risk
		impacts: impacts
	}
}

// #BlastRadiusReport - Detailed blast radius for a single resource
#BlastRadiusReport: {
	// Infrastructure graph
	Graph: {
		resources: [string]: {
			name: string
			"@type": {[string]: true}
			_depth:     int
			_ancestors: {[string]: bool}
			depends_on?: {[string]: true}
			...
		}
		topology: [string]: {[string]: true}
		...
	}

	// Target resource to analyze
	Target: string

	// Configuration
	Config?: {
		organization?: string
		environment?:  string
		...
	}

	// Target resource info
	_target: Graph.resources[Target]

	// All affected resources (transitively)
	affected: [
		for name, r in Graph.resources
		if r._ancestors[Target] != _|_ {name},
	]

	// Affected resources with depth info for ordering
	_affectedWithDepth: [
		for name in affected {
			name:  name
			depth: Graph.resources[name]._depth
		},
	]

	// Sorted by depth (deepest first for rollback)
	_sortedByDepth: list.Sort(_affectedWithDepth, {x: {}, y: {}, less: x.depth > y.depth})

	// Rollback order: affected resources deepest-first, then target
	rollback_order: list.Concat([[for r in _sortedByDepth {r.name}], [Target]])

	// Startup order: reverse of rollback
	startup_order: list.Reverse(rollback_order)

	// Find peers at same layer that are NOT affected (safe to leave running)
	_targetDepth: _target._depth
	_layerKey:    "layer_\(_targetDepth)"
	_sameLayer: [
		for name, _ in Graph.topology[_layerKey]
		if name != Target {name},
	]
	_affectedSet: {for a in affected {(a): true}}
	safe_peers: [
		for name in _sameLayer
		if _affectedSet[name] == _|_ {name},
	]

	// Affected by layer
	affected_by_layer: {
		for name in affected {
			"layer_\(Graph.resources[name]._depth)": (name): true
		}
	}

	// Summary
	summary: {
		target:          Target
		target_depth:    _targetDepth
		affected_count:  len(affected)
		layers_affected: len([for _, _ in affected_by_layer {1}])
		rollback_steps:  len(rollback_order)
		safe_peer_count: len(safe_peers)
	}

	// Risk assessment
	risk: {
		level: [
			if summary.affected_count > 20 {"critical"},
			if summary.affected_count > 10 {"high"},
			if summary.affected_count > 5 {"medium"},
			if summary.affected_count > 0 {"low"},
			"none",
		][0]

		// Cascade depth (how many layers deep does impact go)
		cascade_depth: [
			if len(affected) > 0 {
				list.Max([for a in _affectedWithDepth {a.depth}]) - _targetDepth
			},
			0,
		][0]
	}

	// Generate markdown
	_header: """
		# Blast Radius Analysis: \(Target)

		**Organization**: \(Config.organization | *"N/A")
		**Environment**: \(Config.environment | *"N/A")

		---

		## Summary

		| Metric | Value |
		|--------|-------|
		| Target Resource | `\(Target)` |
		| Target Layer | \(summary.target_depth) |
		| Affected Resources | \(summary.affected_count) |
		| Layers Affected | \(summary.layers_affected) |
		| Cascade Depth | \(risk.cascade_depth) |
		| **Risk Level** | \(risk.level) |

		"""

	_affectedSection: """
		## Affected Resources

		Total: \(len(affected)) resources will be impacted if `\(Target)` fails.

		\(strings.Join([for a in affected {"- `\(a)` (layer \(Graph.resources[a]._depth))"}], "\n"))

		"""

	_orderSection: """
		## Rollback Order

		If you need to rollback changes to `\(Target)`, stop resources in this order:

		\(strings.Join([for i, name in rollback_order {"\(i+1). `\(name)`"}], "\n"))

		## Startup Order

		To restart after maintenance, bring up resources in this order:

		\(strings.Join([for i, name in startup_order {"\(i+1). `\(name)`"}], "\n"))

		"""

	_safePeersSection: [
		if len(safe_peers) > 0 {
			"""
			## Safe Peers

			These resources are at the same layer as `\(Target)` but will NOT be affected:

			\(strings.Join([for p in safe_peers {"- `\(p)`"}], "\n"))

			"""
		},
		"",
	][0]

	markdown: strings.Join([_header, _affectedSection, _orderSection, _safePeersSection], "\n")

	// JSON output
	json: {
		target:          Target
		summary:         summary
		risk:            risk
		affected:        affected
		rollback_order:  rollback_order
		startup_order:   startup_order
		safe_peers:      safe_peers
		affected_by_layer: {
			for layer, members in affected_by_layer {
				(layer): [for m, _ in members {m}]
			}
		}
	}
}

// #CriticalityReport - Rank all resources by how many things depend on them
#CriticalityReport: {
	Graph: {
		resources: [string]: {
			name: string
			"@type": {[string]: true}
			_depth:     int
			_ancestors: {[string]: bool}
			...
		}
		...
	}

	Config?: {
		organization?: string
		environment?:  string
		...
	}

	// Calculate dependent count for each resource
	_ranked: [
		for name, r in Graph.resources {
			name:  name
			depth: r._depth
			types: r["@type"]
			dependents: len([
				for other, o in Graph.resources
				if o._ancestors[name] != _|_ {1},
			])
		},
	]

	// Sort by dependents descending
	ranked: list.Sort(_ranked, {x: {}, y: {}, less: x.dependents > y.dependents})

	// Categorize by criticality
	critical: [for r in ranked if r.dependents > 10 {r}]
	high:     [for r in ranked if r.dependents > 5 && r.dependents <= 10 {r}]
	medium:   [for r in ranked if r.dependents > 2 && r.dependents <= 5 {r}]
	low:      [for r in ranked if r.dependents > 0 && r.dependents <= 2 {r}]
	leaf:     [for r in ranked if r.dependents == 0 {r}]

	summary: {
		total:          len(ranked)
		critical_count: len(critical)
		high_count:     len(high)
		medium_count:   len(medium)
		low_count:      len(low)
		leaf_count:     len(leaf)
	}

	// Generate markdown
	markdown: """
		# Criticality Report

		**Organization**: \(Config.organization | *"N/A")
		**Environment**: \(Config.environment | *"N/A")

		---

		## Summary

		| Criticality | Count | Threshold |
		|-------------|-------|-----------|
		| Critical | \(summary.critical_count) | >10 dependents |
		| High | \(summary.high_count) | 6-10 dependents |
		| Medium | \(summary.medium_count) | 3-5 dependents |
		| Low | \(summary.low_count) | 1-2 dependents |
		| Leaf | \(summary.leaf_count) | 0 dependents |

		## Critical Resources

		These resources have the highest impact if they fail:

		\(strings.Join([for r in critical {"- `\(r.name)` - \(r.dependents) dependents"}], "\n"))

		## High Importance Resources

		\(strings.Join([for r in high {"- `\(r.name)` - \(r.dependents) dependents"}], "\n"))

		"""

	json: {
		summary:  summary
		ranked:   ranked
		critical: critical
		high:     high
	}
}
