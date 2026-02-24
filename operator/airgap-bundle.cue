// operator/airgap-bundle.cue — Schema for airgapped deployment bundles
//
// Defines what goes into an offline-deployable bundle: git repos, Docker images,
// Python wheels, static binaries, system packages. A downstream project fills in
// the specifics; the operator scripts consume this manifest.
//
// Usage:
//   cue export ./operator/ -e bundle --out json | jq .
//   bash operator/bundle.sh   # reads this manifest, produces the bundle

package operator

// #Bundle defines a self-contained airgapped deployment.
#Bundle: {
	name:    string
	version: string
	arch:    *"linux/amd64" | "linux/arm64"

	// Target directory on the build host
	output: string | *"/tmp/\(name)-bundle"

	// Git repositories to bundle (git bundle format)
	repos: [string]: #Repo

	// Docker images to save (docker save | gzip)
	docker: {
		// Pre-built application images
		app: [string]: #DockerImage
		// Base images needed for docker build on the target
		base: [string]: #DockerImage
	}

	// Python wheel dependencies (pip download --only-binary)
	python: {
		version: string | *"3.12"
		packages: [...string]
		// pip/setuptools/wheel for offline bootstrap
		bootstrap: *true | false
	}

	// Static binaries to include (copied or downloaded)
	binaries: [string]: #Binary

	// System packages (.deb) with recursive dependencies
	debs: [string]: #DebPackage

	// Post-install symlinks (e.g., CUE module resolution)
	symlinks: [...#Symlink]

	// Smoke test assertions
	checks: [...#Check]

	// Computed: total number of artifacts
	_artifact_count: len(repos) + len(docker.app) + len(docker.base) + len(binaries) + len(debs)
}

#Repo: {
	path:    string // local path to git repo
	gitlab?: string // target GitLab path (for push script)
	group?:  string // GitLab group
}

#DockerImage: {
	image: string       // image:tag
	file:  string | *"" // output filename (auto-derived if empty)
}

#Binary: {
	source: "local" | "url"
	path:   string // local path or download URL
	dest:   string | *"/usr/local/bin/\(name)"
	name:   string
	static: *true | false // statically linked?
}

#DebPackage: {
	package: string
	// Recursive deps auto-resolved by apt-cache depends
	deps: [...string]
}

#Symlink: {
	link:   string
	target: string
}

#Check: {
	label:    string
	command:  string
	expected: string
}

// --- Gotchas registry ---
// Hard-won lessons from airgapped deployments. Each gotcha documents a trap
// and the workaround. Scripts should check for these proactively.

#Gotcha: {
	id:         string
	symptom:    string
	cause:      string
	workaround: string
	affects: [...string] // which #Bundle fields this applies to
}

gotchas: [...#Gotcha] & [
	{
		id:         "ensurepip-missing"
		symptom:    "python3 -m ensurepip: No module named ensurepip"
		cause:      "Ubuntu cloud images strip ensurepip to save space"
		workaround: "Bundle pip wheel, bootstrap with: python3 pip-*.whl/pip install pip"
		affects: ["python"]
	},
	{
		id:         "typing-extensions-conflict"
		symptom:    "Cannot uninstall typing_extensions: no RECORD file"
		cause:      "System Python installs typing_extensions as a debian package"
		workaround: "Use pip install --ignore-installed"
		affects: ["python"]
	},
	{
		id:         "raptor-libyajl2"
		symptom:    "dpkg: dependency problems: libraptor2-0 depends on libyajl2"
		cause:      "apt-cache depends doesn't recurse into transitive deps"
		workaround: "Recursively resolve: apt-cache depends --recurse <pkg>"
		affects: ["debs"]
	},
	{
		id:         "cue-module-symlink"
		symptom:    "cannot find module providing package <module>"
		cause:      "CUE modules resolve via cue.mod/pkg/ symlinks in dev"
		workaround: "Create symlinks post-clone: ln -sf <repo> cue.mod/pkg/<module>"
		affects: ["repos", "symlinks"]
	},
	{
		id:         "docker-bind-mount-skew"
		symptom:    "ImportError: cannot import name 'X' from 'Y'"
		cause:      "Bind-mounting newer code over older Docker image internals"
		workaround: "Don't bind-mount app code — use the image's built-in version, or mount all dependencies too"
		affects: ["docker"]
	},
	{
		id:         "caddy-tls-internal-localhost"
		symptom:    "TLS alert: internal error (curl to localhost)"
		cause:      "Caddy's internal CA generates cert for SITE_ADDRESS, not localhost"
		workaround: "For POC: use plain HTTP Caddyfile (:80 { reverse_proxy ... })"
		affects: ["docker"]
	},
	{
		id:         "cue-export-oom"
		symptom:    "Killed (exit 137) during cue export"
		cause:      "Large CUE evaluations exceed VM memory"
		workaround: "Generate specs on build host with more RAM, transfer as JSON"
		affects: ["binaries"]
	},
	{
		id:         "grep-pipefail"
		symptom:    "Script killed by set -eo pipefail when grep finds no matches"
		cause:      "grep returns exit 1 on no match, propagated by pipefail"
		workaround: "Use { grep ... || true; } before piping"
		affects: ["repos"]
	},
]
