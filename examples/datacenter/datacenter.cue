// Representative datacenter - exercises all 28 quicue.ca providers
//
// Models a mid-size organisation datacenter with realistic dependencies
// across physical, virtual, container, and application layers.
//
// Each resource maps to one or more of the 28 quicue.ca providers.
// #BindCluster automatically matches providers to resources by @type overlap
// and resolves command templates into executable commands at CUE compile time.
//
// Run:
//   cue vet  ./examples/datacenter/
//   cue eval ./examples/datacenter/ -e output
//   cue eval ./examples/datacenter/ -e output.binding_summary
//   cue eval ./examples/datacenter/ -e output.action_counts
//   cue export ./examples/datacenter/ -e openapi_spec --out json

package main

import (
	"list"
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"

	// Provider registries (29 providers)
	ansible_patterns "quicue.ca/template/ansible/patterns"
	argocd_patterns "quicue.ca/template/argocd/patterns"
	awx_patterns "quicue.ca/template/awx/patterns"
	caddy_patterns "quicue.ca/template/caddy/patterns"
	cloudflare_patterns "quicue.ca/template/cloudflare/patterns"
	dagger_patterns "quicue.ca/template/dagger/patterns"
	docker_patterns "quicue.ca/template/docker/patterns"
	foreman_patterns "quicue.ca/template/foreman/patterns"
	gitlab_patterns "quicue.ca/template/gitlab/patterns"
	govc_patterns "quicue.ca/template/govc/patterns"
	incus_patterns "quicue.ca/template/incus/patterns"
	k3d_patterns "quicue.ca/template/k3d/patterns"
	keycloak_patterns "quicue.ca/template/keycloak/patterns"
	kubectl_patterns "quicue.ca/template/kubectl/patterns"
	kubevirt_patterns "quicue.ca/template/kubevirt/patterns"
	netbox_patterns "quicue.ca/template/netbox/patterns"
	nginx_patterns "quicue.ca/template/nginx/patterns"
	opentofu_patterns "quicue.ca/template/opentofu/patterns"
	pbs_patterns "quicue.ca/template/pbs/patterns"
	postgresql_patterns "quicue.ca/template/postgresql/patterns"
	powercli_patterns "quicue.ca/template/powercli/patterns"
	powerdns_patterns "quicue.ca/template/powerdns/patterns"
	proxmox_patterns "quicue.ca/template/proxmox/patterns"
	restic_patterns "quicue.ca/template/restic/patterns"
	terraform_patterns "quicue.ca/template/terraform/patterns"
	vault_patterns "quicue.ca/template/vault/patterns"
	vyos_patterns "quicue.ca/template/vyos/patterns"
	zabbix_patterns "quicue.ca/template/zabbix/patterns"
)

_base: "https://infra.example.com/resources/"

// ═══════════════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE RESOURCES
// ═══════════════════════════════════════════════════════════════════════════════

