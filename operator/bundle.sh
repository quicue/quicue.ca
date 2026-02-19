#!/usr/bin/env bash
# operator/bundle.sh — Build an airgapped deployment bundle from CUE manifest
#
# Reads the #Bundle definition from operator/airgap-bundle.cue (or a downstream
# override), collects all artifacts, and produces a self-contained directory
# that can be copied to a USB stick and deployed on an offline machine.
#
# Usage:
#   bash operator/bundle.sh                          # from repo root
#   bash operator/bundle.sh --manifest path/to.cue   # custom manifest
#   bash operator/bundle.sh --dry-run                 # show what would be collected
#
# Requires: cue, git, docker, pip, jq
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$SCRIPT_DIR/airgap-bundle.cue"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --manifest=*) MANIFEST="${arg#*=}" ;;
        --dry-run)    DRY_RUN=true ;;
        --help|-h)
            echo "Usage: bash $0 [--manifest=path/to.cue] [--dry-run]"
            exit 0 ;;
    esac
done

# Export bundle manifest as JSON
echo "=== Reading bundle manifest ==="
BUNDLE_JSON=$(cd "$ROOT_DIR" && cue export ./operator/ -e bundle --out json 2>&1) || {
    echo "ERROR: No 'bundle' expression found in manifest."
    echo "Define a concrete #Bundle instance named 'bundle' in your CUE files."
    echo ""
    echo "Example:"
    echo '  bundle: #Bundle & {'
    echo '    name: "my-project"'
    echo '    ...'
    echo '  }'
    exit 1
}

NAME=$(echo "$BUNDLE_JSON" | jq -r '.name')
VERSION=$(echo "$BUNDLE_JSON" | jq -r '.version')
OUTPUT=$(echo "$BUNDLE_JSON" | jq -r '.output')
ARCH=$(echo "$BUNDLE_JSON" | jq -r '.arch')

echo "Bundle: $NAME v$VERSION ($ARCH)"
echo "Output: $OUTPUT"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "=== Dry Run — Would collect: ==="
    echo "$BUNDLE_JSON" | jq '{
        repos: (.repos | keys),
        docker_app: (.docker.app | keys),
        docker_base: (.docker.base | keys),
        binaries: (.binaries | keys),
        debs: (.debs | keys),
        python_packages: .python.packages,
        symlinks: (.symlinks | length),
        checks: (.checks | length)
    }'
    exit 0
fi

mkdir -p "$OUTPUT"/{repos,docker,wheels,bin,debs,scripts}

# --- 1. Git bundles ---
echo ""
echo "=== Git Bundles ==="
echo "$BUNDLE_JSON" | jq -r '.repos | to_entries[] | "\(.key)\t\(.value.path)"' | while IFS=$'\t' read -r name path; do
    echo -n "  $name... "
    if [ -d "$path/.git" ]; then
        git -C "$path" bundle create "$OUTPUT/repos/$name.bundle" --all 2>/dev/null
        echo "$(du -h "$OUTPUT/repos/$name.bundle" | cut -f1)"
    else
        echo "SKIP (not a git repo)"
    fi
done

# --- 2. Docker images ---
echo ""
echo "=== Docker Images ==="
for section in app base; do
    echo "$BUNDLE_JSON" | jq -r ".docker.$section // {} | to_entries[] | \"\(.key)\t\(.value.image)\"" | while IFS=$'\t' read -r name image; do
        echo -n "  $image → $name.tar.gz... "
        if docker image inspect "$image" >/dev/null 2>&1; then
            docker save "$image" | gzip > "$OUTPUT/docker/$name.tar.gz"
            echo "$(du -h "$OUTPUT/docker/$name.tar.gz" | cut -f1)"
        else
            echo "SKIP (not found locally, try: docker pull $image)"
        fi
    done
done

# --- 3. Python wheels ---
echo ""
echo "=== Python Wheels ==="
PY_VERSION=$(echo "$BUNDLE_JSON" | jq -r '.python.version')
PACKAGES=$(echo "$BUNDLE_JSON" | jq -r '.python.packages[]' | tr '\n' ' ')
BOOTSTRAP=$(echo "$BUNDLE_JSON" | jq -r '.python.bootstrap')

if [ -n "$PACKAGES" ]; then
    pip download --dest "$OUTPUT/wheels" \
        --python-version "$PY_VERSION" \
        --platform manylinux2014_x86_64 --platform linux_x86_64 \
        --only-binary=:all: $PACKAGES 2>&1 | tail -3
fi

if [ "$BOOTSTRAP" = "true" ]; then
    pip download --dest "$OUTPUT/wheels" \
        --python-version "$PY_VERSION" \
        --platform manylinux2014_x86_64 --platform linux_x86_64 \
        --only-binary=:all: pip setuptools wheel 2>&1 | tail -1
fi
echo "  $(ls "$OUTPUT/wheels/" | wc -l) wheels"

# --- 4. Static binaries ---
echo ""
echo "=== Static Binaries ==="
echo "$BUNDLE_JSON" | jq -r '.binaries | to_entries[] | "\(.key)\t\(.value.source)\t\(.value.path)"' | while IFS=$'\t' read -r name source path; do
    echo -n "  $name... "
    if [ "$source" = "local" ]; then
        if [ -f "$path" ]; then
            cp "$path" "$OUTPUT/bin/$name"
            chmod +x "$OUTPUT/bin/$name"
            echo "$(du -h "$OUTPUT/bin/$name" | cut -f1)"
        else
            echo "SKIP (not found: $path)"
        fi
    elif [ "$source" = "url" ]; then
        curl -sSL "$path" -o "$OUTPUT/bin/$name"
        chmod +x "$OUTPUT/bin/$name"
        echo "$(du -h "$OUTPUT/bin/$name" | cut -f1)"
    fi
done

# --- 5. Debian packages ---
echo ""
echo "=== Debian Packages ==="
echo "$BUNDLE_JSON" | jq -r '.debs | to_entries[] | .value | "\(.package)\t\(.deps | join(" "))"' | while IFS=$'\t' read -r pkg deps; do
    for p in $pkg $deps; do
        echo -n "  $p... "
        apt-get download "$p" 2>/dev/null && mv "${p}"*.deb "$OUTPUT/debs/" 2>/dev/null && echo "OK" || echo "SKIP"
    done
done

# --- 6. Generate install and smoke test scripts ---
echo ""
echo "=== Generating scripts ==="

# Generate smoke test from checks
echo "$BUNDLE_JSON" | jq -r '.checks[] | "check \"\(.label)\" \"\(.command)\" \"\(.expected)\""' > "$OUTPUT/scripts/smoke-test-checks.sh"
echo "  $(echo "$BUNDLE_JSON" | jq '.checks | length') smoke test checks"

echo ""
echo "=== Bundle complete ==="
du -sh "$OUTPUT"
echo ""
echo "Artifacts: $(echo "$BUNDLE_JSON" | jq '._artifact_count // "?"')"
echo "Next: copy $OUTPUT to target machine, run: sudo bash scripts/install-airgapped.sh"
