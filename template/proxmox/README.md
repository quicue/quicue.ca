# quicue-proxmox

Proxmox VE provider for quicue. Implements action interfaces with qm, pct, and pvecm commands for managing VMs, LXC containers, and Proxmox cluster nodes.

**Status:** [Active]

## Installation

```cue
import "quicue.ca/proxmox@v0"
```

## Prerequisites

- SSH access to Proxmox nodes (key-based authentication recommended)
- Proxmox VE 7.x or 8.x

## Schemas

### VM Operations

| Schema | Description |
|--------|-------------|
| `#VMActions` | VM operations: status, console, config via qm |
| `#VMLifecycle` | Power operations: start, stop, restart, suspend, resume, reset |
| `#VMSnapshots` | Snapshot management: list, create, revert, remove |

### Container Operations

| Schema | Description |
|--------|-------------|
| `#ContainerActions` | LXC operations: status, console, logs, config via pct |
| `#ContainerLifecycle` | Power operations: start, stop, restart |
| `#ContainerSnapshots` | Snapshot management for LXC containers |

### Node Operations

| Schema | Description |
|--------|-------------|
| `#HypervisorActions` | Node-level: list VMs/containers, cluster status, storage status |
| `#ConnectivityActions` | Network: ping, ssh, mtr |
| `#GuestAgent` | QEMU guest agent: exec, upload, download, info |
| `#BackupActions` | Proxmox Backup Server: backup, list backups |

## Usage

### Define a VM with Actions

```cue
package main

import "quicue.ca/proxmox/patterns"

vm_actions: patterns.#VMActions & {
    VMID: 100
    NODE: "pve-node-1"
}

// vm_actions.status.command  -> "ssh pve-node-1 'qm status 100'"
// vm_actions.console.command -> "ssh -t pve-node-1 'qm terminal 100'"
// vm_actions.config.command  -> "ssh pve-node-1 'qm config 100'"
```

### VM Lifecycle Operations

```cue
lifecycle: patterns.#VMLifecycle & {
    VMID: 100
    NODE: "pve-node-1"
}

// lifecycle.start.command   -> "ssh pve-node-1 'qm start 100'"
// lifecycle.stop.command    -> "ssh pve-node-1 'qm shutdown 100'"
// lifecycle.restart.command -> "ssh pve-node-1 'qm reboot 100'"
```

### LXC Container Actions

```cue
container: patterns.#ContainerActions & {
    CTID: 200
    NODE: "pve-node-1"
}

// container.status.command  -> "ssh pve-node-1 'pct status 200'"
// container.console.command -> "ssh -t pve-node-1 'pct enter 200'"
// container.logs.command    -> "ssh pve-node-1 'pct exec 200 -- journalctl -n 100'"
```

### Hypervisor Node Operations

```cue
node: patterns.#HypervisorActions & {
    NODE: "pve-node-1"
    USER: "root"
}

// node.list_vms.command       -> "ssh root@pve-node-1 'qm list'"
// node.list_containers.command -> "ssh root@pve-node-1 'pct list'"
// node.cluster_status.command -> "ssh root@pve-node-1 'pvecm status'"
```

### Integrate with quicue Resources

```cue
import (
    "quicue.ca/vocab"
    "quicue.ca/proxmox/patterns"
)

resources: {
    "dns-server": vocab.#Resource & {
        name:         "dns-server"
        "@type":      {DNSServer: true, LXCContainer: true}
        container_id: "101"
        host:         "pve-node-1"
        ip:           "10.0.1.10"
    }
}

// Generate actions for a resource
dns_actions: patterns.#ContainerActions & {
    CTID: int | *101
    NODE: resources["dns-server"].host
}
```

## Commands

```bash
# Validate all CUE files
cue vet ./...

# View VM actions for a specific VM
cue eval ./examples -e 'vmActions'

# Export actions as JSON
cue export ./examples -e vmActions --out json
```

## Patterns

- `3-layer` - Three-layer infrastructure pattern with Proxmox resources
- `adapter` - Adapter pattern for integrating external Proxmox data

---

Part of the [quicue](https://quicue.ca) ecosystem.
