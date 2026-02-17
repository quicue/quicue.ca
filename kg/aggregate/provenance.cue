// PROV-O — W3C Provenance Ontology projection from knowledge graph entries.
//
// Maps decisions to prov:Activity (the act of deciding), supersession chains
// to prov:wasRevisionOf, insights to prov:Entity, source files to prov:Entity,
// pipeline runs to prov:Activity, and collection protocols to prov:Plan.
//
// Produces a JSON-LD provenance graph that makes the full audit trail
// machine-navigable — from raw data sources through pipeline processing
// to architectural decisions.
//
// Usage (from .kg/index.cue):
//   _index: aggregate.#KGIndex & { ... }
//   provenance: aggregate.#Provenance & { index: _index }
//   // cue export . -e provenance.graph --out json

package aggregate

// #ProvContext — JSON-LD context for provenance exports.
#ProvContext: {
	"prov":    "http://www.w3.org/ns/prov#"
	"dcterms": "http://purl.org/dc/terms/"
	"rdfs":    "http://www.w3.org/2000/01/rdf-schema#"
	"xsd":     "http://www.w3.org/2001/XMLSchema#"
	"kg":      "https://quicue.ca/kg#"
}

// #Provenance — generates a PROV-O graph from #KGIndex entries.
#Provenance: {
	index: #KGIndex

	graph: {
		"@context": #ProvContext

		"@graph": [
			// Decisions as prov:Activity — the act of making a decision
			for id, d in index.decisions {
				"@id":       "kg:\(id)"
				"@type":     ["prov:Activity", "kg:Decision"]
				"rdfs:label": d.title
				"prov:startedAtTime": d.date
				"prov:wasAssociatedWith": {
					"@type":      "prov:Agent"
					"rdfs:label": index.project
				}
				"dcterms:description": d.context
				"prov:generated": {
					"@id":   "kg:\(id)/outcome"
					"@type": "prov:Entity"
					"rdfs:label": d.decision
					"prov:wasGeneratedBy": {"@id": "kg:\(id)"}
					"dcterms:description": d.rationale
				}
				if d.supersedes != _|_ {
					"prov:wasInformedBy": {"@id": "kg:\(d.supersedes)"}
					"prov:generated": {
						"prov:wasRevisionOf": {"@id": "kg:\(d.supersedes)/outcome"}
					}
				}
			},

			// Insights as prov:Entity — discovered knowledge
			for id, ins in index.insights {
				"@id":       "kg:\(id)"
				"@type":     ["prov:Entity", "kg:Insight"]
				"rdfs:label": ins.statement
				"prov:wasGeneratedBy": {
					"@type":      "prov:Activity"
					"rdfs:label": "Discovery via \(ins.method)"
					"prov:startedAtTime": ins.discovered
				}
				"kg:confidence": ins.confidence
			},

			// Source files as prov:Entity — raw data artifacts
			if index.sources != _|_ for id, src in index.sources {
				"@id":   "kg:\(id)"
				"@type": ["prov:Entity", "kg:SourceFile"]
				"rdfs:label": src.file
				"kg:origin":  src.origin
				"dcterms:format": src.format
				if src.sha256 != _|_ {
					"kg:sha256": src.sha256
				}
				if src.extracted_by != _|_ {
					"prov:wasAttributedTo": {
						"@type":      "prov:Agent"
						"rdfs:label": src.extracted_by
					}
				}
				if src.extracted_at != _|_ {
					"prov:generatedAtTime": src.extracted_at
				}
				if src.record_count != _|_ {
					"kg:recordCount": src.record_count
				}
			},

			// Collection protocols as prov:Plan — standing procedures
			if index.protocols != _|_ for id, proto in index.protocols {
				"@id":   "kg:\(id)"
				"@type": ["prov:Plan", "kg:CollectionProtocol"]
				"rdfs:label": proto.name
				"dcterms:description": proto.description
				"kg:system":    proto.system
				"kg:method":    proto.method
				"kg:schedule":  proto.schedule
				"kg:authority": proto.authority
				if proto.endpoint != _|_ {
					"kg:endpoint": proto.endpoint
				}
				if proto.freshness != _|_ {
					"kg:freshness": proto.freshness
				}
			},

			// Pipeline runs as prov:Activity — execution events
			if index.runs != _|_ for id, run in index.runs {
				"@id":   "kg:\(id)"
				"@type": ["prov:Activity", "kg:PipelineRun"]
				"rdfs:label": run.description
				"prov:startedAtTime": run.started_at
				if run.ended_at != _|_ {
					"prov:endedAtTime": run.ended_at
				}
				"prov:wasAssociatedWith": {
					"@type":      "prov:SoftwareAgent"
					"rdfs:label": run.worker
				}
				if run.git_commit != _|_ {
					"kg:gitCommit": run.git_commit
				}
				// Link to consumed sources
				"prov:used": [for srcId in run.sources_used {{"@id": "kg:\(srcId)"}}]
				// Link to produced outputs
				"prov:generated": [for out in run.outputs {{"rdfs:label": out}}]
				// Link to governing protocol
				if run.protocol != _|_ {
					"prov:hadPlan": {"@id": "kg:\(run.protocol)"}
				}
				"kg:status": run.status
			},

			// Derivations as prov:Activity — pipeline audit trail
			if index.derivations != _|_ for id, d in index.derivations {
				"@id":   "kg:\(id)"
				"@type": ["prov:Activity", "kg:Derivation"]
				"rdfs:label": d.description
				"prov:startedAtTime": d.date
				"prov:wasAssociatedWith": {
					"@type":      "prov:SoftwareAgent"
					"rdfs:label": d.worker
				}
				"kg:outputFile":  d.output_file
				"kg:canonPurity": d.canon_purity
				"prov:used": [for src in d.canon_sources {{"rdfs:label": src}}]
				if d.record_count != _|_ {
					"kg:recordCount": d.record_count
				}
			},
		]
	}

	summary: {
		total_activities: len(index.decisions) + _run_count + _deriv_count
		total_entities:   len(index.decisions) + len(index.insights) + _source_count
		total_plans:      _protocol_count
		has_supersession_chains: len([for _, d in index.decisions if d.supersedes != _|_ {true}]) > 0

		_source_count: *0 | int
		if index.sources != _|_ {
			_source_count: len(index.sources)
		}
		_protocol_count: *0 | int
		if index.protocols != _|_ {
			_protocol_count: len(index.protocols)
		}
		_run_count: *0 | int
		if index.runs != _|_ {
			_run_count: len(index.runs)
		}
		_deriv_count: *0 | int
		if index.derivations != _|_ {
			_deriv_count: len(index.derivations)
		}

		has_provenance: _source_count > 0 || _run_count > 0 || _deriv_count > 0
	}
}
