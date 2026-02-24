package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {DockerContainer: true, ComposeStack: true}
	provider: "docker"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-docker"
	description: "Docker provider for quicue. Implements action patterns for containers, Compose stacks, networks, volumes, and images."
	status:      "active"
}
