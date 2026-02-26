// authentik provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {
		IdentityProvider: true
		SSOServer: true
	}
	provider: "authentik"
}
