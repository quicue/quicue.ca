// Pre-computed topology for the devbox graph.
//
// Generated from dependency analysis of devbox.cue + apps.cue.
// Without this, #InfraGraph falls back to depth=0 and direct-parent
// ancestors only, which breaks impact queries and deployment ordering.
//
// Regenerate if resources or dependencies change:
//   python3 tools/toposort.py ... (or trace manually — 14 nodes)

package devbox

// Wire precomputed data into the graph
infra: Precomputed: _precomputed

_precomputed: {
	depth: {
		// Layer 0 — foundation
		"docker": 0

		// Layer 1 — direct docker dependents
		"postgres":  1
		"redis":     1
		"traefik":   1
		"vault-dev": 1
		"minio":     1

		// Layer 2 — depend on layer-1 services
		"gitea":    2
		"k3d":      2
		"registry": 2
		"grafana":  2
		"api":      2
		"worker":   2

		// Layer 3 — depend on layer-2 services
		"runner":   3
		"frontend": 3
	}

	ancestors: {
		"docker": {}

		// Layer 1: all have docker as sole ancestor
		"postgres":  {"docker": true}
		"redis":     {"docker": true}
		"traefik":   {"docker": true}
		"vault-dev": {"docker": true}
		"minio":     {"docker": true}

		// Layer 2: transitive through layer 1
		"gitea":    {"postgres": true, "traefik": true, "docker": true}
		"k3d":      {"docker": true, "traefik": true}
		"registry": {"docker": true, "traefik": true}
		"grafana":  {"postgres": true, "traefik": true, "docker": true}
		"api":      {"traefik": true, "postgres": true, "redis": true, "docker": true}
		"worker":   {"traefik": true, "postgres": true, "redis": true, "minio": true, "docker": true}

		// Layer 3: transitive through layers 1+2
		"runner":   {"gitea": true, "docker": true, "postgres": true, "traefik": true}
		"frontend": {"traefik": true, "api": true, "docker": true, "postgres": true, "redis": true}
	}

	dependents: {
		"docker":   {"postgres": true, "redis": true, "traefik": true, "vault-dev": true, "minio": true, "gitea": true, "k3d": true, "registry": true, "grafana": true, "api": true, "worker": true, "runner": true, "frontend": true}
		"postgres": {"gitea": true, "grafana": true, "api": true, "worker": true, "runner": true, "frontend": true}
		"redis":    {"api": true, "worker": true, "frontend": true}
		"traefik":  {"gitea": true, "k3d": true, "registry": true, "grafana": true, "api": true, "worker": true, "runner": true, "frontend": true}
		"vault-dev": {}
		"minio":     {"worker": true}
		"gitea":     {"runner": true}
		"k3d":       {}
		"registry":  {}
		"grafana":   {}
		"api":       {"frontend": true}
		"worker":    {}
		"runner":    {}
		"frontend":  {}
	}
}
