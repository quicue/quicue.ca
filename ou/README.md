# quicue.ca/ou — Operational Layer & Scoped Views

Role-based filtering, interaction contexts, and W3C Hydra JSON-LD API documentation.

**Use this when:** Different people need different views of the same infrastructure. Ops sees all actions, dev sees read-only commands, auditors see info only. Also use this when you want a self-describing API via W3C Hydra JSON-LD.

## Overview

The ou module narrows execution plans by operator role. The same underlying graph serves developers, operators, and auditors — each sees only the resources and actions appropriate to their role.

## Schemas

**Interaction Context** (`interaction.cue`):
- **#SessionScope** — Constrains visible resources by type, layer, and name filters. Absent fields mean no constraint.
- **#FlowPosition** — Where operator is in deployment sequence: current_layer and gate statuses (passed/pending/failed).
- **#InteractionCtx** — Core scoping pattern. Takes pre-computed bound resources and plan layers, narrows by role and scope, produces filtered view and flat command map.

**Operator Roles** (`roles.cue`):
- **#OperatorRole** — Base role schema with name and visible_categories (struct-as-set).
- **#Roles** — Predefined roles:
  - **ops** — Full access: info, connect, monitor, admin
  - **dev** — Read and connect only: info, connect
  - **readonly** — Information only: info

**Hydra Export** (`hydra.cue`):
- **#HydraContext** — Extends JSON-LD context with hydra namespace and rdfs.
- **#HydraOperation** — Executable operation on a resource (POST, title, description, provider, action, category, flags).
- **#HydraLink** — Navigable relationship to another resource.
- **#HydraClass** — Resource with operations and navigation links.
- **#ApiDocumentation** — Full Hydra API doc export from #InteractionCtx. Self-describing, traversable, complete.

## Usage Example

```cue
import "quicue.ca/patterns@v0"
import "quicue.ca/ou@v0"

// Compute execution plan (binding + graph + layers)
plan: patterns.#ExecutionPlan & {resources: ..., providers: ...}

// Scope for ops on DNS resources
ops_dns_session: ou.#InteractionCtx & {
	bound: plan.cluster.bound
	plan:  plan.plan
	role:  ou.#Roles.ops
	scope: {include_types: {DNSServer: true}}
}

// Scope for readonly on Layer 0 only
readonly_layer0: ou.#InteractionCtx & {
	bound: plan.cluster.bound
	plan:  plan.plan
	role:  ou.#Roles.readonly
	scope: {include_layers: {"0": true}}
	position: {current_layer: 0}
}

// Generate Hydra API doc
hydra_doc: {...}  // Full W3C Hydra JSON-LD from session
```

## Key Patterns

- **Struct-as-set for visible_categories**: Efficient O(1) membership checks during filtering.
- **Pre-resolved inputs**: Takes already-resolved binding and plan (not full #ExecutionPlan) to keep evaluation fast.
- **Type overlap matching**: Any resource @type that overlaps with visible types passes filter (not all-of, any-of).
- **Flat command map**: Quickly access resource→provider/action→command without traversal.

## Files

- `interaction.cue` — #InteractionCtx scoping logic
- `roles.cue` — Predefined operator roles
- `hydra.cue` — W3C Hydra JSON-LD export

## See Also

- `vocab/` — Core resource and action schemas
- `patterns/` — Execution plan (feeding ou)
- `server/` — FastAPI gateway that uses ou for CLI dispatch
