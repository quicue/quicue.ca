// CLI Command Schema
//
// Defines command interfaces for infrastructure-as-graph operations.
// Follows the 3-layer pattern: Interface (vocab) -> Provider -> Instance
//
// Usage:
//   import "quicue.ca/vocab@v0"
//
//   // Provider implements command interface
//   #ProxmoxRun: vocab.#RunCommand & {
//       name: "run"
//       run:  "ssh \(HOST) 'qm/pct \(ACTION) \(TARGET)'"
//   }
//
// DESIGN PRINCIPLES:
// - Commands are declarative: they describe WHAT to do, not HOW
// - Providers implement commands with platform-specific execution
// - The CLI layer handles arg parsing, output formatting, confirmation
// - Commands can be composed into pipelines via output -> input

package vocab

// =============================================================================
// BASE COMMAND INTERFACE
// =============================================================================

// #Command - Base schema for all CLI commands
// Every command shares this core structure. Providers extend with specifics.
#Command: {
	// Command identity
	name:        string
	description: string
	category:    "analysis" | "operations" | "generation" | "lookup"

	// Input specification
	args: {
		// Required positional args
		positional?: [...#Arg]
		// Optional flags
		flags?: [string]: #Flag
	}

	// Output format - what the command produces
	output: {
		format: "text" | "json" | "yaml" | "table" | "graph"
		schema?: string // CUE schema reference for structured output
	}

	// Execution
	// Can be:
	// - Shell command: "ssh \(HOST) 'pct status \(ID)'"
	// - CUE expression: "patterns.#ImpactQuery & {Graph: _graph, Target: \(TARGET)}"
	// - Script path: "./scripts/deploy.sh \(ARGS)"
	run: string

	// Operational metadata (inherited from #Action patterns)
	timeout_seconds?:       int  // Max execution time (0 = no timeout)
	requires_confirmation?: bool // Prompt before executing?
	idempotent?:            bool // Safe to retry?
	destructive?:           bool // Modifies state permanently?

	// Allow extension
	...
}

// #Arg - Positional argument definition
#Arg: {
	name:        string
	description: string
	type:        "string" | "int" | "bool" | "resource" | "file" | "path"
	required:    bool | *true
	default?:    _
	validate?:   string // CUE expression for validation
}

// #Flag - Optional flag definition
#Flag: {
	short?:      string // e.g., "-v"
	description: string
	type:        "string" | "int" | "bool" | "list" | "resource" | "file" | "path"
	default?:    _
}

// =============================================================================
// ANALYSIS COMMANDS
// Query and analyze the infrastructure graph
// =============================================================================

// #ValidateCommand - Validate graph integrity
// Checks for missing deps, cycles, empty types, orphans
#ValidateCommand: #Command & {
	category: "analysis"

	args: {
		positional: [{
			name:        "path"
			description: "Path to CUE files to validate"
			type:        "path"
			required:    false
			default:     "."
		}]
		flags: {
			strict: {
				short:       "-s"
				description: "Fail on warnings (orphans, unused)"
				type:        "bool"
				default:     false
			}
			json: {
				short:       "-j"
				description: "Output as JSON"
				type:        "bool"
				default:     false
			}
		}
	}

	output: {
		format: "json"
		schema: "patterns.#ValidateGraph"
	}

	idempotent: true
}

// #ImpactCommand - What breaks if target fails
// Shows all resources that depend on target (transitively)
#ImpactCommand: #Command & {
	category: "analysis"

	args: {
		positional: [{
			name:        "target"
			description: "Resource name to analyze impact for"
			type:        "resource"
			required:    true
		}]
		flags: {
			depth: {
				short:       "-d"
				description: "Max depth to traverse (0 = unlimited)"
				type:        "int"
				default:     0
			}
			format: {
				short:       "-f"
				description: "Output format"
				type:        "string"
				default:     "tree"
			}
		}
	}

	output: {
		format: "json"
		schema: "patterns.#ImpactQuery"
	}

	idempotent: true
}

