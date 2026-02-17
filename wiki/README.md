# quicue.ca/wiki — Documentation Generator

Generate static MkDocs sites from infrastructure graphs.

**Use this when:** You want browsable infrastructure documentation that stays in sync with your resource definitions. The wiki is generated from the same CUE data that drives your deployment plans — no separate documentation to maintain.

## Overview

The wiki module transforms infrastructure resources into a browsable documentation site: resource pages, type/host groupings, dependency graphs, and MkDocs configuration.

## Schemas

- **#Resource** — Expected shape for wiki input: name, description, @type, ip, hostname, host, depends_on. Open schema for extensions.
- **#WikiProjection** — Transform resources into markdown files, grouped by type and host. Generates index, resource pages, type pages, host pages, dependency graph (Mermaid), and mkdocs.yml.
- **#FullExport** — Convenience wrapper with optional site title, description, URL.

## Generated Output

- `docs/index.md` — Overview with type/host links and resource table
- `docs/resources/{name}.md` — Per-resource pages with details and dependencies
- `docs/types/{type}.md` — Grouped by semantic type (DNSServer, VirtualMachine, etc.)
- `docs/hosts/{host}.md` — Grouped by hosting node
- `docs/graph.md` — Mermaid graph visualization (hosting relationships + dependencies)
- `mkdocs.yml` — Material theme config with navigation

## Usage Example

```cue
import "quicue.ca/wiki@v0"

wiki: wiki.#WikiProjection & {
	Resources: myResources
	SiteTitle: "Infrastructure Catalog"
	SiteDescription: "Central IT infrastructure catalog"
	DocsPath: "docs"
}

// Export all files
result: cue export wiki.files --out json
// result["docs/index.md"].content, result["mkdocs.yml"].content, etc.
```

## Key Patterns

- **Pre-computed groupings**: _by_type, _by_host, _resource_details pre-computed via comprehensions to avoid nested-comprehension performance issues.
- **If-guards for defaults**: Uses `if field != _|_` instead of `| *default` for safe default resolution.
- **Mermaid graphs**: Auto-generates dependency diagrams with hosting edges (solid) and explicit deps (dashed).
- **Static site friendly**: No dynamic data — all content is compiled into markdown and YAML.

## Files

- `wiki.cue` — #WikiProjection and #FullExport

## See Also

- `patterns/graph.cue` — Resource graph structure
- `ou/` — Role-based views (complementary to wiki's full view)
