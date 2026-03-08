# What We Learned from SHACL 1.2

SHACL 1.2 and CUE both constrain typed data at the schema level. SHACL runs against a triple store at runtime. CUE evaluates at build time and exports static artifacts. We looked at Kurt Cagle's [SHACL 1.2 repositories](https://github.com/kurtcagle) — a complete pipeline from schema to validation to export — and mapped each piece to what we already had. This is what fell out.

Cagle's repos are one implementation. SHACL itself is a W3C Recommendation (2017) with broad adoption — TopBraid, Stardog, GraphDB, Amazon Neptune, government linked data platforms. We chose these repos because they cover the full SHACL pipeline — schema, validation, conversion, export — in public code. We're comparing approaches, not ecosystems.

*SHACL 1.2 Working Draft as of March 2026. CUE v0.15.4.*

## Exit criteria: prose vs constraints

Cagle's [shacl-methodology](https://github.com/kurtcagle/shacl-methodology) defines a 10-phase design lifecycle. Each phase has prose exit criteria, Mermaid diagrams, and a human review checkpoint. Structured, sequential, thorough about what has to happen before you move on.

We had the same need — knowing when a project phase is "done" — and solved it with the [charter module](charter.md). A `#Charter` declares the scope of a project graph, and `#GapAnalysis` computes the delta:

```cue
import "quicue.ca/charter"

_charter: charter.#Charter & {
    name: "data-platform"
    scope: {
        total_resources: 18
        root:            "entry-point"
        required_types:  {Database: true, WebFrontend: true, ReverseProxy: true}
    }
    gates: {
        "schema-ready": {
            phase:    1
            requires: {"vocab-draft": true, "type-registry": true}
        }
        "data-loaded": {
            phase:      2
            depends_on: {"schema-ready": true}
            requires:   {"postgres": true, "redis": true, "import-pipeline": true}
        }
    }
}

gaps: charter.#GapAnalysis & {Charter: _charter, Graph: infra}
// gaps.complete == false  → gaps.missing_resources lists what's left
// gaps.next_gate == "schema-ready"  → lowest-phase unsatisfied gate
```

The methodology says "review the domain model with stakeholders before proceeding." The charter gate says `satisfied: false` until `vocab-draft` and `type-registry` exist in the graph. One requires a meeting, the other requires a file. In practice you need both — the file automates the check, not the conversation.

## Binding granularity: property vs entity

Cagle's [shaclify](https://github.com/kurtcagle/shaclify) maps SQL databases to RDF via SHACL shapes and TARQL. The binding mechanism is `sh:codeIdentifier` — each property shape maps to a column name in the source system:

```turtle
hr-shape:Department-name a sh:PropertyShape ;
    sh:path hr:departmentName ;
    sh:codeIdentifier "DepartmentName" ;
    sh:datatype xsd:string ;
    sh:minCount 1 ; sh:maxCount 1 .
```

Property-level binding. Each column gets an explicit shape declaration.

We bind at the entity level. A resource declares its semantic types via `@type`, and the type registry resolves structural requirements:

```cue
#Resource: {
    name:        #SafeID
    "@type":     {[#SafeLabel]: true}
    depends_on?: {[#SafeID]: true}
    ...
}
```

`sh:codeIdentifier` maps individual fields across system boundaries — the right tool for ETL and integration. `@type` classifies entire entities and lets CUE unification propagate constraints from the type registry — the right tool for infrastructure where entities are the natural unit. Different binding granularity for different problems.

## Schema conversion

Cagle's [shaclConverter](https://github.com/kurtcagle/shaclConverter) converts OWL ontologies, XSD schemas, and JSON Schema into SHACL 1.2 shapes.

We have the same problem — foreign schemas need adapters — and solve it with Python scripts that map to the minimum interface:

| Adapter | Input | Output |
|---|---|---|
| `tools/openapi2cue.py` | OpenAPI spec | CUE provider templates (`#ActionDef` registry) |
| `tools/cyclonedx2graph.py` | CycloneDX SBOM JSON | `#Graph` with Kahn's depth precompute |
| `tools/gitlab-ci2graph.py` | `.gitlab-ci.yml` | `#Graph` (stages + jobs + DAG edges) |

Every adapter maps to `{name, @type, depends_on}` — the minimum interface. Once data is in that shape, all graph patterns, W3C projections, and the charter module work without modification.

## Domain graphs

