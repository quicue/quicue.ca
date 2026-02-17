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
| `datacenter/` | Full infrastructure pipeline — 30 resources across 7 layers with dependency graph, execution plan, and deployment actions |
| `homelab/` | Reference homelab configuration — Proxmox nodes, Docker services, networking |
| `graph-patterns/` | Graph analysis — dependency resolution, transitive closure, critical path |
| `drift-detection/` | Detect configuration drift between desired and actual state |
| `federation/` | Multi-site resource federation with cross-site dependencies |
| `type-composition/` | Composing resource types from vocabulary primitives |
| `3-layer/` | The three-layer architecture pattern — definition, template, value |
| `docker-bootstrap/` | Bootstrap a Docker site from service templates with lifecycle management |
| `wiki-projection/` | Generate documentation from infrastructure definitions |
| `toon-export/` | Export infrastructure data in visualization-ready formats |

## Progression

1. Start with **`3-layer/`** to understand the definition → template → value architecture
2. Try **`type-composition/`** to see how resource types compose
3. Explore **`datacenter/`** for a complete real-world pipeline
4. Use **`graph-patterns/`** for dependency analysis techniques
