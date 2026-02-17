package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {DNSServer: true}
	provider: "powerdns"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-powerdns"
	description: "Authoritative DNS management via REST API."
	status:      "active"
}