// #PlanCommand - Generate deployment/shutdown sequences
// Layer-by-layer ordering respecting dependencies
#PlanCommand: #Command & {
	category: "analysis"

	args: {
		positional: [{
			name:        "operation"
			description: "Operation type: deploy, shutdown, restart, rollback"
			type:        "string"
			required:    true
			validate:    "operation =~ \"^(deploy|shutdown|restart|rollback)$\""
		}]
		flags: {
			from_layer: {
				description: "Start from layer N (for rollback)"
				type:        "int"
				default:     0
			}
			target: {
				short:       "-t"
				description: "Target specific resources (comma-separated)"
				type:        "list"
			}
			dry_run: {
				short:       "-n"
				description: "Show plan without executing"
				type:        "bool"
				default:     true
			}
		}
	}

	output: {
		format: "json"
		schema: "patterns.#DeploymentPlan"
	}

	idempotent: true
}

// #RisksCommand - Find single points of failure
// Resources with dependents but no redundancy
#RisksCommand: #Command & {
	category: "analysis"

	args: {
		flags: {
			min_dependents: {
				description: "Minimum dependents to be considered risky"
				type:        "int"
				default:     1
			}
			by_type: {
				description: "Group risks by resource type"
				type:        "bool"
				default:     false
			}
		}
	}

	output: {
		format: "json"
		schema: "patterns.#SinglePointsOfFailure"
	}

	idempotent: true
}

// #CriticalityCommand - Rank resources by importance
// Sorted by dependent count (most critical first)
#CriticalityCommand: #Command & {
	category: "analysis"

	args: {
		flags: {
			top: {
				short:       "-n"
				description: "Show top N resources"
				type:        "int"
				default:     10
			}
			reverse: {
				short:       "-r"
				description: "Show least critical first"
				type:        "bool"
				default:     false
			}
		}
	}

	output: {
		format: "table"
		schema: "patterns.#CriticalityRank"
	}

	idempotent: true
}

// =============================================================================
// OPERATIONS COMMANDS
// Execute actions on resources
// =============================================================================

// #RunCommand - Execute an action on a resource
// Core command for invoking resource actions
#RunCommand: #Command & {
	category: "operations"

	args: {
		positional: [
			{
				name:        "resource"
				description: "Target resource name"
				type:        "resource"
				required:    true
			},
			{
				name:        "action"
				description: "Action to execute (e.g., status, start, ssh)"
				type:        "string"
				required:    true
			},
		]
		flags: {
			confirm: {
				short:       "-y"
				description: "Skip confirmation prompt"
				type:        "bool"
				default:     false
			}
			timeout: {
				description: "Timeout in seconds"
				type:        "int"
			}
			dry_run: {
				short:       "-n"
				description: "Print command without executing"
				type:        "bool"
				default:     false
			}
		}
	}

	output: {
		format: "text"
	}
}

// #BulkCommand - Bulk operations with filtering
// Execute action across multiple resources matching criteria
#BulkCommand: #Command & {
	category: "operations"

	args: {
		positional: [{
			name:        "action"
			description: "Action to execute on all matching resources"
			type:        "string"
			required:    true
		}]
		flags: {
			type: {
				short:       "-t"
				description: "Filter by @type (can be repeated)"
				type:        "list"
			}
			tag: {
				description: "Filter by tag (can be repeated)"
				type:        "list"
			}
			layer: {
				short:       "-l"
				description: "Filter by dependency layer"
				type:        "int"
			}
			parallel: {
				short:       "-p"
				description: "Max parallel executions"
				type:        "int"
				default:     1
			}
			confirm: {
				short:       "-y"
				description: "Skip confirmation prompt"
				type:        "bool"
				default:     false
			}
			dry_run: {
				short:       "-n"
				description: "Print commands without executing"
				type:        "bool"
				default:     false
			}
		}
	}

	output: {
		format: "table"
	}

	requires_confirmation: true
}

