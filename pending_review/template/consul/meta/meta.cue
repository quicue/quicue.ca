// consul provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {
		ServiceDiscovery: true
		ServiceMesh: true
	}
	provider: "consul"
}
