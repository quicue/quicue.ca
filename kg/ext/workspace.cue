// Multi-repo topology — where things live and how repos connect
package ext

// #Workspace maps the physical layout of a multi-repo project.
// Components describe each repo/directory with paths, symlinks, and remotes.
#Workspace: {
	"@type":      "kg:Workspace"
	name:         string & !=""
	description:  string & !=""
	components: {[string]: {
		path:         string & !=""
		description:  string & !=""
		symlink?:     string
		module?:      string
		git_remotes?: {[string]: string}
		branch?:      string
		... // allow domain-specific fields
	}}
	deploy?: {
		domain?:    string
		container?: string
		host?:      string
		path?:      string
		...
	}
}
