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

		// Relationships - @type: @id means values are IRI references
		"depends_on": {
			"@id":   "quicue:dependsOn"
			"@type": "@id"
		}
		"hosted_on": {
			"@id":   "quicue:hostedOn"
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
