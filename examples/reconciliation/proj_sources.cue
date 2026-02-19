// Source attribution projection — expose hidden _in_* fields
//
// CUE hides fields prefixed with _ from exports by default.
// This projection surfaces the per-VM source membership as
// public fields for downstream consumers (Python, JSON-LD, etc.).
//
// Usage:
//   cue export ./examples/reconciliation/ -e vm_sources

package reconciliation

vm_sources: {
	for k, v in vms {
		(k): {
			in_alpha:   v._in_alpha
			in_bravo:   v._in_bravo
			in_charlie: v._in_charlie
		}
	}
}
