// Provider declarations — one set per tier
//
// Each tier binds different providers to the same resource graph.
// Provider matching is by @type overlap: only providers whose declared
// types intersect a resource's @type will bind.

package platform

import (
	"quicue.ca/patterns@v0"

	docker_patterns "quicue.ca/template/docker/patterns"
	proxmox_patterns "quicue.ca/template/proxmox/patterns"
	powerdns_patterns "quicue.ca/template/powerdns/patterns"
	caddy_patterns "quicue.ca/template/caddy/patterns"
	postgresql_patterns "quicue.ca/template/postgresql/patterns"
	zabbix_patterns "quicue.ca/template/zabbix/patterns"
	k3d_patterns "quicue.ca/template/k3d/patterns"
	kubectl_patterns "quicue.ca/template/kubectl/patterns"
	govc_patterns "quicue.ca/template/govc/patterns"
	vault_patterns "quicue.ca/template/vault/patterns"
)

// ─── Desktop: Docker only ────────────────────────────────────────────

_desktop_providers: {
	docker: patterns.#ProviderDecl & {
		types:    {DockerContainer: true, DockerHost: true}
		registry: docker_patterns.#DockerRegistry
	}
}

// ─── Node: Proxmox + service providers ───────────────────────────────

_node_providers: {
	proxmox: patterns.#ProviderDecl & {
		types:    {VirtualizationPlatform: true, LXCContainer: true, VirtualMachine: true}
		registry: proxmox_patterns.#ProxmoxRegistry
	}
	docker: patterns.#ProviderDecl & {
		types:    {DockerContainer: true}
		registry: docker_patterns.#DockerRegistry
	}
	powerdns: patterns.#ProviderDecl & {
		types:    {DNSServer: true}
		registry: powerdns_patterns.#PowerDNSRegistry
	}
	caddy: patterns.#ProviderDecl & {
		types:    {ReverseProxy: true}
		registry: caddy_patterns.#CaddyRegistry
	}
	postgresql: patterns.#ProviderDecl & {
		types:    {Database: true}
		registry: postgresql_patterns.#PostgreSQLRegistry
	}
	zabbix: patterns.#ProviderDecl & {
		types:    {MonitoringServer: true}
		registry: zabbix_patterns.#ZabbixRegistry
	}
}

// ─── Cluster: k3d + kubectl ──────────────────────────────────────────

_cluster_providers: {
	k3d: patterns.#ProviderDecl & {
		types:    {KubernetesCluster: true}
		registry: k3d_patterns.#K3dRegistry
	}
	kubectl: patterns.#ProviderDecl & {
		types:    {KubernetesService: true}
		registry: kubectl_patterns.#KubectlRegistry
	}
}

// ─── Enterprise: govc + full ops suite ───────────────────────────────

_enterprise_providers: {
	govc: patterns.#ProviderDecl & {
		types:    {VMwareCluster: true, VirtualMachine: true}
		registry: govc_patterns.#GovcRegistry
	}
	powerdns: patterns.#ProviderDecl & {
		types:    {DNSServer: true}
		registry: powerdns_patterns.#PowerDNSRegistry
	}
	caddy: patterns.#ProviderDecl & {
		types:    {ReverseProxy: true}
		registry: caddy_patterns.#CaddyRegistry
	}
	postgresql: patterns.#ProviderDecl & {
		types:    {Database: true}
		registry: postgresql_patterns.#PostgreSQLRegistry
	}
	vault: patterns.#ProviderDecl & {
		types:    {Vault: true}
		registry: vault_patterns.#VaultRegistry
	}
	zabbix: patterns.#ProviderDecl & {
		types:    {MonitoringServer: true}
		registry: zabbix_patterns.#ZabbixRegistry
	}
}
