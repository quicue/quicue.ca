// grafana provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {
		MonitoringServer: true
		Dashboard: true
	}
	provider: "grafana"
}
