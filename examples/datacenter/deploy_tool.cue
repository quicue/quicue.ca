// CUE cmd definitions for the datacenter execution plan.
//
// Consumes .script and .ops projections from patterns/projections.cue.
// The tool file is a thin declarative layer — it unifies with the execution
// plan, it does not re-derive anything. The materializer (projections.cue)
// computes; this file wires computed output to tool/ tasks.
//
// Usage:
//   cue cmd deploy-dry ./examples/datacenter/     # show plan summary
//   cue cmd deploy-script ./examples/datacenter/  # generate bash script
//   cue cmd deploy ./examples/datacenter/         # generate and run script

package main

import (
	"strings"
	"tool/cli"
	"tool/file"
	"tool/exec"
)

command: "deploy-dry": {
	print: cli.Print & {
		text: strings.Join([
			"=== Deployment Plan ===",
			"Layers:      \(execution.plan.summary.total_layers)",
			"Resources:   \(execution.plan.summary.total_resources)",
			"Gates:       \(execution.plan.summary.gates_required)",
			"Tasks:       \(execution.ops.stats.total_tasks)",
			"Destructive: \(execution.ops.stats.destructive_count)",
			"",
			for l in execution.plan.layers {
				"Layer \(l.layer): \(strings.Join(l.resources, ", "))"
			},
			"",
			"Run 'cue cmd deploy-script' to generate .deploy.sh",
			"Run 'cue cmd deploy' to generate and execute",
		], "\n")
	}
}

command: "deploy-script": {
	generate: file.Create & {
		filename: ".deploy.sh"
		contents: execution.script
	}
	print: cli.Print & {
		$after: generate
		text:   "Generated: .deploy.sh (\(execution.ops.stats.total_tasks) tasks across \(execution.plan.summary.total_layers) layers)\nRun: bash .deploy.sh"
	}
}

command: deploy: {
	generate: file.Create & {
		filename: ".deploy.sh"
		contents: execution.script
	}
	run: exec.Run & {
		$after: generate
		cmd: ["bash", ".deploy.sh"]
	}
}
