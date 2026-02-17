# OpenTofu Provider

Infrastructure as code via OpenTofu CLI.

## Requirements

- tofu CLI installed

## Usage

```cue
import "quicue.ca/template/opentofu/patterns"

actions: patterns.#OpenTofuRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
