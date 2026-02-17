package valid

import "quicue.ca/kg/core@v0"

d001: core.#Decision & {
	id:     "ADR-001"
	title:  "Use PostgreSQL over SQLite"
	status: "accepted"
	date:   "2026-02-15"

	context:   "Need a database for production workloads."
	decision:  "Use PostgreSQL for all persistent storage."
	rationale: "PostgreSQL handles concurrent writes, has JSONB support, and is well-supported."
	consequences: [
		"All services must include a PostgreSQL client library",
		"Need to manage database migrations",
	]
	related: {"ADR-002": true}
}

d002: core.#Decision & {
	id:     "ADR-002"
	title:  "Use connection pooling"
	status: "proposed"
	date:   "2026-02-15"

	context:      "PostgreSQL has a default connection limit of 100."
	decision:     "Use PgBouncer for connection pooling."
	rationale:    "Reduces connection overhead and allows more concurrent clients."
	consequences: ["Must deploy PgBouncer alongside PostgreSQL"]
}
