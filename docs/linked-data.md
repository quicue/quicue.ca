# Linked Data

Model it in CUE. Validate by unification. Export to whatever the world expects.

quicue.ca produces W3C-compatible linked data from two layers: the **infrastructure layer** models what exists (resources, dependencies, operations), and the **knowledge layer** captures why it exists (decisions, patterns, insights). Both export to standard vocabularies. Both validate by `cue vet`.

## Two layers, one IRI space

```
┌─────────────────────────────────────────────────────────┐
│  Infrastructure layer (quicue.ca/patterns)               │
│                                                          │
│  vocab/context.cue          JSON-LD @context             │
│  patterns/shacl.cue         SHACL shapes                 │
│  ou/hydra.cue               Hydra API documentation      │
│  ou/activitystreams.cue     AS2 change feed              │
│  examples/*/jsonld           JSON-LD graph export         │
├──────────────────────────────────────────────────────────┤
│  Knowledge layer (quicue.ca/kg)                          │
│                                                          │
│  aggregate/provenance.cue   PROV-O audit trails          │
│  aggregate/catalog.cue      DCAT dataset registration    │
│  aggregate/annotation.cue   Web Annotation insights      │
│  aggregate/skos.cue         SKOS pattern taxonomy        │
│  aggregate/turtle.cue       Turtle RDF                   │
│  aggregate/ntriples.cue     N-Triples (greppable RDF)    │
│  aggregate/prolog.cue       Prolog inference rules        │
│  aggregate/datalog.cue      Datalog (guaranteed halt)     │
└──────────────────────────────────────────────────────────┘
```

The layers share namespace wiring. `vocab/context.cue` includes `prov:`, `dcat:`, `oa:`, `as:`, and `sh:` prefixes — both layers export to the same IRI space. A SPARQL query can join infrastructure state with the decisions that shaped it.

## Infrastructure projections

### JSON-LD graph

Every resource exports as a JSON-LD node with typed IRIs and dependency edges:

```bash
cue export ./examples/datacenter/ -e jsonld --out json
```

The `@context` from `vocab/context.cue` maps CUE field names to `quicue:` namespace IRIs.

### SHACL shapes

`patterns/shacl.cue` generates `sh:NodeShape` definitions from the type registry. External consumers can validate your JSON-LD exports without CUE:

```bash
cue export -e shapes.graph --out json > shapes.jsonld
```

### Hydra API

`ou/hydra.cue` generates self-describing API documentation. Each resource type becomes a `hydra:Class` with `supportedOperation` and `supportedProperty`.

### ActivityStreams 2.0

`ou/activitystreams.cue` maps operator sessions to AS2 activities for infrastructure change feeds.

## Knowledge projections

All knowledge projections live in `quicue.ca/kg`'s `aggregate/` package. They share the same input contract — a `#KGIndex` computed from `.kb/` files — and emit structured output.

CUE is the source of truth. You never edit the RDF — you edit CUE and re-export.

### RDF serializations

Three wire formats for the same data model:

| Format | Best for | Export |
|--------|----------|--------|
| **N-Triples** | `grep`, `sort`, `diff`, bulk triplestore loading | `cue export .kb/ -e _ntriples.triples --out text` |
| **Turtle** | Human reading, SPARQL endpoint import | `cue export .kb/ -e _turtle.document --out text` |
| **JSON-LD** | Web APIs, browser consumption | `cue export .kb/ -e _provenance.graph --out json` |

### Semantic vocabularies

| Projection | Standard | Purpose | Export |
|-----------|----------|---------|--------|
| **PROV-O** | [W3C Provenance](https://www.w3.org/TR/prov-o/) | Decision audit trails | `_provenance.graph` |
| **DCAT** | [Data Catalog](https://www.w3.org/TR/vocab-dcat-3/) | Project catalog registration | `_catalog.dataset` |
| **Web Annotation** | [W3C Annotation](https://www.w3.org/TR/annotation-model/) | Insights as annotations | `_annotations.graph` |
| **SKOS** | [Knowledge Org](https://www.w3.org/TR/skos-reference/) | Pattern taxonomy | `_taxonomy.graph` |

### Logic programming

Facts and inference rules make knowledge computable:

| Projection | Runtime | Terminates? | Best for |
|-----------|---------|-------------|----------|
| **Prolog** | SWI-Prolog | No (Turing-complete) | Interactive exploration |
| **Datalog** | Soufflé | Yes (guaranteed) | CI automation, large datasets |

Both include 6 inference rules: transitive provenance, trust levels, authority ranking, shared patterns, active decisions, and actionable insights.

```bash
# Prolog — interactive exploration
cue export .kb/ -e _prolog.program --out text > kb.pl
swipl -l kb.pl

# Datalog — compiles to C++, guaranteed termination
cue export .kb/ -e _datalog.program --out text > kb.dl
souffle kb.dl
```

## Cross-layer queries

The infrastructure graph and knowledge graph share the same IRI space:

```sparql
PREFIX kg: <https://quicue.ca/kg#>
PREFIX quicue: <https://quicue.ca/vocab#>
PREFIX prov: <http://www.w3.org/ns/prov#>

SELECT ?decision ?resource ?deps WHERE {
  ?decision a kg:Decision ; prov:startedAtTime ?date .
  ?resource quicue:depends_on ?dep .
}
GROUP BY ?decision ?resource
HAVING (COUNT(?dep) > 3)
```

## Namespaces

| Prefix | IRI | Layer |
|--------|-----|-------|
| `quicue:` | `https://quicue.ca/vocab#` | Infrastructure |
| `kg:` | `https://quicue.ca/kg#` | Knowledge |
| `prov:` | `http://www.w3.org/ns/prov#` | Both |
| `dcat:` | `http://www.w3.org/ns/dcat#` | Both |
| `oa:` | `http://www.w3.org/ns/oa#` | Knowledge |
| `skos:` | `http://www.w3.org/2004/02/skos/core#` | Knowledge |
| `sh:` | `http://www.w3.org/ns/shacl#` | Infrastructure |
| `hydra:` | `http://www.w3.org/ns/hydra/core#` | Infrastructure |
| `as:` | `https://www.w3.org/ns/activitystreams#` | Infrastructure |
| `dcterms:` | `http://purl.org/dc/terms/` | Both |

JSON-LD contexts: [`quicue:`](https://quicue.ca/vocab) | [`kg:`](https://kg.quicue.ca/context.jsonld)

## Choosing a format

| I want to... | Use |
|--------------|-----|
| Describe resources as linked data | JSON-LD graph |
| Validate RDF externally | SHACL shapes |
| Self-describing API for frontends | Hydra |
| Feed changes to subscribers | ActivityStreams |
| Decision audit trails | PROV-O |
| Load into a triplestore | Turtle or N-Triples |
| Process with unix tools | N-Triples |
| Browse patterns as taxonomy | SKOS |
| Query provenance chains | Prolog or Datalog |
| Automated CI checks | Datalog |
| Register in a data catalog | DCAT |
