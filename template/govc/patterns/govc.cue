// govc Provider - vSphere VM management via govc CLI
//
// Requires environment variables:
//   GOVC_URL, GOVC_USERNAME, GOVC_PASSWORD
//   GOVC_INSECURE=1 (for self-signed / vcsim)
//
// Usage:
//   import "quicue.ca/template/govc/patterns"

package patterns

import "quicue.ca/vocab"

// #GovcRegistry - govc action definitions
#GovcRegistry: {
	// ========== VM Actions ==========

	vm_info: vocab.#ActionDef & {
		name:             "VM Info"
		description:      "Get VM power state, CPU, memory, and guest IP"
		category:         "info"
		params: vm_path: {from_field: "vm_path"}
		command_template: "govc vm.info {vm_path}"
		idempotent:       true
	}

	vm_info_json: vocab.#ActionDef & {
		name:             "VM Info (JSON)"
		description:      "Get full VM configuration as JSON"
		category:         "info"
		params: vm_path: {from_field: "vm_path"}
		command_template: "govc vm.info -json {vm_path}"
		idempotent:       true
	}

	vm_console: vocab.#ActionDef & {
		name:             "VM Console"
		description:      "Open VMRC/web console URL"
		category:         "connect"
		params: vm_path: {from_field: "vm_path"}
		command_template: "govc vm.console {vm_path}"
	}

	// ========== Lifecycle Actions ==========

	vm_power_on: vocab.#ActionDef & {
		name:             "Power On"
		description:      "Power on VM"
		category:         "admin"
		params: vm_path: {from_field: "vm_path"}
		command_template: "govc vm.power -on {vm_path}"
	}

	vm_power_off: vocab.#ActionDef & {
		name:             "Power Off (graceful)"
		description:      "Shut down VM via guest tools"
		category:         "admin"
		params: vm_path: {from_field: "vm_path"}
		command_template: "govc vm.power -off -s {vm_path}"
	}

	vm_power_off_hard: vocab.#ActionDef & {
		name:             "Power Off (hard)"
		description:      "Hard power off VM"
		category:         "admin"
		params: vm_path: {from_field: "vm_path"}
		command_template: "govc vm.power -off {vm_path}"
		destructive:      true
	}

	vm_reset: vocab.#ActionDef & {
		name:             "Reset"
		description:      "Hard reset VM"
		category:         "admin"
		params: vm_path: {from_field: "vm_path"}
		command_template: "govc vm.power -reset {vm_path}"
		destructive:      true
	}

	vm_suspend: vocab.#ActionDef & {
		name:             "Suspend"
		description:      "Suspend VM to memory"
		category:         "admin"
		params: vm_path: {from_field: "vm_path"}
		command_template: "govc vm.power -suspend {vm_path}"
	}

	// ========== Snapshot Actions ==========

	snapshot_tree: vocab.#ActionDef & {
		name:             "Snapshot Tree"
		description:      "List VM snapshot tree"
		category:         "info"
		params: vm_path: {from_field: "vm_path"}
		command_template: "govc snapshot.tree -vm {vm_path}"
		idempotent:       true
	}

	snapshot_create: vocab.#ActionDef & {
		name:             "Create Snapshot"
		description:      "Create VM snapshot"
		category:         "admin"
		params: {
			vm_path:       {from_field: "vm_path"}
			snapshot_name: {required: false}
		}
		command_template: "govc snapshot.create -vm {vm_path} {snapshot_name}"
	}

	snapshot_revert: vocab.#ActionDef & {
		name:             "Revert Snapshot"
		description:      "Revert VM to named snapshot"
		category:         "admin"
		params: {
			vm_path:       {from_field: "vm_path"}
			snapshot_name: {}
		}
		command_template: "govc snapshot.revert -vm {vm_path} {snapshot_name}"
		destructive:      true
	}

	snapshot_remove: vocab.#ActionDef & {
		name:             "Remove Snapshot"
		description:      "Delete a VM snapshot"
		category:         "admin"
		params: {
			vm_path:       {from_field: "vm_path"}
			snapshot_name: {}
		}
		command_template: "govc snapshot.remove -vm {vm_path} {snapshot_name}"
		destructive:      true
	}

	// ========== Host / Cluster Actions ==========

	host_info: vocab.#ActionDef & {
		name:             "Host Info"
		description:      "Get ESXi host status and resource usage"
		category:         "info"
		params: host_path: {from_field: "host_path"}
		command_template: "govc host.info {host_path}"
		idempotent:       true
	}

	cluster_usage: vocab.#ActionDef & {
		name:             "Cluster Usage"
		description:      "Show cluster resource usage summary"
		category:         "monitor"
		params: cluster_path: {from_field: "cluster_path"}
		command_template: "govc cluster.usage {cluster_path}"
		idempotent:       true
	}

	ls: vocab.#ActionDef & {
		name:             "List Inventory"
		description:      "List objects in vSphere inventory path"
		category:         "info"
		params: inventory_path: {from_field: "inventory_path"}
		command_template: "govc ls {inventory_path}"
		idempotent:       true
	}

	// ========== Datastore Actions ==========

	datastore_info: vocab.#ActionDef & {
		name:             "Datastore Info"
		description:      "Show datastore capacity and usage"
		category:         "info"
		params: datastore: {from_field: "datastore"}
		command_template: "govc datastore.info {datastore}"
		idempotent:       true
	}

	datastore_ls: vocab.#ActionDef & {
		name:             "Datastore Contents"
		description:      "List files on datastore"
		category:         "info"
		params: datastore: {from_field: "datastore"}
		command_template: "govc datastore.ls -ds {datastore}"
		idempotent:       true
	}

	// Allow provider extensions
	...
}
