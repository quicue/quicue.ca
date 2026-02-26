// netbox provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {
		DCIMServer: true
		IPAMServer: true
	}
	provider: "netbox"
}
