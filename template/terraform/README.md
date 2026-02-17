# terraform

Generate Terraform JSON (`main.tf.json`) from quicue resource graphs.

Define resources once with platform-agnostic specs, attach platform targets, export valid Terraform.

## Supported Platforms

| Platform | Terraform Provider | Pattern |
|----------|-------------------|---------|
| Proxmox VE | `bpg/proxmox` | `proxmox_virtual_environment_vm` |
| KubeVirt | `hashicorp/kubernetes` | `kubernetes_manifest` |

## Usage

```cue
import "quicue.ca/template/terraform"

resources: {
    "my-vm": terraform.#Compute & {
        name:   "my-vm"
        cpu:    4
        memory: "8Gi"
        disk:   "50Gi"
        proxmox: node: "pve-node-1"
    }
}

tf: terraform.#TerraformOutput & {Resources: resources}
```

```bash
cue export ./my-infra -e tf.output --out json > main.tf.json
terraform init && terraform plan
```

## Multi-Platform

Resources can target multiple platforms simultaneously:

```cue
"core-dns": terraform.#Compute & {
    name:   "core-dns"
    cpu:    2
    memory: "2Gi"
    disk:   "20Gi"
    proxmox: node: "pve-alpha"
    kubevirt: namespace: "kube-system"
}
```

Query platform distribution:

```bash
cue export -e tf.summary --out json
# {"proxmox": 3, "kubevirt": 2, "mirrored": 1, ...}

cue export -e tf.mirrored --out json
# ["core-dns"]
```

## Run Demo

```bash
cue export ./template/terraform/examples -e tf.output --out json
cue export ./template/terraform/examples -e tf.summary --out json
```
