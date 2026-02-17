package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {KubernetesCluster: true}
	provider: "kubectl"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-kubectl"
	description: "Kubernetes cluster management via kubectl CLI."
	status:      "active"
}