// #RunbookCommand - Generate operational runbook
// Combines blast radius + deployment plan for an operation
#RunbookCommand: #Command & {
	category: "operations"

	args: {
		positional: [
			{
				name:        "operation"
				description: "Operation type: maintenance, upgrade, replace"
				type:        "string"
				required:    true
			},
			{
				name:        "target"
				description: "Target resource(s)"
				type:        "resource"
				required:    true
			},
		]
		flags: {
			format: {
				short:       "-f"
				description: "Output format: markdown, json, yaml"
				type:        "string"
				default:     "markdown"
			}
			include_commands: {
				description: "Include actual commands in runbook"
				type:        "bool"
				default:     true
			}
		}
	}

	output: {
		format: "text"
	}

	idempotent: true
}

// #SimulateCommand - What-if analysis
// Simulate changes before applying them
#SimulateCommand: #Command & {
	category: "operations"

	args: {
		positional: [{
			name:        "scenario"
			description: "Scenario: failure, remove, add, move"
			type:        "string"
			required:    true
		}]
		flags: {
			target: {
				short:       "-t"
				description: "Target resource for scenario"
				type:        "resource"
			}
			show_graph: {
				description: "Show updated graph visualization"
				type:        "bool"
				default:     false
			}
		}
	}

	output: {
		format: "json"
		schema: "patterns.#BlastRadius"
	}

	idempotent: true
}

// =============================================================================
// GENERATION COMMANDS
// Generate configuration for external tools
// =============================================================================

// #GenerateCommand - Multi-projection generation
// Generate SSH config, Ansible inventory, Prometheus targets, etc.
#GenerateCommand: #Command & {
	category: "generation"

	args: {
		positional: [{
			name:        "projection"
			description: "Output type: ssh-config, ansible, prometheus, hosts, terraform"
			type:        "string"
			required:    true
		}]
		flags: {
			output: {
				short:       "-o"
				description: "Output file (- for stdout)"
				type:        "string"
				default:     "-"
			}
			filter_type: {
				short:       "-t"
				description: "Only include resources of type"
				type:        "list"
			}
			filter_tag: {
				description: "Only include resources with tag"
				type:        "list"
			}
			template: {
				description: "Custom template file"
				type:        "file"
			}
		}
	}

	output: {
		format: "text"
	}

	idempotent: true
}

// #ExportCommand - JSON graph export
// Export full graph for external consumption
#ExportCommand: #Command & {
	category: "generation"

	args: {
		flags: {
			output: {
				short:       "-o"
				description: "Output file (- for stdout)"
				type:        "string"
				default:     "-"
			}
			pretty: {
				description: "Pretty-print output"
				type:        "bool"
				default:     true
			}
			include_computed: {
				description: "Include computed fields (_depth, _ancestors)"
				type:        "bool"
				default:     true
			}
		}
	}

	output: {
		format: "json"
		schema: "patterns.#ExportGraph"
	}

	idempotent: true
}

// #JsonldCommand - JSON-LD export
// Export as linked data for semantic web integration
#JsonldCommand: #Command & {
	category: "generation"

	args: {
		flags: {
			context: {
				description: "JSON-LD context URL"
				type:        "string"
				default:     "https://quicue.ca/context/v0"
			}
			output: {
				short:       "-o"
				description: "Output file (- for stdout)"
				type:        "string"
				default:     "-"
			}
			frame: {
				description: "JSON-LD frame file for reshaping"
				type:        "file"
			}
		}
	}

	output: {
		format: "json"
	}

	idempotent: true
}

// =============================================================================
// LOOKUP COMMANDS
// Query infrastructure by various criteria
// =============================================================================

