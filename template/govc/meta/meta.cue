package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {VirtualizationPlatform: true}
	provider: "govc"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-govc"
	description: "govc provider for quicue. vSphere VM management via Go vSphere CLI."
	status:      "active"
}
