# dagger

Auto-generated provider template for dagger.

## Resource types

Matches resources with any of: `CIServer, PipelineEngine`

## Actions

11 actions generated from OpenAPI spec.

## Usage

```cue
import "quicue.ca/template/dagger/patterns"

// Use in #BindCluster:
providers: {
    dagger: {
        types: { /* ... */ }
        registry: patterns.#DaggerRegistry
    }
}
```

## Post-generation checklist

1. Review `from_field` mappings — add bindings for path params that correspond to resource fields
2. Add any new resource types to `vocab/types.cue`
3. Validate: `cue vet ./template/dagger/...`
4. Remove actions that aren't useful for your use case
5. Adjust categories (info/connect/admin/monitor) where the inference was wrong
