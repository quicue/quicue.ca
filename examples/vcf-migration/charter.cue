// VCF Migration Charter — constraint-first project planning
//
// Models the full migration lifecycle as a DAG of gates:
//   inventory → validate → pilot → wave-1 → wave-2 → cutover → exit-ready
//
// "exit-ready" is the key gate: it requires provider-agnostic bindings
// for every migrated resource, proving you can leave VCF at renewal.
//
// Run: cue eval ./examples/vcf-migration/ -e gaps --out json
// Run: cue eval ./examples/vcf-migration/ -e gaps.shacl_report --out json

package main

import "quicue.ca/charter"

// ── The Charter ─────────────────────────────────────────────────
//
// 7 gates across 4 phases. Each gate lists concrete resources
// that must exist in the graph before the gate is satisfied.
// CUE computes what's missing — no spreadsheet, no guessing.

vcf_charter: charter.#InfraCharter & {
	name: "VCF Migration 2026"
	scope: {
		total_resources: 11
		root:            "vcenter-primary"
		required_types: {
			VirtualMachine:         true
			VirtualizationPlatform: true
			Database:               true
			LoadBalancer:           true
		}
	}
	gates: {
		"inventory": {
			phase: 1
			requires: {
				"vcenter-primary":    true
				"nutanix-cluster-01": true
				"f5-primary":         true
			}
		}
		"validate": {
			phase: 1
			requires: {
				"esxi-host-01":  true
				"esxi-host-02":  true
				"dell-target-01": true
			}
			depends_on: {"inventory": true}
		}
		"pilot": {
			phase: 2
			requires: {
				"vm-artifactory": true
				"vm-gitlab":      true
			}
			depends_on: {"validate": true}
		}
		"wave-1": {
			phase: 3
			requires: {
				"vm-db-primary":  true
				"vm-app-server":  true
			}
			depends_on: {"pilot": true}
		}
		"wave-2": {
			phase: 3
			requires: {
				"vm-web-frontend": true
			}
			depends_on: {"pilot": true}
		}
		"cutover": {
			phase: 4
			requires: {
				"vcenter-primary":    true
				"dell-target-01":     true
			}
			depends_on: {"wave-1": true, "wave-2": true}
		}
		"exit-ready": {
			phase: 4
			requires: {
				"vm-artifactory":  true
				"vm-gitlab":       true
				"vm-db-primary":   true
				"vm-app-server":   true
				"vm-web-frontend": true
			}
			depends_on: {"cutover": true}
		}
	}
}
