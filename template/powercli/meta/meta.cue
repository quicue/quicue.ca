package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {VirtualizationPlatform: true}
	provider: "powercli"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-powercli"
	description: "PowerCLI provider for quicue. vSphere VM management via VMware PowerShell cmdlets."
	status:      "active"
}
