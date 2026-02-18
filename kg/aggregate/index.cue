// Per-project knowledge graph index — comprehension-derived, never hand-maintained
package aggregate

import (
	"quicue.ca/kg/core@v0"
	"quicue.ca/kg/ext@v0"
)

// #KGIndex computes summary views from raw .kb/ entries.
// All fields in summary, by_status, and by_confidence are derived via comprehensions.
#KGIndex: {
	project: string & !=""

	decisions: {[string]: core.#Decision}
	insights:  {[string]: core.#Insight}
	rejected:  {[string]: core.#Rejected}
	patterns:  {[string]: core.#Pattern}

	// Provenance tracking (optional — projects opt in)
	sources?:   {[string]: ext.#SourceFile}
	protocols?: {[string]: ext.#CollectionProtocol}
	runs?:      {[string]: ext.#PipelineRun}
	derivations?: {[string]: ext.#Derivation}

	summary: {
		total_decisions: len(decisions)
		total_insights:  len(insights)
		total_rejected:  len(rejected)
		total_patterns:  len(patterns)
		total:           total_decisions + total_insights + total_rejected + total_patterns

		// Provenance counts (default to 0 if not present)
		if sources != _|_ {
			total_sources: len(sources)
		}
		if protocols != _|_ {
			total_protocols: len(protocols)
		}
		if runs != _|_ {
			total_runs: len(runs)
		}
		if derivations != _|_ {
			total_derivations: len(derivations)
		}
	}

	by_status: {for s in ["proposed", "accepted", "deprecated", "superseded"] {
		(s): {for k, v in decisions if v.status == s {(k): v.title}}
	}}

	by_confidence: {for c in ["high", "medium", "low"] {
		(c): {for k, v in insights if v.confidence == c {(k): v.statement}}
	}}
}
