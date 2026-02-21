// SBOM dependency graph — CycloneDX SBOM projected as #InfraGraph
//
// Demonstrates: CycloneDX adapter → typed graph → metrics + SPOF analysis
//
// Generate resources.cue from a CycloneDX JSON BOM:
//   python tools/cyclonedx2graph.py examples/sbom/testdata/sample-bom.json \
//       --metadata -o examples/sbom/resources.cue -p sbom
//
// Then evaluate:
//   cue eval ./examples/sbom/ -e output.summary
//   cue eval ./examples/sbom/ -e output.single_points_of_failure

package sbom

import (
	"quicue.ca/patterns@v0"
)

// Analysis projections — all computed from the same graph
validate: patterns.#ValidateGraph & {Input: _resources}
metrics:  patterns.#GraphMetrics & {Graph: infra}
spof:     patterns.#SinglePointsOfFailure & {Graph: infra}

// Output summary
output: {
	summary: {
		total_components: metrics.total_resources
		total_edges:      metrics.total_edges
		max_depth:        metrics.max_depth
		root_components:  metrics.root_count
	}
	single_points_of_failure: spof
}
