// IP conflict projection — detect source disagreements
//
// When multiple sources report different IPs for the same VM,
// that's a data quality signal. Typically means one source is stale.
//
// Usage:
//   cue eval ./examples/reconciliation/ -e ip_conflicts

package reconciliation

// Pre-computed conflict flag (avoids complex inline guards)
_ip_conflict: {for k, v in vms {
	(k): (v.alpha_ip != "" && v.bravo_ip != "" && v.alpha_ip != v.bravo_ip) ||
		(v.alpha_ip != "" && v.charlie_ip != "" && v.alpha_ip != v.charlie_ip) ||
		(v.bravo_ip != "" && v.charlie_ip != "" && v.bravo_ip != v.charlie_ip)
}}

ip_conflicts: {
	conflicts: [for k, v in vms if _ip_conflict[k] {
		name:       k
		alpha_ip:   v.alpha_ip
		bravo_ip:   v.bravo_ip
		charlie_ip: v.charlie_ip
	}]

	conflict_count: len({for k, _ in vms if _ip_conflict[k] {(k): true}})
}
