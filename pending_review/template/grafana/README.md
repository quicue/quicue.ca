# grafana

Auto-generated provider template for grafana.

## Resource types

Matches resources with any of: `MonitoringServer, Dashboard`

## Actions

40 actions generated from OpenAPI spec.

## Usage

```cue
import "quicue.ca/template/grafana/patterns"

// Use in #BindCluster:
providers: {
    grafana: {
        types: { /* ... */ }
        registry: patterns.#GrafanaRegistry
    }
}
```

## Post-generation checklist

1. Review `from_field` mappings — add bindings for path params that correspond to resource fields
2. Add any new resource types to `vocab/types.cue`
3. Validate: `cue vet ./template/grafana/...`
4. Remove actions that aren't useful for your use case
5. Adjust categories (info/connect/admin/monitor) where the inference was wrong
