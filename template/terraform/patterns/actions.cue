// Terraform CLI actions — operational commands for terraform plan, apply, state, etc.
//
// These complement the existing generators (proxmox, kubevirt JSON output)
// with CLI action definitions for running Terraform operations.
//
// Usage:
//   import "quicue.ca/template/terraform/patterns"

package patterns

import "quicue.ca/vocab"

// #TerraformCLIRegistry - Terraform CLI action definitions
#TerraformCLIRegistry: {
	// ========== Core Workflow ==========

	init: vocab.#ActionDef & {
		name:        "Init"
		description: "Initialize Terraform working directory"
		category:    "admin"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "terraform -chdir={tf_dir} init"
	}

	plan: vocab.#ActionDef & {
		name:        "Plan"
		description: "Show execution plan for infrastructure changes"
		category:    "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "terraform -chdir={tf_dir} plan"
		idempotent:       true
	}

	apply: vocab.#ActionDef & {
		name:        "Apply"
		description: "Apply planned infrastructure changes"
		category:    "admin"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "terraform -chdir={tf_dir} apply -auto-approve"
		destructive:      true
	}

	destroy: vocab.#ActionDef & {
		name:        "Destroy"
		description: "Destroy all managed infrastructure"
		category:    "admin"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "terraform -chdir={tf_dir} destroy -auto-approve"
		destructive:      true
	}

	// ========== State Management ==========

	state_list: vocab.#ActionDef & {
		name:        "State List"
		description: "List resources in Terraform state"
		category:    "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "terraform -chdir={tf_dir} state list"
		idempotent:       true
	}

	state_show: vocab.#ActionDef & {
		name:        "State Show"
		description: "Show attributes of a single resource in state"
		category:    "info"
		params: {
			tf_dir: {from_field: "tf_dir"}
			resource: {}
		}
		command_template: "terraform -chdir={tf_dir} state show {resource}"
		idempotent:       true
	}

	// ========== Workspace Management ==========

	workspace_list: vocab.#ActionDef & {
		name:        "List Workspaces"
		description: "List Terraform workspaces"
		category:    "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "terraform -chdir={tf_dir} workspace list"
		idempotent:       true
	}

	workspace_select: vocab.#ActionDef & {
		name:        "Select Workspace"
		description: "Switch to a different workspace"
		category:    "admin"
		params: {
			tf_dir: {from_field: "tf_dir"}
			workspace: {}
		}
		command_template: "terraform -chdir={tf_dir} workspace select {workspace}"
	}

	// ========== Inspection ==========

	output: vocab.#ActionDef & {
		name:        "Show Outputs"
		description: "Display Terraform output values"
		category:    "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "terraform -chdir={tf_dir} output"
		idempotent:       true
	}

	providers: vocab.#ActionDef & {
		name:        "List Providers"
		description: "Show required and installed providers"
		category:    "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "terraform -chdir={tf_dir} providers"
		idempotent:       true
	}

	validate: vocab.#ActionDef & {
		name:        "Validate"
		description: "Validate Terraform configuration syntax"
		category:    "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "terraform -chdir={tf_dir} validate"
		idempotent:       true
	}

	fmt_check: vocab.#ActionDef & {
		name:        "Format Check"
		description: "Check if files are properly formatted"
		category:    "info"
		params: tf_dir: {from_field: "tf_dir"}
		command_template: "terraform -chdir={tf_dir} fmt -check"
		idempotent:       true
	}

	// Allow provider extensions
	...
}
