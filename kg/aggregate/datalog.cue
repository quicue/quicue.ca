// Datalog — guaranteed-terminating logic projection from knowledge graph entries.
//
// Generates Soufflé-compatible Datalog: relation declarations (.decl),
// facts (.facts), and rules. Unlike Prolog, Datalog always terminates —
// safe for automated infrastructure queries at scale.
//
// Usage (from .kb/index.cue):
//   _index: aggregate.#KGIndex & { ... }
//   logic: aggregate.#Datalog & { index: _index }
//   // cue export . -e logic.program --out text

package aggregate

import "strings"

#Datalog: {
	index: #KGIndex

	_decls: """
		// Relation declarations
		.decl decision(id: symbol, title: symbol, status: symbol, date: symbol)
		.decl insight(id: symbol, method: symbol, confidence: symbol, date: symbol)
		.decl pattern(id: symbol, name: symbol, category: symbol)
		.decl pattern_used_in(pattern_id: symbol, project: symbol)
		.decl source(id: symbol, file: symbol, origin: symbol, authority: number)
		.decl protocol(id: symbol, name: symbol, system: symbol, authority: number)
		.decl run(id: symbol, worker: symbol, status: symbol)
		.decl used(run_id: symbol, source_id: symbol)
		.decl derivation(id: symbol, worker: symbol, output: symbol, purity: symbol)

		// Derived relations
		.decl contributed(source_id: symbol, deriv_id: symbol)
		.decl trust(protocol_id: symbol, level: symbol)
		.decl most_authoritative(system: symbol, protocol_id: symbol)
		.decl shared_pattern(pattern_id: symbol, proj1: symbol, proj2: symbol)
		.decl active_decision(id: symbol)
		.decl actionable_insight(id: symbol)

		// Output relations
		.output contributed
		.output trust
		.output most_authoritative
		.output shared_pattern
		.output active_decision
		.output actionable_insight
		"""

	_facts: strings.Join([
		"// Facts — generated from \(index.project) knowledge graph",
		"",
		for id, d in index.decisions {
			"decision(\"\(id)\", \"\(d.title)\", \"\(d.status)\", \"\(d.date)\")."
		},
		for id, ins in index.insights {
			"insight(\"\(id)\", \"\(ins.method)\", \"\(ins.confidence)\", \"\(ins.discovered)\")."
		},
		for id, p in index.patterns {
			"pattern(\"\(id)\", \"\(p.name)\", \"\(p.category)\")."
		},
		for id, p in index.patterns for proj, _ in p.used_in {
			"pattern_used_in(\"\(id)\", \"\(proj)\")."
		},
		if index.sources != _|_ for id, src in index.sources {
			"source(\"\(id)\", \"\(src.file)\", \"\(src.origin)\", 0)."
		},
		if index.protocols != _|_ for id, proto in index.protocols {
			"protocol(\"\(id)\", \"\(proto.name)\", \"\(proto.system)\", \(proto.authority))."
		},
		if index.runs != _|_ for id, run in index.runs {
			"run(\"\(id)\", \"\(run.worker)\", \"\(run.status)\")."
		},
		if index.runs != _|_ for id, run in index.runs for src in run.sources_used {
			"used(\"\(id)\", \"\(src)\")."
		},
		if index.derivations != _|_ for id, d in index.derivations {
			"derivation(\"\(id)\", \"\(d.worker)\", \"\(d.output_file)\", \"\(d.canon_purity)\")."
		},
	], "\n")

	_rules: """
		// Rules — guaranteed to terminate (Datalog restriction: no function symbols)

		contributed(src, deriv) :- derivation(deriv, _, _, _), run(r, _, _), used(r, src).

		trust(proto, "high") :- protocol(proto, _, _, rank), rank <= 2.
		trust(proto, "medium") :- protocol(proto, _, _, rank), rank > 2, rank <= 3.
		trust(proto, "low") :- protocol(proto, _, _, rank), rank > 3.

		most_authoritative(sys, proto) :-
		    protocol(proto, _, sys, rank),
		    !protocol(_, _, sys, better), better < rank.

		shared_pattern(p, proj1, proj2) :-
		    pattern_used_in(p, proj1),
		    pattern_used_in(p, proj2),
		    proj1 != proj2.

		active_decision(id) :- decision(id, _, "accepted", _).
		actionable_insight(id) :- insight(id, _, "high", _).
		"""

	program: _decls + "\n\n" + _facts + "\n\n" + _rules

	summary: {
		total_relations: 15
		total_rules:     6
	}
}
