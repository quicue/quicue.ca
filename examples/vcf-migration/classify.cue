// VCF Migration — Resource classification projection
//
// Classifies every resource into migration buckets:
//   vmware_bound    — requires VMware-specific features (vCenter, NSX, vSAN)
//   portable        — VM workloads that run on any hypervisor
//   containerizable — candidates for K8s/container migration
//   shared_service  — infrastructure shared across platforms (F5, DNS)
//
// Classification is a CUE comprehension — no code, no runtime.
// Add a tag to a resource, re-run cue eval, classification updates.
//
// Run: cue eval ./examples/vcf-migration/ -e classification --out json
// Run: cue eval ./examples/vcf-migration/ -e classification.summary --out json

package main

// ── Classification ──────────────────────────────────────────────

classification: {
	// VMware-bound: resources with VMwareCluster type (management plane)
	vmware_bound: {
		for name, r in resources
		if r["@type"]["VMwareCluster"] != _|_ {
			(name): {
				ip:     r.ip
				reason: "VMware management plane — requires vCenter/VCF"
			}
		}
	}

	// Portable: VMs tagged as portable (run on any hypervisor)
	portable: {
		for name, r in resources
		if r.tags != _|_
		if r.tags["portable"] != _|_ {
			(name): {
				ip:       r.ip
				vm_path:  *r.vm_path | "n/a"
				services: [for t, _ in r["@type"] if t != "VirtualMachine" {t}]
			}
		}
	}

	// Containerizable: VMs tagged as containerizable (K8s candidates)
	containerizable: {
		for name, r in resources
		if r.tags != _|_
		if r.tags["containerizable"] != _|_ {
			(name): {
				ip:       r.ip
				services: [for t, _ in r["@type"] if t != "VirtualMachine" {t}]
				note:     "Candidate for container migration — stateless or front-end"
			}
		}
	}

	// Shared services: resources that persist across any migration
	shared_services: {
		for name, r in resources
		if r.tags != _|_
		if r.tags["shared_service"] != _|_ {
			(name): {
				ip:   r.ip
				type: [for t, _ in r["@type"] {t}]
				note: "Platform-independent — survives any migration"
			}
		}
	}

	// Infrastructure hosts (source and target)
	hosts: {
		source: {
			for name, r in resources
			if r.tags != _|_
			if r.tags["source"] != _|_ {
				(name): r.ip
			}
		}
		target: {
			for name, r in resources
			if r.tags != _|_
			if r.tags["target"] != _|_ {
				(name): r.ip
			}
		}
	}

	// Summary counts
	summary: {
		total_resources:        len(resources)
		vmware_bound_count:     len(vmware_bound)
		portable_count:         len(portable)
		containerizable_count:  len(containerizable)
		shared_service_count:   len(shared_services)
		source_host_count:      len(hosts.source)
		target_host_count:      len(hosts.target)
		migration_ready:        portable_count + containerizable_count
		exit_path_coverage:     "\(portable_count + containerizable_count)/\(portable_count + containerizable_count + vmware_bound_count) workloads portable"
	}
}
