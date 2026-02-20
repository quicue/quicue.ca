package vocab

// JSON-LD context for quicue semantic types
//
// The @context maps CUE field names to semantic IRIs, enabling:
// - SPARQL queries over infrastructure graphs
// - Integration with knowledge graphs and ontologies
// - Interoperability with semantic web tooling
//
// Export: cue export ./vocab -e context --out json > context.jsonld

context: {
	"@context": {
		// Base URI for resolving relative @id references in depends_on
		// Override this in your instance data for your domain
		"@base": "https://infra.example.com/resources/"

		// Namespace prefixes
		"quicue":  "https://quicue.ca/vocab#"
		"dcterms": "http://purl.org/dc/terms/"
		"prov":    "http://www.w3.org/ns/prov#"
		"dcat":    "http://www.w3.org/ns/dcat#"
		"as":      "https://www.w3.org/ns/activitystreams#"
		"oa":      "http://www.w3.org/ns/oa#"
		"sh":      "http://www.w3.org/ns/shacl#"
		"schema":  "https://schema.org/"
		"time":    "http://www.w3.org/2006/time#"
		"earl":    "http://www.w3.org/ns/earl#"
		"skos":    "http://www.w3.org/2004/02/skos/core#"

		// Map each semantic type to the vocabulary
		for typeName, _ in #TypeRegistry {
			(typeName): "quicue:\(typeName)"
		}

		// Resource fields (generic names)
		"name":         "quicue:name"
		"ip":           "quicue:ipAddress"
		"fqdn":         "quicue:fqdn"
		"ssh_user":     "quicue:sshUser"
		"host":         "quicue:host"
		"container_id": "quicue:containerId"
		"vm_id":        "quicue:vmId"
		"description":  "quicue:description"

		// Relationships — IRI references to other resources.
		// depends_on maps to dcterms:requires (ISO 15836-2:2019):
		//   "A requires B to support its function, delivery, or coherence."
		"depends_on": {
			"@id":   "dcterms:requires"
			"@type": "@id"
		}
		"hosted_on": {
			"@id":   "quicue:hostedOn"
			"@type": "@id"
		}

		// Lifecycle — schema:actionStatus (schema.org ActionStatusType)
		"status": {
			"@id":   "schema:actionStatus"
			"@type": "@id"
		}

		// Set containers for multi-valued properties
		"provides": {
			"@id":        "quicue:provides"
			"@container": "@set"
		}
		"tags": {
			"@id":        "quicue:tags"
			"@container": "@set"
		}
		"actions": {
			"@id":        "quicue:hasAction"
			"@container": "@set"
		}
	}
}
