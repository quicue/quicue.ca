package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {MonitoringServer: true}
	provider: "zabbix"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-zabbix"
	description: "Enterprise monitoring via Zabbix API."
	status:      "active"
}
