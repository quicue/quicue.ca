# authentik

Auto-generated provider template for authentik.

## Resource types

Matches resources with any of: `IdentityProvider, SSOServer`

## Actions

40 actions generated from OpenAPI spec.

## Usage

```cue
import "quicue.ca/template/authentik/patterns"

// Use in #BindCluster:
providers: {
    authentik: {
        types: { /* ... */ }
        registry: patterns.#AuthentikRegistry
    }
}
```

## Post-generation checklist

1. Review `from_field` mappings — add bindings for path params that correspond to resource fields
2. Add any new resource types to `vocab/types.cue`
3. Validate: `cue vet ./template/authentik/...`
4. Remove actions that aren't useful for your use case
5. Adjust categories (info/connect/admin/monitor) where the inference was wrong
