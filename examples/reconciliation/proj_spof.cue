// SPOF & risk projection — identify critical infrastructure
//
// Combines dependency data (Charlie) with physical placement (Alpha)
// to find single points of failure and operational blind spots.
//
// Usage:
//   cue eval ./examples/reconciliation/ -e spof

package reconciliation

spof: {
	// High-dependency VMs: many apps depend on these
	high_dependency: [for k, v in vms
		if v._in_charlie
		if (v.appears_in_count != _|_)
		if v.appears_in_count > 3 {
		name:             k
		appears_in_count: v.appears_in_count
		has_placement:    v._in_alpha
	}]

	// Blind spots: operationally important but physically untracked
	blind_spots: [for k, v in vms
		if v._in_charlie
		if (v.depends_on_count != _|_)
		if v.depends_on_count > 0
		if !v._in_alpha {
		name:             k
		depends_on_count: v.depends_on_count
	}]

	// High coupling: VMs shared by many applications
	high_coupling: [for k, v in vms
		if v._in_charlie
		if (v.appears_in_count != _|_)
		if v.appears_in_count > 2 {
		name:             k
		appears_in_count: v.appears_in_count
	}]
}
