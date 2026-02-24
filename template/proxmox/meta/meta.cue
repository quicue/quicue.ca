package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {VirtualizationPlatform: true}
	provider: "proxmox"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-proxmox"
	description: "Proxmox VE provider for quicue. Implements action interfaces with qm, pct, and pvecm commands."
	status:      "active"
}
