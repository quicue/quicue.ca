// HashiCorp Vault - Secrets management via vault CLI
//
// Requires: vault CLI, VAULT_ADDR, VAULT_TOKEN
//
// Usage:
//   import "quicue.ca/template/vault/patterns"

package patterns

import "quicue.ca/vocab"

#VaultRegistry: {
	status: vocab.#ActionDef & {
		name:        "status"
		description: "Vault server seal status and cluster info"
		category:    "info"
		params: {}
		command_template: "vault status"
		idempotent:       true
	}

	kv_get: vocab.#ActionDef & {
		name:        "kv_get"
		description: "Read secret from KV store"
		category:    "info"
		params: secret_path: {from_field: "secret_path"}
		command_template: "vault kv get {secret_path}"
		idempotent:       true
	}

	kv_put: vocab.#ActionDef & {
		name:        "kv_put"
		description: "Write secret to KV store"
		category:    "admin"
		params: {
			secret_path: {from_field: "secret_path"}
			kv_data: {}
		}
		command_template: "vault kv put {secret_path} {kv_data}"
	}

	kv_list: vocab.#ActionDef & {
		name:        "kv_list"
		description: "List secrets at path"
		category:    "info"
		params: secret_path: {from_field: "secret_path"}
		command_template: "vault kv list {secret_path}"
		idempotent:       true
	}

	kv_delete: vocab.#ActionDef & {
		name:        "kv_delete"
		description: "Delete secret from KV store"
		category:    "admin"
		params: secret_path: {from_field: "secret_path"}
		command_template: "vault kv delete {secret_path}"
		destructive:      true
	}

	secret_engines: vocab.#ActionDef & {
		name:        "secret_engines"
		description: "List enabled secrets engines"
		category:    "info"
		params: {}
		command_template: "vault secrets list -format=table"
		idempotent:       true
	}

	auth_methods: vocab.#ActionDef & {
		name:        "auth_methods"
		description: "List enabled auth methods"
		category:    "info"
		params: {}
		command_template: "vault auth list -format=table"
		idempotent:       true
	}

	policy_list: vocab.#ActionDef & {
		name:        "policy_list"
		description: "List all policies"
		category:    "info"
		params: {}
		command_template: "vault policy list"
		idempotent:       true
	}

	policy_read: vocab.#ActionDef & {
		name:        "policy_read"
		description: "Read policy contents"
		category:    "info"
		params: policy_name: {}
		command_template: "vault policy read {policy_name}"
		idempotent:       true
	}

	token_create: vocab.#ActionDef & {
		name:        "token_create"
		description: "Create a new token with policy"
		category:    "admin"
		params: policy_name: {}
		command_template: "vault token create -policy={policy_name}"
	}

	token_lookup: vocab.#ActionDef & {
		name:        "token_lookup"
		description: "Look up current token info"
		category:    "info"
		params: {}
		command_template: "vault token lookup"
		idempotent:       true
	}

	audit_list: vocab.#ActionDef & {
		name:        "audit_list"
		description: "List enabled audit devices"
		category:    "info"
		params: {}
		command_template: "vault audit list"
		idempotent:       true
	}

	pki_issue: vocab.#ActionDef & {
		name:        "pki_issue"
		description: "Issue TLS certificate from PKI engine"
		category:    "admin"
		params: {
			pki_role: {}
			common_name: {}
		}
		command_template: "vault write pki/issue/{pki_role} common_name={common_name}"
	}

	...
}
