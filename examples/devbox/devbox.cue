// Single-Machine Developer Tooling Stack
//
// Everything runs on one host via Docker Compose. No hypervisor, no multi-node
// clustering — just a clean dev environment with proper dependency tracking.
//
// This example contrasts with examples/homelab/ (3-node Proxmox cluster) and
// examples/datacenter/ (30-resource enterprise setup) to show the same patterns
// scaling down to a single workstation.
//
// Run:
//   cue vet  ./examples/devbox/
//   cue eval ./examples/devbox/ -e output.summary
//   cue eval ./examples/devbox/ -e output.deployment_plan
//   cue eval ./examples/devbox/ -e output.impact

package devbox

import (
	"list"
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
)

// ═══════════════════════════════════════════════════════════════════════════════
// SITE CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════════

_site: {
	domain:  string | *"dev.local"
	base_id: string | *"https://\(domain)/resources/"
	host_ip: string | *"127.0.0.1"
}

// ═══════════════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE RESOURCES
// ═══════════════════════════════════════════════════════════════════════════════

_resources: [Name=string]: {"@id": _site.base_id + Name, name: Name}
_resources: {
	// ─────────────────────────────────────────────────────────────────────
	// Layer 0 — Docker Engine (the foundation)
	// ─────────────────────────────────────────────────────────────────────

	"docker": {
		name:           "docker"
		ip:             _site.host_ip
		ssh_user:       "dev"
		container_name: "docker"
		compose_dir:    "/opt/devbox"
		"@type": {DockerHost: true, CriticalInfra: true}
		description: "Docker Engine — container runtime for all services"
	}

	// ─────────────────────────────────────────────────────────────────────
	// Layer 1 — Data Layer
	// ─────────────────────────────────────────────────────────────────────

	"postgres": {
		name:           "postgres"
		ip:             _site.host_ip
		container_name: "postgres"
		compose_dir:    "/opt/devbox"
		db_host:        _site.host_ip
		db_port:        "5432"
		db_name:        "devbox"
		ssh_user:       "postgres"
		"@type": {DockerContainer: true, Database: true}
		depends_on: {"docker": true}
		description: "PostgreSQL — backing store for Gitea, Keycloak, and app databases"
	}

	"redis": {
		name:           "redis"
		ip:             _site.host_ip
		container_name: "redis"
		compose_dir:    "/opt/devbox"
		"@type": {DockerContainer: true, CacheServer: true}
		depends_on: {"docker": true}
		description: "Redis — session cache, job queues, pub/sub"
	}

	// ─────────────────────────────────────────────────────────────────────
	// Layer 2 — Developer Services
	// ─────────────────────────────────────────────────────────────────────

	"traefik": {
		name:           "traefik"
		ip:             _site.host_ip
		container_name: "traefik"
		compose_dir:    "/opt/devbox"
		fqdn:           "traefik.\(_site.domain)"
		admin_url:      "http://\(_site.host_ip):8080"
		"@type": {DockerContainer: true, ReverseProxy: true}
		depends_on: {"docker": true}
		description: "Traefik — reverse proxy with auto-discovery for Docker labels"
	}

	"gitea": {
		name:           "gitea"
		ip:             _site.host_ip
		url:            "https://git.\(_site.domain)"
		container_name: "gitea"
		compose_dir:    "/opt/devbox"
		"@type": {DockerContainer: true, SourceControlManagement: true}
		depends_on: {"postgres": true, "traefik": true}
		description: "Gitea — lightweight Git forge with CI runners"
	}

	"vault-dev": {
		name:           "vault-dev"
		ip:             _site.host_ip
		container_name: "vault"
		compose_dir:    "/opt/devbox"
		vault_addr:     "http://\(_site.host_ip):8200"
		secret_path:    "secret/data/devbox"
		"@type": {DockerContainer: true, Vault: true}
		depends_on: {"docker": true}
		description: "Vault (dev mode) — local secrets for development"
	}

	// ─────────────────────────────────────────────────────────────────────
	// Layer 3 — Build and Test
	// ─────────────────────────────────────────────────────────────────────

	"k3d": {
		name:           "k3d"
		ip:             _site.host_ip
		container_name: "k3d-devbox"
		compose_dir:    "/opt/devbox"
		"@type": {DockerContainer: true, KubernetesCluster: true}
		depends_on: {"docker": true, "traefik": true}
		description: "k3d — local Kubernetes cluster for testing manifests"
	}

	"runner": {
		name:           "runner"
		ip:             _site.host_ip
		container_name: "gitea-runner"
		compose_dir:    "/opt/devbox"
		"@type": {DockerContainer: true, CIRunner: true}
		depends_on: {"gitea": true, "docker": true}
		description: "Gitea Actions runner — local CI/CD execution"
	}

	"registry": {
		name:           "registry"
		ip:             _site.host_ip
		container_name: "registry"
		compose_dir:    "/opt/devbox"
		fqdn:           "registry.\(_site.domain)"
		"@type": {DockerContainer: true, ContainerRegistry: true}
		depends_on: {"docker": true, "traefik": true}
		description: "Container registry — local image storage for builds"
	}

	// ─────────────────────────────────────────────────────────────────────
	// Layer 4 — Observability
	// ─────────────────────────────────────────────────────────────────────

	"grafana": {
		name:           "grafana"
		ip:             _site.host_ip
		url:            "https://mon.\(_site.domain)"
		container_name: "grafana"
		compose_dir:    "/opt/devbox"
		"@type": {DockerContainer: true, MonitoringServer: true}
		depends_on: {"postgres": true, "traefik": true}
		description: "Grafana — dashboards for metrics and logs"
	}

	"minio": {
		name:           "minio"
		ip:             _site.host_ip
		container_name: "minio"
		compose_dir:    "/opt/devbox"
		"@type": {DockerContainer: true, ObjectStorage: true}
		depends_on: {"docker": true}
		description: "MinIO — S3-compatible object storage for backups and artifacts"
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRAPH ANALYSIS
// ═══════════════════════════════════════════════════════════════════════════════

infra: patterns.#InfraGraph & {Input: _resources}
validate: patterns.#ValidateGraph & {Input: _resources}

// Impact queries for critical resources
impact_docker:   patterns.#ImpactQuery & {Graph: infra, Target: "docker"}
impact_postgres: patterns.#ImpactQuery & {Graph: infra, Target: "postgres"}
impact_traefik:  patterns.#ImpactQuery & {Graph: infra, Target: "traefik"}

// Risk analysis
criticality: patterns.#CriticalityRank & {Graph: infra}
deployment:  patterns.#DeploymentPlan & {Graph: infra}
spof:        patterns.#SinglePointsOfFailure & {Graph: infra}
metrics:     patterns.#GraphMetrics & {Graph: infra}

// Blast radius
blast_docker:   patterns.#BlastRadius & {Graph: infra, Target: "docker"}
blast_postgres: patterns.#BlastRadius & {Graph: infra, Target: "postgres"}

// Health simulation: what happens when the database goes down?
health_postgres_down: patterns.#HealthStatus & {
	Graph: infra
	Status: {"postgres": "down"}
}

// Dependency chains
chain_runner:  patterns.#DependencyChain & {Graph: infra, Target: "runner"}
chain_grafana: patterns.#DependencyChain & {Graph: infra, Target: "grafana"}

// Sort criticality by dependents
_critSorted: list.Sort(criticality.ranked, {x: {}, y: {}, less: x.dependents > y.dependents})

// ═══════════════════════════════════════════════════════════════════════════════
// OUTPUT
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
		"docker": {
			affected: impact_docker.affected
			count:    impact_docker.affected_count
		}
		"postgres": {
			affected: impact_postgres.affected
			count:    impact_postgres.affected_count
		}
		"traefik": {
			affected: impact_traefik.affected
			count:    impact_traefik.affected_count
		}
	}

	chains: {
		"runner": {
			path:  chain_runner.path
			depth: chain_runner.depth
		}
		"grafana": {
			path:  chain_grafana.path
			depth: chain_grafana.depth
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
		"docker":   blast_docker.summary
		"postgres": blast_postgres.summary
	}

	single_points_of_failure: {
		risks:   spof.risks
		summary: spof.summary
	}

	health_simulation: {
		scenario:   "postgres is down"
		propagated: health_postgres_down.propagated
		summary:    health_postgres_down.summary
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
	"@context": vocab.context["@context"] & {
		"@base": _site.base_id
	}

	"@graph": [
		for _, r in _resources {{
			"@id":   r."@id"
			"@type": [for t, _ in r."@type" {t}]
			name:    r.name
			if r.ip != _|_ {ip: r.ip}
			if r.description != _|_ {description: r.description}
			if r.depends_on != _|_ {depends_on: [for d, _ in r.depends_on {d}]}
		}},
	]
}
