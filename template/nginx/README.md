# Nginx Provider

Web server and reverse proxy management.

## Requirements

- nginx installed, config directory access

## Usage

```cue
import "quicue.ca/template/nginx/patterns"

actions: patterns.#NginxRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
