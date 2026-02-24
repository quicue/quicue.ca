package ansible

import "list"

// #PrometheusTargets - Generate Prometheus static_configs / file_sd targets
//
// Supports multi-exporter resources (e.g., node:9100 + app:9168),
// per-resource monitoring disable, and tag-based labels.
//
// Usage:
//   cue export -e prometheus.targets --out json > targets.json
#PrometheusTargets: {
	Resources: [string]: {
		ip?: string
		tags?: {[string]: true}
		host?:       string
		node?:       string
		owner?:      string
		monitoring?: #MonitoringConfig
		...
	}

	// Default port when resource has no monitoring.exporters
	DefaultPort: int | *9100

	// Job name for scrape config
	Job: string | *"infrastructure"

	// Extra labels applied to all targets
	ExtraLabels?: [string]: string

	// Which resources are disabled?
	_disabled: {
		for name, res in Resources
		if res.monitoring != _|_
		if res.monitoring.enabled != _|_
		if res.monitoring.enabled == false {
			"\(name)": true
		}
	}

	// Struct keyed by "resource_exporter" to avoid nested-for list issue
	_exporterMap: {
		for name, res in Resources
		if res.ip != _|_
		if _disabled[name] == _|_
		if res.monitoring != _|_
		if res.monitoring.exporters != _|_ {
			for expName, exp in res.monitoring.exporters {
				"\(name)__\(expName)": {
					_resourceName: name
					_exporterName: expName
					_res:          res
					_port:         exp.port
					_path:         exp.path
				}
			}
		}
	}

	_withExporters: [for _, entry in _exporterMap {entry}]

	// Resources using default exporter (no monitoring.exporters)
	_withDefaults: [
		for name, res in Resources
		if res.ip != _|_
		if _disabled[name] == _|_
		if res.monitoring == _|_ || res.monitoring.exporters == _|_ {
			_resourceName: name
			_exporterName: "node"
			_res:          res
			_port:         DefaultPort
		},
	]

	_allTargets: list.Concat([_withExporters, _withDefaults])

	targets: [
		for entry in _allTargets {
			targets: ["\(entry._res.ip):\(entry._port)"]
			labels: {
				instance: entry._resourceName
				job:      "\(Job)"
				exporter: entry._exporterName
				if entry._path != _|_ {
					"__metrics_path__": entry._path
				}
				if entry._res.node != _|_ {node: entry._res.node}
				if entry._res.host != _|_ {node: entry._res.host}
				if entry._res.owner != _|_ {owner: entry._res.owner}
				if entry._res.tags != _|_ {
					for tag, _ in entry._res.tags {
						"tag_\(tag)": "true"
					}
				}
				if ExtraLabels != _|_ {ExtraLabels}
			}
		},
	]
}
