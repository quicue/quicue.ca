# Templates

12 modules include 33 provider templates across 13 categories. Each template teaches the system how to manage a specific platform.

## Categories

| compute | `proxmox`, `govc`, `powercli`, `kubevirt` |
| container | `docker`, `incus`, `k3d`, `kubectl`, `argocd` |
| cicd | `dagger`, `gitlab` |
| networking | `vyos`, `caddy`, `nginx` |
| dns | `cloudflare`, `powerdns`, `technitium` |
| identity | `vault`, `keycloak` |
| database | `postgresql` |
| dcim | `netbox` |
| provisioning | `foreman` |
| automation | `ansible`, `awx` |
| monitoring | `zabbix` |
| iac | `terraform`, `opentofu` |
| backup | `restic`, `pbs` |

## Directory Structure

```
template/<name>/
  meta/meta.cue          # Provider metadata and type matching
  patterns/<name>.cue    # Action registry
  examples/demo.cue      # Working example
  README.md
```

---
*Generated from quicue.ca registries by `#DocsProjection`*