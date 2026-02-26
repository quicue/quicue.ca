// Node tier — Proxmox hypervisor with LXC containers and services
//
// Single bare-metal node running Proxmox. Services in LXC containers
// with dedicated IPs. Full DNS, reverse proxy, monitoring stack.

package platform

// Merge shared topology with node-specific types and fields
_node_resources: {
	for rname, base in _topology {
		(rname): {"@id": _site.base_id + "node/" + rname, name: rname} & base
	}
}
_node_resources: _node_fields

_node_fields: {
	gateway: {
		"@type":     {VirtualizationPlatform: true, CriticalInfra: true}
		ip:          "198.51.100.1"
		ssh_user:    "root"
		description: "Proxmox hypervisor — edge network"
	}
	auth: {
		"@type":       {LXCContainer: true}
		ip:            "198.51.100.20"
		container_id:  110
		host:          "gateway"
		description:   "OpenLDAP identity provider"
	}
	storage: {
		"@type":     {VirtualizationPlatform: true, CriticalInfra: true}
		ip:          "198.51.100.2"
		ssh_user:    "root"
		description: "ZFS storage node"
	}
	dns: {
		"@type":       {LXCContainer: true, DNSServer: true}
		ip:            "198.51.100.53"
		container_id:  100
		host:          "gateway"
		zone_name:     _site.domain
		pdns_api_url:  "http://198.51.100.53:8081"
		pdns_api_key:  "changeme"
		description:   "PowerDNS authoritative server"
	}
	database: {
		"@type":       {LXCContainer: true, Database: true}
		ip:            "198.51.100.54"
		container_id:  101
		host:          "storage"
		db_host:       "198.51.100.54"
		db_port:       "5432"
		db_name:       "platform"
		description:   "PostgreSQL in LXC"
	}
	cache: {
		"@type":       {LXCContainer: true}
		ip:            "198.51.100.55"
		container_id:  102
		host:          "storage"
		description:   "Redis cache in LXC"
	}
	queue: {
		"@type":       {LXCContainer: true}
		ip:            "198.51.100.56"
		container_id:  103
		host:          "storage"
		description:   "RabbitMQ in LXC"
	}
	proxy: {
		"@type":       {LXCContainer: true, ReverseProxy: true}
		ip:            "198.51.100.80"
		container_id:  104
		host:          "gateway"
		admin_url:     "http://localhost:2019"
		description:   "Caddy reverse proxy in LXC"
	}
	worker: {
		"@type":       {LXCContainer: true}
		ip:            "198.51.100.90"
		container_id:  105
		host:          "storage"
		description:   "Background worker in LXC"
	}
	api: {
		"@type":       {LXCContainer: true}
		ip:            "198.51.100.81"
		container_id:  106
		host:          "gateway"
		compose_dir:   "/opt/platform/api"
		description:   "API server in LXC"
	}
	frontend: {
		"@type":       {LXCContainer: true}
		ip:            "198.51.100.82"
		container_id:  107
		host:          "gateway"
		description:   "Web frontend in LXC"
	}
	admin: {
		"@type":       {LXCContainer: true}
		ip:            "198.51.100.83"
		container_id:  108
		host:          "gateway"
		description:   "Admin panel in LXC"
	}
	scheduler: {
		"@type":       {LXCContainer: true}
		ip:            "198.51.100.91"
		container_id:  109
		host:          "storage"
		description:   "Job scheduler in LXC"
	}
	backup: {
		"@type":       {LXCContainer: true}
		ip:            "198.51.100.92"
		container_id:  111
		host:          "storage"
		description:   "Backup agent in LXC"
	}
	monitoring: {
		"@type":       {LXCContainer: true, MonitoringServer: true}
		ip:            "198.51.100.250"
		container_id:  112
		host:          "gateway"
		url:           "https://mon.\(_site.domain)"
		zabbix_url:    "http://198.51.100.250"
		zabbix_token:  "changeme"
		description:   "Zabbix monitoring in LXC"
	}
}
