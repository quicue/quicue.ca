// Ansible CLI actions — operational commands for ansible-playbook, ansible-vault, etc.
//
// These complement the existing generators (inventory, prometheus, alertmanager, grafana)
// with CLI action definitions for running Ansible operations.
//
// Usage:
//   import "quicue.ca/template/ansible/patterns"

package patterns

import "quicue.ca/vocab"

// #AnsibleCLIRegistry - Ansible CLI action definitions
#AnsibleCLIRegistry: {
	// ========== Inventory ==========

	inventory_list: vocab.#ActionDef & {
		name:             "List Inventory"
		description:      "Show parsed Ansible inventory hosts and groups"
		category:         "info"
		params: inventory_path: {from_field: "inventory_path"}
		command_template: "ansible-inventory -i {inventory_path} --list"
		idempotent:       true
	}

	inventory_graph: vocab.#ActionDef & {
		name:             "Inventory Graph"
		description:      "Show inventory host-group relationships as tree"
		category:         "info"
		params: inventory_path: {from_field: "inventory_path"}
		command_template: "ansible-inventory -i {inventory_path} --graph"
		idempotent:       true
	}

	// ========== Ad-hoc Commands ==========

	ping: vocab.#ActionDef & {
		name:             "Ansible Ping"
		description:      "Test Ansible connectivity to hosts"
		category:         "info"
		params: {
			inventory_path: {from_field: "inventory_path"}
			target:         {required: false, default: "all"}
		}
		command_template: "ansible -i {inventory_path} {target} -m ping"
		idempotent:       true
	}

	gather_facts: vocab.#ActionDef & {
		name:             "Gather Facts"
		description:      "Collect system facts from hosts"
		category:         "info"
		params: {
			inventory_path: {from_field: "inventory_path"}
			target:         {required: false, default: "all"}
		}
		command_template: "ansible -i {inventory_path} {target} -m setup"
		idempotent:       true
	}

	// ========== Playbook ==========

	playbook_run: vocab.#ActionDef & {
		name:             "Run Playbook"
		description:      "Execute an Ansible playbook"
		category:         "admin"
		params: {
			inventory_path: {from_field: "inventory_path"}
			playbook_path:  {from_field: "playbook_path"}
		}
		command_template: "ansible-playbook -i {inventory_path} {playbook_path}"
	}

	playbook_check: vocab.#ActionDef & {
		name:             "Check Playbook (dry run)"
		description:      "Dry-run playbook without making changes"
		category:         "info"
		params: {
			inventory_path: {from_field: "inventory_path"}
			playbook_path:  {from_field: "playbook_path"}
		}
		command_template: "ansible-playbook -i {inventory_path} {playbook_path} --check --diff"
		idempotent:       true
	}

	playbook_syntax: vocab.#ActionDef & {
		name:             "Syntax Check"
		description:      "Validate playbook syntax"
		category:         "info"
		params: playbook_path: {from_field: "playbook_path"}
		command_template: "ansible-playbook {playbook_path} --syntax-check"
		idempotent:       true
	}

	// ========== Vault ==========

	vault_encrypt: vocab.#ActionDef & {
		name:             "Vault Encrypt"
		description:      "Encrypt a file with Ansible Vault"
		category:         "admin"
		params: file_path: {from_field: "file_path"}
		command_template: "ansible-vault encrypt {file_path}"
	}

	vault_decrypt: vocab.#ActionDef & {
		name:             "Vault Decrypt"
		description:      "Decrypt a file with Ansible Vault"
		category:         "admin"
		params: file_path: {from_field: "file_path"}
		command_template: "ansible-vault decrypt {file_path}"
	}

	vault_view: vocab.#ActionDef & {
		name:             "Vault View"
		description:      "View encrypted file contents"
		category:         "info"
		params: file_path: {from_field: "file_path"}
		command_template: "ansible-vault view {file_path}"
		idempotent:       true
	}

	// Allow provider extensions
	...
}
