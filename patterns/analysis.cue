// Graph analysis patterns — re-exported from apercue.ca/patterns.
//
// All analysis patterns are imported from apercue — the domain-agnostic
// upstream. They accept any graph satisfying apercue's #AnalyzableGraph
// interface. #InfraGraph satisfies this — no adapter needed.
//
// #CriticalPath uses an O(n) backward pass via precomputed immediate
// dependents map (vs the previous O(n²) nested loop).
// #CriticalPathPrecomputed accepts Python-precomputed scheduling data
// for graphs too large for CUE's recursive fixpoint evaluation.

package patterns

import ( apercue "apercue.ca/patterns@v0"

	// ═══════════════════════════════════════════════════════════════════════════
	// STRUCTURAL ANALYSIS
	// ═══════════════════════════════════════════════════════════════════════════
)

#CycleDetector:       apercue.#CycleDetector
#ConnectedComponents: apercue.#ConnectedComponents
#Subgraph:            apercue.#Subgraph

#GraphDiff: apercue.#GraphDiff

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULING / CRITICAL PATH
// ═══════════════════════════════════════════════════════════════════════════

#CriticalPath:            apercue.#CriticalPath
#CriticalPathPrecomputed: apercue.#CriticalPathPrecomputed
