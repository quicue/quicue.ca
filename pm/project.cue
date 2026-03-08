// Project — composable project type for IT project management.
//
// CUE validates types + charter. Python (toposort.py) does graph traversal.
// This split avoids #InfraGraph's O(n⁵) scaling at >18 nodes while keeping
// type safety and charter gap analysis in CUE.
//
// Workflow:
//   1. Define work_items + charter in CUE
//   2. Run toposort.py to precompute topology
//   3. cue vet validates types + charter gaps
//   4. Python/dashboard consumes precomputed JSON
//
// Usage:
//   import "quicue.ca/pm"
//
//   vcf: pm.#Project & {
//       name: "VCF Migration 2026"
//       owner: "Infrastructure"
//       work_items: { ... }
//       project_charter: { ... }
//       precomputed: _precomputed   // from toposort.py
//   }

package pm

import "quicue.ca/charter"

#Project: {
	name:        string
	description: *"" | string
	owner:       string
	start_date?: string // YYYY-MM-DD

	// Work items — the project's task graph
	work_items: [string]: #WorkItem

	// Charter — constraint-first project planning
	project_charter: charter.#Charter

	// Pre-computed topology from Python toposort.
	// Generate: python3 tools/toposort.py ./project.cue --cue > precomputed.cue
	precomputed: {
		depth: [string]: int
		ancestors: [string]: {[string]: true}
		dependents: [string]: {[string]: true}
	}

	// ── Lightweight graph for charter gap analysis ───────────────
	// Built from precomputed data — no #InfraGraph, no O(n²) recursion.
	_graph: {
		resources: work_items
		roots: {
			for name, d in precomputed.depth
			if d == 0 {(name): true}
		}
		topology: {
			for name, d in precomputed.depth {
				"layer_\(d)": (name): true
			}
		}
		valid: true
	}

	// ── Computed: gap analysis ───────────────────────────────────
	_gaps: charter.#GapAnalysis & {Charter: project_charter, Graph: _graph}
}
