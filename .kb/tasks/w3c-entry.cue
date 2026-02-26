// W3C Community Group entry plan — tracked as typed tasks.
//
// Each task validates against kg/core.#Task. Dependencies form a DAG
// that can be analyzed with the same graph patterns as any other
// quicue.ca resource graph.
package tasks

import "quicue.ca/kg/core@v0"

// ── Phase 0: Clean public repos ─────────────────────────────────

respec_cleanup: core.#Task & {
	id:       "respec-cleanup"
	title:    "Remove ReSpec from public repos"
	status:   "done"
	project:  "w3c-entry"
	priority: "high"
	date:     "2026-02-25"
	description: "Remove self-published ReSpec specs from apercue.ca and quicue.ca. Migrate prose to mtthdn/w3c-specs (private). Arrive at CGs with clean implementation repos, not unofficial spec cosplay."
	refs: {
		"INSIGHT-003": true
		"INSIGHT-008": true
	}
}

// ── Phase 1: Core use case report ───────────────────────────────

core_report: core.#Task & {
	id:       "core-report"
	title:    "Write core use case report"
	status:   "done"
	project:  "w3c-entry"
	priority: "high"
	date:     "2026-02-25"
	depends_on: {"respec-cleanup": true}
	description: "Compile-Time Linked Data: Full W3C Closure From a Single CUE Value. The foundational document that all group-specific submissions reference."
	"@type_tags": {
		"writing":  true
		"w3c":      true
		"strategy": true
	}
}

// ── Phase 2: Group-specific submissions ─────────────────────────

sub_kg_construct: core.#Task & {
	id:       "sub-kg-construct"
	title:    "KG-Construct CG submission"
	status:   "done"
	project:  "w3c-entry"
	priority: "high"
	depends_on: {"core-report": true}
	description: "Use case: CUE as a KG construction language. Declarative graph building, SHACL validation, JSON-LD/N-Triples/Turtle export — all at compile time."
	"@type_tags": {
		"writing": true
		"w3c":     true
	}
	refs: {
		"INSIGHT-001": true
	}
}

sub_context_graphs: core.#Task & {
	id:       "sub-context-graphs"
	title:    "Context Graphs CG submission"
	status:   "done"
	project:  "w3c-entry"
	priority: "high"
	depends_on: {"core-report": true}
	description: "Use case: CUE struct-as-set @type as multi-context resource identity. Type overlap as dispatch. Provider binding via set intersection."
	"@type_tags": {
		"writing": true
		"w3c":     true
	}
}

sub_pm_kr: core.#Task & {
	id:       "sub-pm-kr"
	title:    "PM-KR CG submission"
	status:   "done"
	project:  "w3c-entry"
	priority: "medium"
	depends_on: {"core-report": true}
	description: "Use case: Charter pattern as compile-time project completion. Gap analysis, critical path, EARL test plans — project management as constraint satisfaction."
	"@type_tags": {
		"writing": true
		"w3c":     true
	}
	refs: {
		"INSIGHT-002": true
	}
}

sub_dataspaces: core.#Task & {
	id:       "sub-dataspaces"
	title:    "Dataspaces CG submission"
	status:   "done"
	project:  "w3c-entry"
	priority: "medium"
	depends_on: {"core-report": true}
	description: "Use case: ODRL policies, DCAT catalogs, federated knowledge bases — data governance as CUE constraints. The .kb/ convention as a dataspace primitive."
	"@type_tags": {
		"writing": true
		"w3c":     true
	}
}

// ── Phase 3: Join and submit ────────────────────────────────────

join_cgs: core.#Task & {
	id:       "join-cgs"
	title:    "Join target W3C Community Groups"
	status:   "pending"
	project:  "w3c-entry"
	priority: "high"
	depends_on: {
		"sub-kg-construct":   true
		"sub-context-graphs": true
		"sub-pm-kr":          true
		"sub-dataspaces":     true
	}
	description: "Create W3C account, join KG-Construct, Context Graphs, PM-KR, and Dataspaces CGs. Sign CLAs."
	"@type_tags": {
		"admin": true
		"w3c":   true
	}
}

submit_reports: core.#Task & {
	id:       "submit-reports"
	title:    "Submit use case reports to CGs"
	status:   "pending"
	project:  "w3c-entry"
	priority: "high"
	depends_on: {"join-cgs": true}
	description: "Post core report and group-specific submissions to CG mailing lists / GitHub repos. Introduce the project and offer to present."
	"@type_tags": {
		"outreach": true
		"w3c":      true
	}
}
