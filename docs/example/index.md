# Example: Datacenter (30 resources)

!!! note "Generated output"
    Everything below was produced by `cue export ./examples/datacenter/` ([source](https://github.com/quicue/quicue.ca/tree/main/examples/datacenter)). All IPs use the RFC 5737 documentation range (198.51.100.0/24). Hostnames, container IDs, and credentials are example values.

## Summary

| Metric | Value |
|--------|-------|
| Resources | 30 |
| Dependency layers | 7 |
| Providers matched | 29 |
| Resolved commands | 654 |

## How binding works (small example)

`dns-internal` is declared as `{LXCContainer: true, DNSServer: true}` and depends on `router-core`. Three providers match by type overlap:

| Provider | Matched on | Actions |
|----------|-----------|---------|
| proxmox | `LXCContainer` | container lifecycle (start, stop, status, logs...) |
| powerdns | `DNSServer` | zone management via API |
| foreman | `LXCContainer` | provisioning queries |

Every command is fully resolved at compile time:

```
proxmox/pct_status    → ssh pve-node1 'pct status 100'
proxmox/pct_start     → ssh pve-node1 'pct start 100'
powerdns/zone_list    → curl -s -H 'X-API-Key: changeme' http://198.51.100.211:8081/api/v1/servers/localhost/zones
powerdns/zone_get     → curl -s -H 'X-API-Key: changeme' http://198.51.100.211:8081/api/v1/servers/localhost/zones/dc.example.com
foreman/host_list     → hammer host list
```

`{host}` resolved from `host: "pve-node1"`. `{container_id}` resolved from `container_id: 100`. `{ip}` resolved from `ip: "198.51.100.211"`. If any field were missing, that action would be silently skipped — the provider matched on type, but the specific action couldn't bind.

## Deployment layers

Resources deploy in dependency order. Each layer completes (gate) before the next begins.

| Layer | Resources | Total actions |
|-------|-----------|---------------|
| 0 | router-core | 13 |
| 1 | pve-node1, pve-node2, pve-node3, vcenter | 54 |
| 2 | dns-internal, backup-pbs | 48 |
| 3 | dns-external, netbox, foreman, vault, postgresql, docker-host, incus-cluster | 159 |
| 4 | keycloak, caddy-proxy, k3d-dev, k8s-prod, ansible-controller, zabbix, restic-offsite | 152 |
| 5 | nginx-web, kubevirt-vms, gitlab-scm, awx, opentofu-iac | 131 |
| 6 | argocd, gitlab-runner, dagger-ci, terraform-state | 97 |

## All 30 resources

| Resource | Layer | Types | Providers | Actions |
|----------|-------|-------|-----------|---------|
| router-core | 0 | Router, CriticalInfra | vyos | 13 |
| pve-node1 | 1 | VirtualizationPlatform, CriticalInfra | proxmox | 11 |
| pve-node2 | 1 | VirtualizationPlatform, CriticalInfra | proxmox | 11 |
| pve-node3 | 1 | VirtualizationPlatform | proxmox | 11 |
| vcenter | 1 | VirtualizationPlatform | govc, powercli | 21 |
| dns-internal | 2 | LXCContainer, DNSServer | proxmox, powerdns, foreman | 22 |
| backup-pbs | 2 | LXCContainer, BackupServer | proxmox, pbs, restic, foreman | 26 |
| dns-external | 3 | LXCContainer, DNSServer | proxmox, cloudflare, foreman | 21 |
| netbox | 3 | LXCContainer, DCIM | proxmox, netbox, foreman | 20 |
| foreman | 3 | LXCContainer, ProvisioningServer | proxmox, foreman | 17 |
| vault | 3 | LXCContainer, SecretManager | proxmox, vault, foreman | 26 |
| postgresql | 3 | LXCContainer, Database | proxmox, postgresql, foreman | 23 |
| docker-host | 3 | LXCContainer, DockerHost | proxmox, docker, foreman | 26 |
| incus-cluster | 3 | LXCContainer, ContainerOrchestrator | proxmox, incus, foreman | 26 |
| keycloak | 4 | LXCContainer, IdentityProvider | proxmox, keycloak, foreman | 24 |
| caddy-proxy | 4 | LXCContainer, ReverseProxy | proxmox, caddy, nginx, foreman | 33 |
| k3d-dev | 4 | DockerContainer, KubernetesCluster | docker, k3d, kubectl, kubevirt, argocd | 28 |
| k8s-prod | 4 | KubernetesCluster | k3d, kubectl, kubevirt, argocd | 17 |
| ansible-controller | 4 | LXCContainer, AutomationServer | proxmox, ansible, terraform, opentofu, foreman | 20 |
| zabbix | 4 | LXCContainer, MonitoringServer | proxmox, zabbix, foreman | 21 |
| restic-offsite | 4 | BackupServer | pbs, restic, ansible, terraform, opentofu | 9 |
| nginx-web | 5 | LXCContainer, WebServer | proxmox, caddy, nginx, foreman | 33 |
| kubevirt-vms | 5 | KubernetesWorkload, VirtualMachine | kubectl, kubevirt, argocd | 12 |
| gitlab-scm | 5 | LXCContainer, GitServer, CIServer | proxmox, gitlab, foreman | 18 |
| awx | 5 | LXCContainer, AutomationServer | proxmox, ansible, awx, terraform, opentofu, foreman | 37 |
| opentofu-iac | 5 | LXCContainer, IaCTool | proxmox, terraform, opentofu, foreman | 31 |
| argocd | 6 | KubernetesWorkload, GitOpsController | kubectl, argocd | 9 |
| gitlab-runner | 6 | LXCContainer, CIRunner | proxmox, gitlab, foreman | 18 |
| dagger-ci | 6 | DockerContainer, CIRunner | docker, dagger | 16 |
| terraform-state | 6 | LXCContainer, IaCTool | proxmox, terraform, opentofu, foreman | 54 |
