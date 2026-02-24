// Keycloak - Identity and access management via kcadm CLI
//
// Requires: kcadm.sh (Keycloak admin CLI)
//   kcadm.sh config credentials --server {server_url} --realm master --user admin --password admin
//
// Usage:
//   import "quicue.ca/template/keycloak/patterns"

package patterns

import "quicue.ca/vocab"

#KeycloakRegistry: {
	get_realms: vocab.#ActionDef & {
		name:        "get_realms"
		description: "List all realms"
		category:    "info"
		params: server_url: {from_field: "keycloak_url"}
		command_template: "kcadm.sh get realms --server {server_url}"
		idempotent:       true
	}

	create_realm: vocab.#ActionDef & {
		name:        "create_realm"
		description: "Create a new realm"
		category:    "admin"
		params: {
			server_url: {from_field: "keycloak_url"}
			realm_name: {}
		}
		command_template: "kcadm.sh create realms -s realm={realm_name} -s enabled=true --server {server_url}"
	}

	get_users: vocab.#ActionDef & {
		name:        "get_users"
		description: "List users in realm"
		category:    "info"
		params: {
			server_url: {from_field: "keycloak_url"}
			realm: {from_field: "realm"}
		}
		command_template: "kcadm.sh get users -r {realm} --server {server_url}"
		idempotent:       true
	}

	create_user: vocab.#ActionDef & {
		name:        "create_user"
		description: "Create user in realm"
		category:    "admin"
		params: {
			server_url: {from_field: "keycloak_url"}
			realm: {from_field: "realm"}
			username: {}
		}
		command_template: "kcadm.sh create users -r {realm} -s username={username} -s enabled=true --server {server_url}"
	}

	reset_password: vocab.#ActionDef & {
		name:        "reset_password"
		description: "Reset user password"
		category:    "admin"
		params: {
			server_url: {from_field: "keycloak_url"}
			realm: {from_field: "realm"}
			user_id: {}
		}
		command_template: "kcadm.sh set-password -r {realm} --userid {user_id} --new-password changeme --temporary --server {server_url}"
	}

	get_clients: vocab.#ActionDef & {
		name:        "get_clients"
		description: "List clients (service providers) in realm"
		category:    "info"
		params: {
			server_url: {from_field: "keycloak_url"}
			realm: {from_field: "realm"}
		}
		command_template: "kcadm.sh get clients -r {realm} --server {server_url}"
		idempotent:       true
	}

	get_client_secret: vocab.#ActionDef & {
		name:        "get_client_secret"
		description: "Get client secret for service account"
		category:    "info"
		params: {
			server_url: {from_field: "keycloak_url"}
			realm: {from_field: "realm"}
			client_id: {}
		}
		command_template: "kcadm.sh get clients/{client_id}/client-secret -r {realm} --server {server_url}"
	}

	get_roles: vocab.#ActionDef & {
		name:        "get_roles"
		description: "List realm roles"
		category:    "info"
		params: {
			server_url: {from_field: "keycloak_url"}
			realm: {from_field: "realm"}
		}
		command_template: "kcadm.sh get roles -r {realm} --server {server_url}"
		idempotent:       true
	}

	get_sessions: vocab.#ActionDef & {
		name:        "get_sessions"
		description: "List active user sessions in realm"
		category:    "monitor"
		params: {
			server_url: {from_field: "keycloak_url"}
			realm: {from_field: "realm"}
		}
		command_template: "kcadm.sh get client-session-stats -r {realm} --server {server_url}"
		idempotent:       true
	}

	get_idps: vocab.#ActionDef & {
		name:        "get_idps"
		description: "List federated identity providers"
		category:    "info"
		params: {
			server_url: {from_field: "keycloak_url"}
			realm: {from_field: "realm"}
		}
		command_template: "kcadm.sh get identity-provider/instances -r {realm} --server {server_url}"
		idempotent:       true
	}

	export_realm: vocab.#ActionDef & {
		name:        "export_realm"
		description: "Export realm configuration"
		category:    "info"
		params: {
			server_url: {from_field: "keycloak_url"}
			realm: {from_field: "realm"}
		}
		command_template: "kcadm.sh get realms/{realm} --server {server_url}"
		idempotent:       true
	}

	...
}
