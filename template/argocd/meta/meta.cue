package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {KubernetesCluster: true}
	provider: "argocd"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-argocd"
	description: "GitOps continuous delivery via ArgoCD CLI."
	status:      "active"
}
