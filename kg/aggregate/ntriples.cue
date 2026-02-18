// N-Triples — one triple per line RDF from knowledge graph entries.
//
// The simplest possible RDF serialization: greppable, sortable, diffable.
// Each line is <subject> <predicate> <object> . Good for bulk loading
// into any triplestore and for unix-pipeline processing.
//
// Usage (from .kb/index.cue):
//   _index: aggregate.#KGIndex & { ... }
//   rdf: aggregate.#NTriples & { index: _index }
//   // cue export . -e rdf.triples --out text

package aggregate

import "strings"

// N-Triples namespace constants (expanded — no prefixes in N-Triples)
_nt_rdf:    "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
_nt_rdfs:   "http://www.w3.org/2000/01/rdf-schema#"
_nt_prov:   "http://www.w3.org/ns/prov#"
_nt_dcterm: "http://purl.org/dc/terms/"
_nt_kg:     "https://quicue.ca/kg#"
_nt_skos:   "http://www.w3.org/2004/02/skos/core#"

#NTriples: {
	index: #KGIndex

	_lines: [
		for id, d in index.decisions {
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_kg)Decision> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_prov)Activity> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdfs)label> \"\(d.title)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_dcterm)identifier> \"\(d.id)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_prov)startedAtTime> \"\(d.date)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_kg)status> \"\(d.status)\" ."
		},
		for id, ins in index.insights {
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_kg)Insight> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_prov)Entity> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdfs)label> \"\(ins.statement)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_kg)confidence> \"\(ins.confidence)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_kg)method> \"\(ins.method)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_dcterm)created> \"\(ins.discovered)\" ."
		},
		for id, p in index.patterns {
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_kg)Pattern> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdfs)label> \"\(p.name)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_kg)category> \"\(p.category)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_skos)prefLabel> \"\(p.name)\" ."
		},
		for id, p in index.patterns for proj, _ in p.used_in {
			"<\(_nt_kg)\(id)> <\(_nt_kg)usedIn> \"\(proj)\" ."
		},
		if index.sources != _|_ for id, src in index.sources {
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_kg)SourceFile> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_prov)Entity> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdfs)label> \"\(src.file)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_kg)origin> \"\(src.origin)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_dcterm)format> \"\(src.format)\" ."
		},
		if index.sources != _|_ for id, src in index.sources if src.sha256 != _|_ {
			"<\(_nt_kg)\(id)> <\(_nt_kg)sha256> \"\(src.sha256)\" ."
		},
		if index.protocols != _|_ for id, proto in index.protocols {
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_kg)CollectionProtocol> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_prov)Plan> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdfs)label> \"\(proto.name)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_kg)system> \"\(proto.system)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_kg)authority> \"\(proto.authority)\" ."
		},
		if index.runs != _|_ for id, run in index.runs {
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_kg)PipelineRun> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_prov)Activity> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdfs)label> \"\(run.description)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_prov)startedAtTime> \"\(run.started_at)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_kg)status> \"\(run.status)\" ."
		},
		if index.runs != _|_ for id, run in index.runs for src in run.sources_used {
			"<\(_nt_kg)\(id)> <\(_nt_prov)used> <\(_nt_kg)\(src)> ."
		},
		if index.derivations != _|_ for id, d in index.derivations {
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_kg)Derivation> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdf)type> <\(_nt_prov)Activity> ."
			"<\(_nt_kg)\(id)> <\(_nt_rdfs)label> \"\(d.description)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_kg)outputFile> \"\(d.output_file)\" ."
			"<\(_nt_kg)\(id)> <\(_nt_kg)canonPurity> \"\(d.canon_purity)\" ."
		},
	]

	triples: strings.Join(_lines, "\n")

	summary: {
		total_triples: len(_lines)
	}
}
