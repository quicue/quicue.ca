package terraform

// #ProxmoxTarget - Proxmox VE deployment configuration
#ProxmoxTarget: {
	node:       string
	vmid?:      int & >=100 & <=999999
	pool?:      string
	template?:  string
	balloon?:   int
	onboot?:    bool
	datastore?: string

	// Agent (QEMU guest agent)
	agent?: {
		enabled: bool | *true
		trim?:   bool
		type?:   "virtio" | "isa"
	}

	// BIOS and machine type
	bios?:    *"seabios" | "ovmf"
	machine?: string

	// Serial console (required for cloud images)
	serial_device?: bool

	// Operating system
	os_type?: *"l26" | "l24" | "win11" | "win10" | "wxp" | "solaris" | "other"

	// CPU type
	cpu_type?: string

	// Boot order (e.g., ["scsi0", "net0"])
	boot_order?: [...string]

	// Tags for PVE UI organization
	tags?: [...string]

	// Startup order and delays
	startup?: {
		order:       int
		up_delay?:   int
		down_delay?: int
	}

	// PCI passthrough (GPU, etc.)
	hostpci?: [...{
		device:   string
		id?:      string
		mapping?: string
		pcie?:    bool
		rombar?:  bool
	}]
}

// _proxmoxTerraform - Generate proxmox_virtual_environment_vm resources
_proxmoxTerraform: {
	_input: [string]: {
		_resource: #Compute
		_target:   #ProxmoxTarget
	}

	resource: proxmox_virtual_environment_vm: {
		for name, r in _input {
			"\(name)": {
				name:      r._resource.name
				node_name: r._target.node

				// Clone from template
				if r._target.template != _|_ {
					clone: vm_id: r._target.template
				}

				// CPU
				cpu: {
					cores: r._resource.cpu
					if r._target.cpu_type != _|_ {
						type: r._target.cpu_type
					}
				}

				// Memory
				memory: dedicated: _memoryMB[r._resource.memory]
				if r._target.balloon != _|_ {
					memory: floating: r._target.balloon
				}

				// Disks: multi-disk or single-disk
				if r._resource.disks != _|_ {
					disk: [
						for i, d in r._resource.disks {
							interface:    "\(d.interface)\(i)"
							size:         _diskGB[d.size]
							datastore_id: d.datastore
							if d.cache != _|_ {cache: d.cache}
							if d.discard != _|_ {
								if d.discard {discard: "on"}
							}
							if d.iothread != _|_ {iothread: d.iothread}
							if d.ssd != _|_ {ssd: d.ssd}
						},
					]
				}
				if r._resource.disks == _|_ {
					disk: [{
						interface: "scsi0"
						size:      _diskGB[r._resource.disk]
						datastore_id: *r._target.datastore | "local-lvm"
					}]
				}

				// Network: explicit or default vmbr0
				if r._resource.network != _|_ {
					network_device: [
						for nic in r._resource.network {
							{
								bridge: nic.bridge
								model:  nic.model
								if nic.vlan != _|_ {vlan_id: nic.vlan}
								if nic.mac != _|_ {mac_address: nic.mac}
								if nic.firewall != _|_ {firewall: nic.firewall}
								if nic.mtu != _|_ {mtu: nic.mtu}
							}
						},
					]
				}
				if r._resource.network == _|_ {
					network_device: [{
						bridge: "vmbr0"
						model:  "virtio"
					}]
				}

				// Cloud-init
				if r._resource.cloudinit != _|_ {
					let ci = r._resource.cloudinit
					initialization: {
						datastore_id: ci.datastore

						if ci.user != _|_ || ci.ssh_keys != _|_ || ci.password != _|_ {
							user_account: {
								if ci.user != _|_ {username: ci.user}
								if ci.ssh_keys != _|_ {keys: ci.ssh_keys}
								if ci.password != _|_ {password: ci.password}
							}
						}

						if ci.dns_domain != _|_ || ci.dns_servers != _|_ {
							dns: {
								if ci.dns_domain != _|_ {domain: ci.dns_domain}
								if ci.dns_servers != _|_ {servers: ci.dns_servers}
							}
						}

						if ci.ip != _|_ {
							ip_config: [{
								ipv4: {
									address: ci.ip
									if ci.gateway != _|_ {gateway: ci.gateway}
								}
							}]
						}

						if ci.user_data_file != _|_ {
							user_data_file_id: ci.user_data_file
						}
					}
				}

				// Agent
				if r._target.agent != _|_ {
					agent: [{
						enabled: r._target.agent.enabled
						if r._target.agent.trim != _|_ {trim: r._target.agent.trim}
						if r._target.agent.type != _|_ {type: r._target.agent.type}
					}]
				}

				// BIOS
				if r._target.bios != _|_ {
					bios: r._target.bios
				}

				// Machine type
				if r._target.machine != _|_ {
					machine: r._target.machine
				}

				// Serial device (socket for cloud images)
				if r._target.serial_device != _|_ {
					if r._target.serial_device {
						serial_device: [{device: "socket"}]
					}
				}

				// Operating system type
				if r._target.os_type != _|_ {
					operating_system: type: r._target.os_type
				}

				// Boot order
				if r._target.boot_order != _|_ {
					boot_order: r._target.boot_order
				}

				// Tags
				if r._target.tags != _|_ {
					tags: r._target.tags
				}

				// Startup order
				if r._target.startup != _|_ {
					startup: {
						order: r._target.startup.order
						if r._target.startup.up_delay != _|_ {
							up_delay: r._target.startup.up_delay
						}
						if r._target.startup.down_delay != _|_ {
							down_delay: r._target.startup.down_delay
						}
					}
				}

				// PCI passthrough
				if r._target.hostpci != _|_ {
					hostpci: [
						for pci in r._target.hostpci {
							{
								device: pci.device
								if pci.id != _|_ {id: pci.id}
								if pci.mapping != _|_ {mapping: pci.mapping}
								if pci.pcie != _|_ {pcie: pci.pcie}
								if pci.rombar != _|_ {rombar: pci.rombar}
							}
						},
					]
				}

				// Optional fields
				if r._target.pool != _|_ {pool_id: r._target.pool}
				if r._target.vmid != _|_ {vm_id: r._target.vmid}
				if r._target.onboot != _|_ {on_boot: r._target.onboot}
			}
		}
	}
}
