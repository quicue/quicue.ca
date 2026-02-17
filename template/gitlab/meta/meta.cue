package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {SourceControlManagement: true}
	provider: "gitlab"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-gitlab"
	description: "GitLab project and CI/CD management via API."
	status:      "active"
}
