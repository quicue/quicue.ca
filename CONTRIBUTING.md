# Contributing to quicue.ca

## Getting started

1. Install [CUE](https://cuelang.org/) v0.15.4+
2. Clone this repo
3. Run `make validate` to verify your setup (or `cue vet ./vocab/ ./patterns/`)

## Project structure

```
vocab/            Core type definitions (#Resource, #Action, #ActionDef, #TypeRegistry)
patterns/         Graph algorithms and binding (#InfraGraph, #BindCluster, #ExecutionPlan)
template/*/       29 provider templates (proxmox, docker, caddy, ...)
examples/*/       Working examples (datacenter, homelab, graph-patterns, ...)
ou/               Role-scoped views (ops, dev, readonly) + Hydra JSON-LD
boot/             Bootstrap sequencing
orche/            Multi-site federation and drift detection
cab/              Change Advisory Board reports
wiki/             MkDocs generation
server/           FastAPI execution gateway
kg/               Knowledge graph framework (quicue-kg)
.kb/              Project knowledge base (multi-graph: decisions, patterns, insights, rejected)
docs/             Architecture guide, pattern catalog, template guide
```

See [docs/architecture.md](docs/architecture.md) for how the layers compose.

## Making changes

### Adding a provider

1. Create `template/<name>/` with the standard structure:
   ```
   template/<name>/
     meta/meta.cue         # Provider metadata (type matching)
     patterns/<name>.cue   # Action registry using vocab.#ActionDef
     examples/demo.cue     # Working example
     README.md
   ```
2. Use `vocab.#ActionDef` for all action definitions with explicit `from_field` bindings
3. Run `cue vet ./template/<name>/...` to validate
4. Run `make providers` to confirm no regressions

See [docs/templates.md](docs/templates.md) for a full walkthrough.

### Adding an example

1. Create `examples/<name>/` with a CUE file and a `README.md`
2. Import from `quicue.ca/vocab@v0` and `quicue.ca/patterns@v0`
3. Run `cue vet ./examples/<name>/` to validate
4. Run `cue eval ./examples/<name>/ -e output` to verify output

### Modifying core schemas

Changes to `vocab/` or `patterns/` affect everything downstream. After changes:

```bash
make all  # Validates core + all examples + all providers
```

Or individually:

```bash
make validate   # Core schemas only
make examples   # All examples
make providers  # All 29 provider templates
```

### Adding a pattern

1. Add the definition to the appropriate file in `patterns/`
2. Accept `Graph: #InfraGraph` as input when possible (for composability)
3. Use hidden fields (`_prefix`) for intermediate computation
4. Add a usage example in the file's header comment
5. Exercise the pattern in an example under `examples/`

## Conventions

### Struct-as-set

Use `{key: true}` for `@type`, `depends_on`, `provides`, and `tags`:

```cue
// Good: O(1) membership check
"@type": {LXCContainer: true, DNSServer: true}

// Bad: O(n) list scan
"@type": ["LXCContainer", "DNSServer"]
```

Patterns test membership with `resource["@type"][SomeType] != _|_` — this is O(1) with structs vs O(n) with `list.Contains`.

### Generic field names

Use `host` (not `node`), `container_id` (not `lxcid`), `vm_id` (not `vmid`). Providers map these generic names to platform-specific commands. This decouples the graph from any single platform.

### Compile-time binding

All `{param}` placeholders must resolve at `cue vet` time. No runtime template resolution. If a resource lacks a required field, the action is omitted — not left with unresolved placeholders.

### Hidden fields for export

CUE exports all public (capitalized) fields. Use hidden fields (`_graph`, `_depth`, `_internal`) for intermediate computation that shouldn't appear in JSON output. See [docs/architecture.md](docs/architecture.md) for the export gotcha.

### No runtime state

The CUE layer is pure. No network calls, no file I/O, no side effects. All computation happens at `cue vet`/`cue eval` time.

### Performance awareness

- Transitive closure (`_ancestors`) performance depends on topology, not node count
- Wide fan-in (many deps per node) is costlier than deep chains
- Use precomputed depth values when fan-in causes timeouts
- Prefer struct membership checks over list operations

## Validation

```bash
make all          # Everything
make validate     # Core schemas
make examples     # All examples
make providers    # All providers
make datacenter   # Datacenter example summary
make homelab      # Homelab example summary
make devbox       # Devbox example summary
make impact       # Impact analysis demo
make blast        # Blast radius analysis
make spof         # SPOF detection demo
make export       # Full JSON export
make jsonld       # JSON-LD graph export
make check-downstream  # Validate all downstream consumers
```

## Pull requests

- One logical change per PR
- All `cue vet` checks must pass (CI runs automatically)
- Include a working example if adding new patterns or providers
- Run `make all` locally before pushing
