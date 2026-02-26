// Verify: shared topology invariants
//
// These assertions confirm the graph shape is correct
// before any tier-specific evaluation happens.

package platform

_verify: {
	// Must have exactly 15 resources
	_resource_count: len(_topology) & 15

	// Must have exactly 19 dependency edges
	_edge_count: (len(_topology.dns.depends_on) +
		len(_topology.database.depends_on) +
		len(_topology.cache.depends_on) +
		len(_topology.queue.depends_on) +
		len(_topology.proxy.depends_on) +
		len(_topology.worker.depends_on) +
		len(_topology.api.depends_on) +
		len(_topology.frontend.depends_on) +
		len(_topology.admin.depends_on) +
		len(_topology.scheduler.depends_on) +
		len(_topology.backup.depends_on) +
		len(_topology.monitoring.depends_on)) & 19

	// 3 independent roots
	_roots: len(_topology.gateway) + len(_topology.auth) + len(_topology.storage) & 0

	// api must converge from 3 independent paths
	_api_dep_proxy:    _topology.api.depends_on.proxy & true
	_api_dep_database: _topology.api.depends_on.database & true
	_api_dep_auth:     _topology.api.depends_on.auth & true

	// monitoring must depend on both api and worker (cross-path)
	_mon_dep_api:    _topology.monitoring.depends_on.api & true
	_mon_dep_worker: _topology.monitoring.depends_on.worker & true
}
