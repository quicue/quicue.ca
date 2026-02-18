// Turtle — human-readable RDF from knowledge graph entries.
//
// Grouped by subject with prefix declarations. Compatible with the
// existing Turtle files in infra-ontology/ and infra-shacl/. Can be
// loaded directly into Oxigraph or any SPARQL endpoint.
//
// Usage (from .kb/index.cue):
//   _index: aggregate.#KGIndex & { ... }
//   rdf: aggregate.#Turtle & { index: _index }
//   // cue export . -e rdf.document --out text

package aggregate

import "strings"

#Turtle: {
	index: #KGIndex

	_prefixes: """
		@prefix rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
		@prefix rdfs:   <http://www.w3.org/2000/01/rdf-schema#> .
		@prefix xsd:    <http://www.w3.org/2001/XMLSchema#> .
		@prefix prov:   <http://www.w3.org/ns/prov#> .
		@prefix dcterms: <http://purl.org/dc/terms/> .
		@prefix skos:   <http://www.w3.org/2004/02/skos/core#> .
		@prefix kg:     <https://quicue.ca/kg#> .
		"""

	_decisions: strings.Join([
		"# Decisions",
		for id, d in index.decisions {
			"""
			kg:\(id) a kg:Decision, prov:Activity ;
			    rdfs:label "\(d.title)" ;
			    dcterms:identifier "\(d.id)" ;
			    kg:status "\(d.status)" ;
			    prov:startedAtTime "\(d.date)"^^xsd:date .
			"""
		},
	], "\n")

	_insights: strings.Join([
		"# Insights",
		for id, ins in index.insights {
			"""
			kg:\(id) a kg:Insight, prov:Entity ;
			    rdfs:label "\(ins.statement)" ;
			    dcterms:identifier "\(ins.id)" ;
			    kg:confidence "\(ins.confidence)" ;
			    kg:method "\(ins.method)" ;
			    dcterms:created "\(ins.discovered)"^^xsd:date .
			"""
		},
	], "\n")

	_patterns: strings.Join([
		"# Patterns",
		for id, p in index.patterns {
			strings.Join([
				"kg:\(id) a kg:Pattern ;",
				"    rdfs:label \"\(p.name)\" ;",
				"    skos:prefLabel \"\(p.name)\" ;",
				"    kg:category \"\(p.category)\" ;",
				for proj, _ in p.used_in {
					"    kg:usedIn \"\(proj)\" ;"
				},
				"    .",
			], "\n")
		},
	], "\n")

	_sources: strings.Join([
		if index.sources != _|_ for _ in [0] {
			"# Sources"
		},
		if index.sources != _|_ for id, src in index.sources {
			strings.Join([
				"kg:\(id) a kg:SourceFile, prov:Entity ;",
				"    rdfs:label \"\(src.file)\" ;",
				"    dcterms:identifier \"\(src.id)\" ;",
				"    kg:origin \"\(src.origin)\" ;",
				"    dcterms:format \"\(src.format)\" ;",
				if src.sha256 != _|_ {
					"    kg:sha256 \"\(src.sha256)\" ;"
				},
				"    .",
			], "\n")
		},
	], "\n")

	_protocols: strings.Join([
		if index.protocols != _|_ for _ in [0] {
			"# Collection Protocols"
		},
		if index.protocols != _|_ for id, proto in index.protocols {
			"""
			kg:\(id) a kg:CollectionProtocol, prov:Plan ;
			    rdfs:label "\(proto.name)" ;
			    dcterms:identifier "\(proto.id)" ;
			    kg:system "\(proto.system)" ;
			    kg:authority \(proto.authority) ;
			    kg:method "\(proto.method)" ;
			    kg:schedule "\(proto.schedule)" .
			"""
		},
	], "\n")

	_runs: strings.Join([
		if index.runs != _|_ for _ in [0] {
			"# Pipeline Runs"
		},
		if index.runs != _|_ for id, run in index.runs {
			strings.Join([
				"kg:\(id) a kg:PipelineRun, prov:Activity ;",
				"    rdfs:label \"\(run.description)\" ;",
				"    dcterms:identifier \"\(run.id)\" ;",
				"    prov:startedAtTime \"\(run.started_at)\" ;",
				"    kg:status \"\(run.status)\" ;",
				"    prov:wasAssociatedWith [ rdfs:label \"\(run.worker)\" ] ;",
				for src in run.sources_used {
					"    prov:used kg:\(src) ;"
				},
				"    .",
			], "\n")
		},
	], "\n")

	_derivations: strings.Join([
		if index.derivations != _|_ for _ in [0] {
			"# Derivations"
		},
		if index.derivations != _|_ for id, d in index.derivations {
			"""
			kg:\(id) a kg:Derivation, prov:Activity ;
			    rdfs:label "\(d.description)" ;
			    dcterms:identifier "\(d.id)" ;
			    kg:outputFile "\(d.output_file)" ;
			    kg:canonPurity "\(d.canon_purity)" ;
			    prov:startedAtTime "\(d.date)"^^xsd:date .
			"""
		},
	], "\n")

	document: strings.Join([_prefixes, "", _decisions, _insights, _patterns, _sources, _protocols, _runs, _derivations], "\n\n")

	summary: {
		sections: len([
			"decisions", "insights", "patterns",
			if index.sources != _|_ {"sources"},
			if index.protocols != _|_ {"protocols"},
			if index.runs != _|_ {"runs"},
			if index.derivations != _|_ {"derivations"},
		])
	}
}
