// SKOS type vocabulary — projects vocab.#TypeRegistry as a skos:ConceptScheme.
//
// The type registry IS a taxonomy. This projection makes it
// standards-compliant linked data that any SKOS-aware tool can consume.
//
// Usage:
//   types_vocab: (ou.#TypeVocabulary & {}).vocabulary
//   cue export ./examples/datacenter/ -e datacenter_skos_types --out json

package ou

import "quicue.ca/vocab"

#TypeVocabulary: {
	BaseIRI: string | *"https://quicue.ca/vocab#"

	vocabulary: {
		"@context": {
			"skos":   "http://www.w3.org/2004/02/skos/core#"
			"quicue": BaseIRI
			"rdfs":   "http://www.w3.org/2000/01/rdf-schema#"
		}
		"@type": "skos:ConceptScheme"
		"@id":   "\(BaseIRI)types"
		"skos:prefLabel": "quicue.ca Infrastructure Type Vocabulary"

		"skos:hasTopConcept": [
			for tname, tentry in vocab.#TypeRegistry
			if tentry.description != _|_ {
				"@type":           "skos:Concept"
				"@id":             "\(BaseIRI)\(tname)"
				"skos:prefLabel":  tname
				"skos:definition": tentry.description
				if tentry.grants != _|_ {
					"quicue:grants": tentry.grants
				}
				if tentry.requires != _|_ {
					"quicue:requires": [ for f, _ in tentry.requires {f}]
				}
			},
		]
	}
}
