// VCF Migration — Graph computation + gap analysis + output
//
// Composes:
//   - resources.cue (Layer 3: your infrastructure)
//   - providers.cue (Layer 2: govc + proxmox bindings)
//   - charter.cue   (project gates and milestones)
//   - classify.cue  (migration bucket classification)
//
// Run: cue eval ./examples/vcf-migration/ -e output --out json
// Run: cue eval ./examples/vcf-migration/ -e gaps --out json
// Run: cue eval ./examples/vcf-migration/ -e gaps.gate_status --out json
// Run: cue eval ./examples/vcf-migration/ -e gaps.earl_report --out json
// Run: cue eval ./examples/vcf-migration/ -e vizData --out json

package main

import (
	"quicue.ca/patterns@v0"
	"quicue.ca/charter"
)

// ── Graph ───────────────────────────────────────────────────────

infra: patterns.#InfraGraph & {Input: resources}

// ── Gap Analysis ────────────────────────────────────────────────
//
// Compare the charter's requirements against what's in the graph.
// gaps.complete == false means work remains.
// gaps.next_gate tells you which gate to focus on.
// gaps.shacl_report gives a W3C SHACL ValidationReport.

gaps: charter.#GapAnalysis & {
	Charter: vcf_charter
	Graph:   infra
}

// ── VizData (for sid-demo / graph explorer) ─────────────────────

_viz: patterns.#VizData & {Graph: infra, Resources: resources}
vizData: _viz.data

// ── Output ──────────────────────────────────────────────────────
//
// Side-by-side provider commands for every VM.
// This is the money slide: same resource, two platforms, zero changes.

output: {
	for rname, r in binding.bound
	if r["@type"]["VirtualMachine"] != _|_ {
		(rname): {
			resource: rname
			ip:       r.ip
			"@type":  r["@type"]
			providers: {
				for pname, pactions in r.actions {
					(pname): {
						for aname, action in pactions {
							(aname): action.command
						}
					}
				}
			}
		}
	}
}

// ── Migration Summary ───────────────────────────────────────────

migration_summary: {
	charter_name:    vcf_charter.name
	charter_complete: gaps.complete
	next_gate:       gaps.next_gate
	resource_count:  gaps.resource_count
	missing_resources: gaps.missing_resource_count
	missing_types:     gaps.missing_type_count

	binding_stats: binding.summary
	class_summary: classification.summary

	gate_overview: {
		for gname, gs in gaps.gate_status {
			(gname): {
				satisfied: gs.satisfied
				ready:     gs.ready
				if !gs.satisfied {
					missing: gs.missing
				}
			}
		}
	}
}
