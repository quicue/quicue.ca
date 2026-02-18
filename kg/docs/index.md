# quicue-kg

[![CI](https://github.com/quicue/quicue-kg/actions/workflows/ci.yml/badge.svg)](https://github.com/quicue/quicue-kg/actions/workflows/ci.yml)

CUE-native knowledge graph framework for tracking architectural decisions, patterns, insights, and rejected approaches — with compile-time validation.

## Why

Projects accumulate knowledge that lives outside source code: *why* a technology was chosen, *what* approaches failed, *which* patterns recur. This knowledge typically scatters across wikis, chat logs, and individual memory. When it's lost, teams re-explore failed paths and make decisions without context.

quicue-kg stores this knowledge as typed CUE data in a `.kb/` directory alongside your code. CUE's type system enforces structure — every rejected approach must record an alternative, every insight must cite evidence. Validation is `cue vet .kb/`. No database, no server.

**Who this is for:** Development teams who want queryable, validated project knowledge that lives in version control.

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

A minimal `.kb/` looks like this:

```cue
package kg

import "quicue.ca/kg/core@v0"

decisions: {
    "ADR-001": core.#Decision & {
        id:           "ADR-001"
        title:        "Use PostgreSQL for persistence"
        status:       "accepted"
        date:         "2026-01-15"
        context:      "Need ACID transactions and JSONB support."
        decision:     "Use PostgreSQL 16 with JSONB columns for semi-structured data."
        rationale:    "Mature ecosystem, strong JSONB performance, team expertise."
        consequences: ["All persistence goes through PostgreSQL", "No separate document store needed"]
    }
}
```

CUE validates this at compile time: missing fields, invalid status values, and malformed IDs are all caught before commit.

## Installation

```
module: "quicue.ca/kg@v0"
```

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

## What makes this different

CUE's type system gives properties that are hard to get from traditional knowledge management:

1. **Knowledge conflicts are type errors.** If two teams assert contradictory facts about the same decision, CUE unification fails at build time — not silently at read time.

2. **Federation without infrastructure.** Merging knowledge across projects is a CUE import, not a service call. `cue vet` catches conflicts. No shared database needed.

3. **Progressive refinement.** CUE's type lattice only narrows, never broadens. A field constrained to `"high" | "medium" | "low"` can't silently accept `"maybe"`. Evidence accumulates; it can't disappear.

4. **Schema evolution as a quality ratchet.** Adding a required field to `#Decision` makes every existing entry without it a validation error. The schema enforces improvement.

5. **Computed indexes.** Summary views (`by_status`, `by_confidence`) are CUE comprehensions over the data. They're always in sync because they're derived, never maintained.

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
| `#Derivation` | Data pipeline audit trails tracking how outputs relate to source data |
| `#Workspace` | Multi-repo topology mapping |
| `#Context` | Project identity and self-description |

### Aggregation (`aggregate/`)

| Type | Purpose |
|------|---------|
| `#KGIndex` | Computed summary, by_status, by_confidence views |
| `#KGLint` | Structural quality checks |
| `#Provenance` | PROV-O projection (decisions as provenance activities) |
| `#DatasetEntry` | DCAT projection (project as cataloged dataset) |
| `#FederatedCatalog` | DCAT catalog for federation results |
| `#Annotations` | Web Annotation projection (insights and rejected as annotations) |
| `#Prolog` | Prolog facts + inference rules for logic programming |
| `#Datalog` | Soufflé-compatible Datalog (guaranteed termination) |
| `#NTriples` | N-Triples — one triple per line, greppable RDF |
| `#Turtle` | Turtle — human-readable prefixed RDF |
| `#SKOSTaxonomy` | SKOS concept scheme from pattern categories |

## Linked Data & Logic Projections

The knowledge graph exports to W3C vocabularies and logic programming formats via CUE comprehensions. These projections make your knowledge graph interoperable with linked data tools, triplestores, and logic engines without replacing CUE as the source of truth.

### RDF & Semantic Web

| Projection | Standard | Use case | Export expression |
|-----------|----------|----------|-------------------|
| Provenance | [PROV-O](https://www.w3.org/TR/prov-o/) | Decision audit trails | `_provenance.graph` |
| Catalog | [DCAT](https://www.w3.org/TR/vocab-dcat-3/) | Data catalog registration | `_catalog.dataset` |
| Annotations | [Web Annotation](https://www.w3.org/TR/annotation-model/) | Insight/rejected as annotations | `_annotations.graph` |
| N-Triples | [RDF 1.1](https://www.w3.org/TR/n-triples/) | Bulk triplestore loading, grep/sort/diff | `_ntriples.triples` |
| Turtle | [RDF 1.1](https://www.w3.org/TR/turtle/) | Human-readable RDF, SPARQL endpoint import | `_turtle.document` |
| SKOS | [SKOS](https://www.w3.org/TR/skos-reference/) | Pattern taxonomy as browsable concept scheme | `_taxonomy.graph` |

### Logic Programming

| Projection | Runtime | Use case | Export expression |
|-----------|---------|----------|-------------------|
| Prolog | SWI-Prolog | Inference rules, transitive provenance queries | `_prolog.program` |
| Datalog | Soufflé | Guaranteed-terminating queries at scale | `_datalog.program` |

```bash
# Export decision audit trail as PROV-O JSON-LD
cue export .kb/ -e _provenance.graph --out json

# Register project in a data catalog
cue export .kb/ -e _catalog.dataset --out json

# Greppable RDF for unix pipelines
cue export .kb/ -e _ntriples.triples --out text

# Human-readable RDF for SPARQL endpoints
cue export .kb/ -e _turtle.document --out text

# Pattern taxonomy as SKOS JSON-LD
cue export .kb/ -e _taxonomy.graph --out json

# Logic programming (Prolog facts + inference rules)
cue export .kb/ -e _prolog.program --out text
```

## CLI

```
Usage: kg <command> [args...]

Commands:
  init              Scaffold .kb/ directory with imports
  add <type>        Create new entry (decision|pattern|insight|rejected)
  vet               Validate .kb/ content
  index [--full]    Export aggregated index as JSON
  query <expr>      Query via CUE expression
  lint              Knowledge quality checks
  settle            Check for conflicts, coverage gaps, referential integrity
  diff [ref]        Semantic changelog since git ref
  link <a> <b>      Cross-reference two entries
  graph [--dot]     Export relationships as JSON or DOT
  fed <dirs...>     Federate multiple .kb/ directories
```

## Specification

The full specification (directory layout, type constraints, aggregation semantics, federation protocol) is published at [quicue.github.io/quicue-kg/spec.html](https://quicue.github.io/quicue-kg/spec.html).

JSON-LD vocabulary context: [quicue.github.io/quicue-kg/context.jsonld](https://quicue.github.io/quicue-kg/context.jsonld)

## Development

```bash
make all          # Run all checks
make e2e          # End-to-end tests (schemas, exports, CLI, cross-repo)
make validate     # Validate schemas only
make test-valid   # Run valid test instances
make test-invalid # Confirm invalid instances are rejected
```

## License

Apache-2.0
