// LDES event stream — W3C Linked Data Event Streams via TREE specification.
//
// Each graph snapshot becomes an immutable event in an append-only stream.
// Consumers traverse TREE relations to sync state. Static JSON-LD files
// on any HTTP server — no streaming infrastructure needed.
//
// Usage:
//   import "quicue.ca/ou"
//   event: ou.#LDESEvent & {
//       Resources:     _resources
//       Timestamp:     "2026-02-18T12:00:00Z"
//       EventID:       "https://data.example.org/ldes/1708254000"
//       StreamID:      "https://data.example.org/ldes"
//   }
//   // cue export -e event.event --out json > ldes/1708254000.jsonld

package ou

import "quicue.ca/vocab"

// #LDESContext — extends quicue context with TREE and LDES namespaces.
#LDESContext: vocab.context["@context"] & {
	"tree": "https://w3id.org/tree#"
	"ldes": "https://w3id.org/ldes#"
	"dct":  "http://purl.org/dc/terms/"
	"xsd":  "http://www.w3.org/2001/XMLSchema#"
}

// #LDESEvent — a single LDES event page containing graph state.
#LDESEvent: {
	// Input resources (raw, before graph computation)
	Resources: [string]: {...}

	// Event metadata
	Timestamp:     string       // ISO 8601
	EventID:       string       // IRI for this event page
	StreamID:      string       // IRI for the stream root
	PreviousEvent: string | *"" // IRI of previous event (empty for first)

	event: {
		"@context": #LDESContext

		"@id":   EventID
		"@type": "tree:Node"

		// Link back to stream
		"tree:viewOf": {"@id": StreamID}

		// Relation to previous event (temporal navigation)
		if PreviousEvent != "" {
			"tree:relation": [{
				"@type": "tree:LessThanRelation"
				"tree:node": {"@id": PreviousEvent}
				"tree:path":  "dct:issued"
				"tree:value": Timestamp
			}]
		}

		// Members: each resource is a stream member
		"tree:member": [
			for rname, res in Resources {
				"@id":        "\(StreamID)/member/\(rname)"
				"@type":      "ldes:EventStreamMember"
				"dct:issued": Timestamp
				"ldes:object": {
					"@id":         rname
					"quicue:name": res.name
					if res["@type"] != _|_ {
						"@type": [for t, _ in res["@type"] {t}]
					}
					if res.ip != _|_ {
						"quicue:ipAddress": res.ip
					}
					if res.depends_on != _|_ {
						"quicue:dependsOn": [for d, _ in res.depends_on {d}]
					}
				}
			},
		]
	}
}

// #LDESStreamRoot — the root document for an LDES stream.
#LDESStreamRoot: {
	StreamID:    string
	Description: string | *"Infrastructure event stream"
	LatestEvent: string // IRI of most recent event page

	root: {
		"@context": #LDESContext
		"@id":      StreamID
		"@type":    "ldes:EventStream"

		"dct:title": Description
		"tree:view": {"@id": LatestEvent}
		"ldes:versionOfPath": "dct:isVersionOf"
		"ldes:timestampPath": "dct:issued"
	}
}
