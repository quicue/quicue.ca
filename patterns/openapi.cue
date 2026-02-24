// OpenAPI 3.0.3 specification from bound clusters.
//
// Generates a valid OpenAPI spec where each resource+action becomes a path.
// Categories become tags. Operational metadata becomes vendor extensions.
//
// Usage:
//   import "quicue.ca/patterns@v0"
//
//   spec: patterns.#OpenAPISpec & {
//       Cluster: myBoundCluster
//       Info: { title: "My API", version: "1.0.0" }
//   }
//
//   // cue export . -e spec.spec --out json

package patterns

#OpenAPISpec: {
	Cluster: #BindCluster

	Info: {
		title:       string | *"Infrastructure Operations API"
		description: string | *"Auto-generated from quicue.ca #BindCluster"
		version:     string | *"1.0.0"
	}

	// Collect unique categories for tags
	_categories: {
		for _, r in Cluster.bound {
			for _, pactions in r.actions {
				for _, a in pactions {
					if a.category != _|_ {
						(a.category): true
					}
				}
			}
		}
	}

	_categoryDescriptions: {
		info:    "Read-only information and status queries"
		connect: "Interactive connections (SSH, console)"
		monitor: "Monitoring and health checks"
		admin:   "Administrative operations that modify state"
	}

	spec: {
		openapi: "3.0.3"
		info: {
			title:              Info.title
			description:        Info.description
			version:            Info.version
			"x-dct:conformsTo": "https://spec.openapis.org/oas/3.0.3"
		}

		tags: [
			for cat, _ in _categories {
				name: cat
				if _categoryDescriptions[cat] != _|_ {
					description: _categoryDescriptions[cat]
				}
			},
		]

		paths: {
			for rname, r in Cluster.bound {
				for pname, pactions in r.actions {
					for aname, a in pactions {
						if a.command != _|_ {
							"/resources/\(rname)/\(pname)/\(aname)": post: {
								summary:     a.name
								operationId: "\(rname)--\(pname)--\(aname)"
								if a.description != _|_ {
									description: a.description
								}
								if a.category != _|_ {
									tags: [a.category]
								}
								"x-command":  a.command
								"x-provider": pname
								if a.idempotent != _|_ {
									"x-idempotent": a.idempotent
								}
								if a.destructive != _|_ {
									"x-destructive": a.destructive
								}
								responses: "200": description: "Action executed successfully"
							}
						}
					}
				}
			}
		}
	}

	summary: {
		total_paths: len(spec.paths)
		total_tags:  len(spec.tags)
	}
}
