# consul

Auto-generated provider template for consul.

## Resource types

Matches resources with any of: `ServiceDiscovery, ServiceMesh`

## Actions

26 actions generated from OpenAPI spec.

## Usage

```cue
import "quicue.ca/template/consul/patterns"

// Use in #BindCluster:
providers: {
    consul: {
        types: { /* ... */ }
        registry: patterns.#ConsulRegistry
    }
}
```

## Post-generation checklist

1. Review `from_field` mappings — add bindings for path params that correspond to resource fields
2. Add any new resource types to `vocab/types.cue`
3. Validate: `cue vet ./template/consul/...`
4. Remove actions that aren't useful for your use case
5. Adjust categories (info/connect/admin/monitor) where the inference was wrong
