// OpenTofu - Infrastructure as code via tofu CLI (Terraform fork)
//
// Requires: tofu CLI installed
//
// Usage:
//   import "quicue.ca/template/opentofu/patterns"

package patterns

import "quicue.ca/vocab"

#OpenTofuRegistry: {
	init: vocab.#ActionDef & {
		name:             "init"
		description:      "Initialize working directory"
		category:         "admin"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "tofu -chdir={tf_dir} init"
	}

	plan: vocab.#ActionDef & {
		name:             "plan"
		description:      "Show execution plan"
		category:         "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "tofu -chdir={tf_dir} plan"
		idempotent:       true
	}

	apply: vocab.#ActionDef & {
		name:             "apply"
		description:      "Apply infrastructure changes"
		category:         "admin"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "tofu -chdir={tf_dir} apply -auto-approve"
		destructive:      true
	}

	destroy: vocab.#ActionDef & {
		name:             "destroy"
		description:      "Destroy all managed infrastructure"
		category:         "admin"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "tofu -chdir={tf_dir} destroy -auto-approve"
		destructive:      true
	}

	state_list: vocab.#ActionDef & {
		name:             "state_list"
		description:      "List resources in state"
		category:         "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "tofu -chdir={tf_dir} state list"
		idempotent:       true
	}

	state_show: vocab.#ActionDef & {
		name:             "state_show"
		description:      "Show resource attributes in state"
		category:         "info"
		params: {
			tf_dir:   {from_field: "tf_dir"}
			resource: {}
		}
		command_template: "tofu -chdir={tf_dir} state show {resource}"
		idempotent:       true
	}

	workspace_list: vocab.#ActionDef & {
		name:             "workspace_list"
		description:      "List workspaces"
		category:         "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "tofu -chdir={tf_dir} workspace list"
		idempotent:       true
	}

	output: vocab.#ActionDef & {
		name:             "output"
		description:      "Display output values"
		category:         "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "tofu -chdir={tf_dir} output"
		idempotent:       true
	}

	validate: vocab.#ActionDef & {
		name:             "validate"
		description:      "Validate configuration syntax"
		category:         "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "tofu -chdir={tf_dir} validate"
		idempotent:       true
	}

	providers: vocab.#ActionDef & {
		name:             "providers"
		description:      "Show required and installed providers"
		category:         "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "tofu -chdir={tf_dir} providers"
		idempotent:       true
	}

	...
}
