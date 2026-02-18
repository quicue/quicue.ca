# quicue.ca

Model it in CUE. Validate by unification. Export to whatever the world expects.

## What this is

You declare resources — nodes in a graph — with types and dependencies. CUE computes the rest: dependency layers, transitive closure, blast radius, deployment plans, linked data exports. The gap between your constraints and your data IS the remaining work. When `cue vet` passes, you're done.

```cue
dns: #Resource & {
    "@type":     {LXCContainer: true, DNSServer: true}
    depends_on:  {router: true}
    host:        "node-1"
    container_id: 101
}
```

No runtime. No state file. No plugins. CUE validates everything simultaneously, and the output is plain JSON.

## Two modules

| Module | What it models | What it answers |
|--------|---------------|-----------------|
| **[quicue.ca/patterns](patterns.md)** | Resources, dependencies, operations | What exists? What depends on what? What breaks if X goes down? |
| **[quicue.ca/kg](knowledge-graph.md)** | Decisions, patterns, insights, rejected approaches | Why does it exist? What was decided? What failed? |

Both export to [W3C linked data standards](linked-data.md) — JSON-LD, PROV-O, DCAT, SHACL, SKOS, and more. The infrastructure graph and the knowledge graph share a single IRI space.

## Not just infrastructure

The graph patterns are domain-agnostic. `#BlastRadius`, `#ImpactQuery`, `#SinglePointsOfFailure`, and `#DeploymentPlan` don't know what domain they're in. "What breaks if X goes down?" works whether X is a DNS server, a construction phase, or a research gene.

| Domain | What the graph models | Live |
|--------|----------------------|------|
| IT infrastructure | 30 servers, containers, and services across 7 dependency layers | [datacenter example](example/index.md) |
| Construction management | Deep retrofit work packages for 270-unit Ottawa Community Housing | [CJLQ explorer](https://rfam.cc/cjlq/) |
| Energy efficiency | 17-service processing platform for Ontario Greener Homes | [Greener Homes](https://rfam.cc/cjlq/#greener-homes) |
| Real estate operations | Transaction pipelines, referral networks, compliance workflows | [maison-613](https://maison613.quicue.ca/) |
| Biomedical research | 95 genes across 16 databases — funding gap analysis for NIDCR | [lacuene](https://lacuene.apercue.ca/) |

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

# Export as JSON-LD
cue export ./examples/datacenter/ -e jsonld --out json
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
| `#DeploymentPlan` | Ordered layers with gates |
| `#ExecutionPlan` | All of the above, unified |

See the [Pattern Catalog](patterns.md) for the full list.

## Contract-via-unification

Verification IS unification. You write CUE constraints that must merge with the computed graph. If they can't unify, `cue vet` rejects everything:

```cue
// This must merge with the computed graph output.
// If docker isn't the root, or validation fails, cue vet rejects.
validate: valid: true
infra: roots: {"docker": true}
deployment: layers: [{layer: 0, resources: ["docker"]}, ...]
```

No assertion framework. No test runner. The contract IS CUE values. Unification IS the enforcement.

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

Each provider is a CUE package under `template/` with type matching and action definitions. See the [Template Guide](templates.md).

## Example output

The datacenter example defines 30 resources across 7 dependency layers.

**[See the generated datacenter deployment wiki →](example/index.md)**

## License

Apache 2.0
