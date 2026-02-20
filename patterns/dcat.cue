// DCAT 3 catalog projection — W3C Data Catalog Vocabulary from CUE graphs.
//
// Generates a dcat:Catalog with dcat:Dataset entries from #InfraGraph,
// enabling FAIR data discovery. DCAT 3 features used: DataService,
// DatasetSeries, version properties.
//
// Usage:
//   import "quicue.ca/patterns"
//   catalog: patterns.#DCAT3Catalog & {
//       Graph: _graph
//       CatalogID: "https://data.example.org/infra"
//       Publisher: "Example Infrastructure Team"
//   }
//   // cue export -e catalog.catalog --out json > dcat.jsonld

package patterns

import "quicue.ca/vocab"

// #DCATContext — extends quicue JSON-LD context with DCAT 3 + FOAF namespaces.
#DCATContext: vocab.context."@context" & {
	"dcat":  "http://www.w3.org/ns/dcat#"
	"dct":   "http://purl.org/dc/terms/"
	"foaf":  "http://xmlns.com/foaf/0.1/"
	"xsd":   "http://www.w3.org/2001/XMLSchema#"
	"rdfs":  "http://www.w3.org/2000/01/rdf-schema#"
	"vcard": "http://www.w3.org/2006/vcard/ns#"
}

// #DCAT3Catalog — generates a DCAT 3 catalog from an #InfraGraph.
#DCAT3Catalog: {
	// Input: computed graph (provides .resources, .topology, etc.)
	Graph: #InfraGraph

	// Catalog metadata
	CatalogID:   string | *"https://quicue.ca/catalog"
	Publisher:    string | *"quicue"
	Title:       string | *"Infrastructure Catalog"
	Description: string | *"DCAT 3 catalog of infrastructure resources"
	Version:     string | *"1.0.0"
	BaseIRI:     string | *"https://quicue.ca/dataset/"

	// Optional: SPARQL endpoint URL
	SPARQLEndpoint?: string
	// Optional: LDES stream URL
	LDESEndpoint?: string

	// Computed: resource list from graph input
	_res: Graph.Input

	catalog: {
		"@context": #DCATContext
		"@id":      CatalogID
		"@type":    "dcat:Catalog"

		"dct:title":       Title
		"dct:description": Description
		"dct:publisher": {
			"@type":     "foaf:Agent"
			"foaf:name": Publisher
		}
		"dcat:version": Version

		// Each resource becomes a dcat:Dataset
		"dcat:dataset": [
			for rname, res in _res {
				"@type":          "dcat:Dataset"
				"@id":            "\(BaseIRI)\(rname)"
				"dct:title":      res.name
				"dct:identifier": rname
				if res.description != _|_ {
					"dct:description": res.description
				}
				if res["@type"] != _|_ {
					"dcat:keyword": [for t, _ in res["@type"] {t}]
				}
				if res.depends_on != _|_ {
					"dct:relation": [for d, _ in res.depends_on {
						"@id": "\(BaseIRI)\(d)"
					}]
				}
			},
		]

		// DataService entries (SPARQL, LDES)
		if SPARQLEndpoint != _|_ {
			"dcat:service": [
				{
					"@type":            "dcat:DataService"
					"@id":              "\(CatalogID)/sparql"
					"dct:title":        "SPARQL Endpoint"
					"dcat:endpointURL": SPARQLEndpoint
					"dct:conformsTo":   "https://www.w3.org/TR/sparql11-query/"
					"dcat:servesDataset": {"@id": CatalogID}
				},
				if LDESEndpoint != _|_ {
					{
						"@type":            "dcat:DataService"
						"@id":              "\(CatalogID)/ldes"
						"dct:title":        "LDES Event Stream"
						"dcat:endpointURL": LDESEndpoint
						"dct:conformsTo":   "https://w3id.org/ldes/specification"
						"dcat:servesDataset": {"@id": CatalogID}
					}
				},
			]
		}
	}
}
