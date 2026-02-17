# Proxmox Backup Server Provider

Backup management via proxmox-backup-client CLI.

## Requirements

- proxmox-backup-client, PBS_REPOSITORY configured

## Usage

```cue
import "quicue.ca/template/pbs/patterns"

actions: patterns.#PBSRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
