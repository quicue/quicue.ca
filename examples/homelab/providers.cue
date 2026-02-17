// Provider binding for the reference homelab
//
// Default stack: Proxmox + VyOS + supporting services
//
// To switch provider stacks:
//   - Replace this file with your preferred providers
//   - Only providers whose @type values overlap with resource @type values
//     will bind — unmatched providers are silently ignored
//   - See template/ for all 28 available providers
//
// Common stacks:
//   Proxmox homelab:  proxmox, vyos, powerdns, caddy, vault, postgresql, docker, zabbix, pbs, restic
//   Docker-only:      docker, caddy, vault, postgresql, zabbix, restic
//   Kubernetes:       kubectl, argocd, vault, postgresql, zabbix, restic
//   Incus:            incus, vyos, powerdns, caddy, vault, postgresql, docker, zabbix, restic

package homelab

import (
	"quicue.ca/patterns@v0"

	proxmox_patterns "quicue.ca/template/proxmox/patterns"
	vyos_patterns "quicue.ca/template/vyos/patterns"
	powerdns_patterns "quicue.ca/template/powerdns/patterns"
	caddy_patterns "quicue.ca/template/caddy/patterns"
	vault_patterns "quicue.ca/template/vault/patterns"
	postgresql_patterns "quicue.ca/template/postgresql/patterns"
	docker_patterns "quicue.ca/template/docker/patterns"
	zabbix_patterns "quicue.ca/template/zabbix/patterns"
	pbs_patterns "quicue.ca/template/pbs/patterns"
	restic_patterns "quicue.ca/template/restic/patterns"
	nginx_patterns "quicue.ca/template/nginx/patterns"
	gitlab_patterns "quicue.ca/template/gitlab/patterns"
)

_providers: {
	vyos: patterns.#ProviderDecl & {
		types: {Router: true}
		registry: vyos_patterns.#VyOSRegistry
	}
	proxmox: patterns.#ProviderDecl & {
		types: {VirtualizationPlatform: true, LXCContainer: true, VirtualMachine: true}
		registry: proxmox_patterns.#ProxmoxRegistry
	}
	powerdns: patterns.#ProviderDecl & {
		types: {DNSServer: true}
		registry: powerdns_patterns.#PowerDNSRegistry
	}
	caddy: patterns.#ProviderDecl & {
		types: {ReverseProxy: true}
		registry: caddy_patterns.#CaddyRegistry
	}
	vault: patterns.#ProviderDecl & {
		types: {Vault: true}
		registry: vault_patterns.#VaultRegistry
	}
	postgresql: patterns.#ProviderDecl & {
		types: {Database: true}
		registry: postgresql_patterns.#PostgreSQLRegistry
	}
	docker: patterns.#ProviderDecl & {
		types: {DockerContainer: true, ComposeStack: true}
		registry: docker_patterns.#DockerRegistry
	}
	zabbix: patterns.#ProviderDecl & {
		types: {MonitoringServer: true}
		registry: zabbix_patterns.#ZabbixRegistry
	}
	pbs: patterns.#ProviderDecl & {
		types: {ObjectStorage: true}
		registry: pbs_patterns.#PBSRegistry
	}
	restic: patterns.#ProviderDecl & {
		types: {ObjectStorage: true}
		registry: restic_patterns.#ResticRegistry
	}
	nginx: patterns.#ProviderDecl & {
		types: {LoadBalancer: true, WebFrontend: true}
		registry: nginx_patterns.#NginxRegistry
	}
	gitlab: patterns.#ProviderDecl & {
		types: {SourceControlManagement: true}
		registry: gitlab_patterns.#GitLabRegistry
	}
}

// Bind providers to resources by @type overlap
cluster: patterns.#BindCluster & {
	resources: _resources
	providers: _providers
}

// Unified execution plan — binding + deployment ordering
execution: patterns.#ExecutionPlan & {
	"resources": _resources
	"providers": _providers
}

// Extend output with binding and execution data
output: {
	binding_summary: cluster.summary

	execution_plan: {
		layers: execution.plan.layers
		summary: {
			execution.plan.summary
			binding: execution.cluster.summary
		}
	}

	// Concrete commands — "what do I actually run?"
	commands: {
		for rname, r in cluster.bound {
			(rname): {
				for pname, pactions in r.actions {
					for aname, a in pactions if a.command != _|_ {
						("\(pname)/\(aname)"): a.command
					}
				}
			}
		}
	}
}
