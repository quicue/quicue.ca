package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {Router: true}
	provider: "vyos"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-vyos"
	description: "VyOS provider for quicue. Router configuration and operational commands via SSH."
	status:      "active"
}
