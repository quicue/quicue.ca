// Restic - Deduplicating backup via restic CLI
//
// Requires: restic, RESTIC_REPOSITORY, RESTIC_PASSWORD
//
// Usage:
//   import "quicue.ca/template/restic/patterns"

package patterns

import "quicue.ca/vocab"

#ResticRegistry: {
	init: vocab.#ActionDef & {
		name:             "init"
		description:      "Initialize backup repository"
		category:         "admin"
		params: {}
		command_template: "restic init"
	}

	backup: vocab.#ActionDef & {
		name:             "backup"
		description:      "Create backup of paths"
		category:         "admin"
		params: backup_paths: {from_field: "backup_paths"}
		command_template: "restic backup {backup_paths}"
	}

	snapshots: vocab.#ActionDef & {
		name:             "snapshots"
		description:      "List backup snapshots"
		category:         "info"
		params: {}
		command_template: "restic snapshots"
		idempotent:       true
	}

	restore: vocab.#ActionDef & {
		name:             "restore"
		description:      "Restore snapshot to target path"
		category:         "admin"
		params: {
			snapshot_id: {}
			target_path: {}
		}
		command_template: "restic restore {snapshot_id} --target {target_path}"
	}

	forget: vocab.#ActionDef & {
		name:             "forget"
		description:      "Remove snapshots by retention policy"
		category:         "admin"
		params: {}
		command_template: "restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune"
		destructive:      true
	}

	check: vocab.#ActionDef & {
		name:             "check"
		description:      "Verify repository integrity"
		category:         "info"
		params: {}
		command_template: "restic check"
		idempotent:       true
	}

	stats: vocab.#ActionDef & {
		name:             "stats"
		description:      "Show repository statistics"
		category:         "info"
		params: {}
		command_template: "restic stats"
		idempotent:       true
	}

	diff: vocab.#ActionDef & {
		name:             "diff"
		description:      "Show differences between two snapshots"
		category:         "info"
		params: {
			snapshot_a: {}
			snapshot_b: {}
		}
		command_template: "restic diff {snapshot_a} {snapshot_b}"
		idempotent:       true
	}

	mount: vocab.#ActionDef & {
		name:             "mount"
		description:      "Mount repository as FUSE filesystem"
		category:         "connect"
		params: mount_path: {}
		command_template: "restic mount {mount_path}"
	}

	...
}
