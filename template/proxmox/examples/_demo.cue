// Demo: Proxmox provider usage
package example

import "quicue.ca/proxmox/patterns"

// Define resource parameters once, unify with action patterns
_webServer: {VMID: 100, NODE: "pve1"}

web_server: {
	vm:        patterns.#VMActions & _webServer
	lifecycle: patterns.#VMLifecycle & _webServer
	snapshots: patterns.#VMSnapshots & _webServer
	connect: patterns.#ConnectivityActions & {IP: "10.0.1.100", USER: "root"}
}

// LXC container
_dnsServer: {CTID: 101, NODE: "pve1"}

dns_server: {
	ct:        patterns.#ContainerActions & _dnsServer
	lifecycle: patterns.#ContainerLifecycle & _dnsServer
	snapshots: patterns.#ContainerSnapshots & _dnsServer
}

// Hypervisor nodes
cluster: {
	pve1: patterns.#HypervisorActions & {NODE: "pve1"}
	pve2: patterns.#HypervisorActions & {NODE: "pve2"}
	pve3: patterns.#HypervisorActions & {NODE: "pve3"}
}

// Export commands:
//   cue export ./examples -e web_server.vm.status.command --out text
//   cue export ./examples -e cluster.pve1.list_vms.command --out text

// Summary output
output: {
	example_commands: {
		"vm_status":        "pvesh get /nodes/pve1/qemu/100/status/current"
		"vm_console":       "qm terminal 100"
		"ct_status":        "pvesh get /nodes/pve1/lxc/101/status/current"
		"ct_console":       "pct enter 101"
		"cluster_list_vms": "pvesh get /nodes/pve1/qemu"
	}
	usage: """
		# Get any command:
		cue export ./examples -e web_server.vm.status.command --out text
		cue export ./examples -e dns_server.ct.console.command --out text
		cue export ./examples -e cluster.pve1.list_vms.command --out text
		"""
}
