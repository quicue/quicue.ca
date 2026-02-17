package invalid

import "quicue.ca/kg/core@v0"

// This SHOULD fail: name is empty string
p_bad: core.#Pattern & {
	name:     ""
	category: "data"
	problem:  "test"
	solution: "test"
	context:  "test"
	used_in: {test: true}
}
