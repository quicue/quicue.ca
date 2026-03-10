# Form Projection

`#FormProjection` generates UI form field definitions from `#TypeRegistry` entries. Each registered type produces a form with base fields (name, description, depends_on, tags) plus type-specific required fields and structural dependency fields.

This is a UI-facing projection, not a SHACL shapes converter. For SHACL shapes, see `patterns/shacl.cue`.

## CUE wiring

One line wires the type registry to form output:

```cue
_forms: apercue_patterns.#FormProjection & {
    Types: vocab.#TypeRegistry
}
form_projection: _forms.form_definitions
```

## Pattern definition

`patterns/form.cue` defines the projection:

```cue
#FormProjection: {
    Types: vocab.#TypeRegistry

    _base_fields: [...#FormField] & [
        {name: "name", required: true, field_type: "string", label: "Name"},
        {name: "description", required: false, field_type: "string", label: "Description"},
        {name: "depends_on", required: false, field_type: "set", label: "Dependencies"},
        {name: "tags", required: false, field_type: "set", label: "Tags"},
    ]

    form_definitions: {
        "@context": vocab.context["@context"]
        "@graph": [
            for tname, tentry in Types {
                "@type":         "apercue:FormDefinition"
                "@id":           "urn:form:" + tname
                "dcterms:title": tname
                "apercue:fields": list.Concat([_base_fields, [...]])
            },
        ]
    }
}
```

For each type, the pattern concatenates the four base fields with:

- **Required fields** from `#TypeEntry.requires` (e.g. `container_id`, `host` for LXCContainer)
- **Structural dependency fields** from `#TypeEntry.structural_deps` (reference fields that create edges)

## Example output

The LXCContainer form definition:

```json
{
  "@type": "apercue:FormDefinition",
  "@id": "urn:form:LXCContainer",
  "dcterms:title": "LXCContainer",
  "dcterms:description": "Proxmox LXC container",
  "apercue:fields": [
    { "name": "name", "required": true, "field_type": "string", "label": "Name",
      "help_text": "ASCII identifier: letters, digits, hyphens, dots, underscores" },
    { "name": "description", "required": false, "field_type": "string", "label": "Description" },
    { "name": "depends_on", "required": false, "field_type": "set", "label": "Dependencies",
      "help_text": "Resources this depends on" },
    { "name": "tags", "required": false, "field_type": "set", "label": "Tags" },
    { "name": "container_id", "required": true, "field_type": "string", "label": "container_id" },
    { "name": "host", "required": true, "field_type": "string", "label": "host" },
    { "name": "host", "required": false, "field_type": "reference", "label": "host",
      "help_text": "Creates a dependency edge" }
  ]
}
```

The `host` field appears twice: once as a required string (from `requires`), once as a reference (from `structural_deps`). A UI consumer can use the `field_type` to distinguish between data entry and edge creation.

## Export

```bash
cue export ./examples/datacenter/ -e form_projection --out json
```

The output contains one form definition per registered type. The datacenter example uses 28+ types from `vocab.#TypeRegistry`.
