// harbor provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {
		ContainerRegistry: true
	}
	provider: "harbor"
}
