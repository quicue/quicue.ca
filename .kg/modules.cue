// Module registry — all modules in this repo and their purpose
package kg

modules: {
	vocab: {
		path:        "vocab/"
		module:      "quicue.ca@v0"
		layer:       "definition"
		description: "Core schemas: #Resource, #Action, #TypeRegistry, #ActionDef"
		status:      "active"
	}
	patterns: {
		path:        "patterns/"
		module:      "quicue.ca@v0"
		layer:       "definition"
		description: "Algorithms: graph, bind, deploy, health, SPOF, viz, TOON, OpenAPI, validation"
		status:      "active"
		schemas: [
			"#InfraGraph", "#BindCluster", "#ExecutionPlan",
			"#ImpactQuery", "#BlastRadius", "#SinglePointsOfFailure",
			"#CriticalityRank", "#HealthStatus", "#RollbackPlan",
			"#DeploymentPlan", "#TOONExport", "#ExportGraph",
			"#ValidateGraph", "#GroupByType", "#GraphMetrics",
			"#ImmediateDependents", "#DependencyChain",
		]
	}
	templates: {
		path:        "template/*/"
		layer:       "template"
		description: "28 platform-specific providers, each a self-contained CUE module"
		status:      "active"
		count:       28
		categories: {
			compute:        ["proxmox", "govc", "powercli", "kubevirt"]
			container:      ["docker", "incus", "k3d", "kubectl", "argocd"]
			cicd:           ["dagger", "gitlab"]
			networking:     ["vyos", "caddy", "nginx"]
			dns:            ["cloudflare", "powerdns", "technitium"]
			identity:       ["vault", "keycloak"]
			database:       ["postgresql"]
			dcim:           ["netbox"]
			provisioning:   ["foreman"]
			automation:     ["ansible", "awx"]
			monitoring:     ["zabbix"]
			iac:            ["terraform", "opentofu"]
			backup:         ["restic", "pbs"]
		}
	}
	orche: {
		path:        "orche/"
		module:      "quicue.ca@v0"
		layer:       "orchestration"
		description: "Orchestration schemas: execution steps, federation, drift detection, Docker site bootstrap"
		status:      "active"
		packages:    ["orchestration", "bootstrap", "schema"]
		depends:     ["patterns"]
	}
	boot: {
		path:        "boot/"
		module:      "quicue.ca@v0"
		layer:       "orchestration"
		description: "Bootstrap schemas: #BootstrapResource, #BootstrapPlan, credential collectors"
		status:      "active"
	}
	wiki: {
		path:        "wiki/"
		module:      "quicue.ca@v0"
		layer:       "projection"
		description: "#WikiProjection — MkDocs site generation from resource graphs"
		status:      "active"
	}
	cab: {
		path:        "cab/"
		module:      "quicue.ca@v0"
		layer:       "reporting"
		description: "Change Advisory Board reports: impact, blast radius, runbooks"
		status:      "active"
	}
	ou: {
		path:        "ou/"
		module:      "quicue.ca@v0"
		layer:       "interaction"
		description: "Role-scoped views: #InteractionCtx narrows #ExecutionPlan by role, type, name, layer. Hydra W3C JSON-LD export."
		status:      "active"
		depends:     ["patterns"]
	}
	ci: {
		path:        "ci/gitlab/"
		layer:       "ci"
		description: "Reusable GitLab CI templates for CUE validation, export, topology, impact"
		status:      "active"
	}
	server: {
		path:        "server/"
		layer:       "operations"
		description: "FastAPI execution gateway for running infrastructure commands"
		status:      "active"
		optional:    true
		notes:       "Standalone. Consumes CUE-generated specs but does not depend on CUE at build time."
	}
	examples: {
		path:  "examples/"
		layer: "value"
		description: "10 working examples from minimal 3-layer to full 30-resource datacenter"
		status: "active"
		entries: [
			"datacenter",
			"homelab",
			"graph-patterns",
			"drift-detection",
			"federation",
			"type-composition",
			"3-layer",
			"docker-bootstrap",
			"wiki-projection",
			"toon-export",
		]
	}
}
