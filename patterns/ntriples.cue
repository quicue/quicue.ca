// N-Triples export — infrastructure graph as greppable RDF.
//
// Produces one triple per line, loadable into any triplestore.
// Combines with kg N-Triples for cross-layer SPARQL queries.
//
// Usage:
//   import "quicue.ca/patterns"
//   nt: patterns.#NTriplesExport & { Graph: _graph }
//   // cue export -e nt.triples --out text > data.nt

package patterns

import (
	"list"
	"strings"
)

// #NTriplesExport — generates N-Triples from #InfraGraph.
#NTriplesExport: {
	Graph:   #InfraGraph
	BaseIRI: string | *"https://quicue.ca/resources/"

	_res: Graph.Input

	_vocabIRI: "https://quicue.ca/vocab#"
	_rdfType:  "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"

	// Build triple lines per resource
	_lines: {
		for rname, res in _res {
			(rname): {
				_subj: "<\(BaseIRI)\(rname)>"

				// name triple
				name: "\(_subj) <\(_vocabIRI)name> \"\(rname)\" ."

				// rdf:type triples
				types: [
					if res["@type"] != _|_
					for t, _ in res["@type"] {
						"\(_subj) <\(_rdfType)> <\(_vocabIRI)\(t)> ."
					},
				]

				// depends_on triples
				deps: [
					if res.depends_on != _|_
					for d, _ in res.depends_on {
						"\(_subj) <\(_vocabIRI)dependsOn> <\(BaseIRI)\(d)> ."
					},
				]

				// optional field triples
				extras: [
					if res.ip != _|_ {
						"\(_subj) <\(_vocabIRI)ipAddress> \"\(res.ip)\" ."
					},
					if res.description != _|_ {
						"\(_subj) <\(_vocabIRI)description> \"\(res.description)\" ."
					},
					if res.host != _|_ {
						"\(_subj) <\(_vocabIRI)host> \"\(res.host)\" ."
					},
				]

				all: list.Concat([[name], types, deps, extras])
			}
		}
	}

	// Join all resource lines into a single N-Triples document
	triples: strings.Join([
		for _, rl in _lines {
			strings.Join(rl.all, "\n")
		},
	], "\n")
}
