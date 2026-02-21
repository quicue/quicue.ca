// CI pipeline dependency graph — GitLab CI projected as #InfraGraph
//
// Demonstrates: GitLab CI adapter → typed graph → metrics + SPOF analysis
//
// Generate resources.cue from a .gitlab-ci.yml:
//   python tools/gitlab-ci2graph.py examples/ci/testdata/sample-pipeline.yml \
//       --metadata -o examples/ci/resources.cue -p ci
//
// Then evaluate:
//   cue eval ./examples/ci/ -e output.summary
//   cue eval ./examples/ci/ -e output.single_points_of_failure

package ci

import (
	"quicue.ca/patterns@v0"
)

validate: patterns.#ValidateGraph & {Input: _resources}
metrics:  patterns.#GraphMetrics & {Graph: infra}
spof:     patterns.#SinglePointsOfFailure & {Graph: infra}

output: {
	summary: {
		total_nodes: metrics.total_resources
		total_edges: metrics.total_edges
		max_depth:   metrics.max_depth
		root_count:  metrics.root_count
	}
	single_points_of_failure: spof
}
