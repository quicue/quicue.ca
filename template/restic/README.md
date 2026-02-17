# Restic Provider

Deduplicating backup via restic CLI.

## Requirements

- restic, RESTIC_REPOSITORY and RESTIC_PASSWORD set

## Usage

```cue
import "quicue.ca/template/restic/patterns"

actions: patterns.#ResticRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
