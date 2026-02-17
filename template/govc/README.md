# govc Provider

vSphere VM management via [govc](https://github.com/vmware/govmomi/tree/main/govc) CLI.

## Requirements

- `govc` installed
- Environment: `GOVC_URL`, `GOVC_USERNAME`, `GOVC_PASSWORD`

## Usage

```cue
import "quicue.ca/template/govc/patterns"

actions: patterns.#GovcRegistry
```

## Testing with vcsim

```bash
cd tests && docker compose up -d
export GOVC_URL=https://localhost:8989 GOVC_INSECURE=1
export GOVC_USERNAME=user GOVC_PASSWORD=pass
govc ls /
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
