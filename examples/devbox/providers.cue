// Provider binding for the devbox
//
// Minimal stack: Docker + supporting services. Everything runs on one host.
// No hypervisor providers — this is a single-machine setup.

package devbox

import (
	"quicue.ca/patterns@v0"

	docker_patterns "quicue.ca/template/docker/patterns"
	caddy_patterns "quicue.ca/template/caddy/patterns"
	vault_patterns "quicue.ca/template/vault/patterns"
	postgresql_patterns "quicue.ca/template/postgresql/patterns"
	k3d_patterns "quicue.ca/template/k3d/patterns"
	kubectl_patterns "quicue.ca/template/kubectl/patterns"
	gitlab_patterns "quicue.ca/template/gitlab/patterns"
	zabbix_patterns "quicue.ca/template/zabbix/patterns"
	restic_patterns "quicue.ca/template/restic/patterns"
	nginx_patterns "quicue.ca/template/nginx/patterns"
)

_providers: {
	docker: patterns.#ProviderDecl & {
		types: {DockerContainer: true, DockerHost: true, ComposeStack: true}
		registry: docker_patterns.#DockerRegistry
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
	k3d: patterns.#ProviderDecl & {
		types: {KubernetesCluster: true}
		registry: k3d_patterns.#K3dRegistry
	}
	kubectl: patterns.#ProviderDecl & {
		types: {KubernetesCluster: true}
		registry: kubectl_patterns.#KubectlRegistry
	}
	gitlab: patterns.#ProviderDecl & {
		types: {SourceControlManagement: true, CIRunner: true}
		registry: gitlab_patterns.#GitLabRegistry
	}
	zabbix: patterns.#ProviderDecl & {
		types: {MonitoringServer: true}
		registry: zabbix_patterns.#ZabbixRegistry
	}
	restic: patterns.#ProviderDecl & {
		types: {ObjectStorage: true}
		registry: restic_patterns.#ResticRegistry
	}
	nginx: patterns.#ProviderDecl & {
		types: {LoadBalancer: true}
		registry: nginx_patterns.#NginxRegistry
	}
}

// Bind providers to resources by @type overlap
cluster: patterns.#BindCluster & {
	resources: _resources
	providers: _providers
}

// Unified execution plan
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
