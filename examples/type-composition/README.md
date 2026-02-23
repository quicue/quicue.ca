# type-composition

Actions derived from `@type` arrays and field presence.

## Key Concepts

- `#TypeActions` maps type names to action names
- Actions compose additively: `["DNSServer", "ReverseProxy"]` grants actions from both
- Field presence gates actions: `ping` requires `ip`, `list_vms` requires `ssh_user`

## The Pattern

```cue
// Type-to-action mapping
#TypeActions: {
    DNSServer:              ["check_dns"]
    ReverseProxy:           ["proxy_health"]
    VirtualizationPlatform: ["list_vms"]
    CriticalInfra:          []  // classification, no actions
}

// Action factories with UPPERCASE params
#ActionFactory: {
    ping: {
        IP: string
        vocab.#Action & {
            name:    "Ping"
            command: "ping -c 3 \(IP)"
        }
    }
    check_dns: {
        IP: string
        vocab.#Action & {
            name:    "Check DNS"
            command: "dig @\(IP) SOA"
        }
    }
    // ...
}

// Resource: types determine which actions it gets
resources: "technitium": {
    ip: "198.51.100.10"
    "@type": {DNSServer: true, CriticalInfra: true}
}
// → actions: [ping, check_dns]  (CriticalInfra has no actions)
```

## Run

```bash
cue eval ./examples/type-composition/ -e output
```

## Output

```cue
caddy: {
    types: ["ReverseProxy"]
    actions: ["ping", "proxy_health"]
}
technitium: {
    types: ["DNSServer", "CriticalInfra"]
    actions: ["ping", "check_dns"]
}
"pve-node": {
    types: ["VirtualizationPlatform"]
    actions: ["ping", "list_vms"]
}
"multi-role": {
    types: ["DNSServer", "ReverseProxy"]
    actions: ["ping", "check_dns", "proxy_health"]
}
```

The `multi-role` resource demonstrates additive composition: it has both `DNSServer` and `ReverseProxy` types, so it gets `check_dns` AND `proxy_health` actions.
