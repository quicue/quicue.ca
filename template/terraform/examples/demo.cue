// Demo: Terraform provider usage
// Define resources once, deploy to Proxmox and/or KubeVirt
package example

import "quicue.ca/template/terraform"

// Provider and backend configuration
_config: terraform.#TerraformConfig & {
	Proxmox: {
		endpoint:  "https://pve-alpha.example.com:8006"
		api_token: "terraform@pam!tf=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
		ssh: {
			username: "root"
			nodes: [{
				name:    "pve-alpha"
				address: "192.0.2.10"
			}, {
				name:    "pve-beta"
				address: "192.0.2.11"
			}]
		}
	}
	Kubernetes: config_path: "~/.kube/config"
	Backend: {
		type: "s3"
		config: {
			bucket: "terraform-state"
			key:    "infra/terraform.tfstate"
			region: "us-east-1"
		}
	}
}

// Define resources with platform targets
_resources: {
	// Minimal resource: single disk, default network
	"core-dns": terraform.#Compute & {
		name:   "core-dns"
		cpu:    2
		memory: "2Gi"
		disk:   "20Gi"
		proxmox: {
			node: "pve-alpha"
			vmid: 100
			tags: ["dns", "core"]
			onboot: true
			agent: enabled: true
		}
		kubevirt: {
			namespace:   "kube-system"
			runStrategy: "Always"
		}
	}

	// Cloud-init with network and expanded proxmox target
	"web-frontend": terraform.#Compute & {
		name:   "web-frontend"
		cpu:    4
		memory: "8Gi"
		disk:   "50Gi"
		network: [{
			bridge: "vmbr0"
			model:  "virtio"
			vlan:   100
		}]
		cloudinit: {
			user: "deploy"
			ssh_keys: ["ssh-ed25519 AAAA... admin@infra"]
			ip:      "198.51.100.50/24"
			gateway: "198.51.100.1"
			dns_servers: ["198.51.100.1", "1.1.1.1"]
		}
		proxmox: {
			node:          "pve-beta"
			vmid:          200
			template:      "9000"
			onboot:        true
			bios:          "ovmf"
			machine:       "q35"
			os_type:       "l26"
			cpu_type:      "host"
			serial_device: true
			boot_order: ["scsi0", "net0"]
			tags: ["web", "prod"]
			agent: {
				enabled: true
				trim:    true
			}
			startup: {
				order:    2
				up_delay: 30
			}
		}
		kubevirt: {
			namespace:        "prod"
			instancetype:     "u1.large"
			evictionStrategy: "LiveMigrate"
		}
	}

	// Multi-disk GPU worker with PCI passthrough
	"gpu-worker": terraform.#Compute & {
		name:   "gpu-worker"
		cpu:    16
		memory: "64Gi"
		disk:   "500Gi"
		disks: [{
			size:      "100Gi"
			datastore: "local-zfs"
			interface: "scsi"
			cache:     "writeback"
			discard:   true
			iothread:  true
			ssd:       true
		}, {
			size:      "500Gi"
			datastore: "ceph-pool"
			interface: "scsi"
			discard:   true
		}]
		proxmox: {
			node:     "pve-alpha"
			pool:     "gpu-pool"
			cpu_type: "host"
			machine:  "q35"
			bios:     "ovmf"
			hostpci: [{
				device:  "hostpci0"
				mapping: "gpu-rtx4090"
				pcie:    true
				rombar:  true
			}]
			tags: ["gpu", "ml"]
			startup: {
				order:      1
				up_delay:   60
				down_delay: 30
			}
		}
	}

	// KubeVirt-only ephemeral worker
	"api-ephemeral": terraform.#Compute & {
		name:   "api-ephemeral"
		cpu:    2
		memory: "4Gi"
		disk:   "10Gi"
		kubevirt: {
			namespace:    "prod"
			storageClass: "local-path"
			runStrategy:  "RerunOnFailure"
			labels: "app": "api"
		}
	}

	// Minimal KubeVirt with cloud-init
	"k8s-worker": terraform.#Compute & {
		name:   "k8s-worker"
		cpu:    8
		memory: "16Gi"
		disk:   "100Gi"
		cloudinit: {
			user: "kube"
			ssh_keys: ["ssh-ed25519 AAAA... ops@infra"]
			ip:      "203.0.113.20/24"
			gateway: "203.0.113.1"
		}
		proxmox: {
			node:          "pve-alpha"
			vmid:          300
			template:      "9000"
			onboot:        true
			serial_device: true
			agent: enabled: true
			tags: ["k8s", "worker"]
		}
	}
}

// Generate Terraform JSON
tf: terraform.#TerraformOutput & {
	Config:    _config
	Resources: _resources
}

// Export commands:
//   cue export ./template/terraform/examples -e tf.output --out json > main.tf.json
//   cue export ./template/terraform/examples -e tf.summary --out json
//   cue export ./template/terraform/examples -e tf.mirrored --out json
