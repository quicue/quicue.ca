# Type Registry

57 semantic types for infrastructure resources. Types describe WHAT a resource IS, not what it can do.

## Types

| Type | Description |
|------|-------------|
| `LXCContainer` | Proxmox LXC container |
| `DockerContainer` | Docker container |
| `ComposeStack` | Docker Compose application stack |
| `VirtualMachine` | Virtual machine (Proxmox QEMU, VMware, etc.) |
| `DockerHost` | Docker daemon host |
| `KubernetesService` | Kubernetes workload |
| `VMwareCluster` | VMware vSphere / vCenter cluster |
| `Router` | Network router/firewall |
| `KubernetesCluster` | Kubernetes cluster (k3s, k8s, OpenShift) |
| `DNSServer` | DNS/name resolution server |
| `ReverseProxy` | HTTP/HTTPS reverse proxy |
| `VirtualizationPlatform` | Hypervisor node (Proxmox, VMware) |
| `SourceControlManagement` | Git server (Forgejo, GitLab, Gitea) |
| `Bastion` | SSH jump host / bastion server |
| `Vault` | Secrets management |
| `MonitoringServer` | Metrics/alerting server |
| `LogAggregator` | Log collection and aggregation |
| `DevelopmentWorkstation` | Developer machine |
| `GPUCompute` | GPU-enabled compute node |
| `AuthServer` | Authentication/identity provider |
| `LoadBalancer` | Load balancer / traffic distribution |
| `MessageQueue` | Message broker (RabbitMQ, Kafka, NATS) |
| `CacheCluster` | Distributed cache (Redis, Memcached) |
| `Database` | Database server (PostgreSQL, MySQL, MongoDB) |
| `SearchIndex` | Search engine (Elasticsearch, Meilisearch) |
| `HomeAutomation` | Home automation platform |
| `ObjectStorage` | S3-compatible object storage |
| `ContainerRegistry` | OCI/Docker registry |
| `TracingBackend` | Distributed tracing (Jaeger, Zipkin, Tempo) |
| `StatusMonitor` | Uptime/status monitoring |
| `CIRunner` | CI/CD job runner |
| `MediaServer` | Media streaming server |
| `PhotoManagement` | Photo library management |
| `AudiobookLibrary` | Audiobook server |
| `EbookLibrary` | Ebook server |
| `RecipeManager` | Recipe/meal planning |
| `TunnelEndpoint` | Network tunnel (Cloudflared, WireGuard, Tailscale) |
| `Network` | Network zone / address space |
| `EdgeNode` | Edge/remote site node |
| `APIServer` | API backend service |
| `WebFrontend` | Web frontend / UI server |
| `Worker` | Background job processor |
| `ScheduledJob` | Cron/scheduled task runner |
| `Region` | Geographic region / data center location |
| `AvailabilityZone` | Availability zone within a region |
| `SoftwareApplication` | Software application or service binary |
| `SoftwareLibrary` | Software library or package dependency |
| `SoftwareFramework` | Software framework (Spring, Django, Rails) |
| `SoftwareContainer` | Container image artifact (OCI, Docker) |
| `SoftwarePlatform` | Runtime platform (JVM, Node.js, .NET CLR) |
| `SoftwareFirmware` | Embedded firmware component |
| `SoftwareFile` | Single file artifact in SBOM |
| `OperatingSystem` | Operating system (Ubuntu, Alpine, Windows) |
| `CIPipeline` | CI/CD pipeline definition |
| `CIStage` | Stage within a CI/CD pipeline |
| `CIJob` | Individual job within a CI/CD stage |
| `CriticalInfra` | Critical infrastructure - extra monitoring/alerting |

## Usage

```cue
import "quicue.ca/vocab@v0"

myResource: vocab.#Resource & {
    "@type": {LXCContainer: true, DNSServer: true}
}
```

Types fall into three categories:

- **Implementation** (how it runs): `LXCContainer`, `VirtualMachine`, `DockerContainer`
- **Semantic** (what it does): `DNSServer`, `ReverseProxy`, `Database`
- **Classification** (operational tier): `CriticalInfra`

A resource can have multiple types. A Proxmox LXC running PowerDNS is `{LXCContainer: true, DNSServer: true}`.

---
*Generated from quicue.ca registries by `#DocsProjection`*