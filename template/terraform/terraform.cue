// Terraform provider for quicue
//
// Generates Terraform JSON (main.tf.json) from quicue resource graphs.
// Platform-specific generators: proxmox.cue, kubevirt.cue
//
// Usage:
//   import "quicue.ca/template/terraform"
//
//   tf: terraform.#TerraformOutput & {Resources: myResources}

package terraform

// Memory lookup table: human-readable → MB
_memoryMB: {
	"256Mi":  256
	"512Mi":  512
	"768Mi":  768
	"1Gi":    1024
	"2Gi":    2048
	"4Gi":    4096
	"8Gi":    8192
	"16Gi":   16384
	"32Gi":   32768
	"64Gi":   65536
	"128Gi":  131072
	"256Gi":  262144
	"384Gi":  393216
	"512Gi":  524288
}

// Disk lookup table: human-readable → GB
_diskGB: {
	"5Gi":   5
	"8Gi":   8
	"10Gi":  10
	"15Gi":  15
	"20Gi":  20
	"25Gi":  25
	"30Gi":  30
	"40Gi":  40
	"50Gi":  50
	"100Gi": 100
	"200Gi": 200
	"500Gi": 500
	"1Ti":   1024
	"2Ti":   2048
	"4Ti":   4096
}

// #Compute - Platform-agnostic resource definition
// Define once, deploy to one or more platforms via target blocks.
#Compute: {
	name:   string & =~"^[a-z][a-z0-9-]*$"
	cpu:    int & >=1 & <=128
	memory: #Memory
	disk:   #Storage

	// Multi-disk (overrides single disk when present)
	disks?: [...#Disk]

	// Network interfaces
	network?: [...#NetworkInterface]

	// Cloud-init provisioning
	cloudinit?: #CloudInit

	proxmox?:  #ProxmoxTarget
	kubevirt?: #KubeVirtTarget
}

#Memory:  =~"^[0-9]+(Gi|Mi)$"
#Storage: =~"^[0-9]+(Gi|Ti)$"

// #Disk - Individual disk configuration
#Disk: {
	size:      #Storage
	datastore: *"local-lvm" | string
	interface: *"scsi" | "virtio" | "sata" | "ide"
	cache?:    "none" | "directsync" | "writethrough" | "writeback" | "unsafe"
	discard?:  bool
	iothread?: bool
	ssd?:      bool
	backup?:   bool | *true
}

// #NetworkInterface - Network device configuration
#NetworkInterface: {
	bridge:    *"vmbr0" | string
	model:     *"virtio" | "e1000" | "rtl8139"
	vlan?:     int & >=1 & <=4094
	mac?:      string & =~"^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$"
	firewall?: bool
	mtu?:      int & >=68 & <=9000
}

// #CloudInit - Cloud-init provisioning configuration
#CloudInit: {
	user?:     string
	ssh_keys?: [...string]
	password?: string

	// Network
	ip?:      string
	gateway?: string

	// DNS
	dns_domain?:  string
	dns_servers?: [...string]

	// Custom snippets
	user_data_file?:   string
	vendor_data_file?: string

	// Cloud-init drive storage
	datastore: *"local-lvm" | string
}

// #TerraformOutput - Generate complete Terraform JSON from resources
//
// Usage:
//   cue export -e tf.output --out json > main.tf.json
//   terraform plan
#TerraformOutput: {
	Resources: [string]: #Compute
	Config?:   #TerraformConfig

	// Filter by platform
	_forProxmox: {
		for name, r in Resources if r.proxmox != _|_ {
			"\(name)": {
				_resource: r
				_target:   r.proxmox
			}
		}
	}

	_forKubeVirt: {
		for name, r in Resources if r.kubevirt != _|_ {
			"\(name)": {
				_resource: r
				_target:   r.kubevirt
			}
		}
	}

	// Generate platform-specific Terraform blocks
	_proxmox:  _proxmoxTerraform & {_input: _forProxmox}
	_kubevirt: _kubevirtTerraform & {_input: _forKubeVirt}

	// Generate terraform/provider blocks from Config
	_terraformBlock: {
		if Config != _|_ {
			required_providers: {
				if Config.Proxmox != _|_ || len([for n, _ in _forProxmox {n}]) > 0 {
					proxmox: {
						source:  "bpg/proxmox"
						version: Config.ProxmoxVersion
					}
				}
				if Config.Kubernetes != _|_ || len([for n, _ in _forKubeVirt {n}]) > 0 {
					kubernetes: {
						source:  "hashicorp/kubernetes"
						version: Config.KubernetesVersion
					}
				}
			}
			if Config.Backend != _|_ {
				backend: (Config.Backend.type): Config.Backend.config
			}
		}
	}

	_providerBlock: {
		if Config != _|_ {
			if Config.Proxmox != _|_ {
				proxmox: [{
					endpoint: Config.Proxmox.endpoint
					insecure: Config.Proxmox.insecure
					if Config.Proxmox.api_token != _|_ {
						api_token: Config.Proxmox.api_token
					}
					if Config.Proxmox.username != _|_ {
						username: Config.Proxmox.username
					}
					if Config.Proxmox.password != _|_ {
						password: Config.Proxmox.password
					}
					if Config.Proxmox.ssh != _|_ {
						ssh: [{
							agent:    Config.Proxmox.ssh.agent
							username: Config.Proxmox.ssh.username
							if Config.Proxmox.ssh.nodes != _|_ {
								node: [
									for n in Config.Proxmox.ssh.nodes {
										name:    n.name
										address: n.address
									},
								]
							}
						}]
					}
				}]
			}
			if Config.Kubernetes != _|_ {
				kubernetes: [{
					if Config.Kubernetes.config_path != _|_ {
						config_path: Config.Kubernetes.config_path
					}
					if Config.Kubernetes.config_context != _|_ {
						config_context: Config.Kubernetes.config_context
					}
					if Config.Kubernetes.host != _|_ {
						host: Config.Kubernetes.host
					}
				}]
			}
		}
	}

	// Combined output: valid Terraform JSON
	output: {
		if Config != _|_ {
			terraform: _terraformBlock
			provider:  _providerBlock
		}
		resource: {
			_proxmox.resource
			_kubevirt.resource
		}
	}

	// Queries
	mirrored: [for name, r in Resources if r.proxmox != _|_ if r.kubevirt != _|_ {name}]
	proxmox_only: [for name, r in Resources if r.proxmox != _|_ if r.kubevirt == _|_ {name}]
	kubevirt_only: [for name, r in Resources if r.kubevirt != _|_ if r.proxmox == _|_ {name}]
	summary: {
		proxmox:       len([for name, r in Resources if r.proxmox != _|_ {name}])
		kubevirt:      len([for name, r in Resources if r.kubevirt != _|_ {name}])
		mirrored:      len([for name, r in Resources if r.proxmox != _|_ if r.kubevirt != _|_ {name}])
		proxmox_only:  len([for name, r in Resources if r.proxmox != _|_ if r.kubevirt == _|_ {name}])
		kubevirt_only: len([for name, r in Resources if r.kubevirt != _|_ if r.proxmox == _|_ {name}])
	}
}
