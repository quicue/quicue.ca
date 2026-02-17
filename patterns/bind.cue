// Action binding — resolve provider registries against concrete resources.
//
// CUE evaluates everything at compile time: if a from_field references
// a field that doesn't exist on the resource, cue vet catches it.
// No runtime, no string templates left unresolved.
//
// Usage:
//   import "quicue.ca/patterns@v0"
//
//   cluster: patterns.#BindCluster & {
//       resources: myResources
//       providers: {
//           vyos: {
//               types: {Router: true}
//               registry: vyos_patterns.#VyOSRegistry
//           }
//       }
//   }

package patterns

import (
	"strings"
	"quicue.ca/vocab"
)

// #ResolveTemplate — substitute {param} placeholders in a command template.
// All values must be strings. CUE evaluates this at compile time.
// Uses conditional list selection to produce a single concrete string.
#ResolveTemplate: {
	template: string
	values: {[string]: string}

	_pairs: [for k, v in values {{key: "{\(k)}", val: v}}]

	// Conditional replacement chain (handles up to 8 params).
	// Each step: if pair exists, replace; otherwise pass through.
	// List comprehension + [0] produces exactly one value (no disjunction).
	_r0: template
	_r1: [if len(_pairs) > 0 {strings.Replace(_r0, _pairs[0].key, _pairs[0].val, -1)}, if len(_pairs) <= 0 {_r0}][0]
	_r2: [if len(_pairs) > 1 {strings.Replace(_r1, _pairs[1].key, _pairs[1].val, -1)}, if len(_pairs) <= 1 {_r1}][0]
	_r3: [if len(_pairs) > 2 {strings.Replace(_r2, _pairs[2].key, _pairs[2].val, -1)}, if len(_pairs) <= 2 {_r2}][0]
	_r4: [if len(_pairs) > 3 {strings.Replace(_r3, _pairs[3].key, _pairs[3].val, -1)}, if len(_pairs) <= 3 {_r3}][0]
	_r5: [if len(_pairs) > 4 {strings.Replace(_r4, _pairs[4].key, _pairs[4].val, -1)}, if len(_pairs) <= 4 {_r4}][0]
	_r6: [if len(_pairs) > 5 {strings.Replace(_r5, _pairs[5].key, _pairs[5].val, -1)}, if len(_pairs) <= 5 {_r5}][0]
	_r7: [if len(_pairs) > 6 {strings.Replace(_r6, _pairs[6].key, _pairs[6].val, -1)}, if len(_pairs) <= 6 {_r6}][0]
	_r8: [if len(_pairs) > 7 {strings.Replace(_r7, _pairs[7].key, _pairs[7].val, -1)}, if len(_pairs) <= 7 {_r7}][0]

	result: _r8
}

// #BindActions — bind an #ActionDef registry against a resource.
// Produces concrete vocab.#Action entries for every action whose
// required params ALL resolve from resource fields. Optional params
// (required: false) use their default value when unresolvable.
// Strict: no unresolved placeholders survive.
#BindActions: {
	registry: {[string]: vocab.#ActionDef}
	resource: _

	actions: {
		for aname, adef in registry {
			// A param is "unresolvable" if it has no from_field OR the field
			// is missing on the resource, AND it has no default value.
			// Only required params without defaults block the action.
			let _missing = [
				for pname, pdef in adef.params
				if (pdef.from_field == _|_ || resource[pdef.from_field] == _|_) &&
					pdef.default == _|_ {pname},
			]

			// Only emit if ALL required params resolve
			if len(_missing) == 0 {
				let _values = {
					// Params that resolve from resource fields
					for pname, pdef in adef.params
					if pdef.from_field != _|_
					if resource[pdef.from_field] != _|_ {
						(pname): "\(resource[pdef.from_field])"
					}
				}
				let _defaults = {
					// Params that use default values (from_field absent or field missing)
					for pname, pdef in adef.params
					if pdef.default != _|_
					if pdef.from_field == _|_ || resource[pdef.from_field] == _|_ {
						(pname): pdef.default
					}
				}
				let _allValues = _values & _defaults

				let _resolved = (#ResolveTemplate & {
					template: adef.command_template
					values:   _allValues
				}).result

				(aname): vocab.#Action & {
					name:        adef.name
					description: adef.description
					command:     _resolved
					if adef.category != _|_ {
						category: adef.category
					}
					if adef.idempotent != _|_ {
						idempotent: adef.idempotent
					}
					if adef.destructive != _|_ {
						destructive: adef.destructive
					}
				}
			}
		}
	}
}

// #ProviderDecl — provider declaration for cluster binding.
// Each provider declares what @type values it serves and its action registry.
#ProviderDecl: {
	// Match if ANY of these types appears in the resource's @type
	types: {[string]: true}
	// The #ActionDef registry
	registry: {[string]: vocab.#ActionDef}
}

// #BindCluster — bind providers to resources by @type overlap.
// For each resource, finds matching providers and resolves all applicable actions.
#BindCluster: {
	resources: {[string]: _}
	providers: {[string]: #ProviderDecl}

	// Output: resources with resolved actions (namespaced by provider)
	bound: {
		for rname, resource in resources {
			(rname): resource & {
				actions: {
					for pname, provider in providers {
						// Check type overlap: any provider type in resource @type?
						let _matched = [
							for tname, _ in provider.types
							if resource["@type"][tname] != _|_ {tname},
						]

						if len(_matched) > 0 {
							(pname): (#BindActions & {
								"registry": provider.registry
								"resource": resource
							}).actions
						}
					}
				}
			}
		}
	}

	// Summary
	summary: {
		total_resources: len(resources)
		total_providers: len(providers)
		resolved_commands: len([
			for _, r in bound
			for _, pactions in r.actions
			for _, a in pactions
			if a.command != _|_ {1},
		])
	}
}
