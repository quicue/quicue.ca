# quicue-docker

Docker provider for quicue. Implements action patterns for containers, Compose stacks, networks, volumes, and images.

**Status:** [Active]
## Installation

```cue
import "quicue.ca/docker@v0"
```
## Schemas

| Schema | Description |
|--------|-------------|
| `#ContainerActions` | Container operations: status, logs, shell, start, stop |
| `#ComposeActions` | Docker Compose stack operations: up, down, ps, logs |
| `#NetworkActions` | Network operations: inspect, connect, disconnect |
| `#VolumeActions` | Volume operations: inspect, remove |
| `#ImageActions` | Image operations: pull, inspect, remove |
| `#HostActions` | Docker host operations: info, ps, stats, prune |

## Patterns
- `adapter`
## Concepts
- docker-compose

---

Part of the [quicue](https://quicue.ca) ecosystem.
