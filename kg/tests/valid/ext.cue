package valid

import "quicue.ca/kg/ext@v0"

deriv001: ext.#Derivation & {
	id:           "DERIV-001"
	worker:       "workers/bulk_export.py"
	output_file:  "derived/export.json"
	date:         "2026-02-15"
	description:  "Bulk export of all records"
	canon_purity: "mixed"
	canon_sources: ["HGNC complete gene set"]
	non_canon_elements: ["Filtering heuristic"]
	action_required: "Review filtered records before promotion"
	input_files: ["data/raw.json"]
	record_count: 500
}

ws001: ext.#Workspace & {
	name:        "example-app"
	description: "Multi-service application"
	components: {
		source: {
			path:        "/home/user/example-app"
			description: "Application source"
			module:      "example.com/app"
		}
		staging: {
			path:        "/srv/staging/example-app"
			description: "Staging workspace"
		}
	}
	deploy: {
		domain:    "app.example.com"
		container: "LXC 100"
		host:      "prod-host"
	}
}

ctx001: ext.#Context & {
	"@id":       "https://quicue.ca/project/quicue-kg"
	name:        "quicue-kg"
	description: "CUE-native knowledge graph framework"
	module:      "quicue.ca/kg@v0"
	status:      "active"
	license:     "Apache-2.0"
}

src001: ext.#SourceFile & {
	id:           "SRC-001"
	file:         "staging/exports/inventory-2026-02.xlsx"
	sha256:       "a3f2b8c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1"
	format:       "xlsx"
	origin:       "cmdb"
	extracted_by: "jdoe"
	extracted_at: "2026-02-13"
	record_count: 12
}

proto001: ext.#CollectionProtocol & {
	id:          "PROTO-001"
	name:        "Infrastructure inventory export"
	system:      "cmdb"
	method:      "manual_export"
	schedule:    "weekly"
	description: "Export infrastructure inventory as CSV from the management console."
	authority:   1
	format:      "csv"
	contact:     "infrastructure-team"
	endpoint:    "cmdb.example.com"
	freshness:   "< 7 days"
	known_gaps: ["Offline assets may have stale IP addresses"]
}

run001: ext.#PipelineRun & {
	id:         "RUN-001"
	started_at: "2026-02-13T14:30:00Z"
	ended_at:   "2026-02-13T14:35:22Z"
	worker:     "scripts/run_pipeline.sh"
	git_commit: "abc1234"
	sources_used: ["SRC-001"]
	outputs: ["canonical/output_main.cue", "canonical/output_001.cue"]
	protocol:     "PROTO-001"
	status:       "success"
	description:  "Full pipeline run: parse → merge → canonicalize → export"
	record_count: 1683
	error_count:  0
}
