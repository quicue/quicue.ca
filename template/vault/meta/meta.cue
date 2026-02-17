package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {Vault: true}
	provider: "vault"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-vault"
	description: "Secrets management and PKI via Vault CLI."
	status:      "active"
}
