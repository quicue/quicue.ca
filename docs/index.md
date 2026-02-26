# quicue.ca

Model it in CUE. Validate by unification. Export to whatever the world expects.

## Overview

| Metric | Count |
|--------|-------|
| Modules | 12 |
| Decisions (ADRs) | 14 |
| KB Patterns | 14 |
| Insights | 14 |
| Semantic Types | 57 |
| Downstream Consumers | 3 |
| Deployed Sites | 7 |

## Modules

| Module | Layer | Description |
|--------|-------|-------------|
| [vocab](modules/vocab.md) | `definition` | Core schemas: #Resource, #Action, #TypeRegistry, #ActionDef |
| [patterns](modules/patterns.md) | `definition` | Algorithms: graph, bind, deploy, health, SPOF, viz, TOON, OpenAPI, validation |
| [templates](modules/templates.md) | `template` | 29 platform-specific providers, each a self-contained CUE module |
| [orche](modules/orche.md) | `orchestration` | Orchestration schemas: execution steps, federation, drift detection, Docker site bootstrap |
| [boot](modules/boot.md) | `orchestration` | Bootstrap schemas: #BootstrapResource, #BootstrapPlan, credential collectors |
| [wiki](modules/wiki.md) | `projection` | #WikiProjection — MkDocs site generation from resource graphs |
| [cab](modules/cab.md) | `reporting` | Change Advisory Board reports: impact, blast radius, runbooks |
| [ou](modules/ou.md) | `interaction` | Role-scoped views: #InteractionCtx narrows #ExecutionPlan by role, type, name, layer. Hydra W3C JSON-LD export. |
| [ci](modules/ci.md) | `ci` | Reusable GitLab CI templates for CUE validation, export, topology, impact |
| [server](modules/server.md) | `operations` | FastAPI execution gateway for running infrastructure commands |
| [charter](modules/charter.md) | `constraint` | Constraint-first project planning: declare scope, evaluate gaps, track gates. SHACL gap report projection. |
| [examples](modules/examples.md) | `value` | 17 working examples from minimal 3-layer to full 30-resource datacenter |

## Downstream Consumers

| Project | Domain | Patterns Used |
|---------|--------|---------------|
| [grdn](https://quicue.ca/project/grdn) | Production infrastructure graph — multi-node cluster with ZFS storage, networking, and container orchestration | 14 |
| [cmhc-retrofit](https://quicue.ca/project/cmhc-retrofit) | Construction program management (NHCF deep retrofit, Greener Homes processing platform) | 15 |
| [maison-613](https://rfam.cc/project/maison-613) | Real estate operations — 7 graphs (transaction, referral, compliance, listing, operations, onboarding, client) | 14 |

## Ecosystem Sites

| Site | Description |
|------|-------------|
| [docs](https://docs.quicue.ca) | MkDocs Material documentation site |
| [demo](https://demo.quicue.ca) | Operator dashboard — D3 graph, planner, resource browser |
| [api](https://api.quicue.ca) | Static API showcase — 727 pre-computed JSON endpoints |
| [cat](https://cat.quicue.ca) | DCAT 3 data catalogue |
| [kg](https://kg.quicue.ca) | Knowledge graph framework spec |
| [cmhc-retrofit](https://cmhc-retrofit.quicue.ca) | Construction program management showcase |
| [maison613](https://maison613.quicue.ca) | Real estate operations showcase |

## Quick Start

```bash
git clone https://github.com/quicue/quicue.ca.git
cd quicue.ca

# Validate schemas
cue vet ./vocab/ ./patterns/

# Run the datacenter example
cue eval ./examples/datacenter/ -e output.summary

# What breaks if the router goes down?
cue eval ./examples/datacenter/ -e output.impact."router-core"

# Export as JSON-LD
cue export ./examples/datacenter/ -e jsonld --out json
```

## License

Apache 2.0

---
*Generated from quicue.ca registries by `#DocsProjection`*