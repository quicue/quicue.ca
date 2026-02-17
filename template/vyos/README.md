# VyOS Provider

VyOS router management via SSH.

## Requirements

- SSH access to VyOS router
- `vyos` user (or equivalent with operator/admin privileges)

## Command Modes

- **Operational** (`show_*`): Read-only status and diagnostic commands
- **Configuration** (`config_*`): Uses VyOS script-template for non-interactive config changes

## Usage

```cue
import "quicue.ca/template/vyos/patterns"

actions: patterns.#VyOSRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
