// Source Charlie — dependency graph / application inventory (authority rank 3)
//
// Analogous to: infra-graph, ServiceNow CMDB relationships, or any
// system that tracks application dependencies and resource usage.
//
// Charlie knows which apps depend on which VMs, and how many
// apps share each resource. This is operational knowledge that
// Alpha (hypervisor) and Bravo (asset CMDB) don't have.

package reconciliation

vms: {
	"web-p01": {
		_in_charlie: true, charlie_ip: "198.51.100.10"
		urn: "urn:example:server:web-p01:198-51-100-10"
		resource_type: "server", appears_in_count: 5, depends_on_count: 3
	}
	"web-p02": {
		_in_charlie: true, charlie_ip: "198.51.100.11"
		urn: "urn:example:server:web-p02:198-51-100-11"
		resource_type: "server", appears_in_count: 5, depends_on_count: 3
	}
	"db-p01": {
		_in_charlie: true, charlie_ip: "198.51.100.20"
		urn: "urn:example:database:db-p01:198-51-100-20"
		resource_type: "database", appears_in_count: 8, depends_on_count: 0
	}
	"db-p02": {
		_in_charlie: true, charlie_ip: "198.51.100.21"
		urn: "urn:example:database:db-p02:198-51-100-21"
		resource_type: "database", appears_in_count: 3, depends_on_count: 0
	}
	"lb-p01": {
		_in_charlie: true, charlie_ip: "198.51.100.30"
		urn: "urn:example:loadbalancer:lb-p01:198-51-100-30"
		resource_type: "loadbalancer", appears_in_count: 10, depends_on_count: 2
	}
	"auth-p01": {
		_in_charlie: true, charlie_ip: "198.51.100.60"
		urn: "urn:example:identity:auth-p01:198-51-100-60"
		resource_type: "identity", appears_in_count: 12, depends_on_count: 0
	}
	"mon-p01": {
		_in_charlie: true, charlie_ip: "198.51.100.40"
		urn: "urn:example:monitoring:mon-p01:198-51-100-40"
		resource_type: "monitoring", appears_in_count: 1, depends_on_count: 0
	}
	// Charlie-only VM: known to the dependency graph but not to hypervisor or CMDB
	"ext-api-01": {
		_in_charlie: true, charlie_ip: "203.0.113.200"
		urn: "urn:example:external:ext-api-01:203-0-113-200"
		resource_type: "external", appears_in_count: 4, depends_on_count: 0
	}
}
