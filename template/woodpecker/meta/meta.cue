package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {CIRunner: true}
	provider: "woodpecker"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-woodpecker"
	description: "Woodpecker CI provider. Manages pipelines, agents, secrets, cron jobs, and build logs."
	status:      "active"
}
