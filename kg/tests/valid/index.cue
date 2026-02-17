package valid

import (
	"quicue.ca/kg/core@v0"
	"quicue.ca/kg/aggregate@v0"
)

_test_index: aggregate.#KGIndex & {
	project: "test-project"

	decisions: {
		"ADR-001": core.#Decision & {
			id: "ADR-001", title: "Use PostgreSQL", status: "accepted"
			date: "2026-01-01", context: "test", decision: "test"
			rationale: "test", consequences: ["test"]
		}
		"ADR-002": core.#Decision & {
			id: "ADR-002", title: "Use Redis caching", status: "proposed"
			date: "2026-02-01", context: "test", decision: "test"
			rationale: "test", consequences: ["test"]
		}
	}

	insights: {
		"INSIGHT-001": core.#Insight & {
			id: "INSIGHT-001", statement: "PostgreSQL handles 10k QPS"
			evidence: ["benchmark.py"], method: "statistics"
			confidence: "high", discovered: "2026-01-15"
			implication: "No need for read replicas below 10k QPS"
		}
	}

	rejected: {
		"REJ-001": core.#Rejected & {
			id: "REJ-001", approach: "Use MongoDB"
			reason: "No ACID transactions", date: "2026-01-01"
			alternative: "Use PostgreSQL with JSONB"
		}
	}

	patterns: {
		struct_as_set: core.#Pattern & {
			name: "Struct-as-Set", category: "data"
			problem: "Arrays allow duplicates", solution: "Use {[string]: true}"
			context: "Set membership", used_in: {"quicue.ca": true}
		}
	}
}
