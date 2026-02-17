# Demo Output

Generated from `template/ansible/examples/demo.cue` and `template/terraform/examples/demo.cue`.

---

## Ansible Provider

### Inventory (`cue export -e inventory.all --out yaml`)

```yaml
hosts:
  dns-server:
    ansible_host: 10.0.1.10
    ansible_python_interpreter: /usr/bin/python3
    ansible_user: root
    container_id: 100
    pve_node: pve-node-1
  git-server:
    ansible_host: 10.0.1.20
    ansible_python_interpreter: /usr/bin/python3
    ansible_user: git
    pve_node: pve-node-2
    vmid: 200
  web-proxy:
    ansible_host: 10.0.1.30
    ansible_python_interpreter: /usr/bin/python3
    ansible_user: root
    container_id: 300
    owner: infra-team
    pve_node: pve-node-1
  dev-workstation:
    ansible_become: true
    ansible_host: 10.0.1.50
    ansible_port: 2222
    ansible_python_interpreter: /usr/bin/python3
    ansible_user: dev
    owner: dev-team
    pve_node: pve-node-3
    vmid: 500
  monitoring:
    ansible_host: 10.0.1.60
    ansible_python_interpreter: /usr/bin/python3
    ansible_user: root
    container_id: 600
    owner: infra-team
    pve_node: pve-node-2
children:
  owner_infra-team:
    hosts:
      web-proxy: {}
      monitoring: {}
  owner_dev-team:
    hosts:
      dev-workstation: {}
  node_pve-node-1:
    hosts:
      dns-server: {}
      web-proxy: {}
  node_pve-node-2:
    hosts:
      git-server: {}
      monitoring: {}
  node_pve-node-3:
    hosts:
      dev-workstation: {}
  DNSServer:
    hosts:
      dns-server: {}
  CriticalInfra:
    hosts:
      dns-server: {}
      web-proxy: {}
      monitoring: {}
  SourceControlManagement:
    hosts:
      git-server: {}
  ReverseProxy:
    hosts:
      web-proxy: {}
  DevelopmentWorkstation:
    hosts:
      dev-workstation: {}
  Monitoring:
    hosts:
      monitoring: {}
```

Auto-generated groups: `owner_<name>`, `node_<name>`, and tag-based groups.

### Prometheus Targets (`cue export -e prometheus.targets --out json`)

```json
[
  {
    "targets": ["10.0.1.10:9100"],
    "labels": {
      "environment": "homelab",
      "instance": "dns-server",
      "job": "homelab",
      "exporter": "node",
      "node": "pve-node-1",
      "tag_DNSServer": "true",
      "tag_CriticalInfra": "true"
    }
  },
  {
    "targets": ["10.0.1.10:9119"],
    "labels": {
      "environment": "homelab",
      "instance": "dns-server",
      "job": "homelab",
      "exporter": "bind",
      "node": "pve-node-1",
      "tag_DNSServer": "true",
      "tag_CriticalInfra": "true"
    }
  },
  {
    "targets": ["10.0.1.20:9100"],
    "labels": {
      "instance": "git-server",
      "exporter": "node",
      "node": "pve-node-2",
      "tag_SourceControlManagement": "true"
    }
  },
  {
    "targets": ["10.0.1.20:9168"],
    "labels": {
      "instance": "git-server",
      "exporter": "gitlab",
      "node": "pve-node-2",
      "tag_SourceControlManagement": "true"
    }
  }
]
```

Multi-exporter support: dns-server emits both `node:9100` and `bind:9119`. Resources with `monitoring.enabled: false` (dev-workstation) are excluded.

### AlertManager Config (`cue export -e alertmanager.config --out yaml`)

```yaml
route:
  receiver: default-receiver
  group_by: [alertname, instance]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - match:
        severity: critical
      receiver: critical-receiver
      repeat_interval: 1h
    - match:
        owner: infra-team
      receiver: infra-team-receiver
    - match:
        owner: dev-team
      receiver: dev-team-receiver
receivers:
  - name: default-receiver
  - name: critical-receiver
  - name: infra-team-receiver
    webhook_configs:
      - url: https://ntfy.example.com/infra-alerts
  - name: dev-team-receiver
    email_configs:
      - to: dev@example.com
inhibit_rules:
  - source_matchers: [alertname = NodeDown]
    target_matchers: [alertname = InstanceDown]
    equal: [node]
```

Auto-generated owner routes, critical tag escalation, and node-down inhibition.

### Grafana Dashboard (`cue export -e grafana.dashboard --out json`)

Structure (11 panels):

| Panel | Type | Description |
|-------|------|-------------|
| Status Overview | row | Section header |
| dns-server | stat | UP/DOWN indicator |
| git-server | stat | UP/DOWN indicator |
| web-proxy | stat | UP/DOWN indicator |
| dev-workstation | stat | UP/DOWN indicator |
| monitoring | stat | UP/DOWN indicator |
| Resource Details | row | Collapsed section |
| CPU Usage | timeseries | `node_cpu_seconds_total` by instance |
| Memory Usage | timeseries | Memory used percentage |
| Disk Usage | gauge | Root filesystem % with 70%/90% thresholds |
| Network I/O | timeseries | `node_network_receive/transmit_bytes_total` |

Template variables: `$node` (PVE node filter) and `$instance` (host filter).