_resources: [Name=string]: {"@id": _base + Name, name: Name}
_resources: {
	// =========================================================================
	// Layer 0 — Physical / Network Foundation
	// Providers: vyos, proxmox, govc, powercli
	// =========================================================================

	// [vyos] Core router — all traffic routes through here
	"router-core": {
		name:     "router-core"
		ip:       "198.51.100.1"
		ssh_user: "vyos"
		"@type": {Router: true, CriticalInfra: true}
		description: "VyOS core router"
	}

	// [proxmox] Hypervisor nodes — host all LXC/VM workloads
	"pve-node1": {
		name:     "pve-node1"
		ip:       "198.51.100.10"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true, CriticalInfra: true}
		depends_on: {"router-core": true}
	}
	"pve-node2": {
		name:     "pve-node2"
		ip:       "198.51.100.20"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true, CriticalInfra: true}
		depends_on: {"router-core": true}
	}
	"pve-node3": {
		name:     "pve-node3"
		ip:       "198.51.100.30"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true}
		depends_on: {"router-core": true}
	}

	// [govc, powercli] vSphere management — manages VM lifecycle
	"vcenter": {
		name:         "vcenter"
		ip:           "198.51.100.5"
		ssh_user:     "root"
		url:          "https://vcenter.dc.example.com"
		vcenter_host: "vcenter.dc.example.com"
		// govc paths (representative VM/host for binding)
		vm_path:        "/DC1/vm/web-server"
		host_path:      "/DC1/host/esxi1.dc.example.com"
		cluster_path:   "/DC1/host/cluster1"
		inventory_path: "/DC1"
		datastore:      "datastore1"
		// powercli fields
		vcenter_user:     "administrator@vsphere.local"
		vcenter_password: "changeme"
		vm_name:          "web-server"
		host_name:        "esxi1.dc.example.com"
		cluster_name:     "cluster1"
		"@type": {VirtualizationPlatform: true}
		depends_on: {"router-core": true}
	}

	// =========================================================================
	// Layer 1 — Core Infrastructure Services
	// Providers: powerdns, cloudflare, netbox, foreman, pbs
	// =========================================================================

	// [powerdns] Authoritative DNS — internal name resolution
	"dns-internal": {
		name:         "dns-internal"
		ip:           "198.51.100.211"
		container_id: 100
		host:         "pve-node1"
		pdns_api_url: "http://198.51.100.211:8081"
		pdns_api_key: "changeme"
		zone_name:    "dc.example.com"
		"@type": {LXCContainer: true, DNSServer: true, CriticalInfra: true}
		depends_on: {"pve-node1": true}
	}

	// [cloudflare] External DNS + CDN — public-facing resolution
	"dns-external": {
		name:         "dns-external"
		fqdn:         "dc.example.com"
		cf_api_token: "cf-token-placeholder"
		zone_id:      "cf-zone-placeholder"
		"@type": {TunnelEndpoint: true, DNSServer: true}
		depends_on: {"dns-internal": true}
	}

	// [netbox] DCIM/IPAM — source of truth for IP and device inventory
	"netbox": {
		name:         "netbox"
		ip:           "198.51.100.215"
		url:          "https://netbox.dc.example.com"
		container_id: 103
		host:         "pve-node1"
		netbox_url:   "https://netbox.dc.example.com/api"
		netbox_token: "netbox-token-placeholder"
		"@type": {LXCContainer: true, APIServer: true}
		depends_on: {"pve-node1": true, "dns-internal": true}
	}

	// [foreman] Provisioning — bare metal and VM lifecycle
	"foreman": {
		name:         "foreman"
		ip:           "198.51.100.216"
		url:          "https://foreman.dc.example.com"
		fqdn:         "foreman.dc.example.com"
		container_id: 104
		host:         "pve-node2"
		foreman_url:  "https://foreman.dc.example.com"
		"@type": {LXCContainer: true}
		depends_on: {"pve-node2": true, "dns-internal": true}
	}

	// [pbs] Proxmox Backup Server — VM/CT backups
	"backup-pbs": {
		name:         "backup-pbs"
		ip:           "198.51.100.217"
		url:          "https://pbs.dc.example.com"
		container_id: 105
		host:         "pve-node3"
		pbs_url:      "https://pbs.dc.example.com"
		"@type": {LXCContainer: true, ObjectStorage: true}
		depends_on: {"pve-node3": true}
	}

	// =========================================================================
	// Layer 2 — Security, Identity & Data
	// Providers: vault, keycloak, postgresql
	// =========================================================================

	// [vault] Secrets management — PKI, tokens, dynamic credentials
	"vault": {
		name:         "vault"
		ip:           "198.51.100.220"
		url:          "https://vault.dc.example.com"
		container_id: 107
		host:         "pve-node1"
		vault_addr:   "https://vault.dc.example.com"
		secret_path:  "secret/data/infra"
		"@type": {LXCContainer: true, Vault: true, CriticalInfra: true}
		depends_on: {"pve-node1": true, "dns-internal": true}
	}

	// [keycloak] Identity provider — SSO/OIDC for all services
	"keycloak": {
		name:         "keycloak"
		ip:           "198.51.100.221"
		url:          "https://id.dc.example.com"
		container_id: 108
		host:         "pve-node2"
		keycloak_url: "https://id.dc.example.com"
		realm:        "dc-example"
		"@type": {LXCContainer: true, AuthServer: true, CriticalInfra: true}
		depends_on: {"pve-node2": true, "dns-internal": true, "vault": true}
	}

	// [postgresql] Primary database — used by GitLab, Keycloak, Netbox, AWX
	"postgresql": {
		name:         "postgresql"
		ip:           "198.51.100.222"
		url:          "postgresql://db.dc.example.com:5432"
		container_id: 109
		host:         "pve-node1"
		db_host:      "198.51.100.222"
		db_port:      "5432"
		db_name:      "postgres"
		ssh_user:     "postgres"
		"@type": {LXCContainer: true, Database: true, CriticalInfra: true}
		depends_on: {"pve-node1": true, "dns-internal": true}
	}

	// =========================================================================
	// Layer 3 — Networking & Container Runtime
	// Providers: caddy, nginx, docker, incus
	// =========================================================================

	// [caddy] Primary reverse proxy — TLS termination for all services
	"caddy-proxy": {
		name:         "caddy-proxy"
		ip:           "198.51.100.212"
		container_id: 101
		host:         "pve-node1"
		admin_url:    "http://localhost:2019"
		"@type": {LXCContainer: true, ReverseProxy: true, CriticalInfra: true}
		depends_on: {"pve-node1": true, "dns-internal": true, "vault": true}
	}

	// [nginx] Static content server — docs, catalogue pages
	"nginx-web": {
		name:             "nginx-web"
		ip:               "198.51.100.230"
		fqdn:             "web.dc.example.com"
		container_id:     630
		host:             "pve-node2"
		nginx_status_url: "http://198.51.100.230/nginx_status"
		"@type": {LXCContainer: true, LoadBalancer: true, WebFrontend: true}
		depends_on: {"pve-node2": true, "dns-internal": true, "caddy-proxy": true}
	}

	// [docker] Container host — runs compose stacks
	"docker-host": {
		name:           "docker-host"
		ip:             "198.51.100.231"
		ssh_user:       "root"
		container_id:   631
		host:           "pve-node2"
		container_name: "app-stack"
		compose_dir:    "/opt/compose/apps"
		"@type": {LXCContainer: true, DockerContainer: true, ComposeStack: true}
		depends_on: {"pve-node2": true, "dns-internal": true}
	}

	// [incus] System container cluster — LXC/VM workloads
	"incus-cluster": {
		name:         "incus-cluster"
		ip:           "198.51.100.232"
		ssh_user:     "root"
		container_id: 112
		host:         "pve-node3"
		"@type": {LXCContainer: true, VirtualizationPlatform: true}
		depends_on: {"pve-node3": true, "dns-internal": true}
	}

	// =========================================================================
	// Layer 4 — Kubernetes & Orchestration
	// Providers: k3d, kubectl, kubevirt, argocd
	// =========================================================================

	// [k3d] Dev Kubernetes — lightweight k3s for development
	"k3d-dev": {
		name:         "k3d-dev"
		ip:           "198.51.100.240"
		host:         "docker-host"
		cluster_name: "dev"
		namespace:    "default"
		"@type": {KubernetesCluster: true, DockerContainer: true}
		depends_on: {"docker-host": true}
	}

	// [kubectl] Production Kubernetes — HA cluster
	"k8s-prod": {
		name:      "k8s-prod"
		ip:        "198.51.100.241"
		url:       "https://k8s.dc.example.com:6443"
		namespace: "default"
		"@type": {KubernetesCluster: true, CriticalInfra: true}
		depends_on: {"pve-node1": true, "pve-node2": true, "dns-internal": true, "vault": true}
	}

	// [kubevirt] VMs on Kubernetes — legacy workloads
	"kubevirt-vms": {
		name:      "kubevirt-vms"
		ip:        "198.51.100.241"
		url:       "https://k8s.dc.example.com:6443"
		namespace: "kubevirt"
		vm_name:   "legacy-workload"
		"@type": {VirtualMachine: true, KubernetesCluster: true}
		depends_on: {"k8s-prod": true}
	}

	// [argocd] GitOps controller — manages k8s deployments
	"argocd": {
		name:         "argocd"
		ip:           "198.51.100.241"
		url:          "https://argocd.dc.example.com"
		namespace:    "argocd"
		argocd_url:   "https://argocd.dc.example.com"
		argocd_token: "argocd-token-placeholder"
		"@type": {KubernetesCluster: true, WebFrontend: true}
		depends_on: {"k8s-prod": true, "gitlab-scm": true, "keycloak": true}
	}

	// =========================================================================
	// Layer 5 — CI/CD & Automation
	// Providers: gitlab, awx, dagger, ansible, terraform, opentofu
	// =========================================================================

	// [gitlab] Source control + CI — central code forge
	"gitlab-scm": {
		name:         "gitlab-scm"
		ip:           "198.51.100.214"
		url:          "https://git.dc.example.com"
		container_id: 102
		host:         "pve-node1"
		project_path: "infrastructure/dc-config"
		branch:       "main"
		"@type": {LXCContainer: true, SourceControlManagement: true, CriticalInfra: true}
		depends_on: {"pve-node1": true, "dns-internal": true, "postgresql": true, "keycloak": true, "caddy-proxy": true}
	}

	// [gitlab] CI runner — executes pipelines
	"gitlab-runner": {
		name:         "gitlab-runner"
		ip:           "198.51.100.213"
		container_id: 106
		host:         "pve-node2"
		"@type": {LXCContainer: true, CIRunner: true}
		depends_on: {"pve-node2": true, "gitlab-scm": true}
	}

	// [awx] Ansible Tower — manages playbook execution
	"awx": {
		name:      "awx"
		ip:        "198.51.100.242"
		url:       "https://awx.dc.example.com"
		awx_url:   "https://awx.dc.example.com"
		awx_token: "awx-token-placeholder"
		"@type": {CIRunner: true, WebFrontend: true}
		depends_on: {"k8s-prod": true, "postgresql": true, "keycloak": true}
	}

	// [dagger] CI pipeline engine — container-native CI
	"dagger-ci": {
		name: "dagger-ci"
		ip:   "198.51.100.231"
		host: "docker-host"
		"@type": {CIRunner: true, DockerContainer: true}
		depends_on: {"docker-host": true, "gitlab-scm": true}
	}

	// [ansible] Automation controller — configuration management
	"ansible-controller": {
		name:           "ansible-controller"
		ip:             "198.51.100.245"
		ssh_user:       "ansible"
		host:           "pve-node3"
		inventory_path: "/etc/ansible/hosts"
		playbook_path:  "/etc/ansible/site.yml"
		"@type": {LXCContainer: true, Worker: true}
		depends_on: {"pve-node3": true, "vault": true}
	}

	// [terraform] IaC state — manages cloud and VM resources
	"terraform-state": {
		name:   "terraform-state"
		ip:     "198.51.100.214"
		url:    "https://git.dc.example.com"
		tf_dir: "/opt/terraform/dc"
		"@type": {SourceControlManagement: true, Worker: true}
		depends_on: {"gitlab-scm": true, "vault": true}
	}

	// [opentofu] IaC engine — open-source IaC for Proxmox/vSphere
	"opentofu-iac": {
		name:   "opentofu-iac"
		ip:     "198.51.100.245"
		host:   "ansible-controller"
		tf_dir: "/opt/opentofu/dc"
		"@type": {Worker: true}
		depends_on: {"ansible-controller": true, "vault": true, "vcenter": true}
	}

	// =========================================================================
	// Layer 6 — Monitoring & Backup
	// Providers: zabbix, restic
	// =========================================================================

	// [zabbix] Monitoring — metrics, alerts, SLA tracking
	"zabbix": {
		name:         "zabbix"
		ip:           "198.51.100.250"
		url:          "https://mon.dc.example.com"
		container_id: 113
		host:         "pve-node3"
		zabbix_url:   "http://198.51.100.250/api_jsonrpc.php"
		zabbix_token: "zabbix-token-placeholder"
		"@type": {LXCContainer: true, MonitoringServer: true}
		depends_on: {"pve-node3": true, "dns-internal": true, "postgresql": true}
	}

	// [restic] Off-site backup — encrypted backups to object storage
	"restic-offsite": {
		name:        "restic-offsite"
		ip:          "198.51.100.217"
		host:        "backup-pbs"
		repo_url:    "s3:https://backup.dc.example.com/restic"
		backup_path: "/var/backup"
		"@type": {ObjectStorage: true, Worker: true}
		depends_on: {"backup-pbs": true, "vault": true}
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER DECLARATIONS
// ═══════════════════════════════════════════════════════════════════════════════
//
// Each provider declares what @type values it serves and its action registry.
// #BindCluster matches providers to resources by type overlap.

_providers: {
	vyos: patterns.#ProviderDecl & {
		types: {Router: true}
		registry: vyos_patterns.#VyOSRegistry
	}
	proxmox: patterns.#ProviderDecl & {
		types: {VirtualizationPlatform: true, LXCContainer: true, VirtualMachine: true}
		registry: proxmox_patterns.#ProxmoxRegistry
	}
	govc: patterns.#ProviderDecl & {
		types: {VirtualizationPlatform: true}
		registry: govc_patterns.#GovcRegistry
	}
	powercli: patterns.#ProviderDecl & {
		types: {VirtualizationPlatform: true}
		registry: powercli_patterns.#PowerCLIRegistry
	}
	docker: patterns.#ProviderDecl & {
		types: {DockerContainer: true, ComposeStack: true}
		registry: docker_patterns.#DockerRegistry
	}
	incus: patterns.#ProviderDecl & {
		types: {VirtualizationPlatform: true}
		registry: incus_patterns.#IncusRegistry
	}
	k3d: patterns.#ProviderDecl & {
		types: {KubernetesCluster: true}
		registry: k3d_patterns.#K3dRegistry
	}
	kubectl: patterns.#ProviderDecl & {
		types: {KubernetesCluster: true}
		registry: kubectl_patterns.#KubectlRegistry
	}
	kubevirt: patterns.#ProviderDecl & {
		types: {VirtualMachine: true, KubernetesCluster: true}
		registry: kubevirt_patterns.#KubeVirtRegistry
	}
	argocd: patterns.#ProviderDecl & {
		types: {KubernetesCluster: true}
		registry: argocd_patterns.#ArgoCDRegistry
	}
	caddy: patterns.#ProviderDecl & {
		types: {ReverseProxy: true}
		registry: caddy_patterns.#CaddyRegistry
	}
	nginx: patterns.#ProviderDecl & {
		types: {ReverseProxy: true, LoadBalancer: true}
		registry: nginx_patterns.#NginxRegistry
	}
	cloudflare: patterns.#ProviderDecl & {
		types: {TunnelEndpoint: true}
		registry: cloudflare_patterns.#CloudflareRegistry
	}
	powerdns: patterns.#ProviderDecl & {
		types: {DNSServer: true}
		registry: powerdns_patterns.#PowerDNSRegistry
	}
	vault: patterns.#ProviderDecl & {
		types: {Vault: true}
		registry: vault_patterns.#VaultRegistry
	}
	keycloak: patterns.#ProviderDecl & {
		types: {AuthServer: true}
		registry: keycloak_patterns.#KeycloakRegistry
	}
	postgresql: patterns.#ProviderDecl & {
		types: {Database: true}
		registry: postgresql_patterns.#PostgreSQLRegistry
	}
	gitlab: patterns.#ProviderDecl & {
		types: {SourceControlManagement: true}
		registry: gitlab_patterns.#GitLabRegistry
	}
	zabbix: patterns.#ProviderDecl & {
		types: {MonitoringServer: true}
		registry: zabbix_patterns.#ZabbixRegistry
	}
	netbox: patterns.#ProviderDecl & {
		types: {APIServer: true}
		registry: netbox_patterns.#NetBoxRegistry
	}
	pbs: patterns.#ProviderDecl & {
		types: {ObjectStorage: true}
		registry: pbs_patterns.#PBSRegistry
	}
	restic: patterns.#ProviderDecl & {
		types: {ObjectStorage: true}
		registry: restic_patterns.#ResticRegistry
	}
	awx: patterns.#ProviderDecl & {
		types: {CIRunner: true}
		registry: awx_patterns.#AWXRegistry
	}
	dagger: patterns.#ProviderDecl & {
		types: {CIRunner: true}
		registry: dagger_patterns.#DaggerRegistry
	}
	ansible: patterns.#ProviderDecl & {
		types: {Worker: true}
		registry: ansible_patterns.#AnsibleCLIRegistry
	}
	terraform: patterns.#ProviderDecl & {
		types: {Worker: true, SourceControlManagement: true}
		registry: terraform_patterns.#TerraformCLIRegistry
	}
	opentofu: patterns.#ProviderDecl & {
		types: {Worker: true}
		registry: opentofu_patterns.#OpenTofuRegistry
	}
	foreman: patterns.#ProviderDecl & {
		types: {LXCContainer: true}
		registry: foreman_patterns.#ForemanRegistry
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMMAND BINDING
// ═══════════════════════════════════════════════════════════════════════════════
//
// #BindCluster: for each resource, find providers whose types overlap with
// the resource's @type, then resolve all applicable action templates.

