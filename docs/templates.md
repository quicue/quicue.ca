# Template Authoring Guide

How to create a new provider template for quicue.ca. A template teaches the system how to manage a specific platform — what resource types it serves, what actions it can perform, and how those actions translate to concrete commands.

## Directory structure

```
template/<name>/
  meta/meta.cue          # Provider metadata and type matching
  patterns/<name>.cue    # Action registry
  examples/demo.cue      # Working example (validates with cue vet)
  README.md              # What this provider does and what it requires
```

All four files are required. The `meta/meta.cue` path is the convention used by 27 of 29 existing providers (docker and incus use `meta.cue` at root — prefer the `meta/` subdirectory for new providers).

## Step 1: Provider metadata

`meta/meta.cue` declares what resource types this provider serves:

```cue
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {
    types: {
        // List every @type this provider can act on.
        // A resource matches if ANY of its @type values appears here.
        DNSServer: true
    }
    provider: "powerdns"  // Used to namespace actions: resource.actions.powerdns.*
}

project: {
    "@id":        "https://quicue.ca/project/quicue-powerdns"
    description:  "PowerDNS provider. Zone management via dig and pdnsutil."
    status:       "active"
}
```

**Type selection.** Check `vocab/types.cue` for existing types before creating new ones. Most infrastructure fits the existing taxonomy:

- Implementation types (`LXCContainer`, `VirtualMachine`, `DockerContainer`) — how it runs
- Semantic types (`DNSServer`, `ReverseProxy`, `Database`) — what it does
- A resource typically has one implementation type and one or more semantic types

## Step 2: Action registry

`patterns/<name>.cue` defines the actions this provider can perform, using `vocab.#ActionDef`:

```cue
package patterns

import "quicue.ca/vocab"

#PowerDNSRegistry: {
    zone_list: vocab.#ActionDef & {
        name:        "List Zones"
        description: "List all DNS zones"
        category:    "info"       // info | connect | admin | monitor
        params: {
            ip: {from_field: "ip"}  // Bind from resource.ip
        }
        command_template: "dig @{ip} AXFR"
        idempotent:       true
    }

    zone_check: vocab.#ActionDef & {
        name:        "Check Zone"
        description: "Verify zone SOA record"
        category:    "info"
        params: {
            ip:   {from_field: "ip"}
            fqdn: {from_field: "fqdn", required: false}
        }
        command_template: "dig @{ip} {fqdn} SOA"
        idempotent:       true
    }

    reload: vocab.#ActionDef & {
        name:        "Reload Config"
        description: "Reload PowerDNS configuration"
        category:    "admin"
        params: {
            host:         {from_field: "host"}
            container_id: {from_field: "container_id"}
        }
        command_template: "ssh {host} 'pct exec {container_id} -- pdns_control reload'"
        destructive: true
    }
}
```

### Parameter binding

Each parameter declares `from_field` — the resource field it binds to:

| `from_field` | Resolves from | Example value |
|--------------|---------------|---------------|
| `"ip"` | `resource.ip` | `"198.51.100.211"` |
| `"host"` | `resource.host` | `"pve-alpha"` |
| `"container_id"` | `resource.container_id` | `101` |
| `"ssh_user"` | `resource.ssh_user` | `"root"` |
| `"fqdn"` | `resource.fqdn` | `"dns.example.com"` |

Rules:

- If a required parameter's field is missing from the resource, the entire action is silently omitted (the provider doesn't apply for that action on that resource).
- Optional parameters (`required: false`) with `default` values use the default when the field is absent.
- All values are stringified for template substitution. CUE integers become `"101"`.
- Up to 8 parameters per action (limitation of `#ResolveTemplate`).

### Categories

| Category | When to use |
|----------|-------------|
| `info` | Read-only queries (status, list, show) |
| `connect` | Interactive sessions (SSH, console) |
| `admin` | State-changing operations (start, stop, reload) |
| `monitor` | Monitoring and alerting queries |

### Destructive flag

Set `destructive: true` for actions that permanently change state (delete, purge, reset). The execution gateway and CAB reports use this flag to gate dangerous operations.

## Step 3: Working example

`examples/demo.cue` must validate with `cue vet` and demonstrate the provider with realistic data:

```cue
package demo

import (
    "quicue.ca/vocab"
    "quicue.ca/patterns"
    "quicue.ca/template/powerdns/patterns" as pdns
)

_resources: {
    "dns-primary": vocab.#Resource & {
        name:         "dns-primary"
        "@type":      {LXCContainer: true, DNSServer: true}
        host:         "pve-alpha"
        container_id: 100
        ip:           "198.51.100.211"
        fqdn:         "dns.example.com"
    }
}

_providers: {
    powerdns: patterns.#ProviderDecl & {
        types:    {DNSServer: true}
        registry: pdns.#PowerDNSRegistry
    }
}

output: patterns.#BindCluster & {
    resources: _resources
    providers: _providers
}
```

Verify it works:

```bash
cue vet ./template/powerdns/...
cue eval ./template/powerdns/examples/ -e output.summary
```

## Step 4: README

Document what the provider manages, what resource types it serves, what fields it requires, and what actions it implements. Follow the pattern of existing providers (e.g., `template/proxmox/README.md`).

## Validation checklist

Before submitting a new template:

```bash
# Validate the template itself
cue vet ./template/<name>/...

# Validate that the demo example produces resolved commands
cue eval ./template/<name>/examples/ -e output.summary

# Validate all existing templates still work (regression check)
make providers

# Validate all examples still work
make examples
```

## Conventions

1. **Use generic field names.** `host` not `node`, `container_id` not `lxcid`. The whole point of the binding layer is that generic fields map to platform-specific commands.

2. **One registry per provider.** Name it `#<Name>Registry` (e.g., `#ProxmoxRegistry`, `#CaddyRegistry`). Consumers reference it when declaring providers.

3. **Idempotent by default.** Mark read-only actions as `idempotent: true`. Mark state-changing actions as `destructive: true`.

4. **SSH wrapping.** For actions that execute on remote hosts, use `ssh {host} '<command>'` or `ssh {user}@{ip} '<command>'` in the template. The binding layer resolves the host/IP from resource fields.

5. **Package naming.** `meta/meta.cue` uses `package meta`. `patterns/<name>.cue` uses `package patterns`. `examples/demo.cue` uses `package demo`. These match the directory-scoped CUE package convention.
