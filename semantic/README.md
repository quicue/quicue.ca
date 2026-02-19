# Semantic Web Assets

Standalone W3C standards assets for infrastructure data provenance.
Load these into any SPARQL-capable triple store (Oxigraph, Fuseki, GraphDB, Stardog).

## Files

| File | Standard | Purpose |
|------|----------|---------|
| `provenance.ttl` | OWL + PROV-O | Ontology extension for data lineage |
| `provenance.shacl.ttl` | SHACL | Validation shapes with graduated severity |
| `queries/*.rq` | SPARQL 1.1 | Ready-to-use provenance queries |

## Provenance Ontology

Extends [W3C PROV-O](https://www.w3.org/TR/prov-o/) with infrastructure-specific classes:

- **SourceExport** (prov:Entity) — a data file from a source system
- **CollectionProtocol** (prov:Plan) — standing procedure for data collection
- **PipelineRun** (prov:Activity) — a pipeline execution event
- **NormalizerAgent** (prov:SoftwareAgent) — script that transforms source data
- **LatticeUnification** (prov:Activity) — CUE evaluation that merges per-source files

## SPARQL Queries

| Query | Returns |
|-------|---------|
| `provenance-lineage.rq` | Resource → activity → source chain ("where did this come from?") |
| `provenance-trust.rq` | HIGH/MEDIUM/UNKNOWN trust classification |
| `provenance-validated.rq` | Only CUE-validated resources with complete chains |
| `provenance-sources.rq` | Source systems with authority ranks and known gaps |
| `provenance-pipeline.rq` | Pipeline execution history |

## Quick Start (Oxigraph)

```bash
# Start Oxigraph
docker run -d -p 7878:7878 ghcr.io/oxigraph/oxigraph serve --bind 0.0.0.0:7878

# Load ontology
curl -X POST http://localhost:7878/store?default \
  -H "Content-Type: text/turtle" \
  --data-binary @semantic/provenance.ttl

# Load your JSON-LD data
curl -X POST http://localhost:7878/store?default \
  -H "Content-Type: application/ld+json" \
  --data-binary @data/infra-graph.jsonld

# Run a query
curl -X POST http://localhost:7878/query \
  -H "Content-Type: application/sparql-query" \
  -H "Accept: application/sparql-results+json" \
  --data-binary @semantic/queries/provenance-trust.rq
```

## SHACL Validation

The shapes use graduated severity:

- **Violation** — Broken provenance chain (source export missing hash, pipeline missing source reference)
- **Warning** — Missing timestamp on source export
- **Info** — Resource without `prov:wasGeneratedBy` (aspirational — not all resources have provenance yet)