cluster: patterns.#BindCluster & {
	resources: _resources
	providers: _providers
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRAPH ANALYSIS
// ═══════════════════════════════════════════════════════════════════════════════

infra: patterns.#InfraGraph & {Input: _resources}

// Validation
validate: patterns.#ValidateGraph & {Input: _resources}

// Impact queries — "What breaks if X fails?"
impact_router:  patterns.#ImpactQuery & {Graph: infra, Target: "router-core"}
impact_dns:     patterns.#ImpactQuery & {Graph: infra, Target: "dns-internal"}
impact_vault:   patterns.#ImpactQuery & {Graph: infra, Target: "vault"}
impact_pg:      patterns.#ImpactQuery & {Graph: infra, Target: "postgresql"}
impact_gitlab:  patterns.#ImpactQuery & {Graph: infra, Target: "gitlab-scm"}
impact_k8s:     patterns.#ImpactQuery & {Graph: infra, Target: "k8s-prod"}

// Dependency chains — "What is the startup path?"
chain_argocd:  patterns.#DependencyChain & {Graph: infra, Target: "argocd"}
chain_gitlab:  patterns.#DependencyChain & {Graph: infra, Target: "gitlab-scm"}
chain_opentofu: patterns.#DependencyChain & {Graph: infra, Target: "opentofu-iac"}

