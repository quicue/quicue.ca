// headscale provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {
		VPNServer: true
		NetworkController: true
	}
	provider: "headscale"
}
