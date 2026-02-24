// Execution plan — unification of binding + ordering.
//
// Composes #BindCluster (resolved commands) with #InfraGraph and
// #DeploymentPlan (dependency-ordered layers) over the same resource set.
// CUE enforces that all three agree — the entire constraint set unifies
// or evaluation fails. No partial success.
//
// Usage:
//   deploy: patterns.#ExecutionPlan & {
//       resources: _myResources
//       providers: _myProviders
//   }
//   // deploy.plan.layers       — ordered layers with gates
//   // deploy.cluster.bound     — resources with resolved commands
//   // deploy.graph.topology    — computed depth, ancestors, roots, leaves

package patterns

#ExecutionPlan: {
	resources: _
	providers: {[string]: #ProviderDecl}

	// Composed definitions — same resources flow through all three
	cluster: #BindCluster & {
		"resources": resources
		"providers": providers
	}
	graph: #InfraGraph & {Input: resources}
	plan: #DeploymentPlan & {Graph: graph}

	// Optional category constraint — consumer narrows if desired
	category: string | *""
}
