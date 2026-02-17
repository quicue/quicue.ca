// PowerCLI Provider - vSphere VM management via VMware PowerShell cmdlets
//
// Requires:
//   pwsh with VMware.PowerCLI module installed
//   Connect-VIServer run first (or -Server param)
//
// Usage:
//   import "quicue.ca/template/powercli/patterns"

package patterns

import "quicue.ca/vocab"

// #PowerCLIRegistry - PowerCLI action definitions
#PowerCLIRegistry: {
	// ========== Connection ==========

	connect: vocab.#ActionDef & {
		name:             "Connect to vCenter"
		description:      "Establish PowerCLI session to vCenter server"
		category:         "connect"
		params: {
			server:   {from_field: "vcenter_host"}
			user:     {from_field: "vcenter_user", required: false}
			password: {from_field: "vcenter_password", required: false}
		}
		command_template: "Connect-VIServer -Server {server} -User {user} -Password {password}"
	}

	// ========== VM Actions ==========

	vm_info: vocab.#ActionDef & {
		name:             "VM Info"
		description:      "Get VM power state, CPU, memory, and guest IP"
		category:         "info"
		params: vm_name: {from_field: "vm_name"}
		command_template: "Get-VM -Name {vm_name} | Format-List"
		idempotent:       true
	}

	vm_guest: vocab.#ActionDef & {
		name:             "VM Guest Info"
		description:      "Get guest OS details via VMware Tools"
		category:         "info"
		params: vm_name: {from_field: "vm_name"}
		command_template: "Get-VMGuest -VM {vm_name}"
		idempotent:       true
	}

	vm_console: vocab.#ActionDef & {
		name:             "VM Console URL"
		description:      "Get web console URL"
		category:         "connect"
		params: vm_name: {from_field: "vm_name"}
		command_template: "Open-VMConsoleWindow -VM {vm_name}"
	}

	// ========== Lifecycle Actions ==========

	vm_start: vocab.#ActionDef & {
		name:             "Start VM"
		description:      "Power on VM"
		category:         "admin"
		params: vm_name: {from_field: "vm_name"}
		command_template: "Start-VM -VM {vm_name} -Confirm:$false"
	}

	vm_stop: vocab.#ActionDef & {
		name:             "Stop VM (graceful)"
		description:      "Shut down guest OS"
		category:         "admin"
		params: vm_name: {from_field: "vm_name"}
		command_template: "Shutdown-VMGuest -VM {vm_name} -Confirm:$false"
	}

	vm_stop_hard: vocab.#ActionDef & {
		name:             "Stop VM (hard)"
		description:      "Power off VM immediately"
		category:         "admin"
		params: vm_name: {from_field: "vm_name"}
		command_template: "Stop-VM -VM {vm_name} -Confirm:$false"
		destructive:      true
	}

	vm_restart: vocab.#ActionDef & {
		name:             "Restart VM"
		description:      "Restart guest OS"
		category:         "admin"
		params: vm_name: {from_field: "vm_name"}
		command_template: "Restart-VMGuest -VM {vm_name} -Confirm:$false"
	}

	vm_suspend: vocab.#ActionDef & {
		name:             "Suspend VM"
		description:      "Suspend VM to memory"
		category:         "admin"
		params: vm_name: {from_field: "vm_name"}
		command_template: "Suspend-VM -VM {vm_name} -Confirm:$false"
	}

	// ========== Snapshot Actions ==========

	snapshot_list: vocab.#ActionDef & {
		name:             "List Snapshots"
		description:      "List VM snapshots"
		category:         "info"
		params: vm_name: {from_field: "vm_name"}
		command_template: "Get-Snapshot -VM {vm_name}"
		idempotent:       true
	}

	snapshot_create: vocab.#ActionDef & {
		name:             "Create Snapshot"
		description:      "Create VM snapshot"
		category:         "admin"
		params: {
			vm_name:       {from_field: "vm_name"}
			snapshot_name: {required: false}
		}
		command_template: "New-Snapshot -VM {vm_name} -Name {snapshot_name}"
	}

	snapshot_revert: vocab.#ActionDef & {
		name:             "Revert Snapshot"
		description:      "Revert VM to named snapshot"
		category:         "admin"
		params: {
			vm_name:       {from_field: "vm_name"}
			snapshot_name: {}
		}
		command_template: "Set-VM -VM {vm_name} -Snapshot {snapshot_name} -Confirm:$false"
		destructive:      true
	}

	snapshot_remove: vocab.#ActionDef & {
		name:             "Remove Snapshot"
		description:      "Delete a VM snapshot"
		category:         "admin"
		params: {
			vm_name:       {from_field: "vm_name"}
			snapshot_name: {}
		}
		command_template: "Remove-Snapshot -Snapshot (Get-Snapshot -VM {vm_name} -Name {snapshot_name}) -Confirm:$false"
		destructive:      true
	}

	// ========== Host / Cluster Actions ==========

	host_info: vocab.#ActionDef & {
		name:             "Host Info"
		description:      "Get ESXi host status"
		category:         "info"
		params: host_name: {from_field: "host_name"}
		command_template: "Get-VMHost -Name {host_name} | Format-List"
		idempotent:       true
	}

	cluster_info: vocab.#ActionDef & {
		name:             "Cluster Info"
		description:      "Get cluster resource usage"
		category:         "monitor"
		params: cluster_name: {from_field: "cluster_name"}
		command_template: "Get-Cluster -Name {cluster_name} | Format-List"
		idempotent:       true
	}

	// ========== Datastore Actions ==========

	datastore_info: vocab.#ActionDef & {
		name:             "Datastore Info"
		description:      "Show datastore capacity and usage"
		category:         "info"
		params: datastore: {from_field: "datastore"}
		command_template: "Get-Datastore -Name {datastore} | Format-List"
		idempotent:       true
	}

	// Allow provider extensions
	...
}
