// DCAT — W3C Data Catalog Vocabulary projection from knowledge graph metadata.
//
// Maps ext.#Context to dcat:Dataset and federation results to dcat:Catalog.
// Each .kg/-bearing project becomes a cataloged dataset with distributions
// for the CUE source and JSON-LD export formats.
//
// Usage (from .kg/index.cue):
//   _index: aggregate.#KGIndex & { ... }
//   catalog: aggregate.#DatasetEntry & { index: _index, context: project }
//   // cue export . -e catalog.dataset --out json

package aggregate

import "quicue.ca/kg/ext@v0"

// #DCATContext — JSON-LD context for catalog exports.
#DCATContext: {
	"dcat":    "http://www.w3.org/ns/dcat#"
	"dcterms": "http://purl.org/dc/terms/"
	"foaf":    "http://xmlns.com/foaf/0.1/"
	"rdfs":    "http://www.w3.org/2000/01/rdf-schema#"
	"kg":      "https://quicue.ca/kg#"
}

// #DatasetEntry — generates a dcat:Dataset from a single project's KG.
#DatasetEntry: {
	index:   #KGIndex
	context: ext.#Context

	dataset: {
		"@context": #DCATContext

		"@id":   [if context["@id"] != _|_ {context["@id"]}, "kg:\(index.project)"][0]
		"@type": "dcat:Dataset"

		"dcterms:title":       context.name
		"dcterms:description": context.description
		if context.license != _|_ {
			"dcterms:license": context.license
		}

		"kg:status":  context.status
		"kg:entries": index.summary.total

		// Distribution: CUE source (the .kg/ directory)
		"dcat:distribution": [
			{
				"@type":          "dcat:Distribution"
				"dcterms:title":  "CUE source"
				"dcat:mediaType": "text/plain" // CUE source; no IANA-registered media type yet
				if context.module != _|_ {
					"dcterms:identifier": context.module
				}
			},
			{
				"@type":          "dcat:Distribution"
				"dcterms:title":  "JSON-LD export"
				"dcat:mediaType": "application/ld+json"
			},
		]

		// What this project knows about
		if context.uses != _|_ {
			"dcat:theme": [for u in context.uses {u}]
		}
	}
}

// #FederatedCatalog — aggregates multiple #DatasetEntry into a dcat:Catalog.
// Used by `kg fed` to produce a federated catalog of all .kg/ projects.
#FederatedCatalog: {
	datasets: [...{...}]

	catalog: {
		"@context": #DCATContext

		"@type":              "dcat:Catalog"
		"dcterms:title":      "quicue Knowledge Graph Federation"
		"dcterms:description": "Federated catalog of CUE-native knowledge graphs"
		"dcat:dataset":       datasets
	}

	summary: {
		total_datasets: len(datasets)
	}
}
