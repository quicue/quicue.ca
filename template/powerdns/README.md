# PowerDNS Provider

Authoritative DNS management via REST API.

## Requirements

- curl, PowerDNS API enabled with api-key

## Usage

```cue
import "quicue.ca/template/powerdns/patterns"

actions: patterns.#PowerDNSRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
