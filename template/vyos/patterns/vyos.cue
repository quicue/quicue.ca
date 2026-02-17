// This CUE file defines the schema for interacting with a VyOS router.
// VyOS has two primary command modes:
// - Operational mode (show): read-only commands executed via SSH.
// - Configuration mode (set/delete/commit/save): uses script-template wrapper.
// Import path: quicue.ca/vocab

package patterns
import "quicue.ca/vocab"

#VyOSRegistry: {
    show_interfaces: vocab.#ActionDef & {
        name:        "show_interfaces"
        description: "Show interfaces on the VyOS router."
        category:    "info"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'show interfaces'"
        idempotent: true
    }

    show_route: vocab.#ActionDef & {
        name:        "show_route"
        description: "Show IP route table on the VyOS router."
        category:    "info"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'show ip route'"
        idempotent: true
    }

    show_bgp: vocab.#ActionDef & {
        name:        "show_bgp"
        description: "Show BGP summary on the VyOS router."
        category:    "info"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'show bgp summary'"
        idempotent: true
    }

    show_firewall: vocab.#ActionDef & {
        name:        "show_firewall"
        description: "Show firewall configuration on the VyOS router."
        category:    "info"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'show firewall'"
        idempotent: true
    }

    show_nat: vocab.#ActionDef & {
        name:        "show_nat"
        description: "Show NAT translations on the VyOS router."
        category:    "info"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'show nat translations'"
        idempotent: true
    }

    show_dhcp_leases: vocab.#ActionDef & {
        name:        "show_dhcp_leases"
        description: "Show DHCP server leases on the VyOS router."
        category:    "info"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'show dhcp server leases'"
        idempotent: true
    }

    show_config: vocab.#ActionDef & {
        name:        "show_config"
        description: "Show the current configuration on the VyOS router."
        category:    "info"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'show configuration'"
        idempotent: true
    }

    show_version: vocab.#ActionDef & {
        name:        "show_version"
        description: "Show the version of VyOS running on the router."
        category:    "info"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'show version'"
        idempotent: true
    }

    show_log: vocab.#ActionDef & {
        name:        "show_log"
        description: "Show the last 50 lines of the system log on the VyOS router."
        category:    "monitor"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'show log tail 50'"
        idempotent: true
    }

    config_show_diff: vocab.#ActionDef & {
        name:        "config_show_diff"
        description: "Show the differences between the current and candidate configurations on the VyOS router."
        category:    "info"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'compare'"
        idempotent: true
    }

    config_commit: vocab.#ActionDef & {
        name:        "config_commit"
        description: "Commit the candidate configuration on the VyOS router."
        category:    "admin"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'source /opt/vyatta/etc/functions/script-template; commit'"
    }

    config_save: vocab.#ActionDef & {
        name:        "config_save"
        description: "Save the current configuration on the VyOS router."
        category:    "admin"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'source /opt/vyatta/etc/functions/script-template; save'"
    }

    monitor_traffic: vocab.#ActionDef & {
        name:        "monitor_traffic"
        description: "Show interface counters on the VyOS router."
        category:    "monitor"
        params: {
            router_ip: vocab.#ActionParam & { from_field: "ip" }
            user:      vocab.#ActionParam & { from_field: "ssh_user", required: false }
        }
        command_template: "ssh {user}@{router_ip} 'show interfaces counters'"
        idempotent: true
    }

    ...
}