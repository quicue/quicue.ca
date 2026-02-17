// Reference Homelab — deployable on any supported provider stack
//
// A complete 3-node homelab with reverse proxy, git forge, secrets manager,
// monitoring, DNS, database, and container workloads.
//
// This example is provider-agnostic at the resource layer. Import a provider
// overlay (proxmox.cue, docker.cue, k8s.cue, incus.cue) to bind resources
// to your chosen platform and generate executable commands.
//
// Quick start:
//   1. Copy this directory
//   2. Edit site.cue with your IPs and hostnames
//   3. Pick a provider overlay (or combine them)
//   4. Run: cue export ./examples/homelab/ -e output --out json
//
// Run:
//   cue vet  ./examples/homelab/
//   cue eval ./examples/homelab/ -e output
//   cue eval ./examples/homelab/ -e output.impact
//   cue eval ./examples/homelab/ -e output.deployment_plan
//   cue eval ./examples/homelab/ -e output.commands

package homelab

import (
	"list"
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
)

// ═══════════════════════════════════════════════════════════════════════════════
// SITE CONFIGURATION — Edit these for your environment
// ═══════════════════════════════════════════════════════════════════════════════

_site: {
	domain:  string | *"lab.example.com"
	base_id: string | *"https://\(domain)/resources/"
	subnet:  string | *"198.51.100"  // RFC 5737 documentation range
}

// ═══════════════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE RESOURCES — Provider-agnostic definitions
// ═══════════════════════════════════════════════════════════════════════════════

_resources: [Name=string]: {"@id": _site.base_id + Name, name: Name}
_resources: {
	// ─────────────────────────────────────────────────────────────────────
	// Layer 0 — Network Foundation
	// ─────────────────────────────────────────────────────────────────────

	"router": {
		name:     "router"
		ip:       "\(_site.subnet).1"
		ssh_user: "admin"
		"@type": {Router: true, CriticalInfra: true}
		description: "Core router — all traffic routes through here"
	}

	// ─────────────────────────────────────────────────────────────────────
	// Layer 0 — Compute Nodes
	// ─────────────────────────────────────────────────────────────────────

	"node-a": {
		name:     "node-a"
		ip:       "\(_site.subnet).10"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true, CriticalInfra: true}
		depends_on: {"router": true}
		description: "Primary compute node — hosts critical services"
	}

	"node-b": {
		name:     "node-b"
		ip:       "\(_site.subnet).20"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true}
		depends_on: {"router": true}
		description: "Secondary compute node — hosts app workloads"
	}

	"node-c": {
		name:     "node-c"
		ip:       "\(_site.subnet).30"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true}
		depends_on: {"router": true}
		description: "Tertiary compute node — monitoring and backup"
	}

	// ─────────────────────────────────────────────────────────────────────
	// Layer 1 — Core Services
	// ─────────────────────────────────────────────────────────────────────

	"dns": {
		name:         "dns"
		ip:           "\(_site.subnet).53"
		container_id: 100
		host:         "node-a"
		zone_name:    _site.domain
		pdns_api_url: "http://\(_site.subnet).53:8081"
		pdns_api_key: "changeme"
		"@type": {LXCContainer: true, DNSServer: true, CriticalInfra: true}
		depends_on: {"node-a": true}
		description: "Authoritative DNS for the lab"
	}

	"reverse-proxy": {
		name:         "reverse-proxy"
		ip:           "\(_site.subnet).80"
		container_id: 101
		host:         "node-a"
		admin_url:    "http://localhost:2019"
		"@type": {LXCContainer: true, ReverseProxy: true, CriticalInfra: true}
		depends_on: {"node-a": true, "dns": true}
		description: "TLS termination for all services"
	}

	// ─────────────────────────────────────────────────────────────────────
	// Layer 2 — Security and Data
	// ─────────────────────────────────────────────────────────────────────

	"vault": {
		name:         "vault"
		ip:           "\(_site.subnet).200"
		container_id: 102
		host:         "node-a"
		vault_addr:   "https://vault.\(_site.domain)"
		secret_path:  "secret/data/lab"
		"@type": {LXCContainer: true, Vault: true, CriticalInfra: true}
		depends_on: {"node-a": true, "dns": true}
		description: "Secrets management — PKI, tokens, dynamic credentials"
	}

	"database": {
		name:         "database"
		ip:           "\(_site.subnet).201"
		container_id: 103
		host:         "node-a"
		db_host:      "\(_site.subnet).201"
		db_port:      "5432"
		db_name:      "postgres"
		ssh_user:     "postgres"
		"@type": {LXCContainer: true, Database: true, CriticalInfra: true}
		depends_on: {"node-a": true, "dns": true}
		description: "PostgreSQL — used by Gitea, Keycloak, Zabbix"
	}

	// ─────────────────────────────────────────────────────────────────────
	// Layer 3 — Application Services
	// ─────────────────────────────────────────────────────────────────────

	"gitea": {
		name:         "gitea"
		ip:           "\(_site.subnet).210"
		url:          "https://git.\(_site.domain)"
		container_id: 104
		host:         "node-b"
		project_path: "infrastructure/lab-config"
		branch:       "main"
		"@type": {LXCContainer: true, SourceControlManagement: true}
		depends_on: {"node-b": true, "dns": true, "database": true, "reverse-proxy": true}
		description: "Git forge — source control and CI"
	}

	"docker-host": {
		name:           "docker-host"
		ip:             "\(_site.subnet).211"
		ssh_user:       "root"
		container_id:   105
		host:           "node-b"
		container_name: "app-stack"
		compose_dir:    "/opt/compose/apps"
		"@type": {LXCContainer: true, DockerContainer: true, ComposeStack: true}
		depends_on: {"node-b": true, "dns": true}
		description: "Docker host for compose stacks"
	}

	"wiki": {
		name:             "wiki"
		ip:               "\(_site.subnet).212"
		fqdn:             "wiki.\(_site.domain)"
		container_id:     106
		host:             "node-b"
		nginx_status_url: "http://\(_site.subnet).212/nginx_status"
		"@type": {LXCContainer: true, WebFrontend: true, LoadBalancer: true}
		depends_on: {"node-b": true, "dns": true, "reverse-proxy": true}
		description: "Documentation wiki"
	}

	// ─────────────────────────────────────────────────────────────────────
	// Layer 4 — Monitoring and Backup
	// ─────────────────────────────────────────────────────────────────────

	"monitoring": {
		name:         "monitoring"
		ip:           "\(_site.subnet).250"
		url:          "https://mon.\(_site.domain)"
		container_id: 107
		host:         "node-c"
		zabbix_url:   "http://\(_site.subnet).250/api_jsonrpc.php"
		zabbix_token: "changeme"
		"@type": {LXCContainer: true, MonitoringServer: true}
		depends_on: {"node-c": true, "dns": true, "database": true}
		description: "Zabbix monitoring — metrics and alerts"
	}

	"backup": {
		name:         "backup"
		ip:           "\(_site.subnet).251"
		url:          "https://backup.\(_site.domain)"
		container_id: 108
		host:         "node-c"
		pbs_url:      "https://backup.\(_site.domain)"
		"@type": {LXCContainer: true, ObjectStorage: true}
		depends_on: {"node-c": true}
		description: "Proxmox Backup Server — VM/CT snapshots"
	}

	"restic-offsite": {
		name:        "restic-offsite"
		ip:          "\(_site.subnet).251"
		host:        "backup"
		repo_url:    "s3:https://s3.example.com/lab-backup"
		backup_path: "/var/backup"
		"@type": {ObjectStorage: true, Worker: true}
		depends_on: {"backup": true, "vault": true}
		description: "Off-site encrypted backups"
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRAPH ANALYSIS — computed from resource definitions
// ═══════════════════════════════════════════════════════════════════════════════

infra: patterns.#InfraGraph & {Input: _resources}
validate: patterns.#ValidateGraph & {Input: _resources}

// Impact queries
impact_router:   patterns.#ImpactQuery & {Graph: infra, Target: "router"}
impact_dns:      patterns.#ImpactQuery & {Graph: infra, Target: "dns"}
impact_vault:    patterns.#ImpactQuery & {Graph: infra, Target: "vault"}
impact_database: patterns.#ImpactQuery & {Graph: infra, Target: "database"}

// Risk analysis
criticality: patterns.#CriticalityRank & {Graph: infra}
deployment:  patterns.#DeploymentPlan & {Graph: infra}
spof:        patterns.#SinglePointsOfFailure & {Graph: infra}
metrics:     patterns.#GraphMetrics & {Graph: infra}

// Blast radius
blast_router: patterns.#BlastRadius & {Graph: infra, Target: "router"}
blast_dns:    patterns.#BlastRadius & {Graph: infra, Target: "dns"}

// Health simulation
health_vault_down: patterns.#HealthStatus & {
	Graph: infra
	Status: {"vault": "down"}
}

