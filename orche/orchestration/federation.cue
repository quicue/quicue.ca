// Federation - Multi-site coordination
package orchestration

import "list"

// #Site - Single datacenter/site definition
#Site: {
	name:     string
	tier:     "core" | "edge"
	location: string | *""

	// Network configuration
	network: {
		prefix: string // e.g., "198.51.100.0/24"
		dns: [...string]
		gateway?: string
	}

	// Resources at this site
	resources: [string]: {...}

	// Site-level metadata
	metadata?: [string]: string
}

// #Federation - Multi-site infrastructure
#Federation: {
	name: string

	// Member sites
	sites: [string]: #Site

	// Global resources (span multiple sites)
	global_resources?: [string]: {
		type:       string
		primary_dc: string
		replica_dcs: [...string] // ordered — JSON-LD @list
	}

	// Sync policy
	sync?: {
		mode:     "push" | "pull" | "bidirectional" | *"push"
		interval: string | *"5m"
	}

	// Computed: deployment order (core sites first, then edge)
	// List — order matters for deploy sequencing
	_core_sites: [for sname, s in sites if s.tier == "core" {sname}]
	_edge_sites: [for sname, s in sites if s.tier == "edge" {sname}]
	deployment_order: list.Concat([_core_sites, _edge_sites])

	// Computed: total resources across federation
	total_resources: {
		for sname, site in sites
		for rname, r in site.resources {
			"\(sname)/\(rname)": r & {_site: sname}
		}
	}
}

// #CrossSiteResource - Resource that spans sites
#CrossSiteResource: {
	name: string
	type: {[string]: true} // Set membership like other types
	primary_site: string
	replica_sites: {[string]: true} // Set of site names

	// Replication mode
	replication: {
		mode:       "sync" | "async" | *"async"
		lag_budget: string | *"5m"
	}

	// Failover configuration
	failover: {
		automatic: bool | *false
		priority: [...string] // ordered list — order matters for failover chain
	}
}

// #SiteGraph - Generate graph for a single site
#SiteGraph: {
	Site: #Site

	// Convert site resources to graph input format
	resources: {
		for rname, r in Site.resources {
			(rname): r
		}
	}
}

// #FederationGraph - Generate unified graph across federation
#FederationGraph: {
	Federation: #Federation

	// Flatten all resources with site prefix
	resources: {
		for sname, site in Federation.sites
		for rname, r in site.resources {
			"\(sname)-\(rname)": r & {
				_site: sname
				// Add cross-site dependencies if needed
			}
		}
	}
}
