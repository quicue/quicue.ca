// Validation patterns for Proxmox VE infrastructure
//
// Provides compile-time validation for:
// - VMID/LXCID uniqueness and range constraints
// - GPU passthrough conflict detection
//
// Usage:
//   import "quicue.ca/proxmox"
//
//   _validation: proxmox.#ProxmoxIDValidation & {
//       _vms: vms
//       _lxcs: lxcs
//   }

package proxmox

// #ProxmoxIDValidation ensures VMID and LXCID are unique and within valid ranges
// Creates CUE evaluation errors if duplicates or out-of-range IDs found
#ProxmoxIDValidation: {
	// Input: VMs and LXCs collections
	_vms: [string]: {
		vmid?: int
		vm_id?: int
		...
	}
	_lxcs: [string]: {
		lxcid?: int
		container_id?: int
		...
	}

	// ID range constraints (Proxmox valid range: 100-999999999)
	_minID: int | *100
	_maxID: int | *999

	// Extract VMIDs (support both field names)
	_vmidMap: {
		for name, vm in _vms {
			let _id = vm.vm_id | *vm.vmid
			if _id != _|_ {
				(name): {
					name: name
					id:   _id
				}
			}
		}
	}

	// Extract LXCIDs (support both field names)
	_lxcidMap: {
		for name, lxc in _lxcs {
			let _id = lxc.container_id | *lxc.lxcid
			if _id != _|_ {
				(name): {
					name: name
					id:   _id
				}
			}
		}
	}

	// Check VMID duplicates
	_vmidNames: [for n, _ in _vmidMap {n}]
	_vmidDuplicates: [
		for i, nameA in _vmidNames
		for j, nameB in _vmidNames
		if i < j && _vmidMap[nameA].id == _vmidMap[nameB].id {
			id:      _vmidMap[nameA].id
			vms:     [nameA, nameB]
			message: "VMID conflict: \(_vmidMap[nameA].id) used by '\(nameA)' and '\(nameB)'"
		},
	]

	// Check LXCID duplicates
	_lxcidNames: [for n, _ in _lxcidMap {n}]
	_lxcidDuplicates: [
		for i, nameA in _lxcidNames
		for j, nameB in _lxcidNames
		if i < j && _lxcidMap[nameA].id == _lxcidMap[nameB].id {
			id:      _lxcidMap[nameA].id
			lxcs:    [nameA, nameB]
			message: "LXCID conflict: \(_lxcidMap[nameA].id) used by '\(nameA)' and '\(nameB)'"
		},
	]

	// Check VMID range
	_vmidOutOfRange: [
		for name, entry in _vmidMap
		if entry.id < _minID || entry.id > _maxID {
			vm:      name
			id:      entry.id
			message: "VMID \(entry.id) for '\(name)' out of range [\(_minID)-\(_maxID)]"
		},
	]

	// Check LXCID range
	_lxcidOutOfRange: [
		for name, entry in _lxcidMap
		if entry.id < _minID || entry.id > _maxID {
			lxc:     name
			id:      entry.id
			message: "LXCID \(entry.id) for '\(name)' out of range [\(_minID)-\(_maxID)]"
		},
	]

	// Fail validation if duplicates exist
	for dup in _vmidDuplicates {
		("\(dup.vms[0])_\(dup.vms[1])_vmid_conflict"): {
			_error: dup.message
			_fail:  true
			_fail:  false // Impossible: creates validation error
		}
	}

	for dup in _lxcidDuplicates {
		("\(dup.lxcs[0])_\(dup.lxcs[1])_lxcid_conflict"): {
			_error: dup.message
			_fail:  true
			_fail:  false
		}
	}

	for oor in _vmidOutOfRange {
		("\(oor.vm)_vmid_out_of_range"): {
			_error: oor.message
			_fail:  true
			_fail:  false
		}
	}

	for oor in _lxcidOutOfRange {
		("\(oor.lxc)_lxcid_out_of_range"): {
			_error: oor.message
			_fail:  true
			_fail:  false
		}
	}

	// Expose validation results
	valid: len(_vmidDuplicates) == 0 && len(_lxcidDuplicates) == 0 && len(_vmidOutOfRange) == 0 && len(_lxcidOutOfRange) == 0
	issues: {
		vmid_duplicates:    _vmidDuplicates
		lxcid_duplicates:   _lxcidDuplicates
		vmid_out_of_range:  _vmidOutOfRange
		lxcid_out_of_range: _lxcidOutOfRange
	}
}

// #GPUPassthroughConflictValidation detects when multiple VMs use the same GPU on the same node
// Creates CUE evaluation errors if GPU conflicts detected
#GPUPassthroughConflictValidation: {
	// Input: VMs collection with hardware.gpu definitions
	_vms: [string]: {
		node?: string
		host?: string
		hardware?: {
			gpu?: {
				model?:       string
				passthrough?: bool
				...
			}
			...
		}
		...
	}

	// Extract GPU assignments
	_gpuAssignments: [
		for vmName, vm in _vms {
			let host = vm.host | *vm.node
			if vm.hardware != _|_ && vm.hardware.gpu != _|_ && vm.hardware.gpu.passthrough == true && vm.hardware.gpu.model != _|_ && host != _|_ {
				vmname: vmName
				gpu:    vm.hardware.gpu.model
				node:   host
			}
		},
	]

	// Detect conflicts (same GPU on same node)
	_conflicts: [
		for i, a in _gpuAssignments
		for j, b in _gpuAssignments
		if i < j && a.node == b.node && a.gpu == b.gpu {
			gpu:     a.gpu
			node:    a.node
			vms:     [a.vmname, b.vmname]
			message: "GPU conflict: \(a.gpu) on node \(a.node) assigned to both '\(a.vmname)' and '\(b.vmname)'"
		},
	]

	// Fail validation if conflicts exist
	for conflict in _conflicts {
		("\(conflict.vms[0])_\(conflict.vms[1])_gpu_conflict"): {
			_error: conflict.message
			_fail:  true
			_fail:  false
		}
	}

	// Expose results
	valid:   len(_conflicts) == 0
	issues:  _conflicts
	summary: {
		total_gpu_vms: len(_gpuAssignments)
		conflicts:     len(_conflicts)
	}
}
