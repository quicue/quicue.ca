# Dagger Provider

CI/CD pipeline orchestration via Dagger CLI.

## Requirements

- dagger CLI installed

## Usage

```cue
import "quicue.ca/template/dagger/patterns"

actions: patterns.#DaggerRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
