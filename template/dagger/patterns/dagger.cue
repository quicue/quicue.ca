// Dagger - CI/CD pipeline orchestration via Dagger CLI
//
// Dagger runs pipelines as containerized DAGs.
// Adapted from qc-eco/quicue-dagger vocab.
//
// Requires: dagger CLI
//
// Usage:
//   import "quicue.ca/template/dagger/patterns"

package patterns

import "quicue.ca/vocab"

#DaggerRegistry: {
	call: vocab.#ActionDef & {
		name:        "call"
		description: "Call a Dagger function"
		category:    "admin"
		params: {
			module_ref: {from_field: "dagger_module", required: false}
			function: {}
		}
		command_template: "dagger call -m {module_ref} {function}"
	}

	functions: vocab.#ActionDef & {
		name:        "functions"
		description: "List available functions in module"
		category:    "info"
		params: module_ref: {from_field: "dagger_module", required: false}
		command_template: "dagger functions -m {module_ref}"
		idempotent:       true
	}

	run: vocab.#ActionDef & {
		name:        "run"
		description: "Run a Dagger pipeline command"
		category:    "admin"
		params: command: {}
		command_template: "dagger run {command}"
	}

	shell: vocab.#ActionDef & {
		name:        "shell"
		description: "Open interactive shell in Dagger container"
		category:    "connect"
		params: module_ref: {from_field: "dagger_module", required: false}
		command_template: "dagger shell -m {module_ref}"
	}

	module_init: vocab.#ActionDef & {
		name:        "module_init"
		description: "Initialize a new Dagger module"
		category:    "admin"
		params: {
			module_name: {}
			sdk: {}
		}
		command_template: "dagger init --name {module_name} --sdk {sdk}"
	}

	module_install: vocab.#ActionDef & {
		name:        "module_install"
		description: "Install a Dagger module dependency"
		category:    "admin"
		params: module_ref: {}
		command_template: "dagger install {module_ref}"
	}

	module_develop: vocab.#ActionDef & {
		name:        "module_develop"
		description: "Setup module for local development"
		category:    "admin"
		params: {}
		command_template: "dagger develop"
	}

	query: vocab.#ActionDef & {
		name:        "query"
		description: "Execute raw GraphQL query against Dagger engine"
		category:    "info"
		params: graphql_query: {}
		command_template: "dagger query --doc '{graphql_query}'"
		idempotent:       true
	}

	version: vocab.#ActionDef & {
		name:        "version"
		description: "Show Dagger engine and CLI version"
		category:    "info"
		params: {}
		command_template: "dagger version"
		idempotent:       true
	}

	...
}
