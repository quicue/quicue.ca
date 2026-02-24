// Type Registry - Semantic types for infrastructure resources
//
// Types describe WHAT a resource IS, not what it can do.
// Actions are defined by providers, not by type declarations.
//
// Usage:
//   import "quicue.ca/vocab@v0"
//
//   myResource: vocab.#Resource & {
//       "@type": ["LXCContainer", "DNSServer"]
//   }
//
// Type Categories:
//   - Semantic: DNSServer, ReverseProxy, Vault (what it does)
//   - Implementation: LXCContainer, DockerContainer (how it runs)
//   - Classification: CriticalInfra (operational tier)

package vocab

// #TypeRegistry - Catalog of known semantic types
#TypeRegistry: {[#SafeLabel]: #TypeEntry} & {
	// ========== Implementation Types (how it runs) ==========

	LXCContainer: {
		description: "Proxmox LXC container"
		requires: {
			container_id: int
			host:         string
		}
		grants: ["container_status", "container_console", "container_logs"]
		structural_deps: ["host"]
	}

	DockerContainer: {
		description: "Docker container"
		requires: {
			container_name: string
			host:           string
		}
		grants: ["container_status", "container_logs", "container_restart"]
		structural_deps: ["host"]
	}

	ComposeStack: {
		description: "Docker Compose application stack"
		requires: {
			compose_file: string
			host:         string
		}
		grants: ["stack_status", "stack_logs", "stack_restart"]
		structural_deps: ["host"]
	}

	VirtualMachine: {
		description: "Virtual machine (Proxmox QEMU, VMware, etc.)"
		requires: {
			vm_id: int
			host:  string
		}
		grants: ["vm_status", "vm_console", "vm_start", "vm_stop"]
		structural_deps: ["host"]
	}

	// ========== Network Types ==========

	Router: {
		description: "Network router/firewall (VyOS, MikroTik, pfSense)"
		requires: {
			ip:       string
			ssh_user: string
		}
		grants: ["show_interfaces", "show_routes", "show_firewall"]
	}

	// ========== Orchestration Types ==========

	KubernetesCluster: {
		description: "Kubernetes cluster (k3s, k8s, OpenShift)"
		requires: {
			ip: string
		}
		grants: ["get_pods", "get_services", "get_nodes"]
	}

	// ========== Semantic Types (what it does) ==========

	DNSServer: {
		description: "DNS/name resolution server"
		requires: {
			ip: string
		}
		grants: ["check_dns", "dns_zone_list"]
	}

	ReverseProxy: {
		description: "HTTP/HTTPS reverse proxy (Caddy, nginx, Traefik)"
		requires: {
			ip: string
		}
		grants: ["proxy_status", "proxy_routes"]
	}

	VirtualizationPlatform: {
		description: "Hypervisor node (Proxmox, VMware, Nutanix)"
		requires: {
			ip:       string
			ssh_user: string
		}
		grants: ["list_vms", "list_containers", "node_status"]
	}

	SourceControlManagement: {
		description: "Git server (Forgejo, GitLab, Gitea)"
		requires: {
			url: string
		}
		grants: ["scm_status", "list_repos"]
	}

	Bastion: {
		description: "SSH jump host / bastion server"
		requires: {
			ip:       string
			ssh_user: string
		}
		grants: ["ssh_check", "ssh_tunnel"]
	}

	Vault: {
		description: "Secrets management (Vaultwarden, HashiCorp Vault)"
		requires: {
			url: string
		}
		grants: ["vault_status", "vault_health"]
	}

	MonitoringServer: {
		description: "Metrics/alerting server (Prometheus, Grafana)"
		requires: {
			url: string
		}
		grants: ["monitoring_status", "alert_list"]
	}

	LogAggregator: {
		description: "Log collection and aggregation (Loki, ELK)"
		requires: {
			url: string
		}
		grants: ["log_query", "log_status"]
	}

	DevelopmentWorkstation: {
		description: "Developer machine with containers/VMs"
		requires: {
			ip: string
		}
		grants: ["ssh_check"]
	}

	GPUCompute: {
		description: "GPU-enabled compute node"
		requires: {
			ip: string
		}
		grants: ["gpu_status", "gpu_utilization"]
	}

	AuthServer: {
		description: "Authentication/identity provider"
		requires: {
			url: string
		}
		grants: ["auth_status", "auth_health"]
	}

	LoadBalancer: {
		description: "Load balancer / traffic distribution"
		requires: {
			ip: string
		}
		grants: ["lb_status", "lb_backends"]
	}

	MessageQueue: {
		description: "Message broker (RabbitMQ, Kafka, NATS)"
		requires: {
			url: string
		}
		grants: ["mq_status", "mq_queues"]
	}

	CacheCluster: {
		description: "Distributed cache (Redis, Memcached)"
		requires: {
			url: string
		}
		grants: ["cache_status", "cache_stats"]
	}

	Database: {
		description: "Database server (PostgreSQL, MySQL, MongoDB)"
		requires: {
			url: string
		}
		grants: ["db_status", "db_connections"]
	}

	SearchIndex: {
		description: "Search engine (Elasticsearch, Meilisearch)"
		requires: {
			url: string
		}
		grants: ["search_status", "search_indices"]
	}

	HomeAutomation: {
		description: "Home automation platform (Home Assistant, OpenHAB)"
		requires: {
			url: string
		}
		grants: ["ha_status", "ha_entities"]
	}

	// ========== Storage & Registry Types ==========

	ObjectStorage: {
		description: "S3-compatible object storage (MinIO, Ceph RGW)"
		requires: {
			url: string
		}
		grants: ["storage_status", "bucket_list"]
	}

	ContainerRegistry: {
		description: "OCI/Docker registry (zot, Harbor, Registry)"
		requires: {
			url: string
		}
		grants: ["registry_status", "image_list"]
	}

	// ========== Observability Types ==========

	TracingBackend: {
		description: "Distributed tracing (Jaeger, Zipkin, Tempo)"
		requires: {
			url: string
		}
		grants: ["tracing_status", "trace_query"]
	}

	StatusMonitor: {
		description: "Uptime/status monitoring (Uptime Kuma, Statping)"
		requires: {
			url: string
		}
		grants: ["monitor_status", "monitor_list"]
	}

	// ========== CI/CD Types ==========

	CIRunner: {
		description: "CI/CD job runner (GitLab Runner, GitHub Actions)"
		requires: {
			host: string
		}
		grants: ["runner_status", "job_list"]
		structural_deps: ["host"]
	}

	// ========== Media & Content Types ==========

	MediaServer: {
		description: "Media streaming server (Jellyfin, Plex, Emby)"
		requires: {
			url: string
		}
		grants: ["media_status", "library_stats"]
	}

	PhotoManagement: {
		description: "Photo library management (Immich, PhotoPrism)"
		requires: {
			url: string
		}
		grants: ["photo_status", "library_stats"]
	}

	AudiobookLibrary: {
		description: "Audiobook server (Audiobookshelf)"
		requires: {
			url: string
		}
		grants: ["audiobook_status", "library_stats"]
	}

	EbookLibrary: {
		description: "Ebook server (Calibre-web, Kavita)"
		requires: {
			url: string
		}
		grants: ["ebook_status", "library_stats"]
	}

	RecipeManager: {
		description: "Recipe/meal planning (Mealie, Tandoor)"
		requires: {
			url: string
		}
		grants: ["recipe_status"]
	}

	// ========== Network & Edge Types ==========

	TunnelEndpoint: {
		description: "Network tunnel (Cloudflared, WireGuard, Tailscale)"
		requires: {
			host: string
		}
		grants: ["tunnel_status"]
		structural_deps: ["host"]
	}

	Network: {
		description: "Network zone / address space (VLAN, VPC, subnet, overlay)"
		requires: {
			cidr:   string
			domain: string
		}
		grants: ["network_status", "network_topology"]
	}

	EdgeNode: {
		description: "Edge/remote site node"
		requires: {
			ip: string
		}
		grants: ["edge_status", "edge_sync"]
	}

	APIServer: {
		description: "API backend service"
		requires: {
			url: string
		}
		grants: ["api_status", "api_health"]
	}

	WebFrontend: {
		description: "Web frontend / UI server"
		requires: {
			url: string
		}
		grants: ["web_status", "web_health"]
	}

	Worker: {
		description: "Background job processor"
		requires: {
			host: string
		}
		grants: ["worker_status", "worker_jobs"]
		structural_deps: ["host"]
	}

	ScheduledJob: {
		description: "Cron/scheduled task runner"
		requires: {
			host: string
		}
		grants: ["job_status", "job_history"]
		structural_deps: ["host"]
	}

	// ========== Infrastructure Types ==========

	Region: {
		description: "Geographic region / data center location"
		requires: {
			name: string
		}
	}

	AvailabilityZone: {
		description: "Availability zone within a region"
		requires: {
			name:   string
			region: string
		}
		structural_deps: ["region"]
	}

	// ========== Software Supply Chain Types ==========

	SoftwareApplication: {
		description: "Software application or service binary"
	}

	SoftwareLibrary: {
		description: "Software library or package dependency"
	}

	SoftwareFramework: {
		description: "Software framework (Spring, Django, Rails, Gin)"
	}

	SoftwareContainer: {
		description: "Container image artifact (OCI, Docker)"
	}

	SoftwarePlatform: {
		description: "Runtime platform (JVM, Node.js, .NET CLR)"
	}

	SoftwareFirmware: {
		description: "Embedded firmware component"
	}

	SoftwareFile: {
		description: "Single file artifact in a software bill of materials"
	}

	OperatingSystem: {
		description: "Operating system (Ubuntu, Alpine, Windows)"
	}

	// ========== CI/CD Pipeline Types ==========

	CIPipeline: {
		description: "CI/CD pipeline definition"
	}

	CIStage: {
		description: "Stage within a CI/CD pipeline"
	}

	CIJob: {
		description: "Individual job within a CI/CD stage"
	}

	// ========== Classification Types (operational tier) ==========

	CriticalInfra: {
		description: "Critical infrastructure - extra monitoring/alerting"
		grants: ["alert_status", "backup_status"]
		// No requires - pure classification type
	}

	// Allow extension
	...
}

// #TypeNames - Disjunction of all known type names for validation
#TypeNames: or([for k, _ in #TypeRegistry {k}])

// #ValidTypes - Validate that all types in array are known
// Usage: myResource: { "@type": vocab.#ValidTypes & ["DNSServer", "LXCContainer"] }
#ValidTypes: [...#TypeNames]

// #TypeEntry - Schema for type registry entries
#TypeEntry: {
	description: string
	requires?: {...} // Fields that resources of this type MUST have
	grants?: [...string] // Action names this type grants
	structural_deps?: [...string] // Fields that auto-create depends_on
}
