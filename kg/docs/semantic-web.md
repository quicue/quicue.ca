# Semantic Web & Linked Data

quicue exports infrastructure and knowledge as linked data across two layers: **quicue.ca** models what infrastructure *is* (resources, dependencies, operations), and **quicue-kg** captures *why* it exists (decisions, patterns, insights). Both export to W3C standard vocabularies. Together they form a semantic infrastructure platform where every resource and every decision is addressable, queryable, and machine-navigable.

## Two layers, one graph

```
┌─────────────────────────────────────────────────────────┐
│  quicue.ca — infrastructure modeling                     │
│                                                          │
│  vocab/context.cue     JSON-LD @context (quicue: IRIs)  │
│  patterns/shacl.cue    SHACL shapes for validation       │
│  ou/hydra.cue          Hydra API documentation           │
│  ou/activitystreams.cue  AS2 infrastructure change feed  │
│  examples/*/jsonld      JSON-LD infrastructure graph      │
├──────────────────────────────────────────────────────────┤
│  quicue-kg — knowledge capture                           │
│                                                          │
│  aggregate/provenance.cue   PROV-O audit trails          │
│  aggregate/catalog.cue      DCAT dataset registration    │
│  aggregate/annotation.cue   Web Annotation insights      │
│  aggregate/skos.cue         SKOS pattern taxonomy        │
│  aggregate/turtle.cue       Turtle RDF export            │
│  aggregate/ntriples.cue     N-Triples (greppable RDF)    │
│  aggregate/prolog.cue       Prolog inference rules        │
│  aggregate/datalog.cue      Datalog (guaranteed halt)     │
└──────────────────────────────────────────────────────────┘
```

The layers share namespace wiring. `vocab/context.cue` already includes `prov:`, `dcat:`, `oa:`, `as:`, and `sh:` prefixes — both layers export to the same IRI space. A SPARQL query can join infrastructure state with the decisions that shaped it.

## RDF in 60 seconds

RDF stores data as **triples**: subject-predicate-object statements.

```
<kg:ADR-001>  <rdf:type>        <kg:Decision> .
<kg:ADR-001>  <rdfs:label>      "Use PostgreSQL" .
<kg:ADR-001>  <prov:startedAt>  "2026-01-15" .
```

Every fact is one triple. Triples compose — merge two datasets by concatenating them. Subjects and predicates are IRIs; objects are IRIs or literals. Any tool that speaks RDF (SPARQL endpoints, Oxigraph, Jena, rdflib) consumes this directly.

---

## Infrastructure layer (quicue.ca)

### JSON-LD infrastructure graph

Every infrastructure resource exports as a JSON-LD node with typed IRIs and semantic relationships:

```bash
cue export ./examples/datacenter/ -e jsonld --out json
```

This produces an `@graph` where each resource has `@type` arrays, `depends_on` as IRI references, and metadata (ip, host, container_id). The `@context` from `vocab/context.cue` maps CUE field names to `quicue:` namespace IRIs, making the graph dereferenceable.

### SHACL shapes (`patterns/shacl.cue`)

SHACL (Shapes Constraint Language) validates RDF data the way CUE validates CUE data. `patterns/shacl.cue` generates `sh:NodeShape` definitions from the type registry:

- A base `quicue:ResourceShape` validates the generic resource structure
- Type-specific shapes (DNSServer, LXCContainer, Router, etc.) add property constraints: datatypes, cardinality, value restrictions

```bash
cue export -e shapes.graph --out json > shapes.jsonld
```

These shapes can validate infrastructure RDF in any SHACL processor — useful for external consumers who receive your JSON-LD exports and want to check them without CUE.

### Hydra API (`ou/hydra.cue`)

