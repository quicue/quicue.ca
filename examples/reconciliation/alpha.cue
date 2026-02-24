// Source Alpha — hypervisor inventory (authority rank 1, highest)
//
// Analogous to: vCenter, Proxmox, Hyper-V, libvirt, or any hypervisor
// that is the authoritative source for physical VM state.
//
// Authority 1 means Alpha's IP wins all conflicts in resolutions.cue.

package reconciliation

vms: {
	"web-p01": {
		_in_alpha: true, alpha_ip:              "198.51.100.10"
		state:     "running", cpus:             4, memory_gb:      16
		os:        "Ubuntu 24.04 LTS", cluster: "prod-east", host: "hv-01.lab.example.com"
	}
	"web-p02": {
		_in_alpha: true, alpha_ip:              "198.51.100.11"
		state:     "running", cpus:             4, memory_gb:      16
		os:        "Ubuntu 24.04 LTS", cluster: "prod-east", host: "hv-02.lab.example.com"
	}
	"db-p01": {
		_in_alpha: true, alpha_ip:           "198.51.100.20"
		state:     "running", cpus:          8, memory_gb:      64
		os:        "Rocky Linux 9", cluster: "prod-east", host: "hv-01.lab.example.com"
	}
	"db-p02": {
		_in_alpha: true, alpha_ip:           "198.51.100.21"
		state:     "running", cpus:          8, memory_gb:      64
		os:        "Rocky Linux 9", cluster: "prod-west", host: "hv-03.lab.example.com"
	}
	"lb-p01": {
		_in_alpha: true, alpha_ip:       "198.51.100.30"
		state:     "running", cpus:      2, memory_gb:      4
		os:        "Debian 12", cluster: "prod-east", host: "hv-01.lab.example.com"
	}
	"ci-d01": {
		_in_alpha: true, alpha_ip:              "203.0.113.10"
		state:     "running", cpus:             4, memory_gb: 8
		os:        "Ubuntu 22.04 LTS", cluster: "dev", host:  "hv-04.lab.example.com"
	}
	"ci-d02": {
		_in_alpha: true, alpha_ip:              "203.0.113.11"
		state:     "stopped", cpus:             2, memory_gb: 4
		os:        "Ubuntu 22.04 LTS", cluster: "dev", host:  "hv-04.lab.example.com"
	}
	"mon-p01": {
		_in_alpha: true, alpha_ip:           "198.51.100.40"
		state:     "running", cpus:          4, memory_gb:      16
		os:        "Rocky Linux 9", cluster: "prod-west", host: "hv-03.lab.example.com"
	}
	"bak-p01": {
		_in_alpha: true, alpha_ip:       "198.51.100.50"
		state:     "running", cpus:      2, memory_gb:      8
		os:        "Debian 12", cluster: "prod-west", host: "hv-03.lab.example.com"
	}
	"auth-p01": {
		_in_alpha: true, alpha_ip:                 "198.51.100.60"
		state:     "running", cpus:                2, memory_gb:      8
		os:        "Windows Server 2022", cluster: "prod-east", host: "hv-02.lab.example.com"
	}
	"vpn-p01": {
		_in_alpha: true, alpha_ip:       "198.51.100.70"
		state:     "running", cpus:      2, memory_gb:      4
		os:        "Debian 12", cluster: "prod-east", host: "hv-01.lab.example.com"
	}
	// Alpha-only VM: visible to hypervisor but not tracked elsewhere
	"test-d99": {
		_in_alpha: true, alpha_ip:          "203.0.113.99"
		state:     "stopped", cpus:         1, memory_gb: 2
		os:        "Alpine Linux", cluster: "dev", host:  "hv-04.lab.example.com"
	}
}
