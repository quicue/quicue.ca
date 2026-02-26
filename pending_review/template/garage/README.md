# garage

Auto-generated provider template for garage.

## Resource types

Matches resources with any of: `ObjectStorage, S3Storage`

## Actions

40 actions generated from OpenAPI spec.

## Usage

```cue
import "quicue.ca/template/garage/patterns"

// Use in #BindCluster:
providers: {
    garage: {
        types: { /* ... */ }
        registry: patterns.#GarageRegistry
    }
}
```

## Post-generation checklist

1. Review `from_field` mappings — add bindings for path params that correspond to resource fields
2. Add any new resource types to `vocab/types.cue`
3. Validate: `cue vet ./template/garage/...`
4. Remove actions that aren't useful for your use case
5. Adjust categories (info/connect/admin/monitor) where the inference was wrong
