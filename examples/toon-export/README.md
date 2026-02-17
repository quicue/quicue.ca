# toon-export

TOON (Token Oriented Object Notation) compact export for infrastructure queries.

## What is TOON?

TOON is a compact tabular format that reduces payload size by ~55% compared to JSON for infrastructure data. Resources are grouped by field signature and rendered as delimited tables instead of nested objects.

## Key Concepts

- **`patterns.#TOONExport`** transforms resource structs into compact tabular text
- Resources with identical field sets are grouped into shared tables
- Dependencies rendered as a separate adjacency table
- Configurable field selection and dependency inclusion

## Example

7 resources (DNS, web, proxy, database, monitoring) exported in three formats:

| Format | Fields | Dependencies |
|--------|--------|-------------|
| Full | name, types, ip, host, container_id, vm_id | Yes |
| No deps | name, types, ip, host | No |
| Minimal | name, ip | No |

## Run

```bash
# TOON output (compact tabular format)
cue eval ./examples/toon-export -e toon --out text

# Payload savings comparison
cue eval ./examples/toon-export -e compare

# Equivalent JSON for comparison
cue export ./examples/toon-export -e jsonOutput --out json

# Minimal TOON (just names and IPs)
cue eval ./examples/toon-export -e toon_minimal --out text
```

## Comparison

```
toon_chars:     ~450
json_chars:     ~1050
savings_pct:    ~55
resource_count: 7
note: "TOON reduces payload by 55% for this dataset"
```

Use TOON when compact representation matters — monitoring dashboards, API responses, context windows, or any consumer that benefits from reduced payload size.
