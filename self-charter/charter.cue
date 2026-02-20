// quicue.ca next-steps charter — remaining work for Layer 1.
//
// All phase 1-5 resources are complete (initial build).
// This charter tracks phase 6+ work: SafeID propagation done,
// remaining items are cross-layer integration and projection completeness.
//
// Run:
//   cue eval  ./self-charter/ -e summary
//   cue eval  ./self-charter/ -e gaps.complete
//   cue export ./self-charter/ -e gaps --out json

package main

import (
	"quicue.ca/patterns@v0"
	"quicue.ca/charter@v0"
)

_tasks: {
	// ── Done (anchors for dependency edges) ───────────────────────
	"safeid-propagation": {
		name:        "safeid-propagation"
		"@type":     {Security: true}
		description: "Propagate #SafeID/#SafeLabel from apercue.ca to all quicue.ca surfaces"
	}
	"kb-entries": {
		name:        "kb-entries"
		"@type":     {Documentation: true}
		description: "ADR-014, INSIGHT-012, ASCII-Safe Identifiers pattern in .kb/"
		depends_on:  {"safeid-propagation": true}
	}
	"docs-security": {
		name:        "docs-security"
		"@type":     {Documentation: true}
		description: "Security sections in README, architecture.md, patterns.md, index.md"
		depends_on:  {"safeid-propagation": true}
	}
	"cross-links": {
		name:        "cross-links"
		"@type":     {Documentation: true}
		description: "Ecosystem cross-links in README (Foundation section), org profile"
		depends_on:  {"docs-security": true}
	}

	// ── Remaining: Projection Completeness ────────────────────────
	"specs-registry": {
		name:        "specs-registry"
		"@type":     {Schema: true, Projection: true}
		description: "W3C + provider spec coverage as structured CUE (single source for README, site, spec)"
		depends_on:  {"safeid-propagation": true}
	}
	"api-regen": {
		name:        "api-regen"
		"@type":     {CI: true}
		description: "Regenerate static API (727 endpoints) with SafeID-constrained data"
		depends_on:  {"safeid-propagation": true}
	}
	"demo-regen": {
		name:        "demo-regen"
		"@type":     {CI: true}
		description: "Regenerate demo.quicue.ca D3 dashboard data with latest patterns"
		depends_on:  {"api-regen": true}
	}
	"cat-regen": {
		name:        "cat-regen"
		"@type":     {CI: true}
		description: "Regenerate cat.quicue.ca provider catalogue with latest templates"
		depends_on:  {"safeid-propagation": true}
	}

	// ── Remaining: CI ─────────────────────────────────────────────
	"ci-workflow": {
		name:        "ci-workflow"
		"@type":     {CI: true}
		description: "GitHub Actions: cue vet all packages, examples, templates, .kb/"
		depends_on:  {"safeid-propagation": true}
	}
	"ci-ip-check": {
		name:        "ci-ip-check"
		"@type":     {CI: true, Security: true}
		description: "CI step: verify no RFC 1918 IPs in generated artifacts"
		depends_on:  {"ci-workflow": true}
	}

	// ── Remaining: Import apercue.ca ──────────────────────────────
	"apercue-import": {
		name:        "apercue-import"
		"@type":     {Schema: true}
		description: "Import apercue.ca generic patterns, retire quicue.ca duplicates"
		depends_on:  {"safeid-propagation": true}
	}
	"charter-alignment": {
		name:        "charter-alignment"
		"@type":     {Schema: true}
		description: "Align quicue.ca charter/ with apercue.ca charter/ (shared #Charter, #GapAnalysis)"
		depends_on:  {"apercue-import": true}
	}
}

// ═══════════════════════════════════════════════════════════════════════════
// GRAPH + ANALYSIS
// ═══════════════════════════════════════════════════════════════════════════

graph: patterns.#InfraGraph & {Input: _tasks}

// ═══════════════════════════════════════════════════════════════════════════
// CHARTER
// ═══════════════════════════════════════════════════════════════════════════

_charter: charter.#Charter & {
	name: "quicue-ca-next"

	scope: {
		total_resources: len(_tasks)
		root: {
			"safeid-propagation": true
		}
		required_types: {
			Security:      true
			Documentation: true
			Schema:        true
			Projection:    true
			CI:            true
		}
	}

	gates: {
		"security-complete": {
			phase:       1
			description: "SafeID propagated, docs updated, .kb entries, cross-links"
			requires: {
				"safeid-propagation": true
				"kb-entries":         true
				"docs-security":      true
				"cross-links":        true
			}
		}
		"projections-refreshed": {
			phase:       2
			description: "All public surfaces regenerated with latest patterns"
			requires: {
				"specs-registry": true
				"api-regen":      true
				"demo-regen":     true
				"cat-regen":      true
			}
			depends_on: {"security-complete": true}
		}
		"ci-hardened": {
			phase:       3
			description: "CI validates all packages and checks for IP leaks"
			requires: {
				"ci-workflow": true
				"ci-ip-check": true
			}
			depends_on: {"security-complete": true}
		}
		"apercue-integrated": {
			phase:       4
			description: "quicue.ca imports apercue.ca, shared patterns deduplicated"
			requires: {
				"apercue-import":     true
				"charter-alignment":  true
			}
			depends_on: {"projections-refreshed": true, "ci-hardened": true}
		}
	}
}

gaps: charter.#GapAnalysis & {
	Charter: _charter
	Graph:   graph
}

summary: {
	project:      _charter.name
	deliverables: len(_tasks)
	complete:     gaps.complete
	missing:      gaps.missing_resource_count
	next_gate:    gaps.next_gate
}
