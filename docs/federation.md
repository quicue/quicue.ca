# Federation

quicue.ca projects can federate their knowledge — decisions, patterns, dependencies — through CUE's type system. No external triplestore, no SPARQL endpoint, no contract test framework. CUE unification already is one.

## The .kb/ pattern

Each project that uses quicue.ca can maintain a `.kb/` directory — a multi-graph knowledge base tracking decisions, patterns, insights, and rejected approaches. Each graph type gets its own subdirectory, each an independent CUE package validated against its kg type:

```
your-project/
  .kb/
    cue.mod/module.cue       # Root module (manifest + metadata)
    manifest.cue              # #KnowledgeBase — declares graph topology
    decisions/
      cue.mod/module.cue      # Independent CUE module
      decisions.cue           # core.#Decision entries
    patterns/
      cue.mod/module.cue
      patterns.cue            # core.#Pattern entries
    insights/
      cue.mod/module.cue
      insights.cue            # core.#Insight entries
    rejected/
      cue.mod/module.cue
      rejected.cue            # core.#Rejected entries
```

Each subdirectory validates independently with `cue vet .` — directory structure IS the ontology.

## Dependency tracking

A downstream project's `deps.cue` records every definition it imports from quicue.ca, where it's used, and why:

```cue
_pattern_deps: {
    "#InfraGraph": {
        source:  "quicue.ca/patterns@v0"
        used_in: ["graph.cue"]
        purpose: "Dependency graph computation — depth, ancestors, topology"
    }
    "#BlastRadius": {
        source:  "quicue.ca/patterns@v0"
        used_in: ["projections.cue"]
        purpose: "Transitive impact scope of a resource failure"
    }
    // ...
}
```

This is documentation. The enforcement comes from CUE itself — if `#InfraGraph` changes a field name, every file that imports it fails to unify.

## Upstream tracking

quicue.ca's `.kb/downstream.cue` registers known consumers:

```cue
downstream: {
    grdn: {
        module:        "grdn.quicue.ca"
        description:   "Production homelab infrastructure graph"
        imports:       ["quicue.ca/vocab@v0", "quicue.ca/patterns@v0"]
        pattern_count: 14
        status:        "active"
    }
    "cmhc-retrofit": {
        module:        "quicue.ca/cmhc-retrofit@v0"
        description:   "Construction program management (NHCF, Greener Homes)"
        imports:       ["quicue.ca/patterns@v0"]
        pattern_count: 15
        has_kg:        true
        status:        "active"
    }
    "maison-613": {
        module:        "rfam.cc/maison-613@v0"
        description:   "Real estate operations — 7 graphs (transaction, referral, compliance, ...)"
        imports:       ["quicue.ca/patterns@v0"]
        pattern_count: 14
        has_kg:        true
        status:        "active"
    }
}
```

The `make check-downstream` target runs `cue vet` on all registered consumers. Rename a field in `#InfraGraph` and the downstream build breaks immediately — caught at build time, not discovered in production.

## Federation via unification

Multiple teams can maintain independent `.kb/` directories in their own repos. "Federating" them is just importing and letting CUE unify. If two teams assert contradictory values for the same field, `cue vet` produces a unification error. Conflicts are caught at build time, not discovered in a meeting six months later.

This works because CUE struct unification is:

- **Commutative** — order of import doesn't matter
- **Idempotent** — importing the same fact twice is harmless
- **Conflict-detecting** — contradictory values fail loudly

No merge strategy. No conflict resolution policy. The lattice handles it.

## The #Rejected type

The [quicue-kg](https://github.com/quicue/quicue-kg) framework defines four core types: `#Decision`, `#Pattern`, `#Insight`, and `#Rejected`.

`#Rejected` requires an `alternative` field — you can't record "we tried X and it failed" without saying where to go instead. In a federated setup, a failed experiment in one team's repo becomes a navigational signpost for another team before they start down the same path.

```cue
rejected_001: core.#Rejected & {
    id:          "rejected-001"
    title:       "VizExport pattern for graph rendering"
    date:        "2025-12-10"
    description: "Attempted #VizExport wrapper — CUE exports ALL public fields, causing 4x JSON bloat"
    reason:      "Public field leak: Graph field exported entire input struct (75KB vs 17KB)"
    alternative: "Use hidden _viz wrapper + explicit viz: {data: _viz.data, resources: ...}"
}
```

## Knowledge graph framework

The `.kb/` pattern is powered by [quicue-kg](https://kg.quicue.ca/), a standalone CUE module with:

- Four core types, three extension types, six aggregate projections
- W3C vocabulary projections (PROV-O, DCAT, SHACL, Web Annotations)
- A CLI tool (`kg`) with 11 commands
- A [formal specification](https://kg.quicue.ca/spec/)

See the [quicue-kg documentation](https://kg.quicue.ca/) for the full framework.
