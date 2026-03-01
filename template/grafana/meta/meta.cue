package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {MonitoringServer: true}
	provider: "grafana"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-grafana"
	description: "Grafana observability provider. Manages dashboards, datasources, alerts, annotations, and organizations."
	status:      "active"
}
