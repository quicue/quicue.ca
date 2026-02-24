// Architecture Decision Record — typed, validated, queryable
package core

// #Decision records an architecture decision with mandatory rationale.
// Status transitions: proposed → accepted → deprecated|superseded.
// CUE enforces: non-empty fields, valid ID format, at least one consequence.
#Decision: {
	"@type": "kg:Decision"
	id:      =~"^ADR-\\d{3}$"
	title:   string & !=""
	status:  "proposed" | "accepted" | "deprecated" | "superseded"
	date:    =~"^\\d{4}-\\d{2}-\\d{2}$"

	context:                             string & !=""
	decision:                            string & !=""
	rationale:                           string & !=""
	consequences: [...string] & [_, ...] // at least one

	supersedes?: =~"^ADR-\\d{3}$"
	appliesTo?: [...{...}]
	related?: {[string]: true} // struct-as-set links
	...
}
