# Caddy Provider

Caddy reverse proxy management via [admin API](https://caddyserver.com/docs/api).

## Requirements

- Caddy server with admin API enabled (default: `localhost:2019`)
- `curl` for API calls, `caddy` CLI for config operations

## Usage

```cue
import "quicue.ca/template/caddy/patterns"

actions: patterns.#CaddyRegistry
```

## Remote Access

Caddy's admin API listens on localhost only. For remote:

```bash
ssh -L 2019:localhost:2019 caddy-host
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
