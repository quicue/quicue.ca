package invalid

import "quicue.ca/kg/core@v0"

// This SHOULD fail: alternative is empty (must suggest what to do instead)
r_bad: core.#Rejected & {
	id:          "REJ-001"
	approach:    "Something we tried"
	reason:      "It didn't work"
	date:        "2026-02-15"
	alternative: ""
}
