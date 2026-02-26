// woodpecker provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {
		CIServer: true
		BuildServer: true
	}
	provider: "woodpecker"
}
