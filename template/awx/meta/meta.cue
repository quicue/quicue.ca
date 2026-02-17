package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {CIRunner: true}
	provider: "awx"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-awx"
	description: "Ansible automation controller via AWX REST API."
	status:      "active"
}
