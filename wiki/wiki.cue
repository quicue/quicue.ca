// quicue-wiki: Generate static documentation from infrastructure graphs
//
// Module: quicue.ca/wiki
package wiki

import "strings"

// #Resource defines the expected shape for wiki input resources.
// Use CUE unification to validate data before wiki generation.
// Required: name, @type. Others default to empty.
#Resource: {
	name:        string
	description: string | *""
	"@type": {[string]: true}
	ip:        string | *""
	hostname:  string | *""
	host:      string | *""
	depends_on: {[string]: true} | *{}
	...
}

// #WikiProjection transforms resources into markdown documentation
#WikiProjection: {
	Resources: [string]: #Resource
	SiteTitle:       string | *"Infrastructure Wiki"
	SiteDescription: string | *"Auto-generated from quicue infrastructure graph"
	SiteURL:         string | *""
	DocsPath:        string | *"docs"

	// Collect unique types
	_all_types: {
		for _, res in Resources if res["@type"] != _|_ {
			for t, _ in res["@type"] {
				"\(t)": true
			}
		}
	}
	_type_list: [for t, _ in _all_types {t}]

	// Pre-compute which resources have a host field and what it is
	_resource_host: {
		for name, res in Resources {
			if res.host != _|_ if res.host != "" {
				"\(name)": res.host
			}
		}
	}

	// Collect unique hosts from the pre-computed map
	_all_hosts: {
		for _, h in _resource_host {
			"\(h)": true
		}
	}
	_host_list: [for h, _ in _all_hosts {h}]

	// Resources by type
	_by_type: {
		for t, _ in _all_types {
			"\(t)": [for name, res in Resources if res["@type"] != _|_ && res["@type"][t] != _|_ {name}]
		}
	}

	// Resources by host - use the pre-computed _resource_host map
	_by_host: {
		for h, _ in _all_hosts {
			"\(h)": [for name, host in _resource_host if host == h {name}]
		}
	}

	// Pre-compute resource details for templates.
	// Uses if-guards instead of | *default to work around CUE
	// comprehension binding default-resolution (v0.15.3+).
	_resource_details: {
		for name, res in Resources {
			"\(name)": {
				if res.description != _|_ if res.description != "" {
					desc: res.description
				}
				if res.description == _|_ || res.description == "" {
					desc: "No description"
				}
				if res.ip != _|_ if res.ip != "" {
					ip: res.ip
				}
				if res.ip == _|_ || res.ip == "" {
					ip: "-"
				}
				if res.hostname != _|_ if res.hostname != "" {
					hostname: res.hostname
				}
				if res.hostname == _|_ || res.hostname == "" {
					hostname: "-"
				}
				if _resource_host[name] != _|_ {
					host: _resource_host[name]
				}
				if _resource_host[name] == _|_ {
					host: "-"
				}
				types: strings.Join([for t, _ in res["@type"] {"`\(t)`"}], " ")
			}
		}
	}

	// Pre-compute dependencies using if-guards
	_resource_deps: {
		for name, res in Resources {
			if res.depends_on != _|_ {
				"\(name)": [for d, _ in res.depends_on {d}]
			}
			if res.depends_on == _|_ {
				"\(name)": []
			}
		}
	}

	// Generate all files
	files: {
		// Index page
		"\(DocsPath)/index.md": {
			path:    "\(DocsPath)/index.md"
			content: _mkIndex
		}

		// Resource pages
		for name, _ in Resources {
			"\(DocsPath)/resources/\(name).md": {
				path:    "\(DocsPath)/resources/\(name).md"
				content: _mkResource[name]
			}
		}

		// Type pages
		for t, _ in _all_types {
			let slug = strings.ToLower(t)
			"\(DocsPath)/types/\(slug).md": {
				path:    "\(DocsPath)/types/\(slug).md"
				content: _mkTypePage[t]
			}
		}

		// Host pages
		for h, _ in _all_hosts {
			"\(DocsPath)/hosts/\(h).md": {
				path:    "\(DocsPath)/hosts/\(h).md"
				content: _mkHostPage[h]
			}
		}

		// Dependency graph
		"\(DocsPath)/graph.md": {
			path:    "\(DocsPath)/graph.md"
			content: _mkGraph
		}

		// mkdocs.yml
		"mkdocs.yml": {
			path:    "mkdocs.yml"
			content: _mkConfig
		}
	}

	file_list: [for p, _ in files {p}]

	stats: {
		total_resources: len(Resources)
		total_types:     len(_all_types)
		total_hosts:     len(_all_hosts)
		total_files:     len(files)
	}

	// Index page content
	_mkIndex: """
		# \(SiteTitle)

		\(SiteDescription)

		## Overview

		| Metric | Count |
		|--------|-------|
		| Resources | \(len(Resources)) |
		| Types | \(len(_all_types)) |
		| Hosts | \(len(_all_hosts)) |

		## By Type

		\(_typeLinks)

		## By Host

		\(_hostLinks)

		## All Resources

		| Name | IP | Host | Types |
		|------|----|----|-------|
		\(_resourceTable)

		---
		*Generated from quicue infrastructure graph*
		"""

	_typeLinks: strings.Join([for t in _type_list {
		"- [\(t)](types/\(strings.ToLower(t)).md) (\(len(_by_type[t])))"
	}], "\n")

	_hostLinks: strings.Join([for h in _host_list {
		"- [\(h)](hosts/\(h).md) (\(len(_by_host[h])))"
	}], "\n")

	_resourceTable: strings.Join([for name, _ in Resources {
		let d = _resource_details[name]
		let types = strings.Join([for t, _ in Resources[name]["@type"] {t}], ", ")
		"| [\(name)](resources/\(name).md) | \(d.ip) | \(d.host) | \(types) |"
	}], "\n")

	// Resource pages - using pre-computed details
	_mkResource: {
		for name, _ in Resources {
			let d = _resource_details[name]
			let deps = _resource_deps[name]
			let depsSection = strings.Join([
				if len(deps) > 0 {
					"\n## Dependencies\n\nThis resource depends on:\n\n" + strings.Join([for dep in deps {
						"- [\(dep)](../resources/\(dep).md)"
					}], "\n")
				},
			], "")
			"\(name)": """
				# \(name)

				\(d.desc)

				## Details

				| Field | Value |
				|-------|-------|
				| Name | `\(name)` |
				| IP | `\(d.ip)` |
				| Hostname | `\(d.hostname)` |
				| Host | \(d.host) |
				| Types | \(d.types) |
				\(depsSection)

				---
				*Generated from quicue infrastructure graph*
				"""
		}
	}

	// Type pages - using pre-computed details
	_mkTypePage: {
		for t, _ in _all_types {
			let rows = strings.Join([for name in _by_type[t] {
				let d = _resource_details[name]
				"| [\(name)](../resources/\(name).md) | \(d.ip) | \(d.host) |"
			}], "\n")
			"\(t)": """
				# \(t)

				Resources of type `\(t)`.

				## Resources (\(len(_by_type[t])))

				| Name | IP | Host |
				|------|----|------|
				\(rows)

				---
				*Generated from quicue infrastructure graph*
				"""
		}
	}

	// Host pages - using pre-computed details
	_mkHostPage: {
		for h, _ in _all_hosts {
			let rows = strings.Join([for name in _by_host[h] {
				let d = _resource_details[name]
				let types = strings.Join([for t, _ in Resources[name]["@type"] {t}], ", ")
				"| [\(name)](../resources/\(name).md) | \(d.ip) | \(types) |"
			}], "\n")
			"\(h)": """
				# Host: \(h)

				Resources hosted on `\(h)`.

				## Resources (\(len(_by_host[h])))

				| Name | IP | Types |
				|------|----|-------|
				\(rows)

				---
				*Generated from quicue infrastructure graph*
				"""
		}
	}

	// Dependency graph in Mermaid
	_mkGraph: """
		# Dependency Graph

		```mermaid
		graph TD
		\(_graphNodes)
		\(_graphHostEdges)
		\(_graphDepEdges)
		```

		## Legend
		- Solid arrows: hosting relationship
		- Dashed arrows: explicit dependencies

		---
		*Generated from quicue infrastructure graph*
		"""

	_graphNodes: strings.Join([for name, res in Resources {
		let types = strings.Join([for t, _ in res["@type"] {t}], ",")
		"    \(name)[\"\(name)<br/>\(types)\"]"
	}], "\n")

	_graphHostEdges: strings.Join([for name, host in _resource_host {
		"    \(name) --> \(host)"
	}], "\n")

	_graphDepEdges: strings.Join([for name, _ in Resources if _resource_deps[name] != _|_ {
		strings.Join([for d in _resource_deps[name] {"    \(name) -.-> \(d)"}], "\n")
	}], "\n")

	// MkDocs config
	_mkConfig: """
		site_name: \(SiteTitle)
		site_description: \(SiteDescription)

		theme:
		  name: material
		  features:
		    - navigation.sections
		    - search.highlight
		  palette:
		    scheme: default
		    primary: indigo

		plugins:
		  - search

		markdown_extensions:
		  - tables
		  - pymdownx.superfences:
		      custom_fences:
		        - name: mermaid
		          class: mermaid
		          format: !!python/name:pymdownx.superfences.fence_code_format

		nav:
		  - Home: index.md
		  - By Type:
		\(_navTypes)
		  - By Host:
		\(_navHosts)
		  - Graph: graph.md
		"""

	_navTypes: strings.Join([for t in _type_list {
		"      - \(t): types/\(strings.ToLower(t)).md"
	}], "\n")

	_navHosts: strings.Join([for h in _host_list {
		"      - \(h): hosts/\(h).md"
	}], "\n")
}

// #FullExport for convenience
#FullExport: {
	Resources:       [string]: #Resource
	SiteTitle:       string | *"Infrastructure Wiki"
	SiteDescription: string | *"Auto-generated from quicue infrastructure graph"
	SiteURL:         string | *""

	_wiki: #WikiProjection & {
		"Resources":       Resources
		"SiteTitle":       SiteTitle
		"SiteDescription": SiteDescription
		"SiteURL":         SiteURL
	}

	files:     _wiki.files
	file_list: _wiki.file_list
	stats:     _wiki.stats
}