---

## Terraform Provider

### Summary (`cue export -e tf.summary --out json`)

```json
{
  "proxmox": 4,
  "kubevirt": 3,
  "mirrored": 2,
  "proxmox_only": 2,
  "kubevirt_only": 1
}
```

### Terraform JSON Output (`cue export -e tf.output --out json`)

Selected resources showing key features (full output is ~550 lines):

#### Provider & Backend Configuration

```json
{
  "terraform": {
    "backend": {
      "s3": {
        "bucket": "terraform-state",
        "key": "infra/terraform.tfstate",
        "region": "us-east-1"
      }
    },
    "required_providers": {
      "kubernetes": { "source": "hashicorp/kubernetes", "version": ">=2.35.0" },
      "proxmox": { "source": "bpg/proxmox", "version": ">=0.66.0" }
    }
  },
  "provider": {
    "kubernetes": [{ "config_path": "~/.kube/config" }],
    "proxmox": [{
      "api_token": "terraform@pam!tf=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "endpoint": "https://pve-alpha.example.com:8006",
      "insecure": true,
      "ssh": [{
        "agent": true,
        "username": "root",
        "node": [
          { "name": "pve-alpha", "address": "10.0.0.10" },
          { "name": "pve-beta", "address": "10.0.0.11" }
        ]
      }]
    }]
  }
}
```

#### Proxmox VM: web-frontend (cloud-init + network + full features)

```json
{
  "name": "web-frontend",
  "node_name": "pve-beta",
  "vm_id": 200,
  "on_boot": true,
  "clone": { "vm_id": "9000" },
  "cpu": { "cores": 4, "type": "host" },
  "memory": { "dedicated": 8192 },
  "bios": "ovmf",
  "machine": "q35",
  "operating_system": { "type": "l26" },
  "serial_device": [{ "device": "socket" }],
  "boot_order": ["scsi0", "net0"],
  "agent": [{ "enabled": true, "trim": true }],
  "tags": ["web", "prod"],
  "startup": { "order": 2, "up_delay": 30 },
  "disk": [{
    "interface": "scsi0",
    "size": 50,
    "datastore_id": "local-lvm"
  }],
  "network_device": [{
    "bridge": "vmbr0",
    "model": "virtio",
    "vlan_id": 100
  }],
  "initialization": {
    "datastore_id": "local-lvm",
    "user_account": {
      "username": "deploy",
      "keys": ["ssh-ed25519 AAAA... admin@infra"]
    },
    "dns": { "servers": ["10.0.1.1", "1.1.1.1"] },
    "ip_config": [{
      "ipv4": {
        "address": "10.0.1.50/24",
        "gateway": "10.0.1.1"
      }
    }]
  }
}
```

#### Proxmox VM: gpu-worker (multi-disk + PCI passthrough)

```json
{
  "name": "gpu-worker",
  "node_name": "pve-alpha",
  "pool_id": "gpu-pool",
  "cpu": { "cores": 16, "type": "host" },
  "memory": { "dedicated": 65536 },
  "bios": "ovmf",
  "machine": "q35",
  "tags": ["gpu", "ml"],
  "startup": { "order": 1, "up_delay": 60, "down_delay": 30 },
  "disk": [
    {
      "interface": "scsi0",
      "size": 100,
      "datastore_id": "local-zfs",
      "cache": "writeback",
      "discard": "on",
      "iothread": true,
      "ssd": true
    },
    {
      "interface": "scsi1",
      "size": 500,
      "datastore_id": "ceph-pool",
      "discard": "on"
    }
  ],
  "network_device": [{ "bridge": "vmbr0", "model": "virtio" }],
  "hostpci": [{
    "device": "hostpci0",
    "mapping": "gpu-rtx4090",
    "pcie": true,
    "rombar": true
  }]
}
```

#### KubeVirt VM: web-frontend (cloud-init + network)

```json
{
  "manifest": {
    "apiVersion": "kubevirt.io/v1",
    "kind": "VirtualMachine",
    "metadata": { "name": "web-frontend", "namespace": "prod" },
    "spec": {
      "runStrategy": "Always",
      "instancetype": { "kind": "VirtualMachineInstancetype", "name": "u1.large" },
      "template": {
        "spec": {
          "domain": {
            "cpu": { "cores": 4 },
            "resources": { "requests": { "memory": "8Gi" } },
            "devices": {
              "disks": [
                { "name": "rootdisk", "disk": { "bus": "virtio" } },
                { "name": "cloudinit", "disk": { "bus": "virtio" } }
              ],
              "interfaces": [{ "name": "net0", "masquerade": {} }]
            }
          },
          "evictionStrategy": "LiveMigrate",
          "networks": [{ "name": "net0", "pod": {} }],
          "volumes": [
            { "name": "rootdisk", "dataVolume": { "name": "web-frontend-dv" } },
            { "name": "cloudinit", "cloudInitNoCloud": { "userData": "#cloud-config\n" } }
          ]
        }
      },
      "dataVolumeTemplates": [{
        "metadata": { "name": "web-frontend-dv" },
        "spec": {
          "storage": {
            "accessModes": ["ReadWriteOnce"],
            "resources": { "requests": { "storage": "50Gi" } },
            "storageClassName": "standard"
          },
          "source": { "blank": {} }
        }
      }]
    }
  }
}
```
