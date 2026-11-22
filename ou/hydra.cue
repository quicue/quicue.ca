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
	"list"
	"strings"
	"quicue.ca/vocab"
)

// #HydraContext — extends the quicue JSON-LD context with Hydra namespace.
// @base is the API's resource prefix, not the vocabulary's example base
// (infra.example.com), so relative IRIs resolve on the host that serves them.
#HydraContext: {
	for k, v in vocab.context["@context"] if k != "@base" {(k): v}
	"@base": _apiBase
} & {
	"hydra":        "http://www.w3.org/ns/hydra/core#"
	"rdfs":         "http://www.w3.org/2000/01/rdf-schema#"
	"rdf":          "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	"ActionResult": "quicue:ActionResult"

	// Hydra terms whose values are IRIs. Without "@type": "@id" a JSON-LD
	// processor reads "quicue:ip" or "https://api.quicue.ca/api/v1/" as a
	// string literal, so hydra:property, hydra:entrypoint and the rest
	// pointed nowhere. These match the official Hydra context
	// (http://www.w3.org/ns/hydra/context.jsonld), inlined so the document
	// stays self-contained.
	"hydra:property":   {"@type": "@id"}
	"hydra:entrypoint": {"@type": "@id"}
	"hydra:returns":    {"@type": "@id"}
	"hydra:expects":    {"@type": "@id"}
	"hydra:object":     {"@type": "@id"}
	"hydra:subject":    {"@type": "@id"}
	"hydra:manages":    {"@type": "@id"}
}

// #HydraOperation — a single executable operation on a resource.
//
// Every action executes as POST /resources/{resource}/{provider}/{action}
// (server/app/routers/actions.py, patterns/openapi.cue), so the method is
// POST whatever the action does. Read-only versus destructive is carried
// by quicue:idempotent and quicue:destructive, not by the HTTP method.
#HydraOperation: {
	"@id"?:         string
	"@type":        "hydra:Operation"
	"hydra:method": "POST"
	"hydra:title":  string
	"rdfs:comment": string
	"hydra:returns": {"@id": "quicue:ActionResult"}
	"quicue:provider":    string
	"quicue:action":      string
	"quicue:category":    string
	"quicue:idempotent":  bool | *false
	"quicue:destructive": bool | *false
	// No quicue:command here. This document is published on public and
	// static hosts, and the commands carry ssh targets and credentials.
	// The FastAPI server adds each operation's command from its route
	// table in live mode only (server/app/routers/hydra.py).
}

// #HydraSupportedProperty — a property descriptor for a resource field.
#HydraSupportedProperty: {
	"@type": "hydra:SupportedProperty"
	"hydra:property": string | {...}
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

// #HydraClass — one class per resource type (quicue:Router, quicue:DNSServer).
// Operations do not hang off the class: each action is a hydra:Link
// property whose operation is executed against the link's target, the
// action endpoint /resources/{resource}/{provider}/{action}.
#HydraClass: {
	"@id":        string
	"@type":      "hydra:Class"
	"rdfs:label": string
	"hydra:supportedProperty": [...#HydraSupportedProperty]
}

// _apiBase — canonical prefix for dereferenceable resource URLs.
_apiBase: "https://api.quicue.ca/api/v1/resources/"

// _ctx — the vocabulary context, used to give each field the same property
// IRI in the documentation as it has in the data ("ip" is quicue:ipAddress,
// "name" is dcterms:title).
_ctx: vocab.context["@context"]

// #ActionProperty — the link property for one provider action (inputs _P, _A, _act).
// Its IRI is quicue:action/{provider}/{action}; a resource representation
// carries it with the action endpoint as the value.
#ActionProperty: {
	_P:   string
	_A:   string
	_act: _

	"@type":       "hydra:SupportedProperty"
	"hydra:title": "\(_P)/\(_A)"
	"hydra:required": false
	"hydra:readable": true
	"hydra:writeable": false
	"hydra:property": {
		"@id":         "quicue:action/\(_P)/\(_A)"
		"@type":       "hydra:Link"
		"rdfs:label":  _act.name
		"rdfs:comment": _act.description
		// The operation has its own IRI, so a property defined under two
		// classes (a resource that is both LXCContainer and ReverseProxy)
		// still describes one operation, not two blank-node copies.
		"hydra:supportedOperation": [#HydraOperation & {
			"@id":             "quicue:operation/\(_P)/\(_A)"
			"hydra:title":     _act.name
			"rdfs:comment":    _act.description
			"quicue:provider": _P
			"quicue:action":   _A
			"quicue:category": _act.category
			if _act.idempotent != _|_ {
				"quicue:idempotent": _act.idempotent
			}
			if _act.destructive != _|_ {
				"quicue:destructive": _act.destructive
			}
		}]
	}
}

