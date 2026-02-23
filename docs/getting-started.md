# Getting Started

Model 3 resources, bind 2 providers, get a deployment plan. Takes 5 minutes.

## Install CUE

```bash
# macOS
brew install cue-lang/tap/cue

# Linux (or see https://cuelang.org/docs/introduction/installation/)
curl -sSL https://github.com/cue-lang/cue/releases/latest/download/cue_v0.15.4_linux_amd64.tar.gz | tar xz
sudo mv cue /usr/local/bin/

# Verify
cue version
# cue version v0.15.4 or later
```

## Clone the repo

```bash
git clone https://github.com/quicue/quicue.ca.git
cd quicue.ca
```

## Define your resources

Create a file called `my-infra.cue` in the repo root:

```cue
package datacenter

import (
    "quicue.ca/vocab"
    "quicue.ca/patterns"
    "quicue.ca/template/proxmox/patterns:proxmox_patterns"
    "quicue.ca/template/powerdns/patterns:powerdns_patterns"
)

// Three resources: a router, a DNS server that depends on it,
// and a web server that depends on both.

_resources: {
    router: vocab.#Resource & {
        name:     "router"
        "@type":  {Router: true}
        ip:       "198.51.100.1"
        ssh_user: "admin"
    }
    dns: vocab.#Resource & {
        name:         "dns"
        "@type":      {LXCContainer: true, DNSServer: true}
        depends_on:   {router: true}
        host:         "pve-node1"
        container_id: 100
        ip:           "198.51.100.10"
    }
    web: vocab.#Resource & {
        name:         "web"
        "@type":      {LXCContainer: true, WebServer: true}
        depends_on:   {router: true, dns: true}
        host:         "pve-node1"
        container_id: 101
        ip:           "198.51.100.11"
    }
}

// Two providers: Proxmox manages LXC containers, PowerDNS manages DNS.

_providers: {
    proxmox: patterns.#ProviderDecl & {
        types:    {LXCContainer: true, VirtualMachine: true}
        registry: proxmox_patterns.#ProxmoxRegistry
    }
    powerdns: patterns.#ProviderDecl & {
        types:    {DNSServer: true}
        registry: powerdns_patterns.#PowerDNSRegistry
    }
}

// Compute everything.

execution: patterns.#ExecutionPlan & {
    resources: _resources
    providers: _providers
}

output: {
    summary:   execution.graph.metrics
    topology:  execution.graph.topology
    plan:      execution.plan
}
```

## Validate

```bash
cue vet my-infra.cue
```

No output means it passed. If you misspell a field or leave `depends_on` pointing at a resource that doesn't exist, CUE tells you.

## See what you built

```bash
# Dependency layers
cue eval my-infra.cue -e output.topology

# Deployment plan (ordered layers with gates)
cue eval my-infra.cue -e output.plan

# What commands does dns get?
cue eval my-infra.cue -e execution.cluster.bound.dns.actions

# Full JSON export
cue export my-infra.cue -e output --out json
```

The `dns` resource has type `LXCContainer` and `DNSServer`. Proxmox matches on `LXCContainer` — so `dns` gets container lifecycle commands (`pct status 100`, `pct start 100`, etc.). PowerDNS matches on `DNSServer` — so `dns` also gets zone management commands. All resolved from the resource's fields at compile time.

`web` has type `LXCContainer` and `WebServer`. Proxmox matches on `LXCContainer`. PowerDNS doesn't match (no `DNSServer` type). `web` gets container commands only.

`router` has type `Router`. Neither provider matches. It gets no resolved commands — you'd need a VyOS or similar provider for that.

## What breaks if DNS goes down?

```bash
cue eval my-infra.cue -e '(patterns.#ImpactQuery & {Graph: execution.graph, Target: "dns"})'
```

Answer: `web` is affected (it depends on `dns`). `router` is not (nothing depends on it from `dns`).

## Next steps

- **Add more resources and providers.** See the [datacenter example](example/index.md) for a 30-resource setup with 29 providers.
- **Write your own provider.** The [Template Guide](templates.md) walks through the process.
- **Understand the architecture.** The [Architecture](architecture.md) doc explains the four-layer model.
- **Browse the pattern catalog.** The [Pattern Catalog](patterns.md) lists every computation available.

## Clean up

Delete `my-infra.cue` when you're done — it was just for learning. Your real infrastructure definitions go in `examples/your-name/` or in a separate repo that imports `quicue.ca` as a CUE module.
