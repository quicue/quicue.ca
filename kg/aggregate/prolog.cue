// Prolog — logic programming projection from knowledge graph entries.
//
// Generates Prolog facts from all #KGIndex entry types, plus inference
// rules for transitive provenance, trust levels, and authority ranking.
// The facts are data; the rules are computable knowledge.
//
// Usage (from .kb/index.cue):
//   _index: aggregate.#KGIndex & { ... }
//   logic: aggregate.#Prolog & { index: _index }
//   // cue export . -e logic.program --out text

package aggregate

import "strings"

#Prolog: {
	index: #KGIndex

	_facts: strings.Join([
		"% Generated from \(index.project) knowledge graph",
		"% Facts — one per .kb/ entry",
		"",

		"% decision(Id, Title, Status, Date).",
		for id, d in index.decisions {
			"decision('\(id)', \"\(d.title)\", \(d.status), '\(d.date)')."
		},
		"",

		"% insight(Id, Method, Confidence, Date).",
		for id, ins in index.insights {
			"insight('\(id)', \(ins.method), \(ins.confidence), '\(ins.discovered)')."
		},
		"",

		"% pattern(Id, Name, Category).",
		for id, p in index.patterns {
			"pattern('\(id)', \"\(p.name)\", '\(p.category)')."
		},
		"",

		"% pattern_used_in(PatternId, Project).",
		for id, p in index.patterns for proj, _ in p.used_in {
			"pattern_used_in('\(id)', '\(proj)')."
		},
		"",

		if index.sources != _|_ for _ in [0] {
			"% source(Id, File, Origin, AuthorityRank)."
		},
		if index.sources != _|_ for id, src in index.sources {
			let _rank = *0 | int
			"source('\(id)', \"\(src.file)\", '\(src.origin)', \(_rank))."
		},
		"",

		if index.protocols != _|_ for _ in [0] {
			"% protocol(Id, Name, System, Authority)."
		},
		if index.protocols != _|_ for id, proto in index.protocols {
			"protocol('\(id)', \"\(proto.name)\", '\(proto.system)', \(proto.authority))."
		},
		"",

		if index.runs != _|_ for _ in [0] {
			"% run(Id, Worker, Status)."
		},
		if index.runs != _|_ for id, run in index.runs {
			"run('\(id)', '\(run.worker)', \(run.status))."
		},
		if index.runs != _|_ for _ in [0] {
			""
			"% used(RunId, SourceId)."
		},
		if index.runs != _|_ for id, run in index.runs for src in run.sources_used {
			"used('\(id)', '\(src)')."
		},
		"",

		if index.derivations != _|_ for _ in [0] {
			"% derivation(Id, Worker, OutputFile, Purity)."
		},
		if index.derivations != _|_ for id, d in index.derivations {
			"derivation('\(id)', '\(d.worker)', \"\(d.output_file)\", \(d.canon_purity))."
		},
	], "\n")

	_rules: """
		% Rules — computable knowledge

		% Transitive provenance: what sources contributed to a derivation?
		contributed(Source, Deriv) :-
		    derivation(Deriv, _, _, _),
		    run(Run, _, _),
		    used(Run, Source).

		% Trust level based on protocol authority rank
		trust(Proto, high) :- protocol(Proto, _, _, Rank), Rank =< 2.
		trust(Proto, medium) :- protocol(Proto, _, _, Rank), Rank > 2, Rank =< 3.
		trust(Proto, low) :- protocol(Proto, _, _, Rank), Rank > 3.

		% Most authoritative protocol for a system
		most_authoritative(System, Proto) :-
		    protocol(Proto, _, System, Rank),
		    \\+ (protocol(_, _, System, Better), Better < Rank).

		% High-confidence insights
		actionable(Id) :- insight(Id, _, high, _).

		% Patterns shared between two projects
		shared_pattern(P, Proj1, Proj2) :-
		    pattern_used_in(P, Proj1),
		    pattern_used_in(P, Proj2),
		    Proj1 \\= Proj2.

		% Active decisions (not deprecated/superseded)
		active_decision(Id) :- decision(Id, _, accepted, _).
		"""

	program: _facts + "\n\n" + _rules

	summary: {
		total_facts: len(index.decisions) + len(index.insights) + len(index.patterns) + _source_count + _protocol_count + _run_count + _deriv_count
		total_rules: 6
		_source_count:   *0 | int
		_protocol_count: *0 | int
		_run_count:      *0 | int
		_deriv_count:    *0 | int
		if index.sources != _|_ {_source_count: len(index.sources)}
		if index.protocols != _|_ {_protocol_count: len(index.protocols)}
		if index.runs != _|_ {_run_count: len(index.runs)}
		if index.derivations != _|_ {_deriv_count: len(index.derivations)}
	}
}
