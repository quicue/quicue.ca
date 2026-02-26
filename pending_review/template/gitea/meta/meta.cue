// gitea provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {
		GitForge: true
		SourceControl: true
	}
	provider: "gitea"
}
