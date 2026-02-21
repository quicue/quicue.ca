# Examples

Working examples demonstrating quicue.ca patterns at increasing complexity.

## Quick Start

```bash
# Validate all examples
make examples

# Run a specific example
cue eval ./examples/datacenter/ -e output
```

## Examples

| Example | Description |
|---------|-------------|
| `3-layer/` | The three-layer architecture pattern — definition, template, value |
| `type-composition/` | Composing resource types from vocabulary primitives |
| `datacenter/` | Full infrastructure pipeline — 30 resources across 7 layers with dependency graph, execution plan, and deployment actions |
| `homelab/` | Reference homelab configuration — Proxmox nodes, Docker services, networking |
| `devbox/` | Single-machine Docker Compose stack — 14 services, provider binding, impact queries, criticality ranking |
| `graph-patterns/` | Graph analysis — dependency resolution, transitive closure, critical path |
| `drift-detection/` | Detect configuration drift between desired and actual state |
| `reconciliation/` | Multi-source data reconciliation — N sources observe, CUE lattice unifies, authority hierarchy resolves |
| `federation/` | Multi-site resource federation with cross-site dependencies |
| `docker-bootstrap/` | Bootstrap a Docker site from service templates with lifecycle management |
| `patterns-v2/` | Self-tracking project charter — CUE comprehensions as compile-time queries, gap analysis drives remaining work |
| `showcase/` | The quicue.ca site itself modeled as a dependency graph with 6 sequential delivery gates |
| `wiki-projection/` | Generate documentation from infrastructure definitions |
| `toon-export/` | Export infrastructure data in visualization-ready formats |
| `sbom/` | CycloneDX SBOM → dependency graph — software supply chain as typed graph with SPOF analysis |
| `ci/` | GitLab CI pipeline → dependency graph — stages, jobs, and DAG edges as typed graph |

## Progression

1. Start with **`3-layer/`** to understand the definition → template → value architecture
2. Try **`type-composition/`** to see how resource types compose
3. Explore **`datacenter/`** for a complete real-world pipeline
4. Use **`graph-patterns/`** for dependency analysis techniques
5. Study **`reconciliation/`** for multi-source data merging patterns
6. See **`patterns-v2/`** for charter-driven project tracking
7. Try **`sbom/`** for external spec import — CycloneDX SBOM as a typed graph
8. Try **`ci/`** for CI/CD pipeline import — GitLab CI as a typed graph