// Dependency chains
chain_gitea:   patterns.#DependencyChain & {Graph: infra, Target: "gitea"}
chain_monitor: patterns.#DependencyChain & {Graph: infra, Target: "monitoring"}

// Rollback
rollback_l3: patterns.#RollbackPlan & {Graph: infra, FailedAt: 3}

// Sort criticality by dependents
_critSorted: list.Sort(criticality.ranked, {x: {}, y: {}, less: x.dependents > y.dependents})

// ═══════════════════════════════════════════════════════════════════════════════
// OUTPUT — structured export for downstream consumption
// ═══════════════════════════════════════════════════════════════════════════════

output: {
	summary: {
		total_resources: metrics.total_resources
		max_depth:       metrics.max_depth
		total_edges:     metrics.total_edges
		root_count:      metrics.root_count
		leaf_count:      metrics.leaf_count
	}

	validation: {
		valid:  validate.valid
		issues: validate.issues
	}

	topology: infra.topology
	roots:    infra.roots
	leaves:   infra.leaves

	impact: {
		"router": {
			affected: impact_router.affected
			count:    impact_router.affected_count
		}
		"dns": {
			affected: impact_dns.affected
			count:    impact_dns.affected_count
		}
		"vault": {
			affected: impact_vault.affected
			count:    impact_vault.affected_count
		}
		"database": {
			affected: impact_database.affected
			count:    impact_database.affected_count
		}
	}

	chains: {
		"gitea": {
			path:  chain_gitea.path
			depth: chain_gitea.depth
		}
		"monitoring": {
			path:  chain_monitor.path
			depth: chain_monitor.depth
		}
	}

	criticality_top5: [for i, c in _critSorted if i < 5 {c}]

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

	blast_radius: {
		"router": blast_router.summary
		"dns":    blast_dns.summary
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
}

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
		"@base": _site.base_id
	}

	"@graph": [
		for _, r in _resources {{
			"@id":   r."@id"
			"@type": [for t, _ in r."@type" {t}]
			name:    r.name
			if r.ip != _|_ {ip: r.ip}
			if r.fqdn != _|_ {fqdn: r.fqdn}
			if r.host != _|_ {host: r.host}
			if r.description != _|_ {description: r.description}
			if r.depends_on != _|_ {depends_on: [for d, _ in r.depends_on {d}]}
		}},
	]
}
