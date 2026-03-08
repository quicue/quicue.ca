// VCF Migration — Resource definitions (Layer 3: Instance)
//
// 11 resources representing a realistic migration scenario:
// - 2 hypervisor platforms (Nutanix/ESXi current, Dell VCF target)
// - 1 vCenter management plane
// - 1 F5 load balancer
// - 2 ESXi hosts (source)
// - 1 Dell target host
// - 5 VMs to migrate (Artifactory, GitLab, DB, App, Web)
//
// All resources use generic field names (vm_path, host, ip).
// Provider templates map these to platform-specific commands.
//
// Run: cue eval ./examples/vcf-migration/ -e output --out json

package main

import "quicue.ca/vocab@v0"

// ── Infrastructure Resources ────────────────────────────────────

resources: {
	"vcenter-primary": vocab.#Resource & {
		name: "vcenter-primary"
		ip:   "198.51.100.10"
		"@type": {VMwareCluster: true, CriticalInfra: true}
		tags: {management: true}
	}

	"nutanix-cluster-01": vocab.#Resource & {
		name: "nutanix-cluster-01"
		ip:   "198.51.100.20"
		"@type": {VirtualizationPlatform: true}
		tags: {current_platform: true}
	}

	"f5-primary": vocab.#Resource & {
		name: "f5-primary"
		ip:   "198.51.100.5"
		"@type": {LoadBalancer: true, CriticalInfra: true}
		tags: {shared_service: true}
	}

	"esxi-host-01": vocab.#Resource & {
		name:     "esxi-host-01"
		ip:       "198.51.100.11"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true}
		depends_on: {"vcenter-primary": true}
		host_path: "/DC1/host/Cluster1/198.51.100.11"
		tags: {source: true}
	}

	"esxi-host-02": vocab.#Resource & {
		name:     "esxi-host-02"
		ip:       "198.51.100.12"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true}
		depends_on: {"vcenter-primary": true}
		host_path: "/DC1/host/Cluster1/198.51.100.12"
		tags: {source: true}
	}

	"dell-target-01": vocab.#Resource & {
		name:     "dell-target-01"
		ip:       "198.51.100.30"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true}
		host_path: "/VCF-DC/host/VCF-Cluster/198.51.100.30"
		tags: {target: true, vcf: true}
	}

	// ── VMs to migrate ──────────────────────────────────────────

	"vm-artifactory": vocab.#Resource & {
		name:    "vm-artifactory"
		ip:      "198.51.100.101"
		vm_path: "/DC1/vm/Artifactory"
		vm_id:   1001
		host:    "esxi-host-01"
		"@type": {VirtualMachine: true, ContainerRegistry: true}
		depends_on: {"esxi-host-01": true, "f5-primary": true}
		tags: {portable: true, wave_pilot: true}
	}

	"vm-gitlab": vocab.#Resource & {
		name:    "vm-gitlab"
		ip:      "198.51.100.102"
		vm_path: "/DC1/vm/GitLab"
		vm_id:   1002
		host:    "esxi-host-01"
		"@type": {VirtualMachine: true, SourceControlManagement: true}
		depends_on: {"esxi-host-01": true}
		tags: {portable: true, wave_pilot: true}
		url: "https://git.example.com"
	}

	"vm-db-primary": vocab.#Resource & {
		name:    "vm-db-primary"
		ip:      "198.51.100.103"
		vm_path: "/DC1/vm/DB-Primary"
		vm_id:   1003
		host:    "esxi-host-02"
		"@type": {VirtualMachine: true, Database: true, CriticalInfra: true}
		depends_on: {"esxi-host-02": true}
		tags: {portable: true, wave_1: true}
		url: "postgresql://198.51.100.103:5432"
	}

	"vm-app-server": vocab.#Resource & {
		name:    "vm-app-server"
		ip:      "198.51.100.104"
		vm_path: "/DC1/vm/App-Server"
		vm_id:   1004
		host:    "esxi-host-02"
		"@type": {VirtualMachine: true, APIServer: true}
		depends_on: {"esxi-host-02": true, "vm-db-primary": true, "f5-primary": true}
		tags: {portable: true, wave_1: true}
	}

	"vm-web-frontend": vocab.#Resource & {
		name:    "vm-web-frontend"
		ip:      "198.51.100.105"
		vm_path: "/DC1/vm/Web-Frontend"
		vm_id:   1005
		host:    "esxi-host-01"
		"@type": {VirtualMachine: true, WebFrontend: true}
		depends_on: {"esxi-host-01": true, "vm-app-server": true, "f5-primary": true}
		tags: {containerizable: true, wave_2: true}
	}
}
