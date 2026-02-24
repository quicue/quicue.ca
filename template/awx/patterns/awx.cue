// AWX - Ansible automation controller via REST API / awx CLI
//
// Requires: awx CLI or curl, AWX_TOKEN set
//   pip install awxkit && awx login --conf.host https://awx.example.com
//
// Usage:
//   import "quicue.ca/template/awx/patterns"

package patterns

import "quicue.ca/vocab"

#AWXRegistry: {
	job_templates: vocab.#ActionDef & {
		name:        "job_templates"
		description: "List job templates"
		category:    "info"
		params: {}
		command_template: "awx job_templates list -f human"
		idempotent:       true
	}

	job_launch: vocab.#ActionDef & {
		name:        "job_launch"
		description: "Launch a job template"
		category:    "admin"
		params: template_id: {}
		command_template: "awx job_templates launch {template_id} --monitor"
	}

	job_status: vocab.#ActionDef & {
		name:        "job_status"
		description: "Check job execution status"
		category:    "monitor"
		params: job_id: {}
		command_template: "awx jobs get {job_id} -f human"
		idempotent:       true
	}

	inventories: vocab.#ActionDef & {
		name:        "inventories"
		description: "List inventories"
		category:    "info"
		params: {}
		command_template: "awx inventory list -f human"
		idempotent:       true
	}

	inventory_sync: vocab.#ActionDef & {
		name:        "inventory_sync"
		description: "Sync inventory source"
		category:    "admin"
		params: source_id: {}
		command_template: "awx inventory_sources update {source_id} --monitor"
	}

	projects: vocab.#ActionDef & {
		name:        "projects"
		description: "List projects"
		category:    "info"
		params: {}
		command_template: "awx projects list -f human"
		idempotent:       true
	}

	project_update: vocab.#ActionDef & {
		name:        "project_update"
		description: "Update project from SCM"
		category:    "admin"
		params: project_id: {}
		command_template: "awx projects update {project_id} --monitor"
	}

	credentials: vocab.#ActionDef & {
		name:        "credentials"
		description: "List credentials"
		category:    "info"
		params: {}
		command_template: "awx credentials list -f human"
		idempotent:       true
	}

	workflow_launch: vocab.#ActionDef & {
		name:        "workflow_launch"
		description: "Launch a workflow job template"
		category:    "admin"
		params: workflow_id: {}
		command_template: "awx workflow_job_templates launch {workflow_id} --monitor"
	}

	hosts: vocab.#ActionDef & {
		name:        "hosts"
		description: "List hosts across inventories"
		category:    "info"
		params: {}
		command_template: "awx hosts list -f human"
		idempotent:       true
	}

	...
}
