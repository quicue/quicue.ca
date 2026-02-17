# AWX Provider

Ansible automation controller via AWX REST API.

## Requirements

- awx CLI or curl, AWX_TOKEN set

## Usage

```cue
import "quicue.ca/template/awx/patterns"

actions: patterns.#AWXRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
