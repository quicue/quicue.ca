package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {AuthServer: true}
	provider: "keycloak"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-keycloak"
	description: "Identity and access management via Keycloak admin CLI."
	status:      "active"
}
