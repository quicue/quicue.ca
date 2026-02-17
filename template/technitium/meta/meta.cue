package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {DNSServer: true}
	provider: "technitium"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-technitium"
	description: "DNS management via Technitium REST API."
	status:      "active"
}
