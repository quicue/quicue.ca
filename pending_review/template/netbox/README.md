# netbox

Auto-generated provider template for netbox.

## Resource types

Matches resources with any of: `DCIMServer, IPAMServer`

## Actions

12 actions generated from OpenAPI spec.

## Usage

```cue
import "quicue.ca/template/netbox/patterns"

// Use in #BindCluster:
providers: {
    netbox: {
        types: { /* ... */ }
        registry: patterns.#NetboxRegistry
    }
}
```

## Post-generation checklist

1. Review `from_field` mappings — add bindings for path params that correspond to resource fields
2. Add any new resource types to `vocab/types.cue`
3. Validate: `cue vet ./template/netbox/...`
4. Remove actions that aren't useful for your use case
5. Adjust categories (info/connect/admin/monitor) where the inference was wrong
