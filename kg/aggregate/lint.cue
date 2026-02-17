// Knowledge quality lint rules — computed via comprehensions
package aggregate

// #LintResult reports knowledge quality issues
#LintResult: {
	level:   "error" | "warn" | "info"
	code:    string
	message: string
	entry?:  string
}

// #KGLint computes lint results from a populated #KGIndex
#KGLint: {
	index: #KGIndex

	// Referential integrity: all known IDs across types
	_all_ids: {
		for k, _ in index.decisions {(k): true}
		for k, _ in index.insights {(k): true}
		for k, _ in index.rejected {(k): true}
		for k, _ in index.patterns {(k): true}
	}

	results: [...#LintResult]

	// Note: rich lint logic (stale proposals, confidence upgrades,
	// dangling references) runs in the CLI via jq over exported JSON.
	// CUE comprehensions handle structural checks; jq handles temporal/heuristic ones.
}
