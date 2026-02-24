// Interaction context — Layer 4 scoping over pre-computed execution data.
//
// Takes already-resolved bound resources and plan layers, then narrows
// by operator role, resource scope, and deployment flow position.
// CUE comprehensions do the filtering — no runtime logic.
//
// Usage:
//   import "quicue.ca/ou"
//   import "quicue.ca/patterns"
//
//   _plan: patterns.#ExecutionPlan & { resources: ..., providers: ... }
//
//   session: ou.#InteractionCtx & {
//       bound: _plan.cluster.bound
//       plan:  _plan.plan
//       role:  ou.#Roles.ops
//       scope: { include_types: { DNSServer: true } }
//   }
//   // session.view.resources  — filtered resources with filtered actions
//   // session.commands        — flat map of resource → provider.action → command

package ou

// #SessionScope — constrains which resources are visible.
// Absent fields mean no filtering on that dimension.
#SessionScope: {
	include_types?: {[string]: true}
	include_layers?: {[string]: true}
	include_names?: {[string]: true}
}

// #FlowPosition — where the operator is in the deployment sequence.
#FlowPosition: {
	current_layer: int | *0
	gates: {[string]: "passed" | "pending" | "failed"} | *{}
}

// _typeOverlap — checks if ANY key in filter appears in resource @type.
// Returns true if filter is absent (no constraint).
_typeOverlap: {
	filter: {...} | *{}
	types: {...}
	_hasFilter: bool
	_hasFilter: len(filter) > 0
	result:     bool
	if !_hasFilter {
		result: true
	}
	if _hasFilter {
		let _hits = [
			for t, _ in filter
			if types[t] != _|_ {true},
		]
		result: len(_hits) > 0
	}
}

// _scopeContains — checks if a key exists in a scope filter struct.
// Returns true if filter is absent (no constraint).
_scopeContains: {
	filter: {...} | *{}
	key:        string
	_hasFilter: bool
	_hasFilter: len(filter) > 0
	result:     bool
	if !_hasFilter {
		result: true
	}
	if _hasFilter {
		result: filter[key] != _|_
	}
}

// #InteractionCtx — the core Layer 4 schema.
//
// Accepts pre-computed bound resources and plan (not the full #ExecutionPlan)
// to avoid CUE's nested comprehension evaluation issue where concrete values
// vanish when a definition contains comprehensions over other comprehensions.
#InteractionCtx: {
	bound: {[string]: _}
	plan: {layers: [...], ...}
	role: #OperatorRole | *#Roles.ops
	scope: #SessionScope | *{}
	position: #FlowPosition | *{current_layer: 0, gates: {}}

	// Precompute: which resources appear in which layers
	_resourceLayers: {
		for l in plan.layers
		for rname in l.resources {
			(rname): "\(l.layer)"
		}
	}

	// view — the narrowed set of resources and actions
	view: {
		resources: {
			for rname, binding in bound

			// Scope: type filter
			let _typeOk = (_typeOverlap & {
				if scope.include_types != _|_ {
					filter: scope.include_types
				}
				types: binding["@type"]
			}).result

			// Scope: name filter
			let _nameOk = (_scopeContains & {
				if scope.include_names != _|_ {
					filter: scope.include_names
				}
				key: rname
			}).result

			// Scope: layer filter
			let _layerOk = (_scopeContains & {
				if scope.include_layers != _|_ {
					filter: scope.include_layers
				}
				key: [if _resourceLayers[rname] != _|_ {_resourceLayers[rname]}, ""][0]
			}).result

			if _typeOk && _nameOk && _layerOk {
				(rname): {
					resource: {
						name: binding.name
						if binding["@type"] != _|_ {
							"@type": binding["@type"]
						}
						if binding.ip != _|_ {
							ip: binding.ip
						}
						if binding.host != _|_ {
							host: binding.host
						}
						if binding.depends_on != _|_ {
							depends_on: binding.depends_on
						}
					}
					actions: {
						for pname, pactions in binding.actions {
							let _filtered = {
								for aname, act in pactions
								if act.category != _|_
								if role.visible_categories[act.category] != _|_ {
									(aname): act
								}
							}
							if len(_filtered) > 0 {
								(pname): _filtered
							}
						}
					}
				}
			}
		}
	}

	// commands — flat map for quick access
	commands: {
		for rname, rv in view.resources {
			(rname): {
				for pname, pactions in rv.actions {
					for aname, act in pactions
					if act.command != _|_ {
						let _key = pname + "/" + aname
						(_key): act.command
					}
				}
			}
		}
	}

	// summary
	summary: {
		total_resources: len(view.resources)
		total_actions: len([
			for _, rv in view.resources
			for _, pactions in rv.actions
			for _, act in pactions
			if act.command != _|_ {1},
		])
		role_name:     role.name
		current_layer: position.current_layer
	}
}
