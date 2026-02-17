# PowerCLI Provider

vSphere VM management via [VMware PowerCLI](https://developer.vmware.com/powercli) cmdlets.

## Requirements

- `pwsh` (PowerShell Core)
- `VMware.PowerCLI` module (`Install-Module VMware.PowerCLI`)

## Usage

```cue
import "quicue.ca/template/powercli/patterns"

actions: patterns.#PowerCLIRegistry
```

## Testing with vcsim

```bash
cd tests && docker compose up -d
docker compose exec powercli pwsh
Connect-VIServer -Server vcsim -Port 8989 -User user -Password pass
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
