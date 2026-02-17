// Hydra vocabulary — W3C Hydra JSON-LD generation from scoped views.
//
// Maps quicue concepts to Hydra Core Vocabulary:
//   #Resource @type   →  hydra:Class
//   #Action           →  hydra:Operation
//   depends_on        →  hydra:Link (navigation)
//   #InteractionCtx   →  hydra:ApiDocumentation (scoped)
//
// Extends the existing JSON-LD context from vocab/context.cue
// with the Hydra namespace.
//
// Usage:
//   session: ou.#InteractionCtx & { ... }
//   hydra_doc: session.hydra   // full Hydra ApiDocumentation

package ou

import (
	"strings"
	"quicue.ca/vocab"
)

// #HydraContext — extends the quicue JSON-LD context with Hydra namespace.
#HydraContext: vocab.context."@context" & {
	"hydra": "http://www.w3.org/ns/hydra/core#"
	"rdfs":  "http://www.w3.org/2000/01/rdf-schema#"
}

// #HydraOperation — a single executable operation on a resource.
#HydraOperation: {
	"@type":               "hydra:Operation"
	"hydra:method":        "POST"
	"hydra:title":         string
	"rdfs:comment":        string
	"quicue:provider":     string
	"quicue:action":       string
	"quicue:category":     string
	"quicue:idempotent":   bool | *false
	"quicue:destructive":  bool | *false
	"quicue:command"?:     string
}

// #HydraLink — a navigable relationship to another resource.
#HydraLink: {
	"hydra:property": {
		"@type":      "hydra:Link"
		"@id":        string
		"rdfs:label": string
	}
}

// #HydraClass — a resource with its operations and navigation links.
#HydraClass: {
	"@id":                         string
	"@type":                       "hydra:Class"
	"rdfs:label":                  string
	"hydra:supportedOperation":    [...#HydraOperation]
	"hydra:supportedProperty":     [...#HydraLink]
}

// #ApiDocumentation — generates Hydra JSON-LD from an #InteractionCtx.
// This is the top-level export — a complete, self-describing API surface.
#ApiDocumentation: {
	ctx: _   // receives the #InteractionCtx

	doc: {
		"@context": #HydraContext

		"@type":            "hydra:ApiDocumentation"
		"hydra:title":      "quicue-ou \(ctx.role_name) session"
		"hydra:entrypoint": "/api/v1/"
		"hydra:description": strings.Join([
			"Scoped API surface for role '\(ctx.role_name)'.",
			"Resources: \(ctx.total_resources).",
			"Actions: \(ctx.total_actions).",
		], " ")

		"hydra:supportedClass": [
			for rname, rv in ctx.view.resources {
				#HydraClass & {
					"@id":        "quicue:\(rname)"
					"@type":      "hydra:Class"
					"rdfs:label": rname

					"hydra:supportedOperation": [
						for pname, pactions in rv.actions
						for aname, act in pactions {
							#HydraOperation & {
								"hydra:title":        act.name
								"rdfs:comment":       act.description
								"quicue:provider":    pname
								"quicue:action":      aname
								"quicue:category":    act.category
								if act.idempotent != _|_ {
									"quicue:idempotent": act.idempotent
								}
								if act.destructive != _|_ {
									"quicue:destructive": act.destructive
								}
								if act.command != _|_ {
									"quicue:command": act.command
								}
							}
						},
					]

					"hydra:supportedProperty": [
						if rv.resource.depends_on != _|_
						for dep, _ in rv.resource.depends_on
						// Only link to resources visible in this scope
						if ctx.view.resources[dep] != _|_ {
							#HydraLink & {
								"hydra:property": {
									"@type":      "hydra:Link"
									"@id":        "quicue:\(dep)"
									"rdfs:label": "depends on \(dep)"
								}
							}
						},
					]
				}
			},
		]
	}
}

// Note: Hydra is wired into #InteractionCtx from interaction.cue
// where role, view, and summary are in scope for CUE cross-field references.
