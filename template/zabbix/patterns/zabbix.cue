// Zabbix - Enterprise monitoring via Zabbix API
//
// Requires: curl, Zabbix API URL and auth token
//   Token: POST api_jsonrpc.php with user.login
//
// Usage:
//   import "quicue.ca/template/zabbix/patterns"

package patterns

import "quicue.ca/vocab"

#ZabbixRegistry: {
	host_list: vocab.#ActionDef & {
		name:        "host_list"
		description: "List monitored hosts"
		category:    "info"
		params: {
			api_url: {from_field: "zabbix_url"}
			api_token: {from_field: "zabbix_token"}
		}
		command_template: "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"host.get\",\"params\":{\"output\":[\"hostid\",\"host\",\"status\"]},\"auth\":\"{api_token}\",\"id\":1}' {api_url}/api_jsonrpc.php"
		idempotent:       true
	}

	host_get: vocab.#ActionDef & {
		name:        "host_get"
		description: "Get detailed host info"
		category:    "info"
		params: {
			api_url: {from_field: "zabbix_url"}
			api_token: {from_field: "zabbix_token"}
			host_id: {}
		}
		command_template: "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"host.get\",\"params\":{\"hostids\":\"{host_id}\",\"output\":\"extend\"},\"auth\":\"{api_token}\",\"id\":1}' {api_url}/api_jsonrpc.php"
		idempotent:       true
	}

	problems: vocab.#ActionDef & {
		name:        "problems"
		description: "List active problems/alerts"
		category:    "monitor"
		params: {
			api_url: {from_field: "zabbix_url"}
			api_token: {from_field: "zabbix_token"}
		}
		command_template: "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"problem.get\",\"params\":{\"output\":\"extend\",\"recent\":true,\"sortfield\":[\"eventid\"],\"sortorder\":\"DESC\",\"limit\":50},\"auth\":\"{api_token}\",\"id\":1}' {api_url}/api_jsonrpc.php"
		idempotent:       true
	}

	trigger_active: vocab.#ActionDef & {
		name:        "trigger_active"
		description: "List active triggers"
		category:    "monitor"
		params: {
			api_url: {from_field: "zabbix_url"}
			api_token: {from_field: "zabbix_token"}
		}
		command_template: "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"trigger.get\",\"params\":{\"output\":[\"triggerid\",\"description\",\"priority\"],\"filter\":{\"value\":1},\"sortfield\":\"priority\",\"sortorder\":\"DESC\"},\"auth\":\"{api_token}\",\"id\":1}' {api_url}/api_jsonrpc.php"
		idempotent:       true
	}

	maintenance_create: vocab.#ActionDef & {
		name:        "maintenance_create"
		description: "Create maintenance window for host"
		category:    "admin"
		params: {
			api_url: {from_field: "zabbix_url"}
			api_token: {from_field: "zabbix_token"}
			host_id: {}
			maint_json: {}
		}
		command_template: "curl -s -X POST -H 'Content-Type: application/json' -d '{maint_json}' {api_url}/api_jsonrpc.php"
	}

	template_list: vocab.#ActionDef & {
		name:        "template_list"
		description: "List monitoring templates"
		category:    "info"
		params: {
			api_url: {from_field: "zabbix_url"}
			api_token: {from_field: "zabbix_token"}
		}
		command_template: "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"template.get\",\"params\":{\"output\":[\"templateid\",\"host\",\"name\"]},\"auth\":\"{api_token}\",\"id\":1}' {api_url}/api_jsonrpc.php"
		idempotent:       true
	}

	item_history: vocab.#ActionDef & {
		name:        "item_history"
		description: "Get metric history for item"
		category:    "info"
		params: {
			api_url: {from_field: "zabbix_url"}
			api_token: {from_field: "zabbix_token"}
			item_id: {}
		}
		command_template: "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"history.get\",\"params\":{\"itemids\":\"{item_id}\",\"output\":\"extend\",\"sortfield\":\"clock\",\"sortorder\":\"DESC\",\"limit\":10},\"auth\":\"{api_token}\",\"id\":1}' {api_url}/api_jsonrpc.php"
		idempotent:       true
	}

	...
}
