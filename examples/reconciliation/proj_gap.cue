// Gap report projection — data quality across sources
//
// Surfaces which VMs are fully reconciled (in all 3 sources),
// partially reconciled (in 2), or single-source (in 1).
// Also lists VMs missing from each specific source.
//
// Usage:
//   cue eval ./examples/reconciliation/ -e gap_report.summary
//   cue eval ./examples/reconciliation/ -e gap_report.missing_alpha

package reconciliation

// Pre-computed sets using struct-as-set (O(1) membership, clean len())
_all_three: {for k, v in vms if v._in_alpha && v._in_bravo && v._in_charlie {(k): true}}
_exactly_two: {for k, v in vms
	if (v._in_alpha && v._in_bravo && !v._in_charlie) ||
		(v._in_alpha && !v._in_bravo && v._in_charlie) ||
		(!v._in_alpha && v._in_bravo && v._in_charlie) {(k): true}}
_exactly_one: {for k, v in vms
	if (v._in_alpha && !v._in_bravo && !v._in_charlie) ||
		(!v._in_alpha && v._in_bravo && !v._in_charlie) ||
		(!v._in_alpha && !v._in_bravo && v._in_charlie) {(k): true}}

// Struct-as-set for missing counts (avoids incomplete list len())
_not_alpha: {for k, v in vms if !v._in_alpha {(k): true}}
_not_bravo: {for k, v in vms if !v._in_bravo {(k): true}}
_not_charlie: {for k, v in vms if !v._in_charlie {(k): true}}

gap_report: {
	summary: {
		total:           len(vms)
		in_all_three:    len(_all_three)
		in_two_sources:  len(_exactly_two)
		in_one_source:   len(_exactly_one)
		missing_alpha:   len(_not_alpha)
		missing_bravo:   len(_not_bravo)
		missing_charlie: len(_not_charlie)
	}

	// VMs not in Alpha (hypervisor) — physical inventory gap
	missing_alpha: [for k, v in vms if !v._in_alpha {
		name: k
	}]

	// VMs not in Bravo (CMDB) — ownership/asset tracking gap
	missing_bravo: [for k, v in vms if !v._in_bravo {
		name: k
	}]

	// VMs not in Charlie (dependency graph) — operational visibility gap
	missing_charlie: [for k, v in vms if !v._in_charlie {
		name: k
	}]
}
