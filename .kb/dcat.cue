// DCAT 3 projection — knowledge base manifest → W3C catalog.
//
// This is a unification side effect: evaluating the .kb/ package
// produces a valid DCAT 3 catalog as a computed field. Each semantic
// graph becomes a dcat:Dataset with dct:conformsTo linking to
// the W3C spec its entries natively export to.
//
// Export: cue export .kb/ -e dcat_catalog --out json > kb-dcat.jsonld
package kb

// W3C spec URLs for the semantic vocabularies our graphs map to.
_w3c_specs: {
	"prov:Activity":   "http://www.w3.org/TR/prov-o/"
	"skos:Concept":    "http://www.w3.org/TR/skos-reference/"
	"oa:Annotation":   "http://www.w3.org/TR/annotation-model/"
	"dcat:Dataset":    "http://www.w3.org/TR/vocab-dcat-3/"
	"sh:NodeShape":    "http://www.w3.org/TR/shacl/"
	"earl:Assertion":  "http://www.w3.org/TR/EARL10-Schema/"
	"prov:Derivation": "http://www.w3.org/TR/prov-o/"
}

_catalog_id:  "https://quicue.ca/kb"
_base_iri:    "\(_catalog_id)/"
_project_ctx: kb.context

dcat_catalog: {
	"@context": {
		"dcat":    "http://www.w3.org/ns/dcat#"
		"dct":     "http://purl.org/dc/terms/"
		"foaf":    "http://xmlns.com/foaf/0.1/"
		"prov":    "http://www.w3.org/ns/prov#"
		"skos":    "http://www.w3.org/2004/02/skos/core#"
		"oa":      "http://www.w3.org/ns/oa#"
		"schema":  "https://schema.org/"
		"dcterms": "http://purl.org/dc/terms/"
		"xsd":     "http://www.w3.org/2001/XMLSchema#"
	}
	"@id":   _catalog_id
	"@type": "dcat:Catalog"

	"dct:title":       "\(_project_ctx.name) Knowledge Base"
	"dct:description": _project_ctx.description
	"dct:conformsTo":  "http://www.w3.org/TR/vocab-dcat-3/"
	"dct:publisher": {
		"@type":     "foaf:Agent"
		"foaf:name": _project_ctx.name
	}
	if _project_ctx.license != _|_ {
		"dct:license": _project_ctx.license
	}
	if _project_ctx.repo != _|_ {
		"dcat:landingPage": _project_ctx.repo
	}

	// Each .kb/ graph → dcat:Dataset
	"dcat:dataset": [
		for gname, graph in kb.graphs {
			"@type":           "dcat:Dataset"
			"@id":             "\(_base_iri)\(graph.directory)"
			"dct:title":       gname
			"dct:identifier":  gname
			"dct:description": graph.description

			// W3C spec conformance from semantic mapping
			if _w3c_specs[graph.semantic] != _|_ {
				"dct:conformsTo": _w3c_specs[graph.semantic]
			}

			// Type tags: kg type + W3C vocabulary
			"dcat:keyword": [graph.kg_type, graph.semantic]

			// Distributions: CUE source + JSON-LD export
			"dcat:distribution": [
				{
					"@type":          "dcat:Distribution"
					"dcat:mediaType": "application/cue"
					"dct:title":      "\(gname) — CUE source"
					if _project_ctx.repo != _|_ {
						"dcat:accessURL": "\(_project_ctx.repo)/tree/main/.kb/\(graph.directory)"
					}
				},
				{
					"@type":          "dcat:Distribution"
					"dcat:mediaType": "application/ld+json"
					"dct:title":      "\(gname) — JSON-LD (\(graph.semantic))"
					if _w3c_specs[graph.semantic] != _|_ {
						"dct:conformsTo": {"@id": _w3c_specs[graph.semantic]}
					}
				},
			]
		},
	]

	// Downstream consumers → nested catalogs
	"dcat:catalog": [
		for dname, ds in downstream {
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
