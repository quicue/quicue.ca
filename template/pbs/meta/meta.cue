package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {ObjectStorage: true}
	provider: "pbs"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-pbs"
	description: "Backup management via proxmox-backup-client CLI."
	status:      "active"
}
