package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {ReverseProxy: true, LoadBalancer: true}
	provider: "nginx"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-nginx"
	description: "Web server and reverse proxy management."
	status:      "active"
}