// Operational patterns
criticality: patterns.#CriticalityRank & {Graph: infra}
deployment:  patterns.#DeploymentPlan & {Graph: infra}
spof:        patterns.#SinglePointsOfFailure & {Graph: infra}
by_type:     patterns.#GroupByType & {Graph: infra}
metrics:     patterns.#GraphMetrics & {Graph: infra}

// Blast radius — "Router goes down, what's the damage?"
blast_router: patterns.#BlastRadius & {Graph: infra, Target: "router-core"}
blast_dns:    patterns.#BlastRadius & {Graph: infra, Target: "dns-internal"}

// Health simulation — "What if vault is down?"
health_vault_down: patterns.#HealthStatus & {
	Graph: infra
	Status: {
		"vault": "down"
	}
}

// Rollback — "If layer 3 deployment fails, what do we undo?"
rollback_l3: patterns.#RollbackPlan & {Graph: infra, FailedAt: 3}

// Unified execution plan — same resources through binding + ordering
execution: patterns.#ExecutionPlan & {
	"resources": _resources
	"providers": _providers
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER COVERAGE MAP
// ═══════════════════════════════════════════════════════════════════════════════

// Documents which resource exercises which provider(s).
// This is metadata — not consumed by graph analysis.
_providerMap: {
	"router-core":        ["vyos"]
	"pve-node1":          ["proxmox"]
	"pve-node2":          ["proxmox"]
	"pve-node3":          ["proxmox"]
	"vcenter":            ["govc", "powercli"]
	"dns-internal":       ["powerdns"]
	"dns-external":       ["cloudflare"]
	"netbox":             ["netbox"]
	"foreman":            ["foreman"]
	"backup-pbs":         ["pbs"]
	"vault":              ["vault"]
	"keycloak":           ["keycloak"]
	"postgresql":         ["postgresql"]
	"caddy-proxy":        ["caddy"]
	"nginx-web":          ["nginx"]
	"docker-host":        ["docker"]
	"incus-cluster":      ["incus"]
	"k3d-dev":            ["k3d"]
	"k8s-prod":           ["kubectl"]
	"kubevirt-vms":       ["kubevirt"]
	"argocd":             ["argocd"]
	"gitlab-scm":         ["gitlab"]
	"gitlab-runner":      ["gitlab"]
	"awx":                ["awx"]
	"dagger-ci":          ["dagger"]
	"ansible-controller": ["ansible"]
	"terraform-state":    ["terraform"]
	"opentofu-iac":       ["opentofu"]
	"zabbix":             ["zabbix"]
	"restic-offsite":     ["restic"]
}

