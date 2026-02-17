# drift-detection

Compare declared vs live infrastructure state, generate reconciliation plans.

## Key Concepts

- **`#ResourceState`** models declared and live state with drift classification
- **`#StateReport`** aggregates drift across an entire site with summary counts
- **`#ReconciliationPlan`** generates fix actions (create/update/remove) from drift data
- **`#DockerDriftDetector`** generates container-specific probe commands

## Drift Types

| Type | Meaning | Fix Action |
|------|---------|------------|
| `none` | Declared = Live | No action |
| `changed` | Running but config differs | Update |
| `missing` | Declared but not running | Create |
| `extra` | Running but not declared | Remove |

## Example Data

4 resources with all drift types represented:

- `dns-server` — in sync (no drift)
- `proxy` — changed (image `caddy:2.8` -> `caddy:2.9`)
- `monitoring` — missing (declared but not found)
- `legacy-app` — extra (running but not declared)

## Run

```bash
# Full output with fix plan
cue eval ./examples/drift-detection/ -e output

# Just the summary
cue eval ./examples/drift-detection/ -e output.summary

# Generated fix commands
cue eval ./examples/drift-detection/ -e output.fix_plan

# Docker probe commands
cue eval ./examples/drift-detection/ -e output.docker_probes
```

## Output

```
summary:
  total:   4
  in_sync: 1
  missing: 1
  changed: 1
  extra:   1
```

Feed live state from monitoring APIs (Zabbix, Prometheus) into `#ResourceState` to detect drift automatically.
