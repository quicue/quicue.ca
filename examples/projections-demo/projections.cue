// projections-demo: context events, form projection, and RDF-Star
// on a small graph (6 nodes) where CUE evaluation completes in seconds.
//
// These three projections were removed from the 30-node datacenter example
// because CUE's non-memoizing evaluation makes bulk export infeasible at
// that scale. This example proves the patterns work.
//
// Run:
//   cue vet  ./examples/projections-demo/
//   cue eval ./examples/projections-demo/ -e context_events.summary
//   cue eval ./examples/projections-demo/ -e form_projection.summary
//   cue eval ./examples/projections-demo/ -e rdf_star.summary
//   cue export ./examples/projections-demo/ -e context_events --out json
//   cue export ./examples/projections-demo/ -e form_projection --out json
//   cue export ./examples/projections-demo/ -e rdf_star --out json

package main

import (
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
	apercue_vocab "apercue.ca/vocab@v0"
	apercue_patterns "apercue.ca/patterns@v0"
)

// 6-node web stack
_resources: {
	"lb": {
		name:    "lb"
		"@type": {LoadBalancer: true}
	}
	"web-1": {
		name:       "web-1"
		"@type":    {WebServer: true}
		depends_on: {"lb": true}
	}
	"web-2": {
		name:       "web-2"
		"@type":    {WebServer: true}
		depends_on: {"lb": true}
	}
	"api": {
		name:       "api"
		"@type":    {APIServer: true}
		depends_on: {"web-1": true, "web-2": true}
	}
	"db": {
		name:       "db"
		"@type":    {Database: true}
		depends_on: {"api": true}
	}
	"cache": {
		name:       "cache"
		"@type":    {Cache: true}
		depends_on: {"api": true}
	}
}

infra: patterns.#InfraGraph & {Input: _resources}

// ==========================================================================
// CONTEXT EVENT LOG (federation audit trail)
// ==========================================================================
//
// Maps context events to PROV-O activities with OWL-Time instants.

_events: [...apercue_vocab.#ContextEvent] & [
	{
		timestamp:     "2026-03-01T09:00:00Z"
		type:          "merge"
		source_domain: "monitoring"
		target_domain: "web-stack"
		resources:     ["lb", "web-1", "web-2"]
		outcome:       "success"
		description:   "Monitoring graph merged into web stack model"
	},
	{
		timestamp:     "2026-03-01T10:30:00Z"
		type:          "validate"
		source_domain: "web-stack"
		target_domain: "compliance"
		resources:     ["db", "cache"]
		outcome:       "success"
		description:   "Data-tier resources validated against compliance rules"
	},
	{
		timestamp:     "2026-03-02T14:00:00Z"
		type:          "export"
		source_domain: "web-stack"
		target_domain: "catalog"
		resources:     ["lb", "api"]
		outcome:       "success"
		description:   "Frontend resources exported to DCAT catalog"
	},
]

_event_log: apercue_patterns.#ContextEventLog & {
	Events: _events
	Agent:  "urn:agent:web-stack-controller"
}
context_events: _event_log.event_report

// ==========================================================================
// FORM PROJECTION (UI form definitions from type registry)
// ==========================================================================

_forms: apercue_patterns.#FormProjection & {
	Types: vocab.#TypeRegistry
}
form_projection: _forms.form_definitions

// ==========================================================================
// RDF-STAR ANNOTATION (metadata on dependency edges)
// ==========================================================================

_rdf_star: patterns.#RDFStarAnnotation & {
	Graph:   infra
	BaseIRI: "urn:web-stack:"
	Edges: {
		"web-1->lb": {
			confidence: 0.99
			source:     "health-check"
			timestamp:  "2026-03-01T09:00:00Z"
			method:     "HTTP GET /healthz"
		}
		"db->api": {
			confidence: 0.95
			source:     "connection-pool"
			timestamp:  "2026-03-01T10:00:00Z"
		}
	}
}
rdf_star: _rdf_star.annotated_graph

// Summary
summary: {
	resources:       len([for k, _ in _resources {k}])
	context_events:  _event_log.summary
	form_types:      _forms.summary
	rdf_annotations: _rdf_star.summary
}
