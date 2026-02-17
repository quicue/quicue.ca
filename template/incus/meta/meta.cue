package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {VirtualizationPlatform: true}
	provider: "incus"
}

project: {
    "@id": "https://quicue.ca/project/quicue-incus"
    description: "Incus provider for quicue. Implements action patterns for containers, VMs, profiles, networks, storage, and clusters."
    status: "active"
}
