// Reusable problem/solution pair — Christopher Alexander pattern language as CUE types
package core

// #Pattern captures a reusable solution with cross-project usage tracking.
// used_in uses struct-as-set for O(1) membership and clean unification across projects.
#Pattern: {
	"@type":  "kg:Pattern"
	name:     string & !=""
	category: string & !=""
	problem:  string & !=""
	solution: string & !=""
	context:  string & !=""
	example?: string
	used_in:  {[string]: true} // struct-as-set: projects using this pattern
	related?: {[string]: true} // struct-as-set: related patterns
	...
}
