// Knowledge Base manifest — declares which semantic graphs a repo maintains.
//
// Each graph maps to a kg type and a W3C vocabulary. The directory
// structure IS the ontology: agents route content by directory name,
// CUE validates by type, and export produces standards-compliant
// linked data natively.
//
// Usage:
//   kb: ext.#KnowledgeBase & {
//       context: _project
//       graphs: {
//           decisions: {semantic: "prov:Activity", ...}
//           patterns:  {semantic: "skos:Concept", ...}
//       }
//   }
package ext

// #KnowledgeBase — the repo's knowledge topology.
//
// Declares which semantic graphs exist in .kb/ and how they
// map to W3C vocabularies. The repo is the lexicographer:
// it defines its own knowledge structure.
#KnowledgeBase: {
	"@type": "kg:KnowledgeBase"
	"@id"?:  string

	// Project identity — who maintains this knowledge base
	context: #Context

	// Directory convention — canonical location
	directory: *".kb" | string

	// Semantic graphs — each is a typed, independently validated CUE package
	graphs: {[string]: #Graph}
}

// #Graph — a single semantic graph within a knowledge base.
//
// Maps a kg type to a W3C vocabulary. The directory name IS
// the routing constraint: agents put decisions in decisions/,
// patterns in patterns/. CUE's package scoping enforces that
// each graph validates independently.
#Graph: {
	"@type": "kg:Graph"

	// The kg type this graph contains (e.g., "core.#Decision")
	kg_type: string & !=""

	// The W3C vocabulary this graph natively exports to
	semantic: string & !=""

	// What this graph is for (guides agent routing)
	description: string & !=""

	// Subdirectory name within .kb/
	directory: string & !=""

	// The CUE package name used in this graph's files
	package_name: *directory | string

	status: *"active" | "planned" | "archived"
}

// Standard graph definitions — reusable across projects.
// Projects compose these: graphs: {decisions: #DecisionsGraph, ...}

#DecisionsGraph: #Graph & {
	kg_type:     "core.#Decision"
	semantic:    "prov:Activity"
	description: "Architecture decisions — rationale, consequences, and status. Each decision is a PROV-O activity performed by an agent."
	directory:   "decisions"
}

#PatternsGraph: #Graph & {
	kg_type:     "core.#Pattern"
	semantic:    "skos:Concept"
	description: "Reusable problem/solution pairs. Each pattern is a SKOS concept in a taxonomy with broader/narrower/related relationships."
	directory:   "patterns"
}

#InsightsGraph: #Graph & {
	kg_type:     "core.#Insight"
	semantic:    "oa:Annotation"
	description: "Validated discoveries with evidence and confidence. Each insight is a Web Annotation: body (statement) targeting evidence."
	directory:   "insights"
}

#RejectedGraph: #Graph & {
	kg_type:     "core.#Rejected"
	semantic:    "prov:Activity"
	description: "Failed approaches with alternatives. Each rejection is a PROV-O activity that was invalidated — institutional wisdom about what not to do."
	directory:   "rejected"
}

#DerivationsGraph: #Graph & {
	kg_type:     "ext.#Derivation"
	semantic:    "prov:Derivation"
	description: "Data lineage and audit trails. Each derivation tracks what was produced from what, via which activity."
	directory:   "derivations"
}

#WorkspaceGraph: #Graph & {
	kg_type:     "ext.#Workspace"
	semantic:    "dcat:Dataset"
	description: "Multi-repo topology — components, symlinks, remotes, deployment targets."
	directory:   "workspace"
}
