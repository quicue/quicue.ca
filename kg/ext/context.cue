// Project identity and self-description
package ext

// #Context is a project's identity card.
// Declares what the project is, what patterns it uses, and what concepts it knows.
#Context: {
	"@type":      "kg:Context"
	"@id"?:       string
	name:         string & !=""
	description:  string & !=""
	module?:      string
	repo?:        string
	status:       "active" | "experimental" | "archived" | "planned"
	license?:     string
	cue_version?: string
	uses?: [...{...}]
	knows?: [...{...}]
}