// Verify all 29 providers are represented
_allProviders: {
	for _, providers in _providerMap
	for _, p in providers {
		(p): true
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// OUTPUT
// ═══════════════════════════════════════════════════════════════════════════════

// Sort criticality by dependents (descending)
_critSorted: list.Sort(criticality.ranked, {x: {}, y: {}, less: x.dependents > y.dependents})

output: {
	// ─────────────────────────────────────────────────────────────────────
	// Graph Summary
	// ─────────────────────────────────────────────────────────────────────
	summary: {
		total_resources: metrics.total_resources
		max_depth:       metrics.max_depth
		total_edges:     metrics.total_edges
		root_count:      metrics.root_count
		leaf_count:      metrics.leaf_count
		providers_used:  len(_allProviders)
	}

	validation: {
		valid:  validate.valid
		issues: validate.issues
	}

	topology: infra.topology
	roots:    infra.roots
	leaves:   infra.leaves

	// ─────────────────────────────────────────────────────────────────────
	// Impact Analysis — "What breaks if X fails?"
	// ─────────────────────────────────────────────────────────────────────
	impact: {
		"router-core": {
			affected: impact_router.affected
			count:    impact_router.affected_count
		}
		"dns-internal": {
			affected: impact_dns.affected
			count:    impact_dns.affected_count
		}
		"vault": {
			affected: impact_vault.affected
			count:    impact_vault.affected_count
		}
		"postgresql": {
			affected: impact_pg.affected
			count:    impact_pg.affected_count
		}
		"gitlab-scm": {
			affected: impact_gitlab.affected
			count:    impact_gitlab.affected_count
		}
		"k8s-prod": {
			affected: impact_k8s.affected
			count:    impact_k8s.affected_count
		}
	}

	// ─────────────────────────────────────────────────────────────────────
	// Dependency Chains — "Startup path to root"
	// ─────────────────────────────────────────────────────────────────────
	chains: {
		"argocd": {
			path:  chain_argocd.path
			depth: chain_argocd.depth
		}
		"gitlab-scm": {
			path:  chain_gitlab.path
			depth: chain_gitlab.depth
		}
		"opentofu-iac": {
			path:  chain_opentofu.path
			depth: chain_opentofu.depth
		}
	}

	// ─────────────────────────────────────────────────────────────────────
	// Criticality — Top 10 by impact
	// ─────────────────────────────────────────────────────────────────────
	criticality_top10: [for i, c in _critSorted if i < 10 {c}]

	// ─────────────────────────────────────────────────────────────────────
	// Deployment Plan — layer-by-layer startup
	// ─────────────────────────────────────────────────────────────────────
	deployment_plan: {
		layers: [
			for l in deployment.layers {
				layer:     l.layer
				resources: l.resources
				gate:      l.gate
			},
		]
		summary: deployment.summary
	}

	// ─────────────────────────────────────────────────────────────────────
	// Risk Analysis
	// ─────────────────────────────────────────────────────────────────────
	blast_radius: {
		"router-core": blast_router.summary
		"dns-internal": blast_dns.summary
	}

	single_points_of_failure: {
		risks:   spof.risks
		summary: spof.summary
	}

	health_simulation: {
		scenario:   "vault is down"
		propagated: health_vault_down.propagated
		summary:    health_vault_down.summary
	}

	rollback_plan: {
		scenario:       "deployment failed at layer 3"
		rollback_order: rollback_l3.sequence
		safe:           rollback_l3.safe
	}

	// ─────────────────────────────────────────────────────────────────────
	// Execution Plan — unified binding + ordering
	// ─────────────────────────────────────────────────────────────────────
	execution_plan: {
		layers: execution.plan.layers
		bound:  execution.cluster.bound
		summary: {
			execution.plan.summary
			binding: execution.cluster.summary
		}
	}

	// ─────────────────────────────────────────────────────────────────────
	// Grouping
	// ─────────────────────────────────────────────────────────────────────
	resources_by_type: by_type.groups

	// ─────────────────────────────────────────────────────────────────────
	// Provider Coverage
	// ─────────────────────────────────────────────────────────────────────
	provider_coverage: _providerMap

	// ─────────────────────────────────────────────────────────────────────
	// Command Binding — executable actions from #BindCluster
	// ─────────────────────────────────────────────────────────────────────
	binding_summary: cluster.summary

	action_counts: {
		for rname, r in cluster.bound {
			(rname): len([
				for _, pactions in r.actions
				for _, a in pactions
				if a.command != _|_ {1},
			])
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

// ═══════════════════════════════════════════════════════════════════════════════
// OPENAPI EXPORT
// ═══════════════════════════════════════════════════════════════════════════════
//
// cue export ./examples/datacenter/ -e openapi_spec --out json

_openapi: patterns.#OpenAPISpec & {
	Cluster: cluster
	Info: {
		title:       "Datacenter Operations API"
		description: "Auto-generated from quicue.ca #BindCluster — 35 resources, 29 providers"
		version:     "1.0.0"
	}
}

openapi_spec: _openapi.spec

// ═══════════════════════════════════════════════════════════════════════════════
// VISUALIZATION
// ═══════════════════════════════════════════════════════════════════════════════

_viz: patterns.#VizData & {Graph: infra, Resources: _resources}
vizData: _viz.data

// ═══════════════════════════════════════════════════════════════════════════════
// JSON-LD EXPORT
// ═══════════════════════════════════════════════════════════════════════════════

jsonld: {
	"@context": vocab.context."@context" & {
		"@base": _base
	}

	"@graph": [
		for _, r in _resources {{
			"@id":   r."@id"
			"@type": [for t, _ in r."@type" {t}]
			name:    r.name
			if r.ip != _|_ {ip: r.ip}
			if r.url != _|_ {url: r.url}
			if r.fqdn != _|_ {fqdn: r.fqdn}
			if r.host != _|_ {host: r.host}
			if r.container_id != _|_ {container_id: r.container_id}
			if r.description != _|_ {description: r.description}
			if r.depends_on != _|_ {depends_on: [for d, _ in r.depends_on {d}]}
		}},
	]
}
