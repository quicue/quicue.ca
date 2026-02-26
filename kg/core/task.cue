// Trackable work item — typed, validated, linked to knowledge base entries
package core

// #Task records a unit of work with dependencies and KB references.
// Status transitions: pending → active → done|blocked|dropped.
// refs links to KB entries (ADR, INSIGHT, P, REJ) validated by ID format.
// depends_on uses struct-as-set for graph composition with #Graph/#Charter.
#Task: {
	"@type": "kg:Task"
	id:      #TaskID
	title:   string & !=""
	status:  #TaskStatus
	project: string & !=""

	"@type_tags"?: {[string]: true} // struct-as-set: task classification
	depends_on?: {[string]: true}   // struct-as-set: task dependency edges
	refs?: {[#KBRef]: true}         // struct-as-set: KB entry references
	blocked_by?: string             // freeform reason when status == "blocked"
	priority?: #Priority
	description?: string
	date?: =~"^\\d{4}-\\d{2}-\\d{2}$"
	related?: {[string]: true}
	...
}

// #TaskID — lowercase kebab-case identifier
#TaskID: =~"^[a-z][a-z0-9-]*$"

// #TaskStatus — lifecycle states
#TaskStatus: "pending" | "active" | "blocked" | "done" | "dropped"

// #Priority — triage levels
#Priority: "high" | "medium" | "low"

// #KBRef — validated reference to a KB entry
#KBRef: =~"^(ADR|INSIGHT|P|REJ)-\\d{3}$"
