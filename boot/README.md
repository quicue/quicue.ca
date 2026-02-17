# quicue.ca/boot — Bootstrap & Credential Collection

Patterns for bootstrapping infrastructure and collecting operational credentials.

**Use this when:** You're standing up infrastructure from scratch and need ordered provisioning with credential collection. Handles the "day zero" problem: creating resources in dependency order and gathering access credentials as you go.

## Overview

The boot module handles infrastructure initialization: ordering resources by dependency layer, generating bootstrap scripts, and collecting credentials from multiple sources (SSH, Docker exec, Kubernetes, local files).

## Schemas

**Bootstrap** (`resource.cue`):
- **#BootstrapResource** — Adds bootstrap-specific computed fields to any resource. Includes lifecycle commands (create, start, stop, restart, destroy, status), health checks, and credential collection config.
- **#BootstrapPlan** — Top-level plan with resources grouped by computed layer, execution order, and output scripts.

**Credentials** (`credentials.cue`):
- **#Collector** — Generic credential collector with method (ssh, docker, kubectl, file, command) and generated collection command.
- **#SSHCollector** — SSH-based credential collection: `ssh user@host 'command'`.
- **#DockerCollector** — Docker exec-based collection: `docker exec container command`.
- **#KubectlCollector** — Kubernetes-based collection with namespace, resource, optional jsonpath, and kubeconfig.
- **#FileCollector** — File read via cat (local or remote over SSH).
- **#CredentialBundle** — Output structure with metadata and collected credentials dict.

## Usage Example

```cue
import "quicue.ca/boot@v0"

plan: boot.#BootstrapPlan & {
	metadata: {name: "infra-init", environment: "prod"}
	resources: {
		pve_node: boot.#BootstrapResource & {
			name: "pve_node"
			lifecycle: {
				create: "proxmox-provision --host pve-node-1"
				status: "ssh root@pve-node-1 'pveversion'"
			}
			health: {command: "ssh root@pve-node-1 'pvesh get /nodes/localhost/status'"}
		}
	}
}

// Collect monitoring API token
monitoring_collector: boot.#SSHCollector & {
	name: "monitoring_token"
	host: "mon-server"
	user: "root"
	command: "cat /etc/monitoring/api-token"
}
```

## Files

- `resource.cue` — #BootstrapResource and #BootstrapPlan
- `credentials.cue` — Credential collectors and #CredentialBundle

## See Also

- `patterns/graph.cue` — Layer computation from dependency graph
- `examples/` — Practical bootstrap examples