// #ApiDocumentation — generates Hydra JSON-LD from an #InteractionCtx.
//
//   doc:             the hydra:ApiDocumentation (classes per type)
//   representations: one JSON-LD document per resource, with its fields,
//                    depends_on links and action links; served at
//                    /api/v1/resources/{name}
#ApiDocumentation: {
	ctx: _ // receives the #InteractionCtx

	let R = ctx.view.resources

	// type name → resource names of that type
	_byType: {
		for rname, rv in R
		for t, _ in rv.resource."@type" {
			(t): (rname): true
		}
	}

	// field name → property IRI, from the vocabulary context
	_fieldIRI: {
		for rname, rv in R
		for fname, _ in rv.resource
		if !strings.HasPrefix(fname, "_")
		if !strings.HasPrefix(fname, "@")
		if fname != "depends_on" && fname != "actions" {
			(fname): [
				if (_ctx[fname] & string) != _|_ {_ctx[fname]},
				if (_ctx[fname]["@id"] & string) != _|_ {_ctx[fname]["@id"]},
				"quicue:\(fname)",
			][0]
		}
	}

	// "provider/action" → the type whose class carries the full property
	// definition (the first, by name, of the types that have the action).
	// Other classes reference the property by IRI, so each definition and
	// its operation appear once.
	_actionHome: {
		let typesOf = {
			for t, members in _byType
			for rname, _ in members
			for pname, pactions in R[rname].actions
			for aname, _ in pactions {
				"\(pname)/\(aname)": (t): true
			}
		}
		for key, ts in typesOf {
			(key): list.SortStrings([for t, _ in ts {t}])[0]
		}
	}

	doc: {
		"@context": #HydraContext

		"@type":            "hydra:ApiDocumentation"
		"hydra:title":      "quicue-ou \(ctx.role_name) session"
		"hydra:entrypoint": "https://api.quicue.ca/api/v1/"
		"hydra:description": strings.Join([
			"Scoped API surface for role '\(ctx.role_name)'.",
			"Resources: \(ctx.total_resources).",
			"Actions: \(ctx.total_actions).",
			"Each resource type is a class; each action is a link property",
			"on the resource whose operation runs at the link target.",
		], " ")

		"hydra:supportedClass": [
			for t, members in _byType {
				#HydraClass & {
					"@id":        "quicue:\(t)"
					"rdfs:label": t

					// fields, actions: union over the members of this type,
					// all optional (hydra:required false) except @type and name
					let fields = {
						for rname, _ in members
						for fname, _ in R[rname].resource
						if _fieldIRI[fname] != _|_ {(fname): _fieldIRI[fname]}
					}
					// "provider/action" → the members that have it. The
					// definition comes from the first of them by name: each
					// member's act carries its own resolved command, so the
					// members cannot simply be unified.
					let holders = {
						for rname, _ in members
						for pname, pactions in R[rname].actions
						for aname, _ in pactions {
							"\(pname)/\(aname)": {P: pname, A: aname, names: (rname): true}
						}
					}
					let actions = {
						for key, h in holders {
							let first = list.SortStrings([for n, _ in h.names {n}])[0]
							(key): {P: h.P, A: h.A, act: R[first].actions[h.P][h.A]}
						}
					}
					let deps = [
						for rname, _ in members
						if R[rname].resource.depends_on != _|_
						if len(R[rname].resource.depends_on) > 0 {true},
					]

					"hydra:supportedProperty": [
						#HydraSupportedProperty & {
							"hydra:property": "rdf:type"
							"hydra:title":    "@type"
							"hydra:required": true
						},
						for fname, iri in fields {
							#HydraSupportedProperty & {
								"hydra:property": iri
								"hydra:title":    fname
								if fname == "name" {"hydra:required": true}
							}
						},
						if len(deps) > 0 {
							#HydraSupportedProperty & {
								"hydra:property": {
									"@id":        "dcterms:requires"
									"@type":      "hydra:Link"
									"rdfs:label": "depends on"
								}
								"hydra:title": "depends_on"
							}
						},
						for key, a in actions {
							if _actionHome[key] == t {
								#ActionProperty & {_P: a.P, _A: a.A, _act: a.act}
							}
							if _actionHome[key] != t {
								#HydraSupportedProperty & {
									"hydra:property": "quicue:action/\(key)"
									"hydra:title":    key
								}
							}
						},
					]
				}
			},
		]
	}

	representations: {
		for rname, rv in R {
			(rname): {
				"@context": #HydraContext
				"@id":      "\(_apiBase)\(rname)"
				"@type": [for t, _ in rv.resource."@type" {t}]
				for fname, _ in rv.resource
				if _fieldIRI[fname] != _|_ {
					(fname): rv.resource[fname]
				}
				if rv.resource.depends_on != _|_ {
					depends_on: [
						for dep, _ in rv.resource.depends_on
						if R[dep] != _|_ {"\(_apiBase)\(dep)"},
					]
				}
				for pname, pactions in rv.actions
				for aname, _ in pactions {
					"quicue:action/\(pname)/\(aname)": {"@id": "\(_apiBase)\(rname)/\(pname)/\(aname)"}
				}
			}
		}
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
			"@id":              "https://api.quicue.ca/api/v1/resources"
			"@type":            "hydra:Collection"
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
				"@id": "\(_apiBase)\(rname)"
				"@type": [for t, _ in rv.resource."@type" {t}]
				"name": rname
			},
		]
	}
}

// Note: Hydra is wired into #InteractionCtx from interaction.cue
// where role, view, and summary are in scope for CUE cross-field references.
