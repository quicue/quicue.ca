package valid

import "quicue.ca/kg/core@v0"

i001: core.#Insight & {
	id:          "INSIGHT-001"
	statement:   "CUE scales linearly with node count at ~0.5ms/node for graph validation"
	evidence:    ["benchmark: 500 nodes 0.24s, 1000 nodes 0.56s, 5000 nodes 2.9s"]
	method:      "statistics"
	confidence:  "high"
	discovered:  "2026-02-15"
	implication: "CUE can handle production graph sizes without architectural changes"
	action_items: ["No need for Python fallback below ~5000 nodes"]
}
