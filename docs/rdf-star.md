# RDF-Star Annotations

RDF-Star is part of [RDF 1.2](https://www.w3.org/TR/rdf12-concepts/). It lets you make statements about statements: annotate individual triples with metadata like confidence scores, discovery methods, and timestamps.

Classic RDF can say "Server depends on Network." It cannot say "that dependency was discovered by nmap-scan with confidence 0.95." RDF-Star adds that capability.

## JSON-LD representation

RDF-Star uses `@annotation` blocks on object nodes in JSON-LD:

```json
{
  "@id": "urn:resource:caddy-proxy",
  "dcterms:requires": [
    {
      "@id": "urn:resource:vault",
      "@annotation": {
        "quicue:confidence": 0.99,
        "quicue:source": "tls-cert-chain",
        "quicue:method": "certificate-verification",
        "prov:generatedAtTime": "2026-03-01T09:00:00Z"
      }
    }
  ]
}
```

The `@annotation` block attaches metadata to the specific `caddy-proxy -> vault` edge without affecting the edge itself.

## CUE pattern

`patterns/rdf_star.cue` defines `#RDFStarAnnotation`, which takes a graph and per-edge annotations:

```cue
#RDFStarAnnotation: {
    Graph:   #InfraGraph
    BaseIRI: string | *"urn:resource:"
    Edges:   {[string]: #EdgeAnnotation} | *{}
    Rules:   [...#AnnotationRule] | *[]

    annotated_graph: { "@context": ..., "@graph": [...] }
    summary: { total_resources: ..., total_edges: ..., annotated_edges: ..., annotation_rules: ... }
}
```

## Two annotation modes

**Per-edge annotations** use the `Edges` map with `"source->target"` keys:

```cue
Edges: {
    "caddy-proxy->vault": {
        confidence: 0.99
        source:     "tls-cert-chain"
        method:     "certificate-verification"
    }
}
```

**Rule-based annotations** use the `Rules` list, matching by `@type` on source and target resources:

```cue
Rules: [{
    name:         "monitoring-edges"
    source_types: {MonitoringServer: true}
    annotation: {
        confidence: 0.9
        source:     "agent-discovery"
    }
}]
```

Per-edge annotations take precedence over rule-based ones.

## Datacenter wiring

```cue
_rdf_star: patterns.#RDFStarAnnotation & {
    Graph:   infra
    BaseIRI: _base
    Edges: {
        "caddy-proxy->vault": {
            confidence: 0.99
            source:     "tls-cert-chain"
            timestamp:  "2026-03-01T09:00:00Z"
            method:     "certificate-verification"
        }
        "gitlab-scm->postgresql": {
            confidence: 0.95
            source:     "connection-pool-check"
            timestamp:  "2026-03-01T10:00:00Z"
        }
        "k8s-prod->vault": {
            confidence: 0.8
            source:     "container-runtime-probe"
            timestamp:  "2026-03-02T14:00:00Z"
            notes:      "Secret injection via CSI driver"
        }
        "zabbix->postgresql": {
            confidence: 1.0
            source:     "config-file-parse"
            timestamp:  "2026-03-01T09:00:00Z"
            method:     "zabbix_server.conf DBHost"
        }
    }
}
rdf_star: _rdf_star.annotated_graph
```

## PROV-O vs RDF-Star

[PROV-O](https://www.w3.org/TR/prov-o/) handles graph-level provenance: who derived what from what, when a graph was generated, which agent was responsible. See [Context Events](context-events.md) for that pattern.

RDF-Star handles edge-level metadata: how confident are we in this specific dependency, what tool discovered it, when was it last verified. The two are complementary.

## Export

```bash
cue export ./examples/datacenter/ -e rdf_star --out json
```

The [shacl-comparison](shacl-comparison.md#contextual-truth) page discusses RDF-Star in the context of SHACL's limitations around contextual truth. This page covers the implementation.
