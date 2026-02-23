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
#HydraContext: vocab.context["@context"] & {
	"hydra":        "http://www.w3.org/ns/hydra/core#"
	"rdfs":         "http://www.w3.org/2000/01/rdf-schema#"
	"rdf":          "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	"ActionResult": "quicue:ActionResult"
}

// #HydraOperation — a single executable operation on a resource.
#HydraOperation: {
	"@type":               "hydra:Operation"
	"hydra:method":        "GET"
	"hydra:title":         string
	"rdfs:comment":        string
	"hydra:returns":       "quicue:ActionResult"
	"quicue:provider":     string
	"quicue:action":       string
	"quicue:category":     string
	"quicue:idempotent":   bool | *false
	"quicue:destructive":  bool | *false
	"quicue:command"?:     string
}

// #HydraSupportedProperty — a property descriptor for a resource field.
#HydraSupportedProperty: {
	"@type":           "hydra:SupportedProperty"
	"hydra:property":  string | {...}
	"hydra:title":     string
	"hydra:required":  bool | *false
	"hydra:readable":  bool | *true
	"hydra:writeable": bool | *false
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
	"hydra:supportedProperty":     [...#HydraSupportedProperty]
}

// _apiBase — canonical prefix for dereferenceable resource URLs.
_apiBase: "https://api.quicue.ca/api/v1/resources/"

// #ApiDocumentation — generates Hydra JSON-LD from an #InteractionCtx.
// This is the top-level export — a complete, self-describing API surface.
#ApiDocumentation: {
	ctx: _   // receives the #InteractionCtx

	doc: {
		"@context": #HydraContext

		"@type":            "hydra:ApiDocumentation"
		"hydra:title":      "quicue-ou \(ctx.role_name) session"
		"hydra:entrypoint": "https://api.quicue.ca/api/v1/"
		"hydra:description": strings.Join([
			"Scoped API surface for role '\(ctx.role_name)'.",
			"Resources: \(ctx.total_resources).",
			"Actions: \(ctx.total_actions).",
		], " ")

		"hydra:supportedClass": [
			for rname, rv in ctx.view.resources {
				#HydraClass & {
					"@id":        "\(_apiBase)\(rname)"
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
						// Core fields: @type and name are required
						#HydraSupportedProperty & {
							"hydra:property": "quicue:type"
							"hydra:title":    "@type"
							"hydra:required": true
						},
						#HydraSupportedProperty & {
							"hydra:property": "quicue:name"
							"hydra:title":    "name"
							"hydra:required": true
						},
						// Resource-specific fields (skip internal/structural)
						for fname, _ in rv.resource
						if !strings.HasPrefix(fname, "_")
						if !strings.HasPrefix(fname, "@")
						if fname != "name" && fname != "depends_on" && fname != "actions" {
							#HydraSupportedProperty & {
								"hydra:property": "quicue:\(fname)"
								"hydra:title":    fname
							}
						},
						// Navigation links (depends_on → hydra:Link)
						if rv.resource.depends_on != _|_
						for dep, _ in rv.resource.depends_on
						if ctx.view.resources[dep] != _|_ {
							#HydraSupportedProperty & {
								"hydra:property": {
									"@type":      "hydra:Link"
									"@id":        "\(_apiBase)\(dep)"
									"rdfs:label": "depends on \(dep)"
								}
								"hydra:title": "depends_on/\(dep)"
							}
						},
					]
				}
			},
		]
	}
}

// #HydraEntryPoint — dereferenceable API root for generic Hydra clients.
// Serves as the "front door" — clients discover collections from here.
#HydraEntryPoint: {
	ctx: _

	entrypoint: {
		"@context": #HydraContext
		"@type":    "hydra:EntryPoint"
		"@id":      "https://api.quicue.ca/api/v1/"

		"hydra:collection": {
			"@id":   "https://api.quicue.ca/api/v1/resources"
			"@type": "hydra:Collection"
			"hydra:totalItems": ctx.total_resources
			"hydra:manages": {
				"hydra:property": "rdf:type"
				"hydra:object":   "quicue:Resource"
			}
		}
	}
}

// #HydraCollection — resource listing as hydra:Collection with hydra:member.
// Serves at /api/v1/resources — LDP-compatible container.
#HydraCollection: {
	ctx: _

	collection: {
		"@context":         #HydraContext
		"@type":            "hydra:Collection"
		"@id":              "https://api.quicue.ca/api/v1/resources"
		"hydra:totalItems": ctx.total_resources
		"hydra:member": [
			for rname, rv in ctx.view.resources {
				"@id":   "\(_apiBase)\(rname)"
				"@type": [ for t, _ in rv.resource."@type" {t}]
				"name": rname
			},
		]
	}
}

// Note: Hydra is wired into #InteractionCtx from interaction.cue
// where role, view, and summary are in scope for CUE cross-field references.
