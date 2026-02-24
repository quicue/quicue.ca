// SHACL shape generation — W3C Shapes Constraint Language from CUE definitions.
//
// Generates sh:NodeShape descriptions from #Resource and #TypeRegistry,
// mapping CUE constraints to SHACL property shapes. This is a static
// description of what valid infrastructure data looks like in RDF terms —
// CUE does the actual validation at compile time.
//
// Usage:
//   import "quicue.ca/patterns"
//   shapes: patterns.#SHACLShapes & { resources: _myResources }
//   // cue export -e shapes.graph --out json > shapes.jsonld

package patterns

import "quicue.ca/vocab"

// #SHACLContext — extends the quicue JSON-LD context with SHACL namespace.
#SHACLContext: vocab.context["@context"] & {
	"sh":      "http://www.w3.org/ns/shacl#"
	"rdfs":    "http://www.w3.org/2000/01/rdf-schema#"
	"dcterms": "http://purl.org/dc/terms/"
	"xsd":     "http://www.w3.org/2001/XMLSchema#"
}

// #SHACLPropertyShape — a single property constraint.
#SHACLPropertyShape: {
	"sh:path":      string
	"sh:name":      string
	"sh:datatype"?: string
	"sh:nodeKind"?: string
	"sh:minCount"?: int
	"sh:maxCount"?: int
	"sh:pattern"?:  string
	"sh:in"?: [...string]
	"rdfs:comment"?: string
}

// #SHACLNodeShape — a complete shape for a resource type.
#SHACLNodeShape: {
	"@id":            string
	"@type":          "sh:NodeShape"
	"sh:targetClass": string
	"rdfs:label":     string
	"rdfs:comment"?:  string
	"sh:property": [...#SHACLPropertyShape]
}

// #SHACLShapes — generates SHACL shapes from the quicue vocabulary.
//
// The output is a JSON-LD graph of sh:NodeShape resources that describe
// what a valid #Resource looks like when serialized as RDF.
#SHACLShapes: {
	resources?: _

	graph: {
		"@context": #SHACLContext

		"@graph": [{
			"@id":            "quicue:ResourceShape"
			"@type":          "sh:NodeShape"
			"sh:targetClass": "quicue:Resource"
			"rdfs:label":     "Infrastructure Resource"
			"rdfs:comment":   "Shape constraint for quicue #Resource — validates RDF serializations of infrastructure resources."
			"sh:property": [
				{
					"sh:path":      "quicue:name"
					"sh:name":      "name"
					"sh:datatype":  "xsd:string"
					"sh:minCount":  1
					"sh:maxCount":  1
					"rdfs:comment": "Resource identifier, unique within the graph"
				},
				{
					"sh:path":      "quicue:ipAddress"
					"sh:name":      "ip"
					"sh:datatype":  "xsd:string"
					"sh:maxCount":  1
					"sh:pattern":   "^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$"
					"rdfs:comment": "IPv4 address"
				},
				{
					"sh:path":      "quicue:fqdn"
					"sh:name":      "fqdn"
					"sh:datatype":  "xsd:string"
					"sh:maxCount":  1
					"rdfs:comment": "Fully qualified domain name"
				},
				{
					"sh:path":      "quicue:host"
					"sh:name":      "host"
					"sh:datatype":  "xsd:string"
					"sh:maxCount":  1
					"rdfs:comment": "Hypervisor or host node name"
				},
				{
					"sh:path":      "quicue:containerId"
					"sh:name":      "container_id"
					"sh:maxCount":  1
					"rdfs:comment": "Container identifier (LXC ID, Docker name)"
				},
				{
					"sh:path":      "quicue:vmId"
					"sh:name":      "vm_id"
					"sh:maxCount":  1
					"rdfs:comment": "Virtual machine identifier"
				},
				{
					"sh:path":      "quicue:hostedOn"
					"sh:name":      "hosted_on"
					"sh:nodeKind":  "sh:IRI"
					"sh:maxCount":  1
					"rdfs:comment": "Parent resource (IRI reference)"
				},
				{
					"sh:path":      "quicue:dependsOn"
					"sh:name":      "depends_on"
					"sh:nodeKind":  "sh:IRI"
					"rdfs:comment": "Dependency targets (IRI references, set-valued)"
				},
				{
					"sh:path":      "quicue:sshUser"
					"sh:name":      "ssh_user"
					"sh:datatype":  "xsd:string"
					"sh:maxCount":  1
					"rdfs:comment": "SSH username for remote access"
				},
				{
					"sh:path":      "quicue:provides"
					"sh:name":      "provides"
					"sh:datatype":  "xsd:string"
					"rdfs:comment": "Capabilities this resource provides (set-valued)"
				},
				{
					"sh:path":      "quicue:tags"
					"sh:name":      "tags"
					"sh:datatype":  "xsd:string"
					"rdfs:comment": "Metadata tags (set-valued)"
				},
				{
					"sh:path":      "dcterms:description"
					"sh:name":      "description"
					"sh:datatype":  "xsd:string"
					"sh:maxCount":  1
					"rdfs:comment": "Human-readable resource description"
				},
			]
		},
			// Type shapes — one per registered type
			for typeName, _ in vocab.#TypeRegistry {{
				"@id":            "quicue:\(typeName)Shape"
				"@type":          "sh:NodeShape"
				"sh:targetClass": "quicue:\(typeName)"
				"rdfs:label":     "\(typeName) Resource"
				"sh:property": [{
					"sh:path":      "rdf:type"
					"sh:hasValue":  "quicue:\(typeName)"
					"rdfs:comment": "Must declare @type \(typeName)"
				}]
			}},
		]
	}
}
