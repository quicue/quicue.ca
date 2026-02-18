// Web Annotation — W3C Open Annotation projection from knowledge graph entries.
//
// Maps #Insight to oa:Annotation (motivated by commenting) and #Rejected
// to oa:Annotation (motivated by questioning). Related links become
// oa:hasTarget, evidence/reason becomes oa:hasBody.
//
// Usage (from .kb/index.cue):
//   _index: aggregate.#KGIndex & { ... }
//   annotations: aggregate.#Annotations & { index: _index }
//   // cue export . -e annotations.graph --out json

package aggregate

// #OAContext — JSON-LD context for annotation exports.
#OAContext: {
	"oa":      "http://www.w3.org/ns/oa#"
	"dcterms": "http://purl.org/dc/terms/"
	"rdfs":    "http://www.w3.org/2000/01/rdf-schema#"
	"as":      "https://www.w3.org/ns/activitystreams#"
	"kg":      "https://quicue.ca/kg#"
}

// #Annotations — generates an OA annotation collection from #KGIndex entries.
#Annotations: {
	index: #KGIndex

	graph: {
		"@context": #OAContext

		"@graph": [
			// Insights as annotations — commentary on the knowledge domain
			for id, ins in index.insights {
				"@id":   "kg:\(id)"
				"@type": "oa:Annotation"
				"oa:motivatedBy": "oa:commenting"
				"dcterms:created": ins.discovered

				"oa:hasBody": {
					"@type":  "oa:TextualBody"
					"oa:text": ins.statement
					"dcterms:description": ins.implication
					"kg:confidence": ins.confidence
					"kg:method":     ins.method
					"kg:evidence": ins.evidence
				}

				// Related entries become annotation targets
				if ins.related != _|_ {
					"oa:hasTarget": [
						for rel, _ in ins.related {
							{"@id": "kg:\(rel)"}
						},
					]
				}

				if ins.action_items != _|_ {
					"as:result": [
						for item in ins.action_items {
							{
								"@type": "as:Note"
								"as:content": item
							}
						},
					]
				}
			},

			// Rejected approaches as annotations — questioning previous directions
			for id, rej in index.rejected {
				"@id":   "kg:\(id)"
				"@type": "oa:Annotation"
				"oa:motivatedBy": "oa:questioning"
				"dcterms:created": rej.date

				"oa:hasBody": [
					{
						"@type":   "oa:TextualBody"
						"oa:text": rej.approach
						"oa:purpose": "describing"
						"rdfs:label": "Rejected approach"
					},
					{
						"@type":   "oa:TextualBody"
						"oa:text": rej.reason
						"oa:purpose": "commenting"
						"rdfs:label": "Reason for rejection"
					},
					{
						"@type":   "oa:TextualBody"
						"oa:text": rej.alternative
						"oa:purpose": "replying"
						"rdfs:label": "Recommended alternative"
					},
				]

				// Related entries become annotation targets
				if rej.related != _|_ {
					"oa:hasTarget": [
						for rel, _ in rej.related {
							{"@id": "kg:\(rel)"}
						},
					]
				}
			},
		]
	}

	summary: {
		total_annotations: len(index.insights) + len(index.rejected)
		insights:          len(index.insights)
		rejected:          len(index.rejected)
	}
}
