// Incus - Container and VM management (LXD successor)
//
// Requires: incus CLI
//
// Usage:
//   import "quicue.ca/template/incus/patterns"

package patterns

import "quicue.ca/vocab"

#IncusRegistry: {
	list: vocab.#ActionDef & {
		name:        "list"
		description: "List all instances (containers and VMs)"
		category:    "info"
		params: {}
		command_template: "incus list -f compact"
		idempotent:       true
	}

	info: vocab.#ActionDef & {
		name:        "info"
		description: "Detailed instance information"
		category:    "info"
		params: instance_name: {from_field: "instance_name"}
		command_template: "incus info {instance_name}"
		idempotent:       true
	}

	start: vocab.#ActionDef & {
		name:        "start"
		description: "Start instance"
		category:    "admin"
		params: instance_name: {from_field: "instance_name"}
		command_template: "incus start {instance_name}"
	}

	stop: vocab.#ActionDef & {
		name:        "stop"
		description: "Stop instance"
		category:    "admin"
		params: instance_name: {from_field: "instance_name"}
		command_template: "incus stop {instance_name}"
	}

	restart: vocab.#ActionDef & {
		name:        "restart"
		description: "Restart instance"
		category:    "admin"
		params: instance_name: {from_field: "instance_name"}
		command_template: "incus restart {instance_name}"
	}

	delete: vocab.#ActionDef & {
		name:        "delete"
		description: "Delete instance"
		category:    "admin"
		params: instance_name: {from_field: "instance_name"}
		command_template: "incus delete {instance_name}"
		destructive:      true
	}

	exec: vocab.#ActionDef & {
		name:        "exec"
		description: "Execute command in instance"
		category:    "connect"
		params: {
			instance_name: {from_field: "instance_name"}
			command: {}
		}
		command_template: "incus exec {instance_name} -- {command}"
	}

	snapshot_create: vocab.#ActionDef & {
		name:        "snapshot_create"
		description: "Create instance snapshot"
		category:    "admin"
		params: {
			instance_name: {from_field: "instance_name"}
			snapshot_name: {required: false}
		}
		command_template: "incus snapshot create {instance_name} {snapshot_name}"
	}

	snapshot_restore: vocab.#ActionDef & {
		name:        "snapshot_restore"
		description: "Restore instance from snapshot"
		category:    "admin"
		params: {
			instance_name: {from_field: "instance_name"}
			snapshot_name: {}
		}
		command_template: "incus snapshot restore {instance_name} {snapshot_name}"
		destructive:      true
	}

	image_list: vocab.#ActionDef & {
		name:        "image_list"
		description: "List available images"
		category:    "info"
		params: {}
		command_template: "incus image list -f compact"
		idempotent:       true
	}

	profile_list: vocab.#ActionDef & {
		name:        "profile_list"
		description: "List instance profiles"
		category:    "info"
		params: {}
		command_template: "incus profile list -f compact"
		idempotent:       true
	}

	network_list: vocab.#ActionDef & {
		name:        "network_list"
		description: "List managed networks"
		category:    "info"
		params: {}
		command_template: "incus network list -f compact"
		idempotent:       true
	}

	storage_list: vocab.#ActionDef & {
		name:        "storage_list"
		description: "List storage pools"
		category:    "info"
		params: {}
		command_template: "incus storage list -f compact"
		idempotent:       true
	}

	cluster_list: vocab.#ActionDef & {
		name:        "cluster_list"
		description: "List cluster members"
		category:    "info"
		params: {}
		command_template: "incus cluster list -f compact"
		idempotent:       true
	}

	launch: vocab.#ActionDef & {
		name:        "launch"
		description: "Create and start a new instance from image"
		category:    "admin"
		params: {
			instance_name: {from_field: "instance_name"}
			image: {from_field: "image", required: false}
		}
		command_template: "incus launch {image} {instance_name}"
	}

	copy: vocab.#ActionDef & {
		name:        "copy"
		description: "Copy instance (clone)"
		category:    "admin"
		params: instance_name: {from_field: "instance_name"}
		command_template: "incus copy {instance_name} {instance_name}-copy"
	}

	file_push: vocab.#ActionDef & {
		name:        "file_push"
		description: "Push file into instance"
		category:    "admin"
		params: instance_name: {from_field: "instance_name"}
		command_template: "incus file push - {instance_name}/tmp/"
	}

	logs: vocab.#ActionDef & {
		name:        "logs"
		description: "View instance journal logs"
		category:    "monitor"
		params: instance_name: {from_field: "instance_name"}
		command_template: "incus exec {instance_name} -- journalctl -n 100"
		idempotent:       true
	}

	...
}
