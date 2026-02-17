# NetBox Provider

IPAM and DCIM via NetBox REST API.

## Requirements

- curl, NetBox API token

## Usage

```cue
import "quicue.ca/template/netbox/patterns"

actions: patterns.#NetBoxRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
