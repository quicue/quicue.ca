// Visualization Data Contract
//
// Defines the JSON structure consumed by all quicue visualization tools.
// This is the canonical schema for viz data export.
//
// Usage:
//   cue export ./examples/graph-patterns -e vizData --out json > viz.json
//
// Consumers:
//   - quicue.nu (nushell scripts)
//   - quicue-gum (interactive CLI)
//   - quicue-fzf (fuzzy finder interface)
//   - quicue-tui (terminal UI)

package vocab

// #VizNode - Minimal node representation for all visualization tools
#VizNode: {
	id:   #SafeID
	name: #SafeID
	types: [...#SafeLabel] // Flattened from @type struct
	depth:                 int
	ancestors: [...#SafeID]
	dependents: int // Count, not list

	// Optional fields (present if resource has them)
	ip?:           string
	host?:         string
	container_id?: int | string
	description?:  string
}

// #VizEdge - Dependency edge
#VizEdge: {
	source: #SafeID // Resource name
	target: #SafeID // Resource name (depends on source)
}

// #VizData - Complete visualization payload
#VizData: {
	nodes: [...#VizNode]
	edges: [...#VizEdge]
	topology: [string]: [...string] // layer_N: [resource names]
	roots: [...string]
	leaves: [...string]
	metrics: {
		total:    int
		maxDepth: int
		edges:    int
		roots:    int
		leaves:   int
	}
}
