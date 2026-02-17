package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {TunnelEndpoint: true}
	provider: "cloudflare"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-cloudflare"
	description: "DNS, tunnels, and WAF management via Cloudflare API."
	status:      "active"
}
