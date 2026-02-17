package ansible

// #GrafanaDashboard - Generate Grafana dashboard JSON
//
// Produces a dashboard with:
//   - Status overview: UP/DOWN stat panels in 4-column grid
//   - Detail row: CPU, Memory, Disk, Network timeseries panels
//   - Template variables: $node and $instance dropdowns
//
// Usage:
//   cue export -e grafana.dashboard --out json > dashboard.json
#GrafanaDashboard: {
	Resources: [string]: {
		ip?:   string
		name?: string
		tags?: {[string]: true}
		host?: string
		node?: string
		...
	}

	Title:      string | *"Infrastructure Overview"
	Uid:        string | *"quicue-infra-overview"
	Datasource: string | *"Prometheus"
	Refresh:    string | *"30s"

	// List of resources with IPs (for panel generation)
	_resourceList: [for n, r in Resources if r.ip != _|_ {_name: n, _ip: r.ip}]

	dashboard: {
		title:         Title
		uid:           Uid
		schemaVersion: 39
		editable:      true
		refresh:       Refresh
		time: {
			from: "now-1h"
			to:   "now"
		}

		// Template variables
		templating: list: [
			{
				name:       "node"
				type:       "query"
				datasource: Datasource
				query:      "label_values(up, node)"
				refresh:    2
				includeAll: true
				allValue:   ".*"
				current: {text: "All", value: "$__all"}
			},
			{
				name:       "instance"
				type:       "query"
				datasource: Datasource
				query:      "label_values(up{node=~\"$node\"}, instance)"
				refresh:    2
				includeAll: true
				allValue:   ".*"
				current: {text: "All", value: "$__all"}
			},
		]

		panels: [
			// Row: Status Overview
			{
				id:        1
				title:     "Status Overview"
				type:      "row"
				collapsed: false
				gridPos: {h: 1, w: 24, x: 0, y: 0}
			},

			// Status stat panels (4-column grid)
			for i, entry in _resourceList {
				{
					id:         100 + i
					title:      entry._name
					type:       "stat"
					datasource: Datasource
					targets: [{
						expr:         "up{instance=\"\(entry._name)\"}"
						legendFormat: "{{instance}}"
					}]
					fieldConfig: defaults: {
						mappings: [
							{options: {"0": {text: "DOWN", color: "red"}}, type: "value"},
							{options: {"1": {text: "UP", color: "green"}}, type: "value"},
						]
						thresholds: {
							mode: "absolute"
							steps: [
								{color: "red", value: null},
								{color: "green", value: 1},
							]
						}
					}
					gridPos: {
						h: 3
						w: 6
						x: (i * 6) mod 24
						y: 1 + div((i * 6), 24) * 3
					}
				}
			},

			// Row: Resource Details
			{
				let _statusRows = div((len(_resourceList) * 6 + 23), 24) * 3
				id:        2
				title:     "Resource Details"
				type:      "row"
				collapsed: false
				gridPos: {h: 1, w: 24, x: 0, y: 1 + _statusRows}
				panels: []
			},

			// CPU Usage
			{
				let _statusRows = div((len(_resourceList) * 6 + 23), 24) * 3
				id:         200
				title:      "CPU Usage"
				type:       "timeseries"
				datasource: Datasource
				targets: [{
					expr:         "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\", instance=~\"$instance\"}[5m])) * 100)"
					legendFormat: "{{instance}}"
				}]
				fieldConfig: defaults: {
					unit: "percent"
					max:  100
				}
				gridPos: {h: 8, w: 12, x: 0, y: 2 + _statusRows}
			},

			// Memory Usage
			{
				let _statusRows = div((len(_resourceList) * 6 + 23), 24) * 3
				id:         201
				title:      "Memory Usage"
				type:       "timeseries"
				datasource: Datasource
				targets: [{
					expr:         "(1 - node_memory_MemAvailable_bytes{instance=~\"$instance\"} / node_memory_MemTotal_bytes{instance=~\"$instance\"}) * 100"
					legendFormat: "{{instance}}"
				}]
				fieldConfig: defaults: {
					unit: "percent"
					max:  100
				}
				gridPos: {h: 8, w: 12, x: 12, y: 2 + _statusRows}
			},

			// Disk Usage
			{
				let _statusRows = div((len(_resourceList) * 6 + 23), 24) * 3
				id:         202
				title:      "Disk Usage"
				type:       "gauge"
				datasource: Datasource
				targets: [{
					expr:         "(1 - node_filesystem_avail_bytes{instance=~\"$instance\", mountpoint=\"/\", fstype!=\"tmpfs\"} / node_filesystem_size_bytes{instance=~\"$instance\", mountpoint=\"/\", fstype!=\"tmpfs\"}) * 100"
					legendFormat: "{{instance}}"
				}]
				fieldConfig: defaults: {
					unit: "percent"
					max:  100
					thresholds: {
						mode: "absolute"
						steps: [
							{color: "green", value: null},
							{color: "yellow", value: 70},
							{color: "red", value: 90},
						]
					}
				}
				gridPos: {h: 8, w: 12, x: 0, y: 10 + _statusRows}
			},

			// Network I/O
			{
				let _statusRows = div((len(_resourceList) * 6 + 23), 24) * 3
				id:         203
				title:      "Network I/O"
				type:       "timeseries"
				datasource: Datasource
				targets: [
					{
						expr:         "rate(node_network_receive_bytes_total{instance=~\"$instance\", device!~\"lo|veth.*|br.*\"}[5m])"
						legendFormat: "{{instance}} rx"
					},
					{
						expr:         "-rate(node_network_transmit_bytes_total{instance=~\"$instance\", device!~\"lo|veth.*|br.*\"}[5m])"
						legendFormat: "{{instance}} tx"
					},
				]
				fieldConfig: defaults: unit: "Bps"
				gridPos: {h: 8, w: 12, x: 12, y: 10 + _statusRows}
			},
		]
	}
}
