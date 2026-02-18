# quicue.ca — what fell out of one CUE value

A dependency graph. 30 resources. Two fields: `@type` and `depends_on`. Both are `{Key: true}` structs. One `cue export` produces 72+ projections.

Four things that surprised me.

---

### 1. Type overlap is dispatch

Providers declare what types they serve. Resources declare what they are. Binding is one bottom test:

```cue
let _matched = [
    for tname, _ in provider.types
    if resource["@type"][tname] != _|_ {tname},
]
```

A resource with `{LXCContainer: true, DNSServer: true}` matches both Proxmox and PowerDNS simultaneously. Swap `LXCContainer` for `DockerContainer` and Docker binds instead. 29 providers, zero special cases.

### 2. Transitive closure is six lines

```cue
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

I wrote "include your parents' ancestors." CUE resolved the fixpoint. Graph algorithms as value declarations.

### 3. Every query is already a field

```cue
affected: {
    for rname, r in Graph.resources
    if r._ancestors[Target] != _|_ {(rname): true}
}
```

Impact analysis, blast radius, SPOF detection, criticality ranking — each is one comprehension over `_ancestors`. `cue export` produces every answer. The API is 727 static JSON files on a CDN.

### 4. Constraints are values, not assertions

```cue
validate: valid: true
infra: roots: {"docker": true}
impact_docker: affected: {
    for name, _ in _resources if name != "docker" {
        "\(name)": true
    }
}
```

Same package as the computation. If the graph disagrees, unification is bottom. `cue vet` fails. No test framework — the language is one.

---

Same patterns serve IT infrastructure (30 resources, 654 commands), construction PM (18 CMHC work packages), energy efficiency (17-service platform), and real estate workflows. The domain is in the data, not the framework.

The graph also produces JSON-LD, Hydra, DCAT, N-Triples, SHACL, and ODRL — each is one more CUE definition over the same resources.

[github.com/quicue/quicue.ca](https://github.com/quicue/quicue.ca) | [demo](https://demo.quicue.ca) | [api](https://api.quicue.ca) | [docs](https://docs.quicue.ca)
