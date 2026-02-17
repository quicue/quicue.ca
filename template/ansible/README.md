# ansible

Config generators for Ansible, Prometheus, AlertManager, and Grafana from quicue resource graphs.

## Generators

| Generator | Output | Description |
|-----------|--------|-------------|
| `#AnsibleInventory` | Ansible inventory YAML | hosts + tag-based groups |
| `#PrometheusTargets` | `static_configs` | scrape targets with labels |
| `#AlertManagerRoutes` | routing tree | owner-based alert routing |
| `#GrafanaDashboard` | dashboard JSON | stat panels per resource |

## Usage

```cue
import "quicue.ca/template/ansible"

inventory: ansible.#AnsibleInventory & {Resources: myResources}
```

```bash
cue export ./my-infra -e inventory.all --out yaml > inventory.yml
ansible-playbook -i inventory.yml site.yml
```

## Example Output

```yaml
all:
  hosts:
    dns-server:
      ansible_host: 10.0.1.10
      ansible_user: root
      container_id: 100
      pve_node: pve-node-1
    git-server:
      ansible_host: 10.0.1.20
      ansible_user: git
      vmid: 200
      pve_node: pve-node-2
  children:
    DNSServer:
      hosts:
        dns-server: {}
    CriticalInfra:
      hosts:
        dns-server: {}
        web-proxy: {}
```

## Run Demo

```bash
cue export ./template/ansible/examples -e inventory.all --out yaml
cue export ./template/ansible/examples -e prometheus.targets --out json
cue export ./template/ansible/examples -e alertmanager.routes --out json
cue export ./template/ansible/examples -e grafana.dashboard --out json
```
