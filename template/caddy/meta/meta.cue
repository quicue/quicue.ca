package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {ReverseProxy: true}
	provider: "caddy"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-caddy"
	description: "Caddy provider for quicue. Reverse proxy management via Caddy admin API."
	status:      "active"
}
