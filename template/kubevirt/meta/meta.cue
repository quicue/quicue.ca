package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {VirtualMachine: true, KubernetesCluster: true}
	provider: "kubevirt"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-kubevirt"
	description: "Virtual machine management on Kubernetes via virtctl."
	status:      "active"
}
