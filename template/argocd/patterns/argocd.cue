// ArgoCD - GitOps continuous delivery via argocd CLI
//
// Requires: argocd CLI
//   argocd login argocd.example.com --sso
//
// Usage:
//   import "quicue.ca/template/argocd/patterns"

package patterns

import "quicue.ca/vocab"

#ArgoCDRegistry: {
	// ========== Applications ==========

	app_list: vocab.#ActionDef & {
		name:        "app_list"
		description: "List all ArgoCD applications"
		category:    "info"
		params: {}
		command_template: "argocd app list"
		idempotent:       true
	}

	app_get: vocab.#ActionDef & {
		name:        "app_get"
		description: "Get application details and sync status"
		category:    "info"
		params: app_name: {from_field: "app_name"}
		command_template: "argocd app get {app_name}"
		idempotent:       true
	}

	app_sync: vocab.#ActionDef & {
		name:        "app_sync"
		description: "Sync application to target revision"
		category:    "admin"
		params: app_name: {from_field: "app_name"}
		command_template: "argocd app sync {app_name}"
	}

	app_diff: vocab.#ActionDef & {
		name:        "app_diff"
		description: "Show diff between live and desired state"
		category:    "info"
		params: app_name: {from_field: "app_name"}
		command_template: "argocd app diff {app_name}"
		idempotent:       true
	}

	app_history: vocab.#ActionDef & {
		name:        "app_history"
		description: "Show deployment history"
		category:    "info"
		params: app_name: {from_field: "app_name"}
		command_template: "argocd app history {app_name}"
		idempotent:       true
	}

	app_rollback: vocab.#ActionDef & {
		name:        "app_rollback"
		description: "Rollback to previous deployment"
		category:    "admin"
		params: {
			app_name: {from_field: "app_name"}
			revision_id: {}
		}
		command_template: "argocd app rollback {app_name} {revision_id}"
		destructive:      true
	}

	app_create: vocab.#ActionDef & {
		name:        "app_create"
		description: "Create new ArgoCD application"
		category:    "admin"
		params: {
			app_name: {from_field: "app_name"}
			repo: {}
			path: {}
			dest_ns: {required: false}
		}
		command_template: "argocd app create {app_name} --repo {repo} --path {path} --dest-namespace {dest_ns} --dest-server https://kubernetes.default.svc"
	}

	app_delete: vocab.#ActionDef & {
		name:        "app_delete"
		description: "Delete ArgoCD application"
		category:    "admin"
		params: app_name: {from_field: "app_name"}
		command_template: "argocd app delete {app_name} --yes"
		destructive:      true
	}

	app_wait: vocab.#ActionDef & {
		name:        "app_wait"
		description: "Wait for application to reach synced/healthy state"
		category:    "monitor"
		params: app_name: {from_field: "app_name"}
		command_template: "argocd app wait {app_name} --health --sync"
		idempotent:       true
	}

	// ========== Projects ==========

	project_list: vocab.#ActionDef & {
		name:        "project_list"
		description: "List ArgoCD projects"
		category:    "info"
		params: {}
		command_template: "argocd proj list"
		idempotent:       true
	}

	project_get: vocab.#ActionDef & {
		name:        "project_get"
		description: "Get project details and access policies"
		category:    "info"
		params: project_name: {}
		command_template: "argocd proj get {project_name}"
		idempotent:       true
	}

	// ========== Repos ==========

	repo_list: vocab.#ActionDef & {
		name:        "repo_list"
		description: "List registered git repositories"
		category:    "info"
		params: {}
		command_template: "argocd repo list"
		idempotent:       true
	}

	repo_add: vocab.#ActionDef & {
		name:        "repo_add"
		description: "Register git repository with ArgoCD"
		category:    "admin"
		params: repo_url: {}
		command_template: "argocd repo add {repo_url}"
	}

	// ========== Cluster ==========

	cluster_list: vocab.#ActionDef & {
		name:        "cluster_list"
		description: "List registered clusters"
		category:    "info"
		params: {}
		command_template: "argocd cluster list"
		idempotent:       true
	}

	...
}
