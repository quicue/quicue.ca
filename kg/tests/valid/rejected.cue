package valid

import "quicue.ca/kg/core@v0"

r001: core.#Rejected & {
	id:          "REJ-001"
	approach:    "Use SQLite for production database"
	reason:      "Cannot handle concurrent writes from multiple services. Write lock contention causes timeouts."
	date:        "2026-02-15"
	alternative: "Use PostgreSQL with connection pooling (see ADR-001)"
	related: {"ADR-001": true}
}
