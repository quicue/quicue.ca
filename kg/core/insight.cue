// Validated discovery with mandatory evidence and confidence tracking
package core

// #Insight records a discovery worth preserving.
// Requires at least one piece of evidence and explicit confidence level.
// method tracks HOW the insight was discovered (for reproducibility).
#Insight: {
	"@type":    "kg:Insight"
	id:         =~"^INSIGHT-\\d{3}$"
	statement:  string & !=""
	evidence:   [...string] & [_, ...] // at least one piece of evidence
	method:     "cross_reference" | "gap_analysis" | "statistics" | "experiment" | "observation"
	confidence: "high" | "medium" | "low"
	discovered: =~"^\\d{4}-\\d{2}-\\d{2}$"

	implication:   string & !=""
	action_items?: [...string]
	related?:      {[string]: true}
	...
}
