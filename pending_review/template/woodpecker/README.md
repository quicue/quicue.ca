# woodpecker

Auto-generated provider template for woodpecker.

## Resource types

Matches resources with any of: `CIServer, BuildServer`

## Actions

25 actions generated from OpenAPI spec.

## Usage

```cue
import "quicue.ca/template/woodpecker/patterns"

// Use in #BindCluster:
providers: {
    woodpecker: {
        types: { /* ... */ }
        registry: patterns.#WoodpeckerRegistry
    }
}
```

## Post-generation checklist

1. Review `from_field` mappings — add bindings for path params that correspond to resource fields
2. Add any new resource types to `vocab/types.cue`
3. Validate: `cue vet ./template/woodpecker/...`
4. Remove actions that aren't useful for your use case
5. Adjust categories (info/connect/admin/monitor) where the inference was wrong
