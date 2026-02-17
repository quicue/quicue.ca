// Terraform output for KubeVirt (kubernetes_manifest resources)
//
// Generates kubernetes_manifest resources for KubeVirt VMs.
// Supports multi-disk, network interfaces, and cloud-init.
package terraform

import "list"

// #KubeVirtTarget - Platform-specific config for KubeVirt
#KubeVirtTarget: {
	namespace:    string | *"default"
	storageClass: string | *"standard"
	runStrategy:  *"Always" | "Manual" | "Halted" | "RerunOnFailure"

	evictionStrategy?: "LiveMigrate" | "None"
	instancetype?:     string

	// Network mode: masquerade (default) or bridge
	networkMode?: *"masquerade" | "bridge" | "sriov"

	// Multus network name (for bridge/sriov)
	multusNetwork?: string

	// Node selector for scheduling
	nodeSelector?: [string]: string

	// Annotations on the VM object
	annotations?: [string]: string

	// Labels on the template pod
	labels?: [string]: string
}

// _kubevirtTerraform - Generate Terraform resource blocks for KubeVirt VMs
_kubevirtTerraform: {
	_input: [string]: {
		_resource: #Compute
		_target:   #KubeVirtTarget
	}

	resource: {
		kubernetes_manifest: {
			for _name, r in _input {
				// Pre-compute disk lists to avoid list addition
				let _dataDisks = {
					if r._resource.disks != _|_ {
						out: [
							for i, d in r._resource.disks {
								{
									name: "disk\(i)"
									disk: bus: "virtio"
								}
							},
						]
					}
					if r._resource.disks == _|_ {
						out: [{
							name: "rootdisk"
							disk: bus: "virtio"
						}]
					}
				}
				let _ciDisks = {
					if r._resource.cloudinit != _|_ {
						out: [{
							name: "cloudinit"
							disk: bus: "virtio"
						}]
					}
					if r._resource.cloudinit == _|_ {
						out: []
					}
				}

				// Pre-compute volume lists
				let _dataVolumes = {
					if r._resource.disks != _|_ {
						out: [
							for i, _ in r._resource.disks {
								{
									name: "disk\(i)"
									dataVolume: name: "\(_name)-dv\(i)"
								}
							},
						]
					}
					if r._resource.disks == _|_ {
						out: [{
							name: "rootdisk"
							dataVolume: name: "\(_name)-dv"
						}]
					}
				}
				let _ciVolumes = {
					if r._resource.cloudinit != _|_ {
						let ci = r._resource.cloudinit
						out: [{
							name: "cloudinit"
							cloudInitNoCloud: {
								if ci.user_data_file != _|_ {
									userDataBase64: ci.user_data_file
								}
								if ci.user_data_file == _|_ {
									userData: "#cloud-config\n"
								}
							}
						}]
					}
					if r._resource.cloudinit == _|_ {
						out: []
					}
				}

				"\(_name)": manifest: {
					apiVersion: "kubevirt.io/v1"
					kind:       "VirtualMachine"
					metadata: {
						"name":    r._resource.name
						namespace: r._target.namespace
						if r._target.annotations != _|_ {
							annotations: r._target.annotations
						}
					}
					spec: {
						runStrategy: r._target.runStrategy

						template: {
							metadata: labels: {
								"kubevirt.io/domain": _name
								if r._target.labels != _|_ {r._target.labels}
							}
							spec: {
								domain: {
									cpu: cores: r._resource.cpu
									resources: requests: memory: r._resource.memory
									devices: {
										disks: list.Concat([_dataDisks.out, _ciDisks.out])

										// Network interfaces
										if r._resource.network != _|_ {
											interfaces: [
												for i, _ in r._resource.network {
													{
														name: "net\(i)"
														// Default to masquerade when networkMode not set
														if r._target.networkMode == _|_ {
															masquerade: {}
														}
														if r._target.networkMode != _|_ {
															if r._target.networkMode == "masquerade" {
																masquerade: {}
															}
															if r._target.networkMode == "bridge" {
																bridge: {}
															}
															if r._target.networkMode == "sriov" {
																sriov: {}
															}
														}
													}
												},
											]
										}
										if r._resource.network == _|_ {
											interfaces: [{
												name:       "default"
												masquerade: {}
											}]
										}
									}
								}

								// Network sources
								if r._resource.network != _|_ {
									networks: [
										for i, _ in r._resource.network {
											{
												name: "net\(i)"
												// First interface with masquerade gets pod network
												if r._target.networkMode == _|_ {
													if i == 0 {
														pod: {}
													}
												}
												if r._target.networkMode != _|_ {
													if r._target.networkMode == "masquerade" {
														if i == 0 {
															pod: {}
														}
													}
													if r._target.networkMode == "bridge" {
														if r._target.multusNetwork != _|_ {
															multus: networkName: r._target.multusNetwork
														}
													}
													if r._target.networkMode == "sriov" {
														if r._target.multusNetwork != _|_ {
															multus: networkName: r._target.multusNetwork
														}
													}
												}
											}
										},
									]
								}
								if r._resource.network == _|_ {
									networks: [{
										name: "default"
										pod: {}
									}]
								}

								volumes: list.Concat([_dataVolumes.out, _ciVolumes.out])

								if r._target.evictionStrategy != _|_ {
									evictionStrategy: r._target.evictionStrategy
								}

								if r._target.nodeSelector != _|_ {
									nodeSelector: r._target.nodeSelector
								}
							}
						}

						if r._target.instancetype != _|_ {
							instancetype: {
								kind: "VirtualMachineInstancetype"
								name: r._target.instancetype
							}
						}

						// DataVolumeTemplates: multi-disk or single
						if r._resource.disks != _|_ {
							dataVolumeTemplates: [
								for i, d in r._resource.disks {
									{
										metadata: name: "\(_name)-dv\(i)"
										spec: {
											storage: {
												accessModes: ["ReadWriteOnce"]
												resources: requests: storage: d.size
												if r._target.storageClass != _|_ {
													storageClassName: r._target.storageClass
												}
											}
											source: blank: {}
										}
									}
								},
							]
						}
						if r._resource.disks == _|_ {
							dataVolumeTemplates: [{
								metadata: name: "\(_name)-dv"
								spec: {
									storage: {
										accessModes: ["ReadWriteOnce"]
										resources: requests: storage: r._resource.disk
										if r._target.storageClass != _|_ {
											storageClassName: r._target.storageClass
										}
									}
									source: blank: {}
								}
							}]
						}
					}
				}
			}
		}
	}
}