The [Hydra Core Vocabulary](https://www.hydra-cg.com/spec/latest/core/) makes APIs self-describing. `ou/hydra.cue` generates a `hydra:ApiDocumentation` where:

- Each resource type becomes a `hydra:Class` with `supportedOperation` (available actions) and `supportedProperty` (dependency links)
- Operations carry metadata: HTTP method, provider, action name, idempotent/destructive flags
- Navigation follows IRI links — clients discover operations by traversing the graph

The operator frontend (`ops.quicue.ca`) consumes this to render an interactive explorer. The API at `api.quicue.ca` serves it as `application/ld+json`.

```bash
cue export ./examples/datacenter/ -e datacenter_hydra --out json
```

### ActivityStreams 2.0 (`ou/activitystreams.cue`)

Maps operator sessions to [ActivityStreams 2.0](https://www.w3.org/TR/activitystreams-core/) for infrastructure change feeds:

| Action category | AS2 activity type |
|----------------|-------------------|
| deploy | `as:Create` |
| lifecycle | `as:Update` |
| monitoring, diagnostic | `as:View` |
| shutdown | `as:Delete` |

Output is an `as:OrderedCollection` of activities, each with actor (operator role), object (resource), and instrument (provider/action). Feed subscribers get a machine-readable change log.

```bash
cue export -e feed.stream --out json
```

---

## Knowledge layer (quicue-kg)

### Projection architecture

All kg projections live in `aggregate/` and share the same input contract:

```cue
#SomeProjection: {
    index: #KGIndex          // Input: the computed index
    graph: { ... }            // Output: structured data
    summary: { ... }          // Metadata: counts, stats
}
```

CUE comprehensions iterate over the index and emit structured output. Projections are one-way: CUE `.kb/` files are the source of truth. You never edit the RDF — you edit CUE and re-export.

### RDF serializations

Three wire formats for the same RDF data model:

| Format | Type | Best for |
|--------|------|----------|
| **N-Triples** | `#NTriples` | `grep`, `sort`, `diff`, bulk triplestore loading |
| **Turtle** | `#Turtle` | Human reading, SPARQL endpoint import |
| **JSON-LD** | `#Provenance` | Web APIs, browser consumption |

```bash
# Greppable RDF — one triple per line, fully expanded IRIs
cue export .kb/ -e _ntriples.triples --out text | grep 'prov#Activity'

# Human-readable RDF with prefixes
cue export .kb/ -e _turtle.document --out text

# JSON-LD for web consumption
cue export .kb/ -e _provenance.graph --out json
```

### Semantic vocabularies

| Projection | Standard | Purpose | Export |
|-----------|----------|---------|--------|
| **PROV-O** | [W3C Provenance](https://www.w3.org/TR/prov-o/) | Decision audit trails | `_provenance.graph` |
| **DCAT** | [Data Catalog](https://www.w3.org/TR/vocab-dcat-3/) | Project catalog registration | `_catalog.dataset` |
| **Web Annotation** | [W3C Annotation](https://www.w3.org/TR/annotation-model/) | Insights as annotations | `_annotations.graph` |
| **SKOS** | [Knowledge Org](https://www.w3.org/TR/skos-reference/) | Pattern taxonomy | `_taxonomy.graph` |

**SKOS** maps pattern categories to `skos:Concept` top concepts and patterns to narrower concepts:

```bash
cue export .kb/ -e _taxonomy.graph --out json   # JSON-LD
cue export .kb/ -e _taxonomy.turtle --out text   # Turtle
```

### Logic programming

Facts + inference rules make knowledge computable:

| Projection | Runtime | Terminates? |
|-----------|---------|-------------|
| **Prolog** | SWI-Prolog | No (Turing-complete) |
| **Datalog** | Souffl&eacute; | Yes (guaranteed) |

Both include 6 inference rules: transitive provenance (`contributed`), trust levels, authority ranking, shared patterns, active decisions, and actionable insights.

```bash
# Prolog — interactive exploration
cue export .kb/ -e _prolog.program --out text > kb.pl
swipl -l kb.pl -g "shared_pattern(P, A, B), format('~w: ~w + ~w~n', [P, A, B]), fail."

# Datalog — guaranteed termination, compiles to C++
cue export .kb/ -e _datalog.program --out text > kb.dl
souffle kb.dl
```

**Prolog vs Datalog:** Use Prolog for recursive queries and interactive exploration. Use Datalog for CI automation and large datasets (Souffl&eacute; compiles to native code).

---

## How the layers connect

The infrastructure graph and knowledge graph share the same IRI space. This means you can query across both:

```sparql
# SPARQL: find decisions about resources with > 3 dependencies
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

The integration points:

| quicue.ca produces | kg consumes/extends |
|-------------------|-------------------|
| JSON-LD infrastructure graph | PROV-O ties decisions to resources |
| SHACL shapes for types | SKOS taxonomy for patterns |
| ActivityStreams change feed | Provenance chains for audit |
| Hydra API documentation | DCAT registers the project as a dataset |

`vocab/context.cue` is the bridge — it defines both `quicue:` (infrastructure) and `kg:` (knowledge) namespace mappings, plus all W3C vocabulary prefixes. Both layers import it.

## Choosing a format

| I want to... | Use |
|--------------|-----|
| Describe infrastructure resources as linked data | JSON-LD graph (quicue.ca) |
| Validate infrastructure RDF externally | SHACL shapes (quicue.ca) |
| Self-describing API for frontends | Hydra (quicue.ca) |
| Feed infrastructure changes to subscribers | ActivityStreams (quicue.ca) |
| Decision audit trails | PROV-O (kg) |
| Load into a triplestore | Turtle or N-Triples (kg) |
| Process with unix tools | N-Triples (kg) |
| Browse patterns as taxonomy | SKOS (kg) |
| Query provenance chains | Prolog or Datalog (kg) |
| Automated CI checks | Datalog (kg) |
| Register in a data catalog | DCAT (kg) |

## Namespaces

| Prefix | IRI | Layer | Vocabulary |
|--------|-----|-------|-----------|
| `quicue:` | `https://quicue.ca/vocab#` | Infrastructure | Resource types, fields, actions |
| `kg:` | `https://quicue.ca/kg#` | Knowledge | Decisions, patterns, insights |
| `prov:` | `http://www.w3.org/ns/prov#` | Both | Provenance |
| `dcat:` | `http://www.w3.org/ns/dcat#` | Both | Data catalog |
| `oa:` | `http://www.w3.org/ns/oa#` | Knowledge | Annotations |
| `skos:` | `http://www.w3.org/2004/02/skos/core#` | Knowledge | Taxonomy |
| `sh:` | `http://www.w3.org/ns/shacl#` | Infrastructure | Shape validation |
| `hydra:` | `http://www.w3.org/ns/hydra/core#` | Infrastructure | API description |
| `as:` | `https://www.w3.org/ns/activitystreams#` | Infrastructure | Activity feeds |
| `dcterms:` | `http://purl.org/dc/terms/` | Both | Dublin Core metadata |
| `rdfs:` | `http://www.w3.org/2000/01/rdf-schema#` | Both | RDF Schema |

JSON-LD contexts: [quicue.ca/vocab](https://quicue.ca/vocab) (infrastructure) | [kg.quicue.ca/context.jsonld](https://kg.quicue.ca/context.jsonld) (knowledge)
