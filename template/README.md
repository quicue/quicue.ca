# Provider Templates

29 provider templates implementing the `#ActionDef` vocabulary for real infrastructure tools.

## Templates by Category

### Virtualization & Containers
| Provider | Description |
|----------|-------------|
| `proxmox/` | Proxmox VE — VMs, LXC containers, storage, networking |
| `incus/` | Incus container and VM management |
| `docker/` | Docker containers, networks, volumes, compose |
| `kubevirt/` | KubeVirt virtual machines on Kubernetes |

### Orchestration & Deployment
| Provider | Description |
|----------|-------------|
| `kubernetes/kubectl/` | kubectl apply, rollout, scale |
| `k3d/` | k3d lightweight Kubernetes clusters |
| `argocd/` | Argo CD GitOps deployment |
| `dagger/` | Dagger CI/CD pipelines |
| `ansible/` | Ansible playbooks and ad-hoc commands |
| `awx/` | AWX/Tower job templates |
| `foreman/` | Foreman provisioning |
| `terraform/` | Terraform plan, apply, destroy |
| `opentofu/` | OpenTofu (Terraform fork) |

### Web & Reverse Proxy
| Provider | Description |
|----------|-------------|
| `caddy/` | Caddy web server and reverse proxy |
| `nginx/` | Nginx configuration and reload |
| `cloudflare/` | Cloudflare DNS and tunnels |

### DNS
| Provider | Description |
|----------|-------------|
| `powerdns/` | PowerDNS zones and records |
| `technitium/` | Technitium DNS server |

### Storage & Backup
| Provider | Description |
|----------|-------------|
| `pbs/` | Proxmox Backup Server |
| `restic/` | Restic backup snapshots |
| `postgresql/` | PostgreSQL databases and roles |

### Security & Identity
| Provider | Description |
|----------|-------------|
| `vault/` | HashiCorp Vault secrets and PKI |
| `keycloak/` | Keycloak identity and access management |

### Monitoring
| Provider | Description |
|----------|-------------|
| `zabbix/` | Zabbix monitoring hosts and triggers |
| `netbox/` | NetBox DCIM and IPAM |

### Network
| Provider | Description |
|----------|-------------|
| `vyos/` | VyOS router configuration |

### VMware
| Provider | Description |
|----------|-------------|
| `govc/` | govc VMware vSphere CLI |
| `powercli/` | PowerCLI VMware management |

### CI/CD
| Provider | Description |
|----------|-------------|
| `gitlab/` | GitLab CI/CD pipelines |

## Writing a New Template

See [docs/templates.md](../docs/templates.md) for the template authoring guide.

Each template provides `#ActionDef` implementations mapping infrastructure
operations to CLI commands with typed parameters.
