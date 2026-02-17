// Demo: govc provider usage — vcsim targets
package examples

import "quicue.ca/template/govc/patterns"

// Registry instance
actions: patterns.#GovcRegistry

// vcsim default inventory paths
output: {
	example_commands: {
		vm_info:        "govc vm.info /DC0/vm/DC0_H0_VM0"
		vm_power_on:    "govc vm.power -on /DC0/vm/DC0_H0_VM0"
		snapshot_tree:  "govc snapshot.tree -vm /DC0/vm/DC0_H0_VM0"
		host_info:      "govc host.info /DC0/host/DC0_H0/DC0_H0"
		cluster_usage:  "govc cluster.usage /DC0/host/DC0_C0"
		datastore_info: "govc datastore.info LocalDS_0"
		ls_vms:         "govc ls /DC0/vm/"
	}
	env_setup: """
		export GOVC_URL=https://localhost:8989
		export GOVC_USERNAME=user
		export GOVC_PASSWORD=pass
		export GOVC_INSECURE=1
		"""
}
