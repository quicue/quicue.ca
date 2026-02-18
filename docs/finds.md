# Finds

Things I found building [quicue.ca](https://github.com/quicue/quicue.ca) — a CUE framework where everything is a projection of one typed dependency graph.

---

## It's one value

Every resource declares what it is (`@type`) and what it needs (`depends_on`). Both are struct-as-set:

```cue
"dns-internal": {
    "@type": {LXCContainer: true, DNSServer: true, CriticalInfra: true}
    depends_on: {"pve-node1": true}
    host:         "pve-node1"
    container_id: 100
}
```

`{Key: true}` as a set works because CUE merges structs. No duplicates, O(1) membership, composition is unification.

From 30 resources and two fields, `cue export` produces 72+ projections: deployment plans, rollback sequences, blast radius, 654 resolved CLI commands, Jupyter notebooks, Rundeck jobs, a wiki, JSON-LD, Hydra, DCAT, N-Triples, SHACL shapes, ODRL policies, D3 data, DOT, Mermaid. One evaluation, no pipeline.

## Type overlap as dispatch

Standard tools — Docker, Proxmox, Kubernetes, Ansible, Vault, ArgoCD — all expose typed operations on resources. Good CLI specs, uniform shape. The binding logic is one comprehension:

```cue
// patterns/bind.cue
let _matched = [
    for tname, _ in provider.types
    if resource["@type"][tname] != _|_ {tname},
]
if len(_matched) > 0 {
    (pname): (#BindActions & {
        "registry": provider.registry
        "resource": resource
    }).actions
}
```

A provider declares `types: {LXCContainer: true}`. A resource declares `"@type": {LXCContainer: true, DNSServer: true}`. Binding is `resource["@type"][tname] != _|_`.

That DNS server matches Proxmox (serves LXCContainer) *and* PowerDNS (serves DNSServer) simultaneously. No registration, no interface declaration.

Provider swapping is a type-set change. Replace `LXCContainer` with `DockerContainer` and Docker binds instead of Proxmox — the set intersection changed, so the dispatch changed. This is why 29 providers work without 29 special cases.

## Transitive closure from unification

"What are ALL the ancestors of this resource?" In a procedural language, that's BFS. In CUE:

```cue
// patterns/graph.cue
_ancestors: {
    [_]: true
    if _hasDeps {
        for d, _ in _deps {
            (d): true
            resources[d]._ancestors
        }
    }
}
```

Six lines. Declares a struct shape, adds direct parents, unifies with each parent's ancestors. CUE resolves the fixpoint — the struct expands until merging produces no new keys, then stops.

I wrote "include your parents' ancestors" and CUE figured out the termination. The code credits the "rogpeppe pattern." Whether this was designed for or emergent, it lets you write graph algorithms as value declarations.

## Every query is already computed

Once `_ancestors` exists, impact analysis is one comprehension:

```cue
// patterns/graph.cue
affected: {
    for rname, r in Graph.resources
    if r._ancestors[Target] != _|_ {(rname): true}
}
```

"Which resources have Target in their ancestor set?" That's the entire implementation of "what breaks if this goes down."

Blast radius wraps it and adds rollback ordering. Criticality ranking counts downstream dependents. SPOF detection finds nodes whose failure cascades widest. Each is a comprehension over the same `_ancestors`.

There is no query planner, no index, no runtime. `cue export` produces every answer at eval time.

Consequence: **if every answer is known at build time, the API is a file server.** The project serves 727 pre-computed JSON files from a CDN. No server, no database. CUE comprehensions enumerate all possible queries, so the static API is just those answers as files.

## Constraints are values

Instead of assertions that check output, I write CUE values that must unify with the output:

```cue
// examples/devbox/verify.cue
package devbox

validate: valid: true
infra: roots: {"docker": true}
deployment: layers: [{layer: 0, resources: ["docker"]}, ...]
impact_docker: affected: {
    for name, _ in _resources if name != "docker" {
        "\(name)": true
    }
}
```

Same package as the computation. If the graph produces `validate: valid: false`, unification with `true` is bottom. `cue vet` fails. No assertion framework — the language is one.

The charter module generalizes this: declare what "done" looks like (required resources, gates, type coverage), and `#GapAnalysis` computes the delta. The gap is the remaining work. The backlog is a CUE value.

## The W3C stack is more projections

The same graph produces a full semantic web pipeline. Each W3C format is one more CUE definition over the same resources:

| Format | What it produces | W3C spec |
|--------|-----------------|----------|
| JSON-LD | `@graph` with typed IRIs, `dependsOn` links, `@context` | JSON-LD 1.1 |
| Hydra | Role-scoped API docs: `supportedOperation` from bound actions | Hydra Core |
| DCAT 3 | `dcat:Catalog` with `dcat:Dataset` per resource | DCAT 3 |
| N-Triples | One triple per line — `rdf:type`, `dependsOn` edges | RDF 1.1 |
| SHACL | Node shapes from the type registry — validates RDF data | SHACL |
| ODRL | Machine-readable access policies per resource | ODRL 2.2 |
| ActivityStreams | Change feeds — deploy→`as:Create`, shutdown→`as:Delete` | AS 2.0 |

No converters, no export pipelines. Each takes `#InfraGraph`, produces the target vocabulary's JSON-LD shape. They compose because they share input. They're correct because CUE validates structure at eval time.

Inside CUE, comprehensions are the query layer. Outside CUE — when the data joins external systems — SPARQL and triplestores add value. The N-Triples and JSON-LD exports are the bridge.

## Package scoping as a knowledge base

CUE packages are directory-scoped. We use this for a multi-graph knowledge base:

```
.kb/
├── manifest.cue       # Topology via #KnowledgeBase
├── decisions/         # PROV-O
├── insights/          # Web Annotation
├── patterns/          # SKOS
└── rejected/          # PROV-O
```

Each subdirectory is an independent CUE package. A schema violation in `decisions/` can't poison `patterns/`. The directory structure is the ontology. The root manifest declares which graphs exist and what W3C vocabulary each maps to.

We didn't build a knowledge base framework. We organized files into directories and let CUE's module system handle the isolation.

## It works across domains

Same `#InfraGraph`, same `#ImpactQuery`, same `#Charter` — four domains:

| Domain | Graph | Shape |
|--------|-------|-------|
| IT infrastructure | 30 resources, 29 providers, 654 commands | Service topology |
| Construction PM | 18 CMHC deep retrofit work packages | Project delivery |
| Energy efficiency | 17-service Greener Homes platform | Platform topology |
| Real estate | Transaction pipeline, compliance tracker | Workflow graph |

A resource is a typed node with dependencies. Whether it's a Linux container or a construction work package doesn't matter — the patterns compute the same things: depth, ancestors, impact, deployment order, critical path.

The PM sees schedule phases. The platform engineer sees deployment layers. Same code, same `cue export`.

---

[github.com/quicue/quicue.ca](https://github.com/quicue/quicue.ca) | [demo](https://demo.quicue.ca) | [static API](https://api.quicue.ca) | [docs](https://docs.quicue.ca) | [kg spec](https://kg.quicue.ca)
