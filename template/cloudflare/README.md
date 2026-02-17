# Cloudflare Provider

DNS, tunnels, and WAF management via Cloudflare API.

## Requirements

- curl or wrangler CLI, CF_API_TOKEN set

## Usage

```cue
import "quicue.ca/template/cloudflare/patterns"

actions: patterns.#CloudflareRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
