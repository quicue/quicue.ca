// DCAT 3 catalog projection — W3C Data Catalog Vocabulary from CUE graphs.
//
// Two projections:
//   #DCAT3Catalog     — infrastructure resources → dcat:Dataset entries
//   #DCATKnowledgeBase — .kb/ manifest → dcat:Catalog with W3C-typed datasets
//
// The knowledge base projection leverages the full W3C stack:
//   decisions → prov:Activity (PROV-O)
//   patterns  → skos:Concept (SKOS)
//   insights  → oa:Annotation (Web Annotations)
//   rejected  → prov:Activity (PROV-O)
//
// Usage:
//   import "quicue.ca/patterns"
//
//   // Infrastructure resources:
//   catalog: patterns.#DCAT3Catalog & {
//       Graph: _graph
//       CatalogID: "https://data.example.org/infra"
//       Publisher: "Example Infrastructure Team"
//   }
//
//   // Knowledge base:
//   kb_catalog: patterns.#DCATKnowledgeBase & {
//       Manifest: _kb_manifest
//       CatalogID: "https://data.example.org/kb"
//   }

package patterns

import "quicue.ca/vocab"

// #DCATContext — extends quicue JSON-LD context with DCAT 3, FOAF,
// PROV-O, SKOS, and Web Annotation namespaces for full W3C interop.
#DCATContext: vocab.context."@context" & {
	"dcat":  "http://www.w3.org/ns/dcat#"
	"dct":   "http://purl.org/dc/terms/"
	"foaf":  "http://xmlns.com/foaf/0.1/"
	"xsd":   "http://www.w3.org/2001/XMLSchema#"
	"rdfs":  "http://www.w3.org/2000/01/rdf-schema#"
	"vcard": "http://www.w3.org/2006/vcard/ns#"
	"oa":    "http://www.w3.org/ns/oa#"
}

// _#W3CSpecMap — canonical spec URLs for semantic vocabulary references.
// Used by #DCATKnowledgeBase to set dct:conformsTo on each dataset.
_#W3CSpecMap: {
	"prov:Activity":   "http://www.w3.org/TR/prov-o/"
	"skos:Concept":    "http://www.w3.org/TR/skos-reference/"
	"oa:Annotation":   "http://www.w3.org/TR/annotation-model/"
	"dcat:Dataset":    "http://www.w3.org/TR/vocab-dcat-3/"
	"sh:NodeShape":    "http://www.w3.org/TR/shacl/"
	"earl:Assertion":  "http://www.w3.org/TR/EARL10-Schema/"
	"prov:Derivation": "http://www.w3.org/TR/prov-o/"
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

// #DCATKnowledgeBase — projects a .kb/ manifest into a DCAT 3 catalog.
//
// Each semantic graph (decisions, patterns, insights, rejected) becomes a
// dcat:Dataset with dct:conformsTo linking to the W3C spec its entries
// natively export to. Distributions declare available export formats.
//
// Uses structural typing — accepts any struct matching .kb/ manifest shape
// without importing quicue.ca/kg. The patterns package stays independent.
//
// Usage:
//   kb_catalog: patterns.#DCATKnowledgeBase & {
//       Manifest: {
//           context: { name: "my-project", description: "...", module: "...", repo: "..." }
//           graphs: {
//               decisions: { kg_type: "core.#Decision", semantic: "prov:Activity", description: "...", directory: "decisions" }
//               patterns:  { kg_type: "core.#Pattern",  semantic: "skos:Concept",  description: "...", directory: "patterns" }
//           }
//       }
//   }
#DCATKnowledgeBase: {
	// Manifest: structural match for ext.#KnowledgeBase (no kg import needed)
	Manifest: {
		context: {
			name:        string
			description: string
			module:      string
			repo?:       string
			license?:    string
			status?:     string
			...
		}
		graphs: {[string]: {
			kg_type:     string
			semantic:    string
			description: string
			directory:   string
			status?:     string
			...
		}}
		...
	}

	// Optional: downstream consumers as nested catalogs
	Downstream?: {[string]: {
		"@id"?:      string
		module?:     string
		description: string
		has_kb?:     bool
		...
	}}

	// Catalog metadata
	CatalogID:   string | *"https://quicue.ca/kb"
	Publisher:    string | *Manifest.context.name
	Title:       string | *"\(Manifest.context.name) Knowledge Base"
	Description: string | *Manifest.context.description
	License?:    string
	BaseIRI:     string | *"\(CatalogID)/"

	// Computed: resolve license from manifest if not overridden
	_license: string | *""
	if Manifest.context.license != _|_ {
		_license: Manifest.context.license
	}
	if License != _|_ {
		_license: License
	}

	catalog: {
		"@context": #DCATContext & {
			"oa": "http://www.w3.org/ns/oa#"
		}
		"@id":   CatalogID
		"@type": "dcat:Catalog"

		"dct:title":       Title
		"dct:description": Description
		"dct:publisher": {
			"@type":     "foaf:Agent"
			"foaf:name": Publisher
		}
		"dct:conformsTo": "http://www.w3.org/TR/vocab-dcat-3/"

		if Manifest.context.repo != _|_ {
			"dcat:landingPage": Manifest.context.repo
		}
		if _license != "" {
			"dct:license": _license
		}

		// Each .kb/ graph → dcat:Dataset
		"dcat:dataset": [
			for gname, graph in Manifest.graphs {
				"@type":          "dcat:Dataset"
				"@id":            "\(BaseIRI)\(graph.directory)"
				"dct:title":      "\(gname) — \(graph.semantic)"
				"dct:identifier": gname
				"dct:description": graph.description

				// W3C spec conformance from semantic mapping
				if _#W3CSpecMap[graph.semantic] != _|_ {
					"dct:conformsTo": _#W3CSpecMap[graph.semantic]
				}

				// Type classification
				"dcat:keyword": [graph.kg_type, graph.semantic]

				// Available distributions (CUE source + JSON-LD export)
				"dcat:distribution": [
					{
						"@type":          "dcat:Distribution"
						"dcat:mediaType": "application/cue"
						"dct:title":      "\(gname) — CUE source"
						if Manifest.context.repo != _|_ {
							"dcat:accessURL": "\(Manifest.context.repo)/tree/main/.kb/\(graph.directory)"
						}
					},
					{
						"@type":          "dcat:Distribution"
						"dcat:mediaType": "application/ld+json"
						"dct:title":      "\(gname) — JSON-LD (\(graph.semantic))"
						"dct:conformsTo": {
							if _#W3CSpecMap[graph.semantic] != _|_ {
								"@id": _#W3CSpecMap[graph.semantic]
							}
						}
					},
				]

			},
		]

		// Downstream consumers as nested catalogs
		if Downstream != _|_ {
			"dcat:catalog": [
				for dname, ds in Downstream {
					"@type":           "dcat:Catalog"
					"dct:title":       dname
					"dct:description": ds.description
					if ds["@id"] != _|_ {
						"@id": ds["@id"]
					}
					if ds.module != _|_ {
						"dct:identifier": ds.module
					}
					if ds.has_kb != _|_ if ds.has_kb {
						"dcat:keyword": ["has-knowledge-base"]
					}
				},
			]
		}
	}
}
