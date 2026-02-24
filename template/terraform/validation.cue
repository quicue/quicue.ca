package terraform

import ( "list"

	// Validation constraints for #TerraformOutput
	// These run at evaluation time and produce errors for conflicts.
)

#TerraformOutput: {
	// Forward-declare so references resolve across files
	Resources: [string]: #Compute

	// VMID conflict detection: no two resources may share a proxmox.vmid
	_vmids: [
		for name, r in Resources
		if r.proxmox != _|_
		if r.proxmox.vmid != _|_ {
			_name: name
			_vmid: r.proxmox.vmid
		},
	]
	_vmidValues: [for v in _vmids {v._vmid}]
	_vmidUnique: list.UniqueItems & _vmidValues

	// Cloud-init IP conflict detection: no two resources may share a cloudinit.ip
	_ips: [
		for name, r in Resources
		if r.cloudinit != _|_
		if r.cloudinit.ip != _|_ {
			_name: name
			_ip:   r.cloudinit.ip
		},
	]
	_ipValues: [for v in _ips {v._ip}]
	_ipUnique: list.UniqueItems & _ipValues
}
