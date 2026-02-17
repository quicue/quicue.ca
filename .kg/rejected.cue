// Approaches tried and abandoned in quicue.ca
package kg

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
	approach:    "Organize .kg/ entries in subdirectories by type (decisions/, insights/, etc.)"
	reason:      "CUE packages are directory-scoped. Files in .kg/decisions/ are a SEPARATE package instance from .kg/project.cue, even if both declare package kg. Cross-references between them fail."
	date:        "2026-02-15"
	alternative: "Keep .kg/ flat: all .cue files at root level. Use separate files per type (decisions.cue, insights.cue) for organization within the single package scope."
	related: {"ADR-001": true}
}
