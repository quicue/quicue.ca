// Multi-source reconciliation schema
//
// Demonstrates the "Sources OBSERVE, Resolutions DECIDE" pattern:
// N data sources each write their own fields into a shared struct,
// then CUE's lattice unification merges them without conflict.
//
// Key design rules:
//   1. Each source owns its own IP field (alpha_ip, bravo_ip, charlie_ip)
//   2. Hidden booleans (_in_alpha, _in_bravo, _in_charlie) default to false
//   3. Sources only set their own fields — no shared mutation
//   4. resolutions.cue picks primary_ip by authority hierarchy
//   5. Projections surface hidden fields as public JSON
//
// This avoids false unification errors (_|_) because sources never
// claim the same mutable field.
//
// Run:
//   cue vet  ./examples/reconciliation/
//   cue eval ./examples/reconciliation/ -e gap_report.summary
//   cue eval ./examples/reconciliation/ -e ip_conflicts
//   cue eval ./examples/reconciliation/ -e vm_sources
//   cue eval ./examples/reconciliation/ -e spof

package reconciliation

// #VM — a virtual machine observed by 1-3 independent sources.
//
// Each source writes ONLY its own fields. CUE struct unification
// merges them: if alpha.cue and bravo.cue both mention "web-p01",
// the result is one struct with both sets of fields filled in.
#VM: {
	name: string

	// Resolved IP (set by resolutions.cue)
	primary_ip?: string

	// Per-source IP claims — each source owns its own
	alpha_ip:   *"" | string
	bravo_ip:   *"" | string
	charlie_ip: *"" | string

	// Source presence markers (hidden, exposed via proj_sources.cue)
	_in_alpha:   *false | true
	_in_bravo:   *false | true
	_in_charlie: *false | true

	// Source Alpha facts: hypervisor inventory (highest authority)
	state?: string
	cpus?:  int
	memory_gb?: number
	os?:        string
	cluster?:   string
	host?:      string

	// Source Bravo facts: asset management / CMDB
	asset_type?:     string
	model?:          string
	serial_number?:  string
	location?:       string
	rack?:           string
	managed_by?:     string
	bravo_status?:   string

	// Source Charlie facts: dependency graph / application inventory
	urn?:              string
	resource_type?:    string
	appears_in_count?: int
	depends_on_count?: int
}

// Canonical key: VM name → #VM struct
vms: [Name=string]: #VM & {name: Name}
