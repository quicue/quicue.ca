package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {KubernetesCluster: true}
	provider: "k3d"
}

project: {
    "@id": "https://quicue.ca/project/quicue-k3d"
    description: "CUE patterns for k3d (Kubernetes in Docker) - local Kubernetes development clusters."
    status: "active"
}
