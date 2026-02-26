// Universal Platform — shared resource graph
//
// 15 resources with 3 independent roots, creating non-trivial
// blast radii and meaningful CAB check scenarios.
//
// Graph shape:
//   gateway (layer 0)        auth (layer 0)        storage (layer 0)
//     |                        |                   / |    \
//   dns (layer 1)            (via api)     database cache  queue
//     |                        |              |             |
//   proxy (layer 2)          (via api)      (via api)    worker
//     |                        |              |           / |
//     +------→ api (layer 3) ←-+---←---------+          /  |
//               |                                       / scheduler
//          +---------+                          backup  monitoring
//          |         |
//       frontend   admin
//
// 3 roots:
//   gateway  → DNS/proxy/api path
//   auth     → identity, feeds api directly
//   storage  → persistence layer (database, cache, queue)

package platform

// Site configuration
_site: {
	domain:  string | *"platform.example.com"
	base_id: string | *"https://\(domain)/resources/"
}

// Shared dependency topology — same graph at every scale
_topology: {
	// Layer 0 — roots (no dependencies)
	gateway: {}
	auth:    {}
	storage: {}

	// Layer 1 — infrastructure services
	dns:      {depends_on: {gateway: true}}
	database: {depends_on: {storage: true}}
	cache:    {depends_on: {storage: true}}
	queue:    {depends_on: {storage: true}}

	// Layer 2
	proxy:  {depends_on: {dns: true}}
	worker: {depends_on: {queue: true, database: true}}

	// Layer 3 — convergent
	api: {depends_on: {proxy: true, database: true, auth: true}}

	// Layer 4 — user-facing + batch
	frontend:  {depends_on: {api: true}}
	admin:     {depends_on: {api: true, auth: true}}
	scheduler: {depends_on: {worker: true, api: true}}
	backup:    {depends_on: {database: true, storage: true}}

	// Layer 5 — observability
	monitoring: {depends_on: {api: true, worker: true}}
}
