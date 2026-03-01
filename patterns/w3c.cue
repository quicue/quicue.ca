// W3C projection patterns — re-exported from apercue.ca/patterns.
//
// Generic W3C vocabulary projections that work with any graph satisfying
// apercue's #AnalyzableGraph interface. #InfraGraph satisfies this.
//
// These are DOMAIN-AGNOSTIC projections. For infrastructure-specific
// W3C patterns (SHACL shapes with IP/hostname fields, DCAT with
// DataService entries, ODRL with infrastructure permissions), see
// shacl.cue, dcat.cue, and odrl.cue respectively.

package patterns

import apercue "apercue.ca/patterns@v0"

// ═══════════════════════════════════════════════════════════════════════════
// GRAPH SELF-DESCRIPTION
// ═══════════════════════════════════════════════════════════════════════════

#VoIDDataset: apercue.#VoIDDataset

// ═══════════════════════════════════════════════════════════════════════════
// VOCABULARY / ONTOLOGY
// ═══════════════════════════════════════════════════════════════════════════

#SKOSTaxonomy: apercue.#SKOSTaxonomy
#OWLOntology:  apercue.#OWLOntology

// ═══════════════════════════════════════════════════════════════════════════
// QUALITY / ANNOTATIONS
// ═══════════════════════════════════════════════════════════════════════════

#DataQualityReport:   apercue.#DataQualityReport
#AnnotationCollection: apercue.#AnnotationCollection

// ═══════════════════════════════════════════════════════════════════════════
// PROVENANCE
// ═══════════════════════════════════════════════════════════════════════════

#ProvenancePlan: apercue.#ProvenancePlan
