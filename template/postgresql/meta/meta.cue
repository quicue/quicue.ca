package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
	types: {Database: true}
	provider: "postgresql"
}

project: {
	"@id":       "https://quicue.ca/project/quicue-postgresql"
	description: "Database administration via psql and pg_* utilities."
	status:      "active"
}
