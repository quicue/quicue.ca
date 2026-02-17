// Deploy Any App — define minimal specs, get graph-integrated resources
//
// Add an app by filling in an #App struct. quicue.ca computes:
//   - Docker resource with proper @type and depends_on
//   - Traefik FQDN for reverse-proxied HTTP access
//   - Dependency edges to postgres, redis, minio as declared
//   - Full integration with graph analysis, impact queries, blast radius
//
// Usage:
//   _apps: myapp: #App & { image: "myapp:latest", port: 3000, needs_db: true }
//   cue eval ./examples/devbox/ -e output.summary

package devbox

// ═══════════════════════════════════════════════════════════════════════════════
// APP TEMPLATE
// ═══════════════════════════════════════════════════════════════════════════════

// #App — minimal spec for a Docker-based application
#App: {
	// Required: container image and exposed port
	image: string
	port:  int & >0 & <65536

	// Infrastructure dependencies — toggle what this app needs
	needs_db:      bool | *false // → depends_on postgres
	needs_cache:   bool | *false // → depends_on redis
	needs_storage: bool | *false // → depends_on minio

	// Optional: additional dependency edges (resource names)
	extra_deps: {[string]: true} | *{}

	// Optional: environment variables (informational, exported in resource)
	env: {[string]: string} | *{}

	// Optional: description override
	description: string | *""
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP INSTANCES — add your apps here
// ═══════════════════════════════════════════════════════════════════════════════

_apps: [Name=string]: #App

_apps: {
	"api": #App & {
		image:       "node:22-alpine"
		port:        3000
		needs_db:    true
		needs_cache: true
		env: {
			DATABASE_URL: "postgres://dev:dev@postgres:5432/api"
			REDIS_URL:    "redis://redis:6379/0"
		}
		description: "REST API — Express.js backend"
	}

	"worker": #App & {
		image:         "python:3.12-slim"
		port:          8080
		needs_db:      true
		needs_cache:   true
		needs_storage: true
		env: {
			CELERY_BROKER: "redis://redis:6379/1"
			S3_ENDPOINT:   "http://minio:9000"
		}
		description: "Background worker — Celery task processor"
	}

	"frontend": #App & {
		image: "node:22-alpine"
		port:  5173
		extra_deps: {"api": true}
		description: "SPA frontend — Vite dev server proxying to API"
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPUTED RESOURCES — apps become graph nodes automatically
// ═══════════════════════════════════════════════════════════════════════════════

_resources: {
	for name, app in _apps {
		"\(name)": {
			"@id":          _site.base_id + name
			"name":         name
			ip:             _site.host_ip
			container_name: name
			compose_dir:    "/opt/devbox"
			fqdn:           "\(name).\(_site.domain)"
			"@type": {DockerContainer: true, AppWorkload: true}

			// Compute dependency edges from declared needs
			depends_on: {
				"traefik": true
				if app.needs_db {"postgres": true}
				if app.needs_cache {"redis": true}
				if app.needs_storage {"minio": true}
				for dep, _ in app.extra_deps {"\(dep)": true}
			}

			if app.description != "" {
				description: app.description
			}
		}
	}
}
