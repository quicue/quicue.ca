package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {CIRunner: true}
	provider: "dagger"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-dagger"
	description: "CI/CD pipeline orchestration via Dagger CLI."
	status:      "active"
}
