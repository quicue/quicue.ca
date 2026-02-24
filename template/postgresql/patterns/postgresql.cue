// PostgreSQL - Database administration via psql and pg_* utilities
//
// Requires: psql, pg_dump, pg_restore
//   PGHOST, PGUSER, PGDATABASE (or connection params)
//
// Usage:
//   import "quicue.ca/template/postgresql/patterns"

package patterns

import "quicue.ca/vocab"

#PostgreSQLRegistry: {
	query: vocab.#ActionDef & {
		name:        "query"
		description: "Execute SQL query"
		category:    "info"
		params: {
			db_host: {from_field: "db_host"}
			db_name: {from_field: "db_name"}
			sql: {}
		}
		command_template: "psql -h {db_host} -d {db_name} -c '{sql}'"
	}

	db_list: vocab.#ActionDef & {
		name:        "db_list"
		description: "List all databases"
		category:    "info"
		params: db_host: {from_field: "db_host"}
		command_template: "psql -h {db_host} -l"
		idempotent:       true
	}

	db_size: vocab.#ActionDef & {
		name:        "db_size"
		description: "Show database sizes"
		category:    "info"
		params: db_host: {from_field: "db_host"}
		command_template: "psql -h {db_host} -c \"SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database ORDER BY pg_database_size(datname) DESC\""
		idempotent:       true
	}

	connection_count: vocab.#ActionDef & {
		name:        "connection_count"
		description: "Active connection count by database"
		category:    "monitor"
		params: db_host: {from_field: "db_host"}
		command_template: "psql -h {db_host} -c \"SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname\""
		idempotent:       true
	}

	active_queries: vocab.#ActionDef & {
		name:        "active_queries"
		description: "Show running queries with duration"
		category:    "monitor"
		params: db_host: {from_field: "db_host"}
		command_template: "psql -h {db_host} -c \"SELECT pid, now()-pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE state='active' ORDER BY duration DESC\""
		idempotent:       true
	}

	locks: vocab.#ActionDef & {
		name:        "locks"
		description: "Show blocking locks"
		category:    "monitor"
		params: db_host: {from_field: "db_host"}
		command_template: "psql -h {db_host} -c \"SELECT blocked_locks.pid AS blocked_pid, blocking_locks.pid AS blocking_pid, blocked_activity.query AS blocked_query FROM pg_catalog.pg_locks blocked_locks JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype=blocked_locks.locktype JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid=blocked_locks.pid WHERE NOT blocked_locks.granted\""
		idempotent:       true
	}

	replication_status: vocab.#ActionDef & {
		name:        "replication_status"
		description: "Show streaming replication status"
		category:    "monitor"
		params: db_host: {from_field: "db_host"}
		command_template: "psql -h {db_host} -c \"SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication\""
		idempotent:       true
	}

	vacuum: vocab.#ActionDef & {
		name:        "vacuum"
		description: "Run VACUUM ANALYZE on database"
		category:    "admin"
		params: {
			db_host: {from_field: "db_host"}
			db_name: {from_field: "db_name"}
		}
		command_template: "psql -h {db_host} -d {db_name} -c 'VACUUM ANALYZE'"
	}

	pg_dump: vocab.#ActionDef & {
		name:        "pg_dump"
		description: "Dump database to file"
		category:    "admin"
		params: {
			db_host: {from_field: "db_host"}
			db_name: {from_field: "db_name"}
			dump_path: {}
		}
		command_template: "pg_dump -h {db_host} -Fc {db_name} -f {dump_path}"
	}

	pg_restore: vocab.#ActionDef & {
		name:        "pg_restore"
		description: "Restore database from dump"
		category:    "admin"
		params: {
			db_host: {from_field: "db_host"}
			db_name: {from_field: "db_name"}
			dump_path: {}
		}
		command_template: "pg_restore -h {db_host} -d {db_name} {dump_path}"
		destructive:      true
	}

	...
}
