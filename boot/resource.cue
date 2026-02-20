// patterns/resource.cue
// Bootstrap resource pattern - unifies with any resource definition

package boot

// #BootstrapResource adds bootstrap-specific computed fields to any resource
// It uses open schema (...) so it can unify with any resource shape
#BootstrapResource: {
	// Allow any fields from the unified resource
	...

	// Required: resource must have a name (ASCII-safe)
	name: =~"^[a-zA-Z][a-zA-Z0-9_.-]*$"

	// Optional: lifecycle commands (if present, used for bootstrap)
	lifecycle?: {
		create?:  string
		start?:   string
		stop?:    string
		restart?: string
		destroy?: string
		status?:  string
	}

	// Optional: health check (if present, used for readiness)
	health?: {
		command?: string
		timeout?: string
		retries?: int
		...
	}

	// Optional: network info (used for health checks)
	ip?:   string
	port?: int

	// Optional: dependencies (used for layer computation)
	depends_on?: {[=~"^[a-zA-Z][a-zA-Z0-9_.-]*$"]: true} | [...=~"^[a-zA-Z][a-zA-Z0-9_.-]*$"]

	// Bootstrap-specific additions (these are what quicue-boot adds)
	_bootstrap: {
		// Computed layer (0 = no deps, 1 = deps on layer 0, etc.)
		layer: int | *0

		// Generated commands
		commands: {
			create?:       string
			health_check?: string
			collect?:      string
		}

		// Credential collection config
		credentials?: {
			collector: string // command to collect
			paths: [...string]
		}
	}
}

// #BootstrapPlan is the top-level plan structure
#BootstrapPlan: {
	metadata: {
		name:        string
		environment: string | *"dev"
		version?:    string
	}

	// Resources to bootstrap (unify with #BootstrapResource)
	resources: [string]: #BootstrapResource

	// Computed: resources grouped by layer
	_layers: {
		for name, res in resources {
			"\(res._bootstrap.layer)": "\(name)": res
		}
	}

	// Computed: execution order
	execution_order: [...string]

	// Outputs
	output: {
		create_script:     string
		collect_script:    string
		dependency_graph?: string
	}
}
