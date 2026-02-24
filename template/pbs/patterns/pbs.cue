// Proxmox Backup Server - Backup management via proxmox-backup-client
//
// Requires: proxmox-backup-client, PBS_REPOSITORY
//   export PBS_REPOSITORY=user@pam@pbs-host:store
//
// Usage:
//   import "quicue.ca/template/pbs/patterns"

package patterns

import "quicue.ca/vocab"

#PBSRegistry: {
	backup: vocab.#ActionDef & {
		name:        "backup"
		description: "Create backup of files or images"
		category:    "admin"
		params: backup_spec: {}
		command_template: "proxmox-backup-client backup {backup_spec}"
	}

	snapshot_list: vocab.#ActionDef & {
		name:        "snapshot_list"
		description: "List backup snapshots in datastore"
		category:    "info"
		params: {}
		command_template: "proxmox-backup-client snapshot list"
		idempotent:       true
	}

	restore: vocab.#ActionDef & {
		name:        "restore"
		description: "Restore from backup snapshot"
		category:    "admin"
		params: {
			snapshot: {}
			target_path: {}
		}
		command_template: "proxmox-backup-client restore {snapshot} {target_path}"
	}

	verify: vocab.#ActionDef & {
		name:        "verify"
		description: "Verify backup integrity"
		category:    "info"
		params: {}
		command_template: "proxmox-backup-client snapshot list --output-format json"
		idempotent:       true
	}

	catalog: vocab.#ActionDef & {
		name:        "catalog"
		description: "Browse backup catalog (file listing)"
		category:    "info"
		params: snapshot: {}
		command_template: "proxmox-backup-client catalog dump {snapshot}"
		idempotent:       true
	}

	gc: vocab.#ActionDef & {
		name:        "gc"
		description: "Garbage collect unused chunks"
		category:    "admin"
		params: {}
		command_template: "proxmox-backup-client garbage-collect"
	}

	key_create: vocab.#ActionDef & {
		name:        "key_create"
		description: "Create encryption key for backups"
		category:    "admin"
		params: key_path: {}
		command_template: "proxmox-backup-client key create {key_path}"
	}

	benchmark: vocab.#ActionDef & {
		name:        "benchmark"
		description: "Run backup performance benchmark"
		category:    "info"
		params: {}
		command_template: "proxmox-backup-client benchmark"
		idempotent:       true
	}

	...
}
