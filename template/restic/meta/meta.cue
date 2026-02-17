package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {ObjectStorage: true}
	provider: "restic"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-restic"
	description: "Deduplicating backup via restic CLI."
	status:      "active"
}
