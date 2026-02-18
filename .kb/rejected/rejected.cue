// Approaches tried and abandoned in quicue.ca
package rejected

import "quicue.ca/kg/core@v0"

r001: core.#Rejected & {
	id:          "REJ-001"
	approach:    "Use #VizExport with public Graph field for visualization export"
	reason:      "CUE exports ALL public (capitalized) fields. A definition like #Foo: { Graph: #InfraGraph, data: ... } exports Graph in full, causing 4x JSON bloat (75KB vs 17KB)."
	date:        "2025-11-15"
	alternative: "Use hidden _viz wrapper with explicit public projection: _viz holds the computation, viz: { data: _viz.data } exposes only the output."
	related: {"ADR-002": true}
}

r002: core.#Rejected & {
	id:          "REJ-002"
	approach:    "Combine deps block and cue.mod/pkg/ symlink for module resolution"
	reason:      "CUE v0.15.3 treats a module listed in deps AND present as a symlink in cue.mod/pkg/ as ambiguous, causing resolution failures."
	date:        "2026-01-15"
	alternative: "For local-only dev modules, use symlink only and omit deps from module.cue. Choose one resolution mechanism, not both."
}

r003: core.#Rejected & {
	id:          "REJ-003"
	approach:    "Flat .kg/ directory for all knowledge graph entries"
	reason:      "A single flat directory conflates graph types. Agent routing requires manual inspection of entry types. The directory name '.kg' collides with the 'kg' framework module, causing persistent confusion across sessions."
	date:        "2026-02-17"
	alternative: "Multi-graph .kb/ architecture: each knowledge type gets its own subdirectory (decisions/, patterns/, insights/, rejected/), each an independent CUE package validated against its kg type. Directory structure IS the ontology."
	related: {"ADR-001": true}
}

r004: core.#Rejected & {
	id:          "REJ-004"
	approach:    "Thin charter schema without computed gap analysis (~65 lines, cue vet errors as gap report)"
	reason:      "Initial design favored #Charter, #Scale, #Gate only — no #GapAnalysis, no #Milestone. The idea was that cue vet failure messages ARE the gap report. In practice, raw cue vet errors are unstructured text unsuitable for programmatic consumption. Downstream tools need typed output (missing_resources, gate_status, next_gate) to drive dashboards, CI gates, and progress tracking."
	date:        "2026-02-17"
	alternative: "Full charter with computed gap analysis: #Charter, #Gate, #GapAnalysis, #Milestone (~240 lines). Contract-via-unification remains the enforcement mechanism; gap analysis adds a structured reporting layer on top."
	related: {"ADR-005": true}
}
