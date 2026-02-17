# HashiCorp Vault Provider

Secrets management and PKI via Vault CLI.

## Requirements

- vault CLI, VAULT_ADDR and VAULT_TOKEN set

## Usage

```cue
import "quicue.ca/template/vault/patterns"

actions: patterns.#VaultRegistry
```

## Validation

```bash
cue eval ./patterns/
cue eval ./examples/
```
