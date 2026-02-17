# quicue.ca/cab — Change Advisory Board (CAB) Reports & Config

Impact analysis, blast radius, runbooks, and change governance workflows.

**Use this when:** You need to generate change management artifacts — impact reports, deployment runbooks, rollback plans — from your infrastructure graph. Useful for ITIL-style change processes or any team that reviews infrastructure changes before deployment.

## Overview

The CAB module generates reports from the dependency graph: which resources are affected by a change, what order to deploy in, how to roll back if something fails, and what risk level the change carries.

## Report Patterns

**Impact & Criticality** (`reports/impact_report.cue`):
- **#ImpactReport** — Analyze impact of multiple changed resources. Computes affected count per target, risk level (critical/high/medium/low/none), and priority review list. Generates markdown and JSON.
- **#BlastRadiusReport** — Deep analysis of single resource failure. Shows affected resources by layer, rollback/startup order, cascade depth, safe peers. Markdown with tables.
- **#CriticalityReport** — Rank all resources by dependents. Categories: critical (>10), high (6-10), medium (3-5), low (1-2), leaf (0).

**Deployment & Runbooks** (`reports/runbook.cue`):
- **#DeploymentRunbook** — Layer-by-layer deployment procedure with gating between layers. Verification checklist per layer, shutdown procedure, CAB approval section.
- **#RollbackPlan** — Rollback sequence if deployment fails at specific layer. Resources to rollback (deepest-first), safe resources, post-rollback verification checklist.
- **#MaintenanceRunbook** — Maintenance procedure for a single resource (restart, update, replace, remove). Pre-maintenance stops, maintenance steps, post-maintenance starts.

**Configuration** (`config/cab_config.cue`):
- **#CABConfig** — Global CAB workflow settings: schedule, approval requirements, artifact config, report format, notification channels.
- **#Schedule** — Nightly validation time, artifact retention days, analysis frequency, timezone.
- **#Approval** — Min approvers, required roles, auto-approve thresholds (low/medium/high/critical).
- **#ArtifactConfig** — Artifact naming, date format, timestamp inclusion, format (tar.gz/zip), include flags (configs, reports, source, git_history).
- **#ReportConfig** — Output format (markdown/html/json), detail level (summary/standard/verbose), include flags (change summary, impact, blast radius, runbook, rollback, redundancy).
- **#NotificationConfig** — Channels (email, slack, webhook) and triggers (validation failure, artifact ready, high risk, deployment events).

## Usage Example

```cue
import "quicue.ca/cab/reports@v0"
import "quicue.ca/cab/config@v0"

cabConfig: config.#CABConfig & {
	organization: "Acme Corp"
	environment: "production"
	approval: {min_approvers: 2, auto_approve_low_risk: true}
	reports: {include: {impact_analysis: true, blast_radius: true}}
}

impact: reports.#ImpactReport & {
	Graph: infraGraph
	ChangedResources: ["dns", "proxy"]
	Config: cabConfig
}
// impact.markdown, impact.json
```

## Files

- `reports/impact_report.cue` — Impact, blast radius, criticality reports
- `reports/runbook.cue` — Deployment, rollback, maintenance runbooks
- `config/cab_config.cue` — CAB configuration and metadata

## See Also

- `patterns/graph.cue` — #ImpactQuery, #BlastRadius (underlying patterns)
- `infra-graph` — UI that consumes CAB reports
