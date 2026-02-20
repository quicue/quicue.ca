# patterns-v2

Self-hosting example: quicue.ca tracks its own patterns-v2 work as a typed dependency graph.

## What this demonstrates

This example uses quicue.ca's own patterns to manage a batch of work — 13 tasks across 5 gates and 3 phases. The task graph is an `#InfraGraph`. The scheduling, gap analysis, compliance checking, and issue tracking are all computed from the same graph.

**Single-graph pattern (tag-based):**

- All tasks live in one graph with a `status` tag (`schema:actionStatus`)
- `progress` = comprehension filter extracting `status == "done"` tasks
- The gap between charter constraints and done tasks IS the remaining work
- No duplicate data — flip one field in `progress.cue` to mark work complete

This maps directly to ITIL change management: target state vs. current state, with the gap computed by CUE comprehensions.

## W3C alignment

| Vocabulary | Usage |
|-----------|-------|
| `schema:actionStatus` | Task lifecycle states (Potential → Active → Completed) |
| `dcterms:requires` | Dependency relationships (ISO 15836-2:2019) |
| `prov:wasDerivedFrom` | Tasks link to INSIGHT-010 via `derived_from` |
| `sh:ValidationReport` | Compliance results + gap analysis as SHACL reports |
| `time:Interval` | CPM scheduling as OWL-Time intervals with durations |

## Concepts exercised

| Domain | Concept |
|--------|---------|
| CUE | Fixpoint recursion, comprehension-as-query, tag-filtered views |
| quicue | Everything-is-a-projection, @type unification, struct-as-set |
| W3C | schema:actionStatus, dcterms:requires, sh:ValidationReport, time:Interval |
| ITIL | Change management: planned state -> current -> gap |
| SHACL | Charter gates as structural shape constraints |

## Usage

```bash
# What's left to do?
cue eval ./examples/patterns-v2/ -e gaps.unsatisfied_gates

# Gap analysis as SHACL report (W3C-compliant)
cue export ./examples/patterns-v2/ -e gaps.shacl_report --out json

# Critical path (which tasks block everything?)
cue eval ./examples/patterns-v2/ -e cpm.critical_sequence

# Per-task slack as OWL-Time intervals
cue eval ./examples/patterns-v2/ -e cpm.time_report

# Full dashboard
cue eval ./examples/patterns-v2/ -e summary

# Compliance meta-rules
cue eval ./examples/patterns-v2/ -e compliance.results

# Compliance as SHACL validation report
cue export ./examples/patterns-v2/ -e compliance.shacl_report --out json

# Project to GitLab issues
cue export ./examples/patterns-v2/ -e gitlab_issues --out json

# Topology layers
cue eval ./examples/patterns-v2/ -e plan.topology
```

## Completing tasks

Edit `progress.cue` — one line per task:

```cue
_tasks: "exercise-cycle-detector": status: "done"
```

Then re-run `cue eval -e summary` to see the gap shrink.

## Pushing to GitLab

When the GitLab instance is reachable:

```bash
cue export ./examples/patterns-v2/ -e gitlab_issues --out json | \
  jq -c '.[]' | while read issue; do
    glab issue create \
      --title "$(echo $issue | jq -r .title)" \
      --description "$(echo $issue | jq -r .description)" \
      --label "$(echo $issue | jq -r '.labels | join(",")')" \
      --weight "$(echo $issue | jq -r .weight)"
  done
```

## Tasks

| Phase | Gate | Tasks | Status |
|-------|------|-------|--------|
| 1 | exercising-tests | 7 exercise-* tasks | Pending |
| 1 | rename-audit | audit-validate-rename | Pending |
| 2 | compliance-wiring | wire-compliance-datacenter, wire-compliance-ci | Pending |
| 2 | gitlab-projection | create-gitlab-projection | Done |
| 3 | docs-update | update-patterns-docs, update-graph-patterns-readme | Done |

## Critical path

The longest chain (8 units total):

```
exercise-compliance-check (3) -> wire-compliance-datacenter (3) -> wire-compliance-ci (2)
```

All other tasks have slack (can be delayed without affecting total duration).
