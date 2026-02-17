package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {APIServer: true}
	provider: "netbox"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-netbox"
	description: "IPAM and DCIM via NetBox REST API."
	status:      "active"
}
