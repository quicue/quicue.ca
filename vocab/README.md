# quicue.ca/vocab — Core Infrastructure Vocabulary

Core schemas for infrastructure-as-graph: resources, actions, and semantic types.

**Use this when:** You're defining infrastructure resources and need the base type system. Every other module in quicue.ca builds on these schemas.

## Overview

The vocabulary module provides the foundational definitions for representing infrastructure as a directed acyclic graph (DAG). Resources are the nodes; actions are provider-specific commands you can run against them; types classify what a resource is so providers can match against it.

Types describe *what* a resource is (DNSServer, LXCContainer), not what you can do with it — that's determined by which providers match the resource's types.

## Schemas

- **#Resource** (`resource.cue`) — Core resource definition with identity, network, hosting, dependencies, and extensible fields. Uses `@type` as struct-as-set for O(1) membership checks.
- **#Action** (`actions.cue`) — Base schema for all executable actions. Defines operational metadata: timeout, confirmation, idempotency, destructiveness, prerequisites.
- **#ActionDef** — Action definition with typed parameters and command templates. Enables compile-time parameter binding and validation.
- **#ActionRegistry** — Catalog of known actions (ping, ssh, container_status, node_status, proxy_routes, etc.) with explicit parameter contracts.
- **#TypeRegistry** (`types.cue`) — Semantic types for resources (DNSServer, ReverseProxy, VirtualMachine, LXCContainer, Vault, Database, etc.). Each type defines required fields and granted actions.
- **#ProviderMatch** — Declares what resource types a provider serves for action binding.

## Usage Example

```cue
import "quicue.ca/vocab@v0"

myResources: [Name=string]: vocab.#Resource & {
	name: Name
	"@type": {DNSServer: true, VirtualizationPlatform: true}
	ip: "10.1.1.5"
	ssh_user: "root"
	depends_on: {router: true, storage: true}
}

result: cue export . --out json
```

## Key Patterns

- **Struct-as-set**: `"@type": {[string]: true}` and `depends_on: {[string]: true}` provide O(1) membership and clean unification.
- **Generic field names**: container_id, vm_id, host, ssh_user work across providers. Providers map to platform-specific tools (Proxmox pct/qm, Docker, K8s, etc.).
- **Open schema**: Resources extend with domain-specific fields via `...`.
- **Parameter binding**: #ActionDef uses `from_field` to bind resource fields to action parameters at compile time — no runtime templates.

## Files

- `resource.cue` — #Resource schema
- `actions.cue` — #Action, #ActionDef, #ActionRegistry schemas
- `types.cue` — #TypeRegistry with semantic and implementation types
- `context.cue` — JSON-LD context for linked data export

## See Also

- `patterns/bind.cue` — Action binding (resolves #ActionDef against resources)
- `patterns/graph.cue` — Graph analysis built on #Resource
