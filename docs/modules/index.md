# Modules

12 modules organized by architectural layer.

| Module | Layer | Status | Description |
|--------|-------|--------|-------------|
| [vocab](vocab.md) | `definition` | active | Core schemas: #Resource, #Action, #TypeRegistry, #ActionDef |
| [patterns](patterns.md) | `definition` | active | Algorithms: graph, bind, deploy, health, SPOF, viz, TOON, OpenAPI, validation |
| [templates](templates.md) | `template` | active | 29 platform-specific providers, each a self-contained CUE module |
| [orche](orche.md) | `orchestration` | active | Orchestration schemas: execution steps, federation, drift detection, Docker site bootstrap |
| [boot](boot.md) | `orchestration` | active | Bootstrap schemas: #BootstrapResource, #BootstrapPlan, credential collectors |
| [wiki](wiki.md) | `projection` | active | #WikiProjection — MkDocs site generation from resource graphs |
| [cab](cab.md) | `reporting` | active | Change Advisory Board reports: impact, blast radius, runbooks |
| [ou](ou.md) | `interaction` | active | Role-scoped views: #InteractionCtx narrows #ExecutionPlan by role, type, name, layer. Hydra W3C JSON-LD export. |
| [ci](ci.md) | `ci` | active | Reusable GitLab CI templates for CUE validation, export, topology, impact |
| [server](server.md) | `operations` | active | FastAPI execution gateway for running infrastructure commands |
| [charter](charter.md) | `constraint` | active | Constraint-first project planning: declare scope, evaluate gaps, track gates. SHACL gap report projection. |
| [examples](examples.md) | `value` | active | 17 working examples from minimal 3-layer to full 30-resource datacenter |

---
*Generated from quicue.ca registries by `#DocsProjection`*