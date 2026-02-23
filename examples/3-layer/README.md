# 3-layer

Interface (vocab) → Provider (templates) → Instance (your data).

## Key Concepts

- **Layer 1 (Interface):** `vocab.#Action` defines the shape
- **Layer 2 (Provider):** Templates with UPPERCASE params (`CONTAINER_ID`, `HOST`)
- **Layer 3 (Instance):** Unify templates with concrete values

## The Pattern

```cue
import "quicue.ca/vocab@v0"

// Layer 2: Provider template (maps generic → platform-specific)
#ProxmoxLXC: {
    CONTAINER_ID: int    // from resource.container_id
    HOST:         string // from resource.host
    console: vocab.#Action & {
        name:        "Console"
        description: "Enter LXC container console"
        command:     "ssh -t \(HOST) 'pct enter \(CONTAINER_ID)'"
    }
    // ... more actions
}

// Layer 3: Instance - generic fields, provider maps them
resources: "dns-server": {
    name:         "dns-server"
    host:         "pve-node-1"  // generic: hypervisor host
    container_id: 100           // generic: container identifier
    "@type": {DNSServer: true, LXCContainer: true}

    actions: {
        #ProxmoxLXC & {CONTAINER_ID: container_id, HOST: host}
    }
}
```

Resources use generic field names (`host`, `container_id`). Providers map to platform-specific commands (`pct enter`).

## Run

```bash
cue eval ./examples/3-layer/ -e output
```

## Output

```cue
"dns-server": {
    resource: "dns-server"
    "@type": {DNSServer: true, LXCContainer: true}
    actions: {
        console: "ssh -t pve-node-1 'pct enter 100'"
        logs:    "ssh pve-node-1 'pct exec 100 -- journalctl -n 50'"
        config:  "ssh pve-node-1 'pct config 100'"
        status:  "ssh pve-node-1 'pct status 100'"
        ping:    "ping -c 3 198.51.100.10"
        ssh:     "ssh root@198.51.100.10"
    }
}
"git-server": {
    resource: "git-server"
    "@type": {SourceControlManagement: true, LXCContainer: true}
    actions: {
        console: "ssh -t pve-node-2 'pct enter 200'"
        logs:    "ssh pve-node-2 'pct exec 200 -- journalctl -n 50'"
        config:  "ssh pve-node-2 'pct config 200'"
        status:  "ssh pve-node-2 'pct status 200'"
        ping:    "ping -c 3 198.51.100.20"
        ssh:     "ssh git@198.51.100.20"
    }
}
```
