// PM Type Registry — Semantic types for IT project management
//
// Work items extend vocab.#Resource — a task graph IS a dependency graph.
// All existing graph patterns (#InfraGraph, #CriticalityRank, #DeploymentPlan,
// #SinglePointsOfFailure, #VizData) work unchanged on project work items.
//
// Usage:
//   import "quicue.ca/pm"
//
//   work_items: [Name=string]: pm.#WorkItem & { name: Name }
//
// Type Categories:
//   - Work breakdown: Task, Milestone, Phase, Deliverable, Decision
//   - Organization: Team, Stakeholder, Vendor
//   - Risk & Quality: Risk, Issue, Dependency
//   - IT-specific: ChangeRequest, Environment, ServiceWindow, Rollback

package pm

import "quicue.ca/vocab@v0"

// #WorkItem — base type for all PM work. Extends #Resource with
// schedule, effort, and status fields. The depends_on field drives
// the same graph analysis that infrastructure resources use.
#WorkItem: vocab.#Resource & {
	// Schedule
	duration_weeks?: number
	effort_hours?:   number
	start_date?:     string // YYYY-MM-DD
	end_date?:       string // YYYY-MM-DD

	// Ownership
	owner?: string
	team?:  string

	// Status tracking
	status?:       "not_started" | "in_progress" | "blocked" | "complete" | "cancelled"
	priority?:     "critical" | "high" | "medium" | "low"
	pct_complete?: int & >=0 & <=100

	// Cost
	budget?:      number
	actual_cost?: number

	// Risk
	risk_level?: "critical" | "high" | "medium" | "low"

	// Work item relationships (struct-as-set)
	blockers?:     {[vocab.#SafeID]: true}
	deliverables?: {[vocab.#SafeID]: true}

	// Narrative
	notes?: string
}

// ═══════════════════════════════════════════════════════════════════════════
// PM TYPE REGISTRY — what a work item IS
// ═══════════════════════════════════════════════════════════════════════════

#PMTypeRegistry: {[vocab.#SafeLabel]: vocab.#TypeEntry} & {
	// ── Work Breakdown ──────────────────────────────────────────
	Task: {
		description: "Atomic unit of work with owner, duration, and effort"
	}
	Milestone: {
		description: "Zero-duration checkpoint verifying gate conditions"
	}
	Phase: {
		description: "Container grouping work items (planning, execution, closeout)"
	}
	Deliverable: {
		description: "Tangible output — document, system, report, artifact"
	}
	Decision: {
		description: "Recorded decision point (ADR-style) with rationale"
	}

	// ── Organization ────────────────────────────────────────────
	Team: {
		description: "Responsible team or organizational unit"
	}
	Stakeholder: {
		description: "Person or group with interest, authority, or influence"
	}
	Vendor: {
		description: "External supplier, contractor, or service provider"
	}

	// ── Risk & Quality ──────────────────────────────────────────
	Risk: {
		description: "Identified risk with likelihood and impact assessment"
	}
	Issue: {
		description: "Active problem requiring resolution"
	}
	ExternalDependency: {
		description: "Cross-project, vendor, or approval dependency"
	}

	// ── IT-Specific ─────────────────────────────────────────────
	ChangeRequest: {
		description: "CAB/change management item for production changes"
	}
	Environment: {
		description: "Target environment — dev, staging, production"
	}
	ServiceWindow: {
		description: "Maintenance window constraint for change execution"
	}
	RollbackPlan: {
		description: "Documented rollback procedure for a change"
	}

	// Allow extension
	...
}

// #PMTypeNames — disjunction of all PM type names for validation
#PMTypeNames: or([for k, _ in #PMTypeRegistry {k}])

// #AllTypeNames — combined infra + PM type names
#AllTypeNames: vocab.#TypeNames | #PMTypeNames