// #LookupCommand - Reverse queries
// Find resources by IP, port, owner, type, etc.
#LookupCommand: #Command & {
	category: "lookup"

	args: {
		positional: [
			{
				name:        "field"
				description: "Field to search: ip, host, type, tag, provides"
				type:        "string"
				required:    true
			},
			{
				name:        "value"
				description: "Value to search for"
				type:        "string"
				required:    true
			},
		]
		flags: {
			exact: {
				short:       "-e"
				description: "Exact match (default is substring)"
				type:        "bool"
				default:     false
			}
			show_deps: {
				description: "Include dependency info in output"
				type:        "bool"
				default:     false
			}
		}
	}

	output: {
		format: "table"
	}

	idempotent: true
}

// #DiffCommand - Compare environments
// Show differences between two graphs (e.g., staging vs prod)
#DiffCommand: #Command & {
	category: "lookup"

	args: {
		positional: [
			{
				name:        "source"
				description: "Source environment/path"
				type:        "path"
				required:    true
			},
			{
				name:        "target"
				description: "Target environment/path"
				type:        "path"
				required:    true
			},
		]
		flags: {
			ignore_computed: {
				description: "Ignore computed fields in diff"
				type:        "bool"
				default:     true
			}
			fields: {
				description: "Only diff these fields (comma-separated)"
				type:        "list"
			}
		}
	}

	output: {
		format: "text"
	}

	idempotent: true
}

// #DriftCommand - Live vs declared state
// Compare declared graph against live infrastructure
#DriftCommand: #Command & {
	category: "lookup"

	args: {
		flags: {
			check_only: {
				short:       "-c"
				description: "Exit 1 if drift detected (for CI)"
				type:        "bool"
				default:     false
			}
			parallel: {
				short:       "-p"
				description: "Parallel live checks"
				type:        "int"
				default:     5
			}
			timeout: {
				description: "Per-resource check timeout (seconds)"
				type:        "int"
				default:     10
			}
		}
	}

	output: {
		format: "json"
	}

	idempotent: true
}

// =============================================================================
// COMMAND INTERFACES - For providers to implement
// These define the minimal contract providers must fulfill
// =============================================================================

// #AnalysisCommands - Commands every provider should support
#AnalysisCommands: {
	validate:    #ValidateCommand
	impact:      #ImpactCommand
	plan:        #PlanCommand
	risks:       #RisksCommand
	criticality: #CriticalityCommand
	...
}

// #OperationsCommands - Execution commands
#OperationsCommands: {
	run:      #RunCommand
	bulk:     #BulkCommand
	runbook:  #RunbookCommand
	simulate: #SimulateCommand
	...
}

// #GenerationCommands - Output generation
#GenerationCommands: {
	generate: #GenerateCommand
	export:   #ExportCommand
	jsonld:   #JsonldCommand
	...
}

// #LookupCommands - Query operations
#LookupCommands: {
	lookup: #LookupCommand
	diff:   #DiffCommand
	drift:  #DriftCommand
	...
}

// #CLIProvider - Full CLI implementation
// Providers unify with this to declare their command implementations
#CLIProvider: {
	name:        string
	description: string

	// Command implementations grouped by category
	analysis:   #AnalysisCommands
	operations: #OperationsCommands
	generation: #GenerationCommands
	lookup:     #LookupCommands

	// Allow provider-specific commands
	...
}

// =============================================================================
// PROVIDER IMPLEMENTATION EXAMPLE
// Shows how a provider (e.g., Proxmox) implements commands
// =============================================================================

// Example: Proxmox provider run command implementation
// This shows the 3-layer pattern for CLI commands:
//
// #ProxmoxRunCommand: #RunCommand & {
//     name:        "run"
//     description: "Execute action on Proxmox resource"
//
//     // Provider maps generic args to platform-specific execution
//     run: """
//         # Resolve resource to Proxmox node + ID
//         NODE=\(RESOURCE.host)
//         TYPE=\(RESOURCE.container_id != _|_ ? "pct" : "qm")
//         ID=\(RESOURCE.container_id != _|_ ? RESOURCE.container_id : RESOURCE.vm_id)
//
//         # Execute action
//         ssh $NODE "$TYPE \(ACTION) $ID"
//         """
// }
//
// Instance usage:
//
// cli: #ProxmoxCLI & {
//     operations: run: #ProxmoxRunCommand
// }

