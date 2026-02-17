package kg

import "quicue.ca/kg/aggregate@v0"

index: aggregate.#KGIndex & {
	project: "quicue-kg"

	decisions: decisions
	insights:  insights
	rejected:  rejected
	patterns:  patterns
}
