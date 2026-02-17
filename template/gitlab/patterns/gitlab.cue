// GitLab - Project and CI/CD management via glab CLI and API
//
// Requires: glab CLI or curl, GITLAB_TOKEN
//   glab auth login --hostname git.example.com
//
// Usage:
//   import "quicue.ca/template/gitlab/patterns"

package patterns

import "quicue.ca/vocab"

#GitLabRegistry: {
	// ========== Project ==========

	project_list: vocab.#ActionDef & {
		name:             "project_list"
		description:      "List projects"
		category:         "info"
		params: {}
		command_template: "glab project list"
		idempotent:       true
	}

	project_view: vocab.#ActionDef & {
		name:             "project_view"
		description:      "View project details"
		category:         "info"
		params: project: {from_field: "project_path"}
		command_template: "glab project view {project}"
		idempotent:       true
	}

	// ========== Merge Requests ==========

	mr_list: vocab.#ActionDef & {
		name:             "mr_list"
		description:      "List merge requests"
		category:         "info"
		params: project: {from_field: "project_path", required: false}
		command_template: "glab mr list -R {project}"
		idempotent:       true
	}

	mr_create: vocab.#ActionDef & {
		name:             "mr_create"
		description:      "Create merge request"
		category:         "admin"
		params: {
			title:         {}
			source_branch: {}
			target_branch: {required: false}
		}
		command_template: "glab mr create --title '{title}' --source-branch {source_branch} --target-branch {target_branch} --yes"
	}

	mr_merge: vocab.#ActionDef & {
		name:             "mr_merge"
		description:      "Merge a merge request"
		category:         "admin"
		params: mr_id: {}
		command_template: "glab mr merge {mr_id} --yes"
	}

	mr_approve: vocab.#ActionDef & {
		name:             "mr_approve"
		description:      "Approve a merge request"
		category:         "admin"
		params: mr_id: {}
		command_template: "glab mr approve {mr_id}"
	}

	// ========== CI/CD ==========

	pipeline_list: vocab.#ActionDef & {
		name:             "pipeline_list"
		description:      "List recent pipelines"
		category:         "info"
		params: project: {from_field: "project_path", required: false}
		command_template: "glab ci list -R {project}"
		idempotent:       true
	}

	pipeline_run: vocab.#ActionDef & {
		name:             "pipeline_run"
		description:      "Trigger pipeline on branch"
		category:         "admin"
		params: branch: {from_field: "branch", required: false}
		command_template: "glab ci run --branch {branch}"
	}

	pipeline_status: vocab.#ActionDef & {
		name:             "pipeline_status"
		description:      "Show pipeline status and jobs"
		category:         "monitor"
		params: {}
		command_template: "glab ci status"
		idempotent:       true
	}

	job_log: vocab.#ActionDef & {
		name:             "job_log"
		description:      "View CI job log output"
		category:         "monitor"
		params: job_id: {}
		command_template: "glab ci trace {job_id}"
		idempotent:       true
	}

	// ========== Issues ==========

	issue_list: vocab.#ActionDef & {
		name:             "issue_list"
		description:      "List project issues"
		category:         "info"
		params: project: {from_field: "project_path", required: false}
		command_template: "glab issue list -R {project}"
		idempotent:       true
	}

	issue_create: vocab.#ActionDef & {
		name:             "issue_create"
		description:      "Create new issue"
		category:         "admin"
		params: {
			title:       {}
			description: {required: false}
		}
		command_template: "glab issue create --title '{title}' --description '{description}'"
	}

	// ========== Registry ==========

	registry_list: vocab.#ActionDef & {
		name:             "registry_list"
		description:      "List container registry images"
		category:         "info"
		params: project: {from_field: "project_path", required: false}
		command_template: "glab registry list -R {project}"
		idempotent:       true
	}

	// ========== Variables ==========

	variable_list: vocab.#ActionDef & {
		name:             "variable_list"
		description:      "List CI/CD variables"
		category:         "info"
		params: project: {from_field: "project_path", required: false}
		command_template: "glab variable list -R {project}"
		idempotent:       true
	}

	...
}
