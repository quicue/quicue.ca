# VCF Migration Example

Provider-agnostic migration planning from Nutanix/ESXi to VMware VCF,
with a built-in exit path to Proxmox VE.

## What This Demonstrates

1. **Side-by-side providers** — Same 5 VMs bound to both `govc` (VMware) and `proxmox` simultaneously. 65 resolved commands, zero changes to resource definitions.

2. **Charter-driven gates** — 7 migration gates across 4 phases with DAG ordering. CUE computes what's satisfied, what's missing, and what gate to work on next.

3. **Resource classification** — Comprehension that buckets every resource into vmware-bound, portable, containerizable, or shared-service. 5/6 workloads are portable.

4. **Graph + VizData** — Full dependency graph with topology, depth, roots, leaves. VizData export for sid-demo visualization.

## Files

| File | What |
|------|------|
| `resources.cue` | 11 resources: vCenter, Nutanix, F5, ESXi hosts, Dell target, 5 VMs |
| `providers.cue` | govc + proxmox provider declarations, #BindCluster |
| `charter.cue` | #InfraCharter with 7 gates: inventory → validate → pilot → wave → cutover → exit-ready |
| `classify.cue` | Migration classification comprehension |
| `graph.cue` | Graph, gap analysis, VizData, output composition |

## Commands

```bash
# Migration summary (the money output)
cue eval ./examples/vcf-migration/ -e migration_summary --out json -c=false

# Side-by-side provider commands for each VM
cue eval ./examples/vcf-migration/ -e output --out json -c=false

# Gap analysis (charter satisfaction)
cue eval ./examples/vcf-migration/ -e gaps.gate_status --out json -c=false

# Resource classification
cue eval ./examples/vcf-migration/ -e classification.summary --out json -c=false

# SHACL validation report (W3C)
cue eval ./examples/vcf-migration/ -e gaps.shacl_report --out json -c=false

# EARL evaluation report (W3C)
cue eval ./examples/vcf-migration/ -e gaps.earl_report --out json -c=false

# VizData for graph explorer
cue eval ./examples/vcf-migration/ -e vizData --out json -c=false
```

## Key Insight

The provider is a dial, not a decision. Adding `proxmox` took 15 lines.
Removing VMware takes zero lines — just stop using the govc provider.
Your resources, your graph, your charter — all unchanged.
