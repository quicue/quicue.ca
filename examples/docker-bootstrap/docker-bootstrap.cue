// Docker Bootstrap: create a complete Docker site from service templates
// Run: cue eval ./examples/docker-bootstrap/ -e output
//
// Demonstrates:
//   - bootstrap.#DockerSite composing services into a dependency graph
//   - Pre-built service templates (#PostgresService, #RedisService, etc.)
//   - Automatic depends_on merging (every service depends on network)
//   - Generated docker run commands from CUE definitions
//   - boot.#BootstrapResource lifecycle and credential collection

package main

import (
	"quicue.ca/orche/bootstrap"
	boot "quicue.ca/boot"
)

// Define a monitoring stack using Docker service templates
site: bootstrap.#DockerSite & {
	name:    "monitoring"
	tier:    "core"
	network: "monitoring-net"

	network_config: subnet: "203.0.113.0/24"

	services: {
		postgres: bootstrap.#PostgresService & {
			name: "mon-postgres"
			ports: ["5432:5432"]
			environment: {
				POSTGRES_PASSWORD: "changeme"
				POSTGRES_DB:       "grafana"
			}
			volumes: ["/opt/monitoring/pgdata:/var/lib/postgresql/data"]
		}

		redis: bootstrap.#RedisService & {
			name: "mon-redis"
			ports: ["6379:6379"]
		}

		prometheus: bootstrap.#PrometheusService & {
			name: "mon-prometheus"
			ports: ["9090:9090"]
			volumes: ["/opt/monitoring/prom-config:/etc/prometheus"]
		}

		grafana: bootstrap.#GrafanaService & {
			name: "mon-grafana"
			ports: ["3000:3000"]
			depends_on: {postgres: true, prometheus: true}
			environment: {
				GF_SECURITY_ADMIN_PASSWORD: "changeme"
				GF_DATABASE_TYPE:           "postgres"
				GF_DATABASE_HOST:           "mon-postgres:5432"
			}
		}

		alertmanager: bootstrap.#AppService & {
			name:  "mon-alertmanager"
			image: "prom/alertmanager:latest"
			type: {Monitoring: true, Container: true}
			ports: ["9093:9093"]
			depends_on: {prometheus: true}
			environment: {}
		}
	}
}

// Wrap Grafana in a BootstrapResource for lifecycle management
grafana_bootstrap: boot.#BootstrapResource & {
	name: "mon-grafana"
	ip:   "203.0.113.5"
	port: 3000
	health: {
		command: "curl -sf http://203.0.113.5:3000/api/health"
		timeout: "30s"
		retries: 5
	}
	_bootstrap: {
		layer: 2
		credentials: {
			collector: "curl -sf http://203.0.113.5:3000/api/admin/settings | jq .security"
			paths: ["/opt/monitoring/grafana-creds.json"]
		}
	}
}

output: {
	site_name:     site.name
	network:       site.network_config.actions.create.command
	service_count: len(site.services)

	// Show the generated docker run commands
	create_commands: {
		for sname, svc in site.services {
			"\(sname)": site.containers[sname].actions.create.command
		}
	}

	// Show dependency graph: every service auto-depends on network
	dependencies: {
		for sname, svc in site.services {
			"\(sname)": {
				depends_on: svc.depends_on
			}
		}
	}

	// Bootstrap lifecycle for Grafana
	grafana_health: grafana_bootstrap.health
	grafana_layer:  grafana_bootstrap._bootstrap.layer
}
