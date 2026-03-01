package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {ContainerRegistry: true}
	provider: "harbor"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-harbor"
	description: "Harbor container registry provider. Manages projects, repositories, artifacts, tags, and replication policies."
	status:      "active"
}
