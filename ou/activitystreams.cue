// ActivityStreams 2.0 — W3C activity vocabulary projection from operator sessions.
//
// Maps #InteractionCtx operations to AS2 activities, enabling
// infrastructure change feeds that tools can subscribe to.
// Each operation becomes an as:Activity with actor (operator role),
// object (resource), and instrument (provider/action).
//
// Usage:
//   session: ou.#InteractionCtx & { ... }
//   feed: ou.#ActivityStream & { ctx: session }
//   // cue export -e feed.stream --out json

package ou

import "quicue.ca/vocab"

// #ASContext — extends the quicue JSON-LD context with ActivityStreams namespace.
#ASContext: vocab.context."@context" & {
	"as":      "https://www.w3.org/ns/activitystreams#"
	"rdfs":    "http://www.w3.org/2000/01/rdf-schema#"
	"dcterms": "http://purl.org/dc/terms/"
}

// _categoryTypes — maps action categories to AS2 activity types.
_categoryTypes: {
	deploy:     "as:Create"
	lifecycle:  "as:Update"
	monitoring: "as:View"
	diagnostic: "as:View"
	shutdown:   "as:Delete"
}

// #ActivityStream — generates an AS2 OrderedCollection from an #InteractionCtx.
//
// The output is a JSON-LD activity feed where each visible operation
// becomes an activity. The operator role is the actor, the resource is
// the object, and the provider/action pair is the instrument.
#ActivityStream: {
	ctx: _   // receives the #InteractionCtx

	stream: {
		"@context": #ASContext

		"@type":         "as:OrderedCollection"
		"as:summary":    "\(ctx.summary.role_name) session — \(ctx.summary.total_resources) resources, \(ctx.summary.total_actions) actions"
		"as:totalItems": ctx.summary.total_actions
		"as:orderedItems": [
			for rname, rv in ctx.view.resources
			for pname, pactions in rv.actions
			for aname, act in pactions {
				// Map category to AS2 type via list-first-match
				let _type = [
					if act.destructive != _|_ if act.destructive {"as:Delete"},
					if act.category != _|_ if _categoryTypes[act.category] != _|_ {_categoryTypes[act.category]},
					"as:Activity",
				][0]

				"@type": _type
				"as:actor": {
					"@type":      "as:Application"
					"as:name":    ctx.summary.role_name
					"rdfs:label": "Operator role: \(ctx.summary.role_name)"
				}
				"as:object": {
					"@type":   "as:Object"
					"@id":     "quicue:\(rname)"
					"as:name": rname
				}
				"as:instrument": {
					"@type":   "as:Service"
					"as:name": "\(pname)/\(aname)"
					if act.command != _|_ {
						"as:url": act.command
					}
				}
				"as:summary": "\(ctx.summary.role_name) performs \(aname) on \(rname) via \(pname)"
			},
		]
	}
}
