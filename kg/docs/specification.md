# Specification

The full quicue-kg specification covers directory layout, type constraints, aggregation semantics, W3C projection mappings, and the federation protocol.

**[Read the specification &rarr;](https://kg.quicue.ca/spec/index.html)**

The specification is a W3C-style ReSpec document covering:

- **Core types** — `#Decision`, `#Pattern`, `#Insight`, `#Rejected` with validation rules
- **Extension types** — `#Derivation`, `#Workspace`, `#Context`, `#SourceFile`, `#CollectionProtocol`, `#PipelineRun`
- **Aggregation** — `#KGIndex` computed views, `#KGLint` quality checks
- **W3C projections** — PROV-O, Web Annotation, DCAT, N-Triples, Turtle, SKOS, Prolog, Datalog
- **Federation protocol** — Cross-project discovery, merge semantics, conflict detection
- **JSON-LD context** — Namespace mappings and RDFS class hierarchy

## JSON-LD Context

The `kg:` namespace resolves to `https://quicue.ca/kg#`. The vocabulary context is available at:

- **Machine-readable:** [context.jsonld](https://kg.quicue.ca/context.jsonld)
- **Source:** `vocab/context.cue` in the repository
