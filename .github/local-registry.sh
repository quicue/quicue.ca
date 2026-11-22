#!/usr/bin/env bash
# local-registry.sh: serve the vendored apercue.ca@v0 from a local OCI registry.
#
# populate-cue-cache.sh copies the vendored module straight into the CUE
# module cache. CUE v0.15 accepts that; v0.17 does not. Publishing the
# vendored copy to a scratch registry goes through the normal module path,
# so it works on every CUE version and is the same flow consumers will use
# once apercue is published for real.
#
# Writes CUE_REGISTRY to $GITHUB_ENV when run in Actions, otherwise prints
# the export line. The registry runs until the job ends.
#
# Note: `cue mod registry` is documented as a test aid that may change.
set -euo pipefail

PORT="${CUE_LOCAL_REGISTRY_PORT:-5055}"
VERSION="${APERCUE_VENDOR_VERSION:-v0.0.1}"
VENDOR_DIR="cue.mod/pkg/apercue.ca@v0"

[ -d "$VENDOR_DIR" ] || { echo "FAIL: $VENDOR_DIR not found" >&2; exit 1; }

cue mod registry "localhost:${PORT}" > /tmp/cue-local-registry.log 2>&1 &
for _ in $(seq 1 20); do
    curl -fsS "http://localhost:${PORT}/v2/" > /dev/null 2>&1 && break
    sleep 0.5
done

REG="apercue.ca=localhost:${PORT}+insecure"
STAGE="$(mktemp -d)"
cp -r "$VENDOR_DIR"/. "$STAGE"/
(cd "$STAGE" && CUE_REGISTRY="$REG" cue mod publish "$VERSION")

if [ -n "${GITHUB_ENV:-}" ]; then
    echo "CUE_REGISTRY=$REG" >> "$GITHUB_ENV"
else
    echo "export CUE_REGISTRY=$REG"
fi
