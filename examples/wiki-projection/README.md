# wiki-projection

Generate a complete MkDocs documentation site from an infrastructure graph.

## Key Concepts

- **`wiki.#WikiProjection`** transforms resource definitions into a full documentation site
- Auto-generates: index page, per-resource pages, per-type pages, per-host pages
- Includes Mermaid dependency diagrams
- Produces a valid `mkdocs.yml` configuration

## Generated Pages

From 5 resources, the projection creates:

| Page | Content |
|------|---------|
| `docs/index.md` | Resource table, type summary, quick stats |
| `docs/graph.md` | Mermaid dependency diagram |
| `docs/resources/<name>.md` | Per-resource detail (type, IP, host, dependencies) |
| `docs/types/<type>.md` | All resources of a given type |
| `docs/hosts/<host>.md` | All resources on a given host |
| `mkdocs.yml` | MkDocs configuration with navigation |

## Run

```bash
# Full output (stats, file list, previews)
cue eval ./examples/wiki-projection/ -e output

# Just the stats
cue eval ./examples/wiki-projection/ -e output.stats

# Preview the index page
cue eval ./examples/wiki-projection/ -e output.index_preview --out text

# Preview the dependency graph (Mermaid)
cue eval ./examples/wiki-projection/ -e output.graph_preview --out text

# MkDocs config
cue eval ./examples/wiki-projection/ -e output.mkdocs_config --out text
```

## Usage

Export the files to disk and serve with MkDocs:

```bash
# Export all wiki files as JSON
cue export ./examples/wiki-projection/ -e projection.files --out json

# Then write each file to disk and run:
# mkdocs serve
```

The wiki stays in sync with infrastructure changes because it's generated from the same CUE source.
