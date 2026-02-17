# Keycloak Provider

Identity and access management via Keycloak admin CLI.

## Requirements

- kcadm.sh or curl for REST API

## Usage

```cue
import "quicue.ca/template/keycloak/patterns"

actions: patterns.#KeycloakRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
