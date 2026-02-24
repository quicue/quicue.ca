// KubeVirt - VM management on Kubernetes via virtctl
//
// Requires: virtctl CLI, kubeconfig configured
//   virtctl is a kubectl plugin for VM lifecycle
//
// Usage:
//   import "quicue.ca/template/kubevirt/patterns"

package patterns

import "quicue.ca/vocab"

#KubeVirtRegistry: {
	// ========== VM Lifecycle ==========

	vm_start: vocab.#ActionDef & {
		name:        "vm_start"
		description: "Start a VirtualMachine"
		category:    "admin"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "virtctl start {vm_name} -n {namespace}"
	}

	vm_stop: vocab.#ActionDef & {
		name:        "vm_stop"
		description: "Stop a VirtualMachine (graceful)"
		category:    "admin"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "virtctl stop {vm_name} -n {namespace}"
	}

	vm_restart: vocab.#ActionDef & {
		name:        "vm_restart"
		description: "Restart a VirtualMachine"
		category:    "admin"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "virtctl restart {vm_name} -n {namespace}"
	}

	vm_pause: vocab.#ActionDef & {
		name:        "vm_pause"
		description: "Pause a running VirtualMachineInstance"
		category:    "admin"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "virtctl pause vm {vm_name} -n {namespace}"
	}

	vm_unpause: vocab.#ActionDef & {
		name:        "vm_unpause"
		description: "Unpause a paused VirtualMachineInstance"
		category:    "admin"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "virtctl unpause vm {vm_name} -n {namespace}"
	}

	// ========== Console / Access ==========

	console: vocab.#ActionDef & {
		name:        "console"
		description: "Open serial console to VM"
		category:    "connect"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "virtctl console {vm_name} -n {namespace}"
	}

	vnc: vocab.#ActionDef & {
		name:        "vnc"
		description: "Open VNC console to VM"
		category:    "connect"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "virtctl vnc {vm_name} -n {namespace}"
	}

	ssh: vocab.#ActionDef & {
		name:        "ssh"
		description: "SSH into VM via virtctl proxy"
		category:    "connect"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "virtctl ssh {vm_name} -n {namespace}"
	}

	// ========== Migration ==========

	migrate: vocab.#ActionDef & {
		name:        "migrate"
		description: "Live migrate VM to another node"
		category:    "admin"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
		}
		command_template: "virtctl migrate {vm_name} -n {namespace}"
	}

	// ========== Networking ==========

	expose: vocab.#ActionDef & {
		name:        "expose"
		description: "Expose VM port via Service"
		category:    "admin"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
			port: {}
			svc_name: {}
		}
		command_template: "virtctl expose vm {vm_name} --port {port} --name {svc_name} -n {namespace}"
	}

	port_forward: vocab.#ActionDef & {
		name:        "port_forward"
		description: "Forward local port to VM"
		category:    "connect"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
			port_map: {}
		}
		command_template: "virtctl port-forward {vm_name} {port_map} -n {namespace}"
	}

	// ========== Disk / Image ==========

	image_upload: vocab.#ActionDef & {
		name:        "image_upload"
		description: "Upload VM disk image to DataVolume"
		category:    "admin"
		params: {
			image_path: {}
			dv_name: {}
			namespace: {from_field: "namespace", required: false}
			size: {}
		}
		command_template: "virtctl image-upload dv {dv_name} --image-path={image_path} --size={size} -n {namespace}"
	}

	// ========== Snapshots ==========

	snapshot_create: vocab.#ActionDef & {
		name:        "snapshot_create"
		description: "Create VM snapshot"
		category:    "admin"
		params: {
			vm_name: {from_field: "vm_name"}
			namespace: {from_field: "namespace", required: false}
			snapshot_name: {}
		}
		command_template: "kubectl create -f - <<< '{\"apiVersion\":\"snapshot.kubevirt.io/v1alpha1\",\"kind\":\"VirtualMachineSnapshot\",\"metadata\":{\"name\":\"{snapshot_name}\",\"namespace\":\"{namespace}\"},\"spec\":{\"source\":{\"apiGroup\":\"kubevirt.io\",\"kind\":\"VirtualMachine\",\"name\":\"{vm_name}\"}}}'"
	}

	...
}
