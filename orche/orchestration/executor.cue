// Executor - Real deployment execution via CUE tool/exec
// Run with: cue cmd deploy ./infra/site-main.cue
package orchestration

import (
	"tool/exec"
	"tool/cli"
	"strings"

	"quicue.ca/patterns"
)

// #ExecutionStep - Single step in deployment
#ExecutionStep: {
	id:          string
	resource:    string
	action:      string
	command:     string
	layer:       int
	description: string | *""

	// Execution metadata
	idempotent:  bool | *false
	destructive: bool | *false
	timeout:     int | *300 // seconds
}

// #ExecutionPlan - Ordered list of steps grouped by layer
#ExecutionPlan: {
	name: string
	layers: [...{
		layer: int
		resources: [...string]
		steps: [...#ExecutionStep]
	}]

	// Flattened step list for execution
	all_steps: [...#ExecutionStep]
	all_steps: [
		for l in layers
		for s in l.steps {s},
	]

	// Summary
	summary: {
		total_layers: len(layers)
		total_steps:  len(all_steps)
	}
}

// =============================================================================
// DEPLOY COMMAND - Execute deployment plan layer by layer
// =============================================================================
command: deploy: {
	// Import plan from the site definition
	$id: "deploy"

	// Pre-flight check
	preflight: cli.Print & {
		text: """
			=== DEPLOYMENT STARTING ===
			Executing deployment plan...
			"""
	}

	// Execute each step
	// Note: In real usage, _plan would come from the site definition
	// This shows the pattern; actual wiring happens in infra/*.cue
}

// =============================================================================
// DEPLOY_DRY COMMAND - Show what would be executed
// =============================================================================
command: deploy_dry: {
	$id: "deploy_dry"

	show: cli.Print & {
		text: """
			=== DRY RUN: Deployment Plan ===

			This would execute the deployment plan.
			Run 'cue cmd deploy' to execute for real.
			"""
	}
}

// =============================================================================
// STATUS COMMAND - Check status of all resources
// =============================================================================
command: status: {
	$id: "status"

	header: cli.Print & {
		text: "=== RESOURCE STATUS ==="
	}
}

// =============================================================================
// DESTROY COMMAND - Tear down resources
// =============================================================================
command: destroy: {
	$id: "destroy"

	warning: cli.Print & {
		text: """
			=== DESTROY WARNING ===
			This will remove all resources.
			"""
	}
}

// =============================================================================
// #DependencyGraph - Compute execution order from dependency analysis
// =============================================================================
// Delegates to patterns.#InfraGraph for recursive depth computation.
// Supports arbitrary depth (no hardcoded layer limit).
#DependencyGraph: {
	resources: [string]: {
		name: string
		depends_on: {[string]: true}
		actions?: [string]: {command: string, ...}
		...
	}

	_graph: patterns.#InfraGraph & {Input: resources}
	_plan: patterns.#DeploymentPlan & {Graph: _graph}

	// Execution order: resources sorted by dependency layer
	execution_order: [
		for l in _plan.layers
		for rname in l.resources {rname},
	]
}

// =============================================================================
// Helper: Generate deployment steps from resources
// =============================================================================
#GenerateDeploySteps: {
	Resources: [string]: {
		name: string
		depends_on: {[string]: true}
		actions: [string]: {command: string, ...}
		...
	}

	_graph: patterns.#InfraGraph & {Input: Resources}

	steps: {
		for rname, r in Resources {
			"\(rname)_create": #ExecutionStep & {
				id:       "\(rname)_create"
				resource: rname
				action:   "create"
				command:  r.actions.create.command
				layer:    _graph.resources[rname]._depth
			}
		}
	}
}

// =============================================================================
// Deploy with layer-by-layer execution
// =============================================================================
#LayeredDeploy: {
	Plan: #ExecutionPlan

	// Generate exec.Run for each layer
	execution: {
		for lidx, layer in Plan.layers {
			"layer_\(lidx)": {
				// Print layer header
				header: cli.Print & {
					text: "\n=== Layer \(lidx): \(strings.Join(layer.resources, ", ")) ==="
				}

				// Execute each step in the layer (can run in parallel within layer)
				for step in layer.steps {
					"exec_\(step.id)": exec.Run & {
						cmd: ["bash", "-c", step.command]
						stdout: string
						stderr: string
					}
				}

				// Health check after layer completes
				healthcheck: cli.Print & {
					text: "Layer \(lidx) complete. Checking health..."
				}
			}
		}
	}
}
