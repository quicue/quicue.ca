// RDF-Star (RDF 1.2) reification projection.
//
// Produces JSON-LD with @annotation blocks on dependency edges,
// allowing metadata (confidence, provenance, method) to be attached
// to individual dependency relationships.
//
// Classic RDF: "Server depends on Network" (flat assertion).
// RDF-Star: "Server depends on Network, AND that dependency has
//            confidence 0.95, discovered by nmap-scan on 2026-03-01."
//
// Usage:
//   import "quicue.ca/patterns"
//   rdf: patterns.#RDFStarAnnotation & {
//       Graph: _graph
//       Edges: { "server->network": { confidence: 0.95, source: "nmap" } }
//   }
//   // cue export -e rdf.annotated_graph --out json

package patterns

import "quicue.ca/vocab"

// #EdgeAnnotation — metadata to attach to a specific dependency edge.
#EdgeAnnotation: {
	confidence?: number & >=0 & <=1
	source?:     string
	timestamp?:  string
	method?:     string
	notes?:      string
}

// #AnnotationRule — rule-based annotation: match edges by source/target type.
#AnnotationRule: {
	name:          string
	source_types?: {[string]: true}
	target_types?: {[string]: true}
	annotation:    #EdgeAnnotation
}

// #RDFStarAnnotation — produce RDF-Star annotated JSON-LD from a graph.
//
// Two annotation modes:
//   1. Per-edge: Edges map with "source->target" keys
//   2. Rule-based: Rules list matching by @type on source/target
//
// Per-edge annotations take precedence over rule-based ones.
#RDFStarAnnotation: {
	Graph:   #InfraGraph
	BaseIRI: string | *"urn:resource:"

	// Per-edge overrides: "source->target" => annotation
	Edges: {[string]: #EdgeAnnotation} | *{}

	// Rule-based: match by type
	Rules: [...#AnnotationRule] | *[]

	// Pre-compute complete @annotation structs per edge key.
	// Only edges with at least one annotation field get an entry.
	//
	// Two separate comprehensions handle the two cases (per-edge vs
	// rule-only) to avoid referencing Edges[key] when key is absent.
	_edge_annotations: {
		// Case 1: edges with per-edge configuration
		for rname, res in Graph.resources
		if res.depends_on != _|_
		for dep, _ in res.depends_on
		if Edges[rname+"->"+dep] != _|_ {
			let _key = rname + "->" + dep
			let _e = Edges[_key]

			(_key): {
				if _e.confidence != _|_ {
					"quicue:confidence": _e.confidence
				}
				if _e.source != _|_ {
					"quicue:source": _e.source
				}
				if _e.timestamp != _|_ {
					"prov:generatedAtTime": _e.timestamp
				}
				if _e.method != _|_ {
					"quicue:method": _e.method
				}
				if _e.notes != _|_ {
					"rdfs:comment": _e.notes
				}
			}
		}

		// Case 2: edges matched only by rules (no per-edge config)
		for rname, res in Graph.resources
		if res.depends_on != _|_
		for dep, _ in res.depends_on
		if Edges[rname+"->"+dep] == _|_ {
			let _key = rname + "->" + dep

			let _rule_anns = [
				for rule in Rules
				let _src_ok = rule.source_types == _|_ || len([
					for t, _ in res["@type"]
					if rule.source_types[t] != _|_ {1}
				]) > 0
				let _tgt_ok = rule.target_types == _|_ || len([
					for t, _ in Graph.resources[dep]["@type"]
					if rule.target_types[t] != _|_ {1}
				]) > 0
				if _src_ok
				if _tgt_ok
				{rule.annotation}
			]

			if len(_rule_anns) > 0 {
				let _first = _rule_anns[0]
				(_key): {
					if _first.confidence != _|_ {
						"quicue:confidence": _first.confidence
					}
					if _first.source != _|_ {
						"quicue:source": _first.source
					}
					if _first.timestamp != _|_ {
						"prov:generatedAtTime": _first.timestamp
					}
					if _first.method != _|_ {
						"quicue:method": _first.method
					}
					if _first.notes != _|_ {
						"rdfs:comment": _first.notes
					}
				}
			}
		}
	}

	annotated_graph: {
		"@context": vocab.context["@context"] & {
			"quicue": "https://quicue.ca/vocab#"
			"rdfs":   "http://www.w3.org/2000/01/rdf-schema#"
		}
		"@graph": [
			for rname, res in Graph.resources {
				"@type": [for t, _ in res["@type"] {t}]
				"@id":   BaseIRI + rname
				"dcterms:title": res.name

				if res.depends_on != _|_ {
					"dcterms:requires": [
						for dep, _ in res.depends_on {
							let _key = rname + "->" + dep

							"@id": BaseIRI + dep

							if _edge_annotations[_key] != _|_ {
								"@annotation": _edge_annotations[_key]
							}
						},
					]
				}
			},
		]
	}

	summary: {
		total_resources: len([for r, _ in Graph.resources {r}])
		total_edges: len([
			for _, res in Graph.resources
			if res.depends_on != _|_
			for dep, _ in res.depends_on {1},
		])
		annotated_edges: len([for k, _ in _edge_annotations {k}])
		annotation_rules: len(Rules)
	}
}
