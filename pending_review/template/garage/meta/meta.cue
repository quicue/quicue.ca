// garage provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {
		ObjectStorage: true
		S3Storage: true
	}
	provider: "garage"
}
