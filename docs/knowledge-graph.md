# Knowledge Graph

`quicue.ca/kg@v0` — CUE-native knowledge capture with compile-time validation.

Projects accumulate knowledge that lives outside source code: *why* a technology was chosen, *what* approaches failed, *which* patterns recur. This knowledge typically scatters across wikis, chat logs, and individual memory. When it's lost, teams re-explore failed paths and make decisions without context.

quicue-kg stores this knowledge as typed CUE data in a `.kg/` directory alongside your code. CUE's type system enforces structure — every rejected approach must record an alternative, every insight must cite evidence. Validation is `cue vet .kg/`. No database, no server.

## Quick start

```bash
# Initialize a knowledge graph in your project
kg init

# Record a decision
kg add decision
# Edit the generated file, then validate
kg vet

# See what you've recorded
kg index --summary
```

## Installation

**Via GHCR** (available now):
```bash
export CUE_REGISTRY='quicue.ca=ghcr.io/quicue/cue-modules,registry.cue.works'
cue mod tidy
```

**Via local symlink** (development):
```bash
mkdir -p cue.mod/pkg/quicue.ca/kg
ln -s /path/to/quicue-kg/* cue.mod/pkg/quicue.ca/kg/
```

## Types

### Core (`core/`)

| Type | ID Pattern | Purpose |
|------|-----------|---------|
| `#Decision` | `ADR-NNN` | Architecture decisions with mandatory rationale and consequences |
| `#Pattern` | — | Reusable problem/solution pairs with cross-project tracking |
| `#Insight` | `INSIGHT-NNN` | Validated discoveries with mandatory evidence and confidence level |
| `#Rejected` | `REJ-NNN` | Failed approaches — must record what to do instead |

### Extensions (`ext/`)

| Type | Purpose |
|------|---------|
| `#Derivation` | Data pipeline audit trails |
| `#Workspace` | Multi-repo topology mapping |
| `#Context` | Project identity and self-description |
| `#SourceFile` | Source artifact tracking with SHA256 and origin metadata |
| `#CollectionProtocol` | Repeatable data collection procedures (maps to prov:Plan) |
| `#PipelineRun` | Single pipeline execution event (maps to prov:Activity) |

### Aggregation (`aggregate/`)

| Type | Purpose |
|------|---------|
| `#KGIndex` | Computed summary, by_status, by_confidence views |
| `#KGLint` | Structural quality checks |
| `#Provenance` | PROV-O projection (decisions as provenance activities) |
| `#DatasetEntry` | DCAT projection (project as cataloged dataset) |
| `#FederatedCatalog` | DCAT catalog for federation results |
| `#Annotations` | Web Annotation projection (insights as annotations) |
| `#Prolog` | Prolog facts + inference rules |
| `#Datalog` | Soufflé-compatible Datalog (guaranteed termination) |
| `#NTriples` | N-Triples — one triple per line, greppable RDF |
| `#Turtle` | Turtle — human-readable prefixed RDF |
| `#SKOSTaxonomy` | SKOS concept scheme from pattern categories |

All aggregate types produce W3C-compatible linked data. See [Linked Data](linked-data.md) for the full projection reference.

## What makes this different

1. **Knowledge conflicts are type errors.** If two teams assert contradictory facts, CUE unification fails at build time — not silently at read time.

2. **Federation without infrastructure.** Merging knowledge across projects is a CUE import, not a service call. `cue vet` catches conflicts.

3. **Progressive refinement.** CUE's type lattice only narrows, never broadens. A field constrained to `"high" | "medium" | "low"` can't silently accept `"maybe"`.

4. **Schema evolution as a quality ratchet.** Adding a required field to `#Decision` makes every existing entry without it a validation error.

5. **Computed indexes.** Summary views (`by_status`, `by_confidence`) are CUE comprehensions — always in sync because they're derived.

## CLI

```
Usage: kg <command> [args...]

Commands:
  init              Scaffold .kg/ directory with imports
  add <type>        Create new entry (decision|pattern|insight|rejected)
  vet               Validate .kg/ content
  index [--full]    Export aggregated index as JSON
  query <expr>      Query via CUE expression
  lint              Knowledge quality checks
  settle            Check for conflicts, coverage gaps, referential integrity
  diff [ref]        Semantic changelog since git ref
  link <a> <b>      Cross-reference two entries
  graph [--dot]     Export relationships as JSON or DOT
  fed <dirs...>     Federate multiple .kg/ directories
```

## Specification

The formal specification covers directory layout, type constraints, aggregation semantics, and the federation protocol:

**[Read the specification →](https://kg.quicue.ca/spec/index.html)**

JSON-LD vocabulary context: [kg.quicue.ca/context.jsonld](https://kg.quicue.ca/context.jsonld)

Source: [github.com/quicue/quicue-kg](https://github.com/quicue/quicue-kg)
