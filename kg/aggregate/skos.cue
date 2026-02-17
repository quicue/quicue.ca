// SKOS — Simple Knowledge Organization System projection for patterns.
//
// Maps #Pattern categories to skos:ConceptScheme and individual patterns
// to skos:Concept with skos:broader/narrower relationships. Produces a
// browsable taxonomy of the project's pattern language.
//
// Compatible with the existing SKOS taxonomy in infra-ontology/skos.ttl.
//
// Usage (from .kg/index.cue):
//   _index: aggregate.#KGIndex & { ... }
//   taxonomy: aggregate.#SKOSTaxonomy & { index: _index }
//   // cue export . -e taxonomy.graph --out json

package aggregate

import "strings"

#SKOSContext: {
	"skos":    "http://www.w3.org/2004/02/skos/core#"
	"dcterms": "http://purl.org/dc/terms/"
	"rdfs":    "http://www.w3.org/2000/01/rdf-schema#"
	"kg":      "https://quicue.ca/kg#"
}

#SKOSTaxonomy: {
	index: #KGIndex

	// Group patterns by category
	_categories: {for _, p in index.patterns {(p.category): true}}

	graph: {
		"@context": #SKOSContext

		"@graph": [
			// The concept scheme itself
			{
				"@id":                "kg:\(index.project)/patterns"
				"@type":              "skos:ConceptScheme"
				"dcterms:title":      "\(index.project) Pattern Language"
				"skos:hasTopConcept": [for cat, _ in _categories {{"@id": "kg:\(index.project)/category/\(cat)"}}]
			},

			// Categories as top concepts
			for cat, _ in _categories {
				"@id":   "kg:\(index.project)/category/\(cat)"
				"@type": "skos:Concept"
				"skos:prefLabel":    cat
				"skos:inScheme":     {"@id": "kg:\(index.project)/patterns"}
				"skos:topConceptOf": {"@id": "kg:\(index.project)/patterns"}
				"skos:narrower": [
					for pid, p in index.patterns if p.category == cat {
						{"@id": "kg:\(pid)"}
					},
				]
			},

			// Individual patterns as concepts
			for id, p in index.patterns {
				"@id":   "kg:\(id)"
				"@type": "skos:Concept"
				"skos:prefLabel":  p.name
				"skos:definition": p.problem
				"skos:note":       p.solution
				"skos:broader":    {"@id": "kg:\(index.project)/category/\(p.category)"}
				"skos:inScheme":   {"@id": "kg:\(index.project)/patterns"}
				if p.related != _|_ {
					"skos:related": [for rel, _ in p.related {{"@id": "kg:\(rel)"}}]
				}
				"kg:usedIn": [for proj, _ in p.used_in {proj}]
			},
		]
	}

	// Turtle export for compatibility with infra-ontology/skos.ttl
	turtle: strings.Join([
		"@prefix skos: <http://www.w3.org/2004/02/skos/core#> .",
		"@prefix dcterms: <http://purl.org/dc/terms/> .",
		"@prefix kg: <https://quicue.ca/kg#> .",
		"",
		"kg:\(index.project)/patterns a skos:ConceptScheme ;",
		"    dcterms:title \"\(index.project) Pattern Language\" .",
		"",
		for cat, _ in _categories {
			"""
			kg:\(index.project)/category/\(cat) a skos:Concept ;
			    skos:prefLabel "\(cat)" ;
			    skos:inScheme kg:\(index.project)/patterns ;
			    skos:topConceptOf kg:\(index.project)/patterns .
			"""
		},
		"",
		for id, p in index.patterns {
			"""
			kg:\(id) a skos:Concept ;
			    skos:prefLabel "\(p.name)" ;
			    skos:definition "\(p.problem)" ;
			    skos:broader kg:\(index.project)/category/\(p.category) ;
			    skos:inScheme kg:\(index.project)/patterns .
			"""
		},
	], "\n")

	summary: {
		total_concepts:  len(index.patterns) + len(_categories)
		total_categories: len(_categories)
		total_patterns:   len(index.patterns)
	}
}
