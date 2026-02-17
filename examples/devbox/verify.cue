// Contract — constraints that must unify with the computed graph
//
// These are not assertions checked after the fact. They are CUE values
// that must merge with the graph analysis output. If any constraint
// cannot unify, `cue vet` rejects the entire evaluation.
//
// This is the verification: unification succeeds = contract satisfied.

package devbox

// ─── Graph structure ───────────────────────────────────────────────
// The graph must validate and have meaningful depth.
validate: valid: true

// ─── Infrastructure roots ──────────────────────────────────────────
// Docker is the only root — everything else depends on something.
infra: roots: {"docker": true}

// ─── Deployment ordering ───────────────────────────────────────────
// The first layer must contain only docker (the foundation).
deployment: layers: [{layer: 0, resources: ["docker"]}, ...]

// ─── Impact propagation ───────────────────────────────────────────
// If docker goes down, everything is affected.
// This constraint says: every non-docker resource must appear in
// docker's impact set. Unification enforces this.
impact_docker: affected: {
	for name, _ in _resources if name != "docker" {
		"\(name)": true
	}
}

// ─── SPOF detection ───────────────────────────────────────────────
// Docker must be identified as a single point of failure.
// (It's the only root, so it must be critical.)
spof: risks: [{name: "docker"}, ...]
