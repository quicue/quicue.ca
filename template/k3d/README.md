# quicue-k3d

CUE patterns for k3d (Kubernetes in Docker) - local Kubernetes development clusters.

**Status:** [Active]
## Installation

```cue
import "quicue.ca/k3d@v0"
```
## Schemas

| Schema | Description |
|--------|-------------|
| `#ClusterActions` | k3d cluster operations: create, delete, start, stop |
| `#NodeActions` | Node management |
| `#RegistryActions` | Local registry operations |
| `#KubectlActions` | kubectl command wrappers |
| `#HelmActions` | Helm chart operations |
| `#DeploymentActions` | Kubernetes deployment operations |

## Patterns
- `adapter`
## Concepts
- kubernetes

---

Part of the [quicue](https://quicue.ca) ecosystem.
