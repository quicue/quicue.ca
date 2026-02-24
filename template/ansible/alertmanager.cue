package ansible

// #AlertManagerRoutes - Generate AlertManager configuration
//
// Produces a complete alertmanager.yml-compatible config with:
//   - Owner-based route tree
//   - Critical infrastructure priority route
//   - Auto-generated receiver stubs (webhook/email)
//   - Node-down inhibition rule
//
// Usage:
//   cue export -e alertmanager.config --out yaml > alertmanager.yml
#AlertManagerRoutes: {
	Resources: [string]: {
		owner?:    string
		severity?: string
		tags?: {[string]: true}
		...
	}

	// Receiver definitions (webhook_url or email per owner)
	Receivers?: [string]: {
		webhook_url?: string
		email?:       string
	}

	// Default receiver for unmatched alerts
	DefaultReceiver: string | *"default-receiver"

	// Group settings
	GroupBy: [...string] | *["alertname", "instance"]
	GroupWait:      string | *"30s"
	GroupInterval:  string | *"5m"
	RepeatInterval: string | *"4h"

	// Tag name that identifies critical resources
	CriticalTag: string | *"CriticalInfra"

	// Computed: unique owners
	_by_owner: {
		for _, res in Resources
		if res.owner != _|_ {
			"\(res.owner)": true
		}
	}

	// Computed: resources with critical tag
	_critical_resources: [
		for name, res in Resources
		if res.tags != _|_
		if res.tags[CriticalTag] != _|_ {name},
	]

	// Full AlertManager config structure
	config: {
		route: {
			receiver:        DefaultReceiver
			group_by:        GroupBy
			group_wait:      GroupWait
			group_interval:  GroupInterval
			repeat_interval: RepeatInterval

			routes: [
				// Critical infrastructure gets shorter repeat interval
				if len(_critical_resources) > 0 {
					{
						match: {"severity": "critical"}
						receiver:        "critical-receiver"
						repeat_interval: "1h"
					}
				},

				// Owner-based routes
				for owner, _ in _by_owner {
					{
						match: {"owner": owner}
						receiver: "\(owner)-receiver"
					}
				},
			]
		}

		// Auto-generated receivers
		receivers: [
			{name: DefaultReceiver},
			if len(_critical_resources) > 0 {
				{name: "critical-receiver"}
			},
			for owner, _ in _by_owner {
				{
					name: "\(owner)-receiver"
					if Receivers != _|_ {
						if Receivers[owner] != _|_ {
							if Receivers[owner].webhook_url != _|_ {
								webhook_configs: [{
									url: Receivers[owner].webhook_url
								}]
							}
							if Receivers[owner].email != _|_ {
								email_configs: [{
									to: Receivers[owner].email
								}]
							}
						}
					}
				}
			},
		]

		// Inhibition: node down suppresses container alerts on that node
		inhibit_rules: [{
			source_matchers: ["alertname = NodeDown"]
			target_matchers: ["alertname = InstanceDown"]
			equal: ["node"]
		}]
	}

	// Backward-compatible flat routes array
	routes: config.route.routes
}
