# quicue.ca

Model infrastructure as a dependency graph. Get deployment plans, blast radius, executable commands, and documentation — all computed from one `cue export`.

## The idea

You declare resources with types and dependencies:

```cue
dns: #Resource & {
    "@type":     {LXCContainer: true, DNSServer: true}
    depends_on:  {router: true}
    host:        "node-1"
    container_id: 101
}
```

You declare providers that serve certain types:

```cue
proxmox: #ProviderDecl & {
    types:    {LXCContainer: true, VirtualMachine: true}
    registry: proxmox_actions
}
```

quicue.ca does the rest at compile time:

- **Binding**: `dns` has type `LXCContainer`, Proxmox serves `LXCContainer` — match. Every `{host}` and `{container_id}` placeholder resolves from the resource's fields. Missing field? Type error, not a runtime surprise.
- **Graph analysis**: dependency layers, transitive closure, blast radius, single points of failure — all computed from `depends_on` edges.
- **Deployment planning**: ordered layers with gates, rollback sequences, startup/shutdown order.
- **Export**: JSON, Jupyter notebooks, Rundeck jobs, Bash scripts, MkDocs wiki, JSON-LD — all from one evaluation.

No runtime. No state file. No plugins. CUE validates everything simultaneously, and the output is plain JSON.

## Prerequisites

- [CUE](https://cuelang.org/docs/introduction/installation/) v0.15.4 or later

## Quick start

```bash
git clone https://github.com/quicue/quicue.ca.git
cd quicue.ca

# Validate schemas
cue vet ./vocab/ ./patterns/

# Run the datacenter example (30 resources, 29 providers, 654 resolved commands)
cue eval ./examples/datacenter/ -e output.summary

# What breaks if the router goes down?
cue eval ./examples/datacenter/ -e output.impact.\"router-core\"

# Export the full execution plan
cue export ./examples/datacenter/ -e output --out json
```

## What it computes

| Pattern | What it answers |
|---------|-----------------|
| `#InfraGraph` | Dependency layers, transitive closure, topology |
| `#BindCluster` | Which providers match which resources, resolved commands |
| `#ImpactQuery` | "What breaks if X goes down?" |
| `#BlastRadius` | Change impact with rollback order |
| `#SinglePointsOfFailure` | Resources with no redundancy |
| `#HealthStatus` | Simulated failure propagation |
| `#ExecutionPlan` | All of the above, unified into deployment layers with gates |

See the [Pattern Catalog](patterns.md) for the full list.

## Providers (29)

| Category | Providers |
|----------|-----------|
| Compute | proxmox, govc, powercli, kubevirt |
| Container/Orchestration | docker, incus, k3d, kubectl, argocd |
| CI/CD | dagger, gitlab |
| Networking | vyos, caddy, nginx |
| DNS | cloudflare, powerdns, technitium |
| Identity/Secrets | vault, keycloak |
| Database | postgresql |
| DCIM/IPAM | netbox |
| Provisioning | foreman |
| Automation | ansible, awx |
| Monitoring | zabbix |
| IaC | terraform, opentofu |
| Backup | restic, pbs |

Each provider is a CUE package under `template/` with type matching and action definitions. See the [Template Guide](templates.md) for how to write your own.

## Example output

The datacenter example defines 30 resources across 7 dependency layers. Here's what quicue.ca produces from that — a deployment wiki, layer by layer, with resolved commands per resource.

**[See the generated datacenter deployment wiki →](example/index.md)**

## License

Apache 2.0
