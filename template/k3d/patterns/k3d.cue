// K3d - K3s-in-Docker cluster management
//
// Requires: k3d CLI, Docker running
//
// Usage:
//   import "quicue.ca/template/k3d/patterns"

package patterns

import "quicue.ca/vocab"

#K3dRegistry: {
	cluster_list: vocab.#ActionDef & {
		name:        "cluster_list"
		description: "List k3d clusters"
		category:    "info"
		params: {}
		command_template: "k3d cluster list"
		idempotent:       true
	}

	cluster_create: vocab.#ActionDef & {
		name:        "cluster_create"
		description: "Create k3d cluster"
		category:    "admin"
		params: cluster_name: {from_field: "cluster_name"}
		command_template: "k3d cluster create {cluster_name}"
	}

	cluster_delete: vocab.#ActionDef & {
		name:        "cluster_delete"
		description: "Delete k3d cluster"
		category:    "admin"
		params: cluster_name: {from_field: "cluster_name"}
		command_template: "k3d cluster delete {cluster_name}"
		destructive:      true
	}

	cluster_start: vocab.#ActionDef & {
		name:        "cluster_start"
		description: "Start stopped k3d cluster"
		category:    "admin"
		params: cluster_name: {from_field: "cluster_name"}
		command_template: "k3d cluster start {cluster_name}"
	}

	cluster_stop: vocab.#ActionDef & {
		name:        "cluster_stop"
		description: "Stop running k3d cluster"
		category:    "admin"
		params: cluster_name: {from_field: "cluster_name"}
		command_template: "k3d cluster stop {cluster_name}"
	}

	node_list: vocab.#ActionDef & {
		name:        "node_list"
		description: "List k3d nodes"
		category:    "info"
		params: {}
		command_template: "k3d node list"
		idempotent:       true
	}

	kubeconfig_get: vocab.#ActionDef & {
		name:        "kubeconfig_get"
		description: "Write kubeconfig for cluster"
		category:    "info"
		params: cluster_name: {from_field: "cluster_name"}
		command_template: "k3d kubeconfig get {cluster_name}"
		idempotent:       true
	}

	registry_list: vocab.#ActionDef & {
		name:        "registry_list"
		description: "List k3d registries"
		category:    "info"
		params: {}
		command_template: "k3d registry list"
		idempotent:       true
	}

	registry_create: vocab.#ActionDef & {
		name:        "registry_create"
		description: "Create local container registry"
		category:    "admin"
		params: registry_name: {from_field: "registry_name", required: false}
		command_template: "k3d registry create {registry_name}"
	}

	...
}