Cagle's [contextGraph](https://github.com/kurtcagle/contextGraph) models a meeting ontology with 11 classes, 13 intent types, and RDF provenance chains — SHACL shapes constrain domain vocabulary with cardinality at each level.

We model the same kind of thing — typed nodes with domain vocabulary and dependency edges — but type checking happens at `cue vet` time, not at triple-store ingestion time:

| Domain Graph | Nodes | Edges | Charter Gates |
|---|---|---|---|
| NHCF deep retrofit | 18 | 27 | 5 DAG gates across 8 phases |
| Greener Homes processing | 17 | 25 | 5 capability gates across 6 layers |
| Transaction pipeline | 16 | 22 | 6 deal gates |
| Compliance tracker | 12 | 18 | 4 obligation gates |
| Datacenter example | 30 | 61 | Full topology with SPOF analysis |

Same structure — a typed dependency graph with domain vocabulary. The difference is when validation happens: after loading (SHACL) or before any output (CUE).

## W3C projections

We generate W3C-standard outputs from a single `#Graph` definition. Each projection is a CUE file that comprehends over the graph and emits a different format:

| Projection | CUE Source | W3C Standard |
|---|---|---|
| SHACL shapes | `patterns/shacl.cue` | [SHACL](https://www.w3.org/TR/shacl/) |
| Data catalog | `patterns/dcat.cue` | [DCAT 3](https://www.w3.org/TR/vocab-dcat-3/) |
| N-Triples | `patterns/ntriples.cue` | [N-Triples](https://www.w3.org/TR/n-triples/) |
| Access policies | `patterns/odrl.cue` | [ODRL 2.2](https://www.w3.org/TR/odrl-model/) |
| API documentation | `ou/hydra.cue` | [Hydra](https://www.hydra-cg.com/spec/latest/core/) |
| Gap reports | `charter/charter.cue` | [EARL](https://www.w3.org/TR/EARL10-Schema/) + SHACL |

Adding a projection means writing a new CUE file — the source graph doesn't change. In Cagle's ecosystem, each standard gets a separate Turtle file. Both produce views from shared data — the difference is whether the projection is a CUE comprehension or a Turtle document. These six are the projections most relevant to this comparison. The full list is at [Linked Data](linked-data.md#infrastructure-projections).

## Evaluation architecture

```
SHACL:  Schema → Validator → Store → Query → Output
        (Turtle)  (pyshacl)  (Fuseki) (SPARQL)

CUE:    Schema → Output
        (CUE)    (cue export)
```

The SHACL stack has distinct components at each stage — separately deployable, separately testable, each with its own failure mode. In the CUE stack, one tool serves all three roles: the schema is the validator (unification), the query engine (comprehensions), and the exporter (JSON/YAML/text output).

This works when data changes at deployment cadence, queries are known in advance, and output formats are standard. We serve pre-computed JSON files from a CDN — every API endpoint was generated by `cue export`, no runtime dependencies.

## Where SHACL is the right tool

### Contextual truth

Cagle's [annotation-context-ontology](https://github.com/kurtcagle/annotation-context-ontology) addresses something CUE can't do natively. RDF-Star annotation syntax says "this fact is true in this context with this confidence":

```turtle
dragon:Smaug animal:hasLength 8
    ~ _:juvenile {|
        ctx:holdsIn ctx:JuvenileStage ;
        ctx:confidence 0.92
    |} .

dragon:Smaug animal:hasLength 45
    ~ _:adult {|
        ctx:holdsIn ctx:AdultStage ;
        ctx:confidence 0.98
    |} .
```

The same triple holds different values in different contexts, with explicit confidence scores. CUE's closed-world assumption means you model this as separate graphs per context — which works, but loses the explicit relationship between perspectives that RDF-Star provides as a language primitive.

For infrastructure, the closed-world assumption is usually what you want — a server either has 32GB of RAM or it doesn't. For knowledge representation, opinion modeling, or temporal reasoning, RDF-Star is more expressive.

### Runtime validation

SHACL validates data at ingestion time. If external parties submit data you don't control, pyshacl validates it on arrival. CUE validates at build time — it can't validate data submitted at request time without a runtime wrapper.

### Ad-hoc queries and federation

SPARQL handles queries you didn't anticipate and federates across multiple endpoints. CUE comprehensions precompute known queries over local data. If you need exploratory analysis across datasets you don't own, SPARQL is the right tool.

### Ecosystem maturity

SHACL is a W3C Recommendation (2017). TopBraid, Stardog, GraphDB, Amazon Neptune, and government linked data platforms have native support. CUE is younger, without standards-body backing. If your organization requires W3C compliance at every layer — not just the output format — SHACL's pedigree matters.

### Interoperability

The RDF ecosystem is vast — triplestores, SPARQL endpoints, linked data crawlers, ontology editors, reasoning engines. We export to RDF formats (N-Triples, JSON-LD, Turtle) which bridges the gap, but CUE itself isn't part of that ecosystem. Data flows out; tools that consume RDF natively can't consume CUE natively.

## SHACL 1.2 developments

SHACL 1.2 adds `sh:rootClass`, which lets a shape target the root of a class hierarchy — constraints propagate down the class tree, useful for taxonomy validation. Improved `sh:rule` semantics allow shapes to derive new triples during validation, blurring the line between constraint checking and inference. Both are relevant to ontology-heavy workflows where class hierarchies are the primary organizational unit.

## Where CUE hits limits

These are limits we've hit in practice — documented in our own [insights](insights/).

**Performance on large graphs.** CUE's recursive struct references don't memoize. Transitive closure on diamond-shaped DAGs grows exponentially — not with node count, but with fan-in. We hit this at 25 nodes with wide fan-in and solved it by precomputing depth/ancestors in Python. The CUE patterns work for graphs up to ~30 nodes with simple topologies; beyond that, precomputation is required. See [INSIGHT-001](insights/#insight-001-cue-transitive-closure-performance-is-topology-sensitive-not-node-count-limited).

**No runtime.** CUE evaluates once and produces output. No daemon, no query endpoint, no request handler. For infrastructure that changes at deployment cadence, this is fine. For live systems where state changes continuously, you need something that runs continuously.

**Closed-world assumption.** CUE assumes all data is present at evaluation time. It can't express uncertainty, partial knowledge, or multiple conflicting perspectives on the same entity without separate graph instances.

**Hidden-field evaluation gaps.** `cue vet` doesn't fully evaluate hidden (`_prefix`) fields. Test assertions on hidden values give false confidence — the assertion passes even with conflicting values. Critical invariants need public fields or explicit `cue eval -e` in CI. See [INSIGHT-005](insights/#insight-005-cue-vet-does-not-fully-evaluate-hidden-fields--test-assertions-on-hidden-values-give-false-confidence).

## Quick reference

| Capability | SHACL | CUE | quicue.ca |
|---|---|---|---|
| **Schema** | `sh:NodeShape` in Turtle | CUE definitions | `patterns/shacl.cue` generates SHACL from CUE |
| **Validation** | pyshacl / Jena (runtime) | `cue vet` (compile-time) | Unification catches violations at eval time |
| **Derived properties** | SPARQL CONSTRUCT | CUE comprehensions | `_depth`, `_ancestors`, `_dependents` precomputed |
| **Data binding** | `sh:codeIdentifier` (property) | `@type` (entity) | `vocab/types.cue` + `#TypeRegistry` |
| **Schema conversion** | OWL/XSD/JSON Schema → SHACL | Python adapters | `openapi2cue.py`, `cyclonedx2graph.py`, `gitlab-ci2graph.py` |
| **Query** | SPARQL (ad-hoc, federated) | CUE comprehensions (known, local) | Graph definitions precompute known queries |
| **W3C output** | Separate Turtle per standard | One CUE file per standard | SHACL, DCAT, N-Triples, ODRL, Hydra, EARL ([full list](linked-data.md#infrastructure-projections)) |
| **Runtime** | Triple store + SHACL processor | None | CDN serves pre-computed JSON |
| **Exit criteria** | Prose methodology | `#GapAnalysis` (machine-evaluable) | Charter gates in CUE |
| **Contextual truth** | RDF-Star (native) | Separate graphs (workaround) | No native equivalent |

## References

- [quicue.ca](https://github.com/quicue/quicue.ca) — CUE typed graph framework
- [apercue.ca](https://github.com/quicue/apercue) — domain-agnostic foundation (generic `#Graph`, W3C projections)
- [Kurt Cagle's repositories](https://github.com/kurtcagle) — SHACL 1.2 ecosystem
- [SHACL (W3C Recommendation)](https://www.w3.org/TR/shacl/) — Shapes Constraint Language 1.0
- [SHACL 1.2 Core (Working Draft)](https://www.w3.org/TR/shacl12-core/) — W3C Data Shapes Working Group
- [CUE Language Specification](https://cuelang.org/docs/reference/spec/) — Configure Unify Execute
