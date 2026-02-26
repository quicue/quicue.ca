// Enterprise tier — VMware vSphere + full ops suite
//
// Production datacenter with vSphere cluster, VMs, enterprise DNS,
// secrets management, and monitoring. Full operational tooling.

package platform

// Merge shared topology with enterprise-specific types and fields
_enterprise_resources: {
	for rname, base in _topology {
		(rname): {"@id": _site.base_id + "enterprise/" + rname, name: rname} & base
	}
}
_enterprise_resources: _enterprise_fields

_enterprise_fields: {
	gateway: {
		"@type":          {VMwareCluster: true, CriticalInfra: true}
		ip:               "203.0.113.1"
		cluster_path:     "/DC1/host/Edge"
		inventory_path:   "/DC1"
		description:      "vSphere edge cluster"
	}
	auth: {
		"@type":          {VirtualMachine: true}
		ip:               "203.0.113.20"
		vm_id:            2001
		vm_path:          "/DC1/vm/platform/auth"
		host:             "gateway"
		description:      "Active Directory / LDAP VM"
	}
	storage: {
		"@type":          {VMwareCluster: true, CriticalInfra: true}
		ip:               "203.0.113.2"
		cluster_path:     "/DC1/host/Storage"
		inventory_path:   "/DC1"
		description:      "vSphere storage cluster"
	}
	dns: {
		"@type":          {VirtualMachine: true, DNSServer: true}
		ip:               "203.0.113.53"
		vm_id:            1001
		vm_path:          "/DC1/vm/platform/dns"
		host:             "gateway"
		zone_name:        _site.domain
		pdns_api_url:     "http://203.0.113.53:8081"
		pdns_api_key:     "changeme"
		description:      "PowerDNS VM"
	}
	database: {
		"@type":          {VirtualMachine: true, Database: true}
		ip:               "203.0.113.54"
		vm_id:            1002
		vm_path:          "/DC1/vm/platform/database"
		host:             "storage"
		db_host:          "203.0.113.54"
		db_port:          "5432"
		db_name:          "platform"
		description:      "PostgreSQL VM"
	}
	cache: {
		"@type":          {VirtualMachine: true}
		ip:               "203.0.113.55"
		vm_id:            1003
		vm_path:          "/DC1/vm/platform/cache"
		host:             "storage"
		description:      "Redis VM"
	}
	queue: {
		"@type":          {VirtualMachine: true}
		ip:               "203.0.113.56"
		vm_id:            1004
		vm_path:          "/DC1/vm/platform/queue"
		host:             "storage"
		description:      "RabbitMQ VM"
	}
	proxy: {
		"@type":          {VirtualMachine: true, ReverseProxy: true}
		ip:               "203.0.113.80"
		vm_id:            1005
		vm_path:          "/DC1/vm/platform/proxy"
		host:             "gateway"
		admin_url:        "http://localhost:2019"
		description:      "Caddy VM"
	}
	worker: {
		"@type":          {VirtualMachine: true}
		ip:               "203.0.113.90"
		vm_id:            1006
		vm_path:          "/DC1/vm/platform/worker"
		host:             "storage"
		description:      "Background worker VM"
	}
	api: {
		"@type":          {VirtualMachine: true}
		ip:               "203.0.113.81"
		vm_id:            1007
		vm_path:          "/DC1/vm/platform/api"
		host:             "gateway"
		description:      "API server VM"
	}
	frontend: {
		"@type":          {VirtualMachine: true}
		ip:               "203.0.113.82"
		vm_id:            1008
		vm_path:          "/DC1/vm/platform/frontend"
		host:             "gateway"
		description:      "Web frontend VM"
	}
	admin: {
		"@type":          {VirtualMachine: true}
		ip:               "203.0.113.83"
		vm_id:            1009
		vm_path:          "/DC1/vm/platform/admin"
		host:             "gateway"
		description:      "Admin panel VM"
	}
	scheduler: {
		"@type":          {VirtualMachine: true}
		ip:               "203.0.113.91"
		vm_id:            1010
		vm_path:          "/DC1/vm/platform/scheduler"
		host:             "storage"
		description:      "Job scheduler VM"
	}
	backup: {
		"@type":          {VirtualMachine: true}
		ip:               "203.0.113.92"
		vm_id:            1011
		vm_path:          "/DC1/vm/platform/backup"
		host:             "storage"
		description:      "Backup agent VM"
	}
	monitoring: {
		"@type":          {VirtualMachine: true, MonitoringServer: true}
		ip:               "203.0.113.250"
		vm_id:            1012
		vm_path:          "/DC1/vm/platform/monitoring"
		host:             "gateway"
		url:              "https://mon.enterprise.example.com"
		zabbix_url:       "http://203.0.113.250"
		zabbix_token:     "changeme"
		description:      "Zabbix monitoring VM"
	}
}
