package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {ObjectStorage: true}
	provider: "garage"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-garage"
	description: "Garage S3-compatible distributed storage provider. Manages buckets, keys, and cluster nodes."
	status:      "active"
}