// =============================================================================
// COMMAND REGISTRY
// Default implementations using CUE patterns
// =============================================================================

// #DefaultCommands - Reference implementations using patterns
// Template parameters use ${PARAM} syntax for CLI-time interpolation
#DefaultCommands: #CLIProvider & {
	name:        "default"
	description: "Default CLI using CUE patterns"

	analysis: {
		validate: #ValidateCommand & {
			name:        "validate"
			description: "Validate graph integrity (missing deps, cycles, empty types)"
			run:         "cue eval -e 'patterns.#ValidateGraph & {Input: resources}'"
		}

		impact: #ImpactCommand & {
			name:        "impact"
			description: "Show what breaks if target fails"
			run:         #"cue eval -e 'patterns.#ImpactQuery & {Graph: _graph, Target: "${TARGET}"}'"#
		}

		plan: #PlanCommand & {
			name:        "plan"
			description: "Generate deployment/shutdown sequence"
			run:         "cue eval -e 'patterns.#DeploymentPlan & {Graph: _graph}'"
		}

		risks: #RisksCommand & {
			name:        "risks"
			description: "Find single points of failure"
			run:         "cue eval -e 'patterns.#SinglePointsOfFailure & {Graph: _graph}'"
		}

		criticality: #CriticalityCommand & {
			name:        "criticality"
			description: "Rank resources by dependent count"
			run:         "cue eval -e 'patterns.#CriticalityRank & {Graph: _graph}'"
		}
	}

	operations: {
		run: #RunCommand & {
			name:        "run"
			description: "Execute action on resource"
			run:         #"eval "$(cue eval -e 'resources["${RESOURCE}"].actions.${ACTION}.command')""#
		}

		bulk: #BulkCommand & {
			name:        "bulk"
			description: "Execute action on multiple resources"
			run:         "# Bulk execution handled by CLI wrapper"
		}

		runbook: #RunbookCommand & {
			name:        "runbook"
			description: "Generate operational runbook for change"
			run:         #"cue eval -e 'patterns.#BlastRadius & {Graph: _graph, Target: "${TARGET}"}'"#
		}

		simulate: #SimulateCommand & {
			name:        "simulate"
			description: "What-if scenario analysis"
			run:         #"cue eval -e 'patterns.#BlastRadius & {Graph: _graph, Target: "${TARGET}"}'"#
		}
	}

	generation: {
		generate: #GenerateCommand & {
			name:        "generate"
			description: "Generate external tool configuration"
			run:         #"cue eval -e '_projections.${PROJECTION}' --out text"#
		}

		export: #ExportCommand & {
			name:        "export"
			description: "Export graph as JSON"
			run:         "cue eval -e 'patterns.#ExportGraph & {Graph: _graph}' --out json"
		}

		jsonld: #JsonldCommand & {
			name:        "jsonld"
			description: "Export as JSON-LD"
			run:         "cue eval -e '_jsonld' --out json"
		}
	}

	lookup: {
		lookup: #LookupCommand & {
			name:        "lookup"
			description: "Find resources by field value"
			run:         #"cue eval -e '[for n, r in resources if r.${FIELD} =~ "${VALUE}" {r}]'"#
		}

		diff: #DiffCommand & {
			name:        "diff"
			description: "Compare two environments"
			run:         #"diff <(cue eval ${SOURCE} -e resources) <(cue eval ${TARGET} -e resources)"#
		}

		drift: #DriftCommand & {
			name:        "drift"
			description: "Check live vs declared state"
			run:         "# Drift detection requires live probing - provider-specific"
		}
	}
}
