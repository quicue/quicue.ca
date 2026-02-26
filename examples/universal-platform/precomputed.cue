// Precomputed topology — shared across all tiers
//
// Since all 4 tiers have identical dependency graphs,
// the depth, ancestors, and dependents are the same.
//
// Generated from resources.cue topology.

package platform

_precomputed: {
	depth: {
		auth:        0
		gateway:     0
		storage:     0
		cache:       1
		database:    1
		dns:         1
		queue:       1
		backup:      2
		proxy:       2
		worker:      2
		api:         3
		admin:       4
		frontend:    4
		monitoring:  4
		scheduler:   4
	}
	ancestors: {
		auth:        {}
		gateway:     {}
		storage:     {}
		cache:       {storage: true}
		database:    {storage: true}
		dns:         {gateway: true}
		queue:       {storage: true}
		backup:      {storage: true, database: true}
		proxy:       {gateway: true, dns: true}
		worker:      {storage: true, database: true, queue: true}
		api:         {auth: true, gateway: true, storage: true, database: true, dns: true, proxy: true}
		admin:       {auth: true, gateway: true, storage: true, database: true, dns: true, proxy: true, api: true}
		frontend:    {auth: true, gateway: true, storage: true, database: true, dns: true, proxy: true, api: true}
		monitoring:  {auth: true, gateway: true, storage: true, database: true, dns: true, queue: true, proxy: true, worker: true, api: true}
		scheduler:   {auth: true, gateway: true, storage: true, database: true, dns: true, queue: true, proxy: true, worker: true, api: true}
	}
	dependents: {
		auth:        {api: true, admin: true, frontend: true, monitoring: true, scheduler: true}
		gateway:     {dns: true, proxy: true, api: true, admin: true, frontend: true, monitoring: true, scheduler: true}
		storage:     {cache: true, database: true, queue: true, backup: true, worker: true, api: true, admin: true, frontend: true, monitoring: true, scheduler: true}
		cache:       {}
		database:    {backup: true, worker: true, api: true, admin: true, frontend: true, monitoring: true, scheduler: true}
		dns:         {proxy: true, api: true, admin: true, frontend: true, monitoring: true, scheduler: true}
		queue:       {worker: true, monitoring: true, scheduler: true}
		backup:      {}
		proxy:       {api: true, admin: true, frontend: true, monitoring: true, scheduler: true}
		worker:      {monitoring: true, scheduler: true}
		api:         {admin: true, frontend: true, monitoring: true, scheduler: true}
		admin:       {}
		frontend:    {}
		monitoring:  {}
		scheduler:   {}
	}
}
