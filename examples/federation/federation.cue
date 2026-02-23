// Federation: multi-site infrastructure with core/edge topology
// Run: cue eval ./examples/federation/ -e output
//
// Demonstrates:
//   - orche.#Site and orche.#Federation for multi-site modeling
//   - Automatic deployment ordering (core before edge)
//   - Cross-site resource flattening with site prefix
//   - orche.#CrossSiteResource for replicated services

package main

import "quicue.ca/orche/orchestration"

// Two-site federation: core datacenter + edge node
infra: orchestration.#Federation & {
	name: "homelab"

	sites: {
		"dc-core": orchestration.#Site & {
			name:     "dc-core"
			tier:     "core"
			location: "basement"
			network: {
				prefix: "198.51.100.0/24"
				dns: ["198.51.100.10"]
				gateway: "198.51.100.1"
			}
			resources: {
				router: {
					name: "vyos-core"
					"@type": {Router: true}
					ip:         "198.51.100.1"
					depends_on: {}
				}
				dns: {
					name: "powerdns"
					"@type": {DNSServer: true, LXCContainer: true}
					ip:         "198.51.100.10"
					depends_on: {router: true}
				}
				proxy: {
					name: "caddy-proxy"
					"@type": {ReverseProxy: true, LXCContainer: true}
					ip:         "198.51.100.11"
					depends_on: {dns: true}
				}
				gitlab: {
					name: "gitlab-scm"
					"@type": {SourceControlManagement: true, LXCContainer: true}
					ip:         "198.51.100.20"
					depends_on: {dns: true, proxy: true}
				}
			}
		}

		"edge-remote": orchestration.#Site & {
			name:     "edge-remote"
			tier:     "edge"
			location: "cottage"
			network: {
				prefix: "203.0.113.0/24"
				dns: ["203.0.113.1"]
			}
			resources: {
				tunnel: {
					name: "wireguard-tunnel"
					"@type": {TunnelEndpoint: true}
					ip:         "203.0.113.1"
					depends_on: {}
				}
				backup: {
					name: "restic-offsite"
					"@type": {BackupService: true}
					ip:         "203.0.113.10"
					depends_on: {tunnel: true}
				}
			}
		}
	}
}

// Cross-site: GitLab replicated to edge for disaster recovery
gitlab_replica: orchestration.#CrossSiteResource & {
	name:          "gitlab-scm"
	type:          {SourceControlManagement: true}
	primary_site:  "dc-core"
	replica_sites: {"edge-remote": true}
	replication: {
		mode:       "async"
		lag_budget: "15m"
	}
	failover: {
		automatic: false
		priority: ["dc-core", "edge-remote"]  // ordered — failover chain
	}
}

output: {
	federation_name: infra.name
	// Lists preserve order: core deploys before edge
	deployment_order: infra.deployment_order
	total_resources:  len(infra.total_resources)
	sites: {
		for sname, site in infra.sites {
			"\(sname)": {
				tier:           site.tier
				resource_count: len(site.resources)
				network_prefix: site.network.prefix
			}
		}
	}
	cross_site: {
		gitlab: {
			primary:     gitlab_replica.primary_site
			replication: gitlab_replica.replication.mode
			failover:    gitlab_replica.failover.priority
		}
	}
}
