// dagger provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {
		CIServer: true
		PipelineEngine: true
	}
	provider: "dagger"
}
