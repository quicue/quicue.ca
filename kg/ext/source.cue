// Source file tracking — anchors provenance to physical artifacts
package ext

// #SourceFile records a data source artifact with identity and lineage.
// Maps to prov:Entity in the PROV-O projection: the source file IS the entity
// that pipeline activities consume (prov:used) and transform.
//
// Usage:
//   sources: {
//       "inventory-2026-02": ext.#SourceFile & {
//           id:          "SRC-001"
//           file:        "staging/exports/inventory-2026-02.xlsx"
//           sha256:      "a3f2b8c1..."
//           format:      "xlsx"
//           origin:      "cmdb"
//           extracted_by: "jdoe"
//           extracted_at: "2026-02-13"
//       }
//   }
#SourceFile: {
	"@type":       "kg:SourceFile"
	id:            =~"^SRC-\\d{3}$"
	file:          string & !=""
	sha256?:       =~"^[0-9a-f]{64}$"
	format:        "xlsx" | "csv" | "json" | "jsonld" | "ttl" | "cue" | "xml" | "yaml" | string
	origin:        string & !="" // system name: "sharepoint", "vcenter", "topdesk", "zabbix", "manual"
	description?:  string
	extracted_by?: string       // who ran the export
	extracted_at?: =~"^\\d{4}-\\d{2}-\\d{2}$"
	record_count?: int & >=0
	related?:      {[string]: true}
}

// #CollectionProtocol documents how data is collected from a source system.
// This is the repeatable procedure — not a single collection event, but the
// standing protocol. Maps to prov:Plan in PROV-O: the protocol is the plan
// that governs collection activities.
//
// Usage:
//   protocols: {
//       "vcenter-export": ext.#CollectionProtocol & {
//           id:       "PROTO-001"
//           name:     "vCenter VM inventory export"
//           system:   "vcenter"
//           method:   "manual_export"
//           schedule: "weekly"
//           ...
//       }
//   }
#CollectionProtocol: {
	"@type":      "kg:CollectionProtocol"
	id:           =~"^PROTO-\\d{3}$"
	name:         string & !=""
	system:       string & !=""       // source system identifier
	method:       "api_pull" | "manual_export" | "scheduled_export" | "file_drop" | "scrape"
	schedule:     "daily" | "weekly" | "monthly" | "on_demand" | "continuous" | string
	description:  string & !=""
	authority:    int & >=1            // rank in authority chain (1 = highest)
	format:       "xlsx" | "csv" | "json" | "jsonld" | "xml" | string
	contact?:     string               // responsible person/team
	endpoint?:    string               // API URL or export path
	query?:       string               // filter/query used during export
	freshness?:   string               // expected data age (e.g., "< 24h")
	known_gaps?:  [...string]          // documented gaps in this source
	related?:     {[string]: true}
}

// #PipelineRun records a single execution of the data pipeline.
// Maps to prov:Activity — consumes source files (prov:used),
// produces canonical output (prov:generated), associated with
// a worker agent (prov:wasAssociatedWith).
//
// Distinct from #Derivation: a #Derivation documents a class of
// pipeline output (canonical type), while #PipelineRun documents
// a specific execution event.
//
// Usage:
//   runs: {
//       "run-2026-02-13": ext.#PipelineRun & {
//           id:         "RUN-001"
//           started_at: "2026-02-13T14:30:00Z"
//           worker:     "run_pipeline.sh"
//           ...
//       }
//   }
#PipelineRun: {
	"@type":      "kg:PipelineRun"
	id:           =~"^RUN-\\d{3}$"
	started_at:   string & !=""        // ISO 8601 datetime
	ended_at?:    string               // ISO 8601 datetime
	worker:       string & !=""        // script/tool that ran
	git_commit?:  string               // repo state at run time
	sources_used: [...string] & [_, ...] // SRC-* IDs consumed
	outputs:      [...string] & [_, ...] // file paths produced
	protocol?:    string               // PROTO-* ID governing this run
	status:       "success" | "partial" | "failed"
	description:  string & !=""
	record_count?: int & >=0           // total records processed
	error_count?:  int & >=0
	related?:     {[string]: true}
}
