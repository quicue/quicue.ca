# quicue-incus

Incus provider for quicue. Implements action patterns for containers, VMs, profiles, networks, storage, and clusters.

**Status:** [Active]
## Installation

```cue
import "quicue.ca/incus@v0"
```
## Schemas

| Schema | Description |
|--------|-------------|
| `#ContainerActions` | Container operations via incus |
| `#VMActions` | Virtual machine operations |
| `#ProfileActions` | Profile management |
| `#NetworkActions` | Network configuration |
| `#StorageActions` | Storage pool operations |
| `#ClusterActions` | Cluster management |

## Patterns
- `adapter`

---

Part of the [quicue](https://quicue.ca) ecosystem.
