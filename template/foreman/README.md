# Foreman Provider

Bare metal provisioning and lifecycle via Foreman API.

## Requirements

- hammer CLI or curl for REST API

## Usage

```cue
import "quicue.ca/template/foreman/patterns"

actions: patterns.#ForemanRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
