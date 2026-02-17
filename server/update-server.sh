#!/bin/bash
# server/update-server.sh — Export CUE data and push to api.quicue.ca
#
# Usage: DEPLOY_HOST=myhost DEPLOY_CONTAINER=625 bash server/update-server.sh [--rebuild]
#   --rebuild  Also rebuild the Docker image (needed after code changes)
#
# Required env vars:
#   DEPLOY_HOST       Proxmox node hostname (SSH target)
#   DEPLOY_CONTAINER  LXC container ID on the Proxmox node

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REMOTE="${DEPLOY_HOST:?Set DEPLOY_HOST to the Proxmox node hostname}"
CT="${DEPLOY_CONTAINER:?Set DEPLOY_CONTAINER to the LXC container ID}"

cd "$ROOT_DIR"

echo "=== api.quicue.ca Update ==="

# Phase 1: Export CUE data
echo "--- Exporting CUE data ---"
cue export ./examples/datacenter/ -e openapi_spec --out json > /tmp/quicue-openapi.json
cue export ./examples/datacenter/ -e jsonld --out json > /tmp/quicue-graph.jsonld
cue export ./examples/datacenter/ -e datacenter_hydra --out json > /tmp/quicue-hydra.jsonld
echo "  openapi.json: $(wc -c < /tmp/quicue-openapi.json)B"
echo "  graph.jsonld: $(wc -c < /tmp/quicue-graph.jsonld)B"
echo "  hydra.jsonld: $(wc -c < /tmp/quicue-hydra.jsonld)B"

# Phase 2: Push data files
echo "--- Pushing to container $CT ---"
scp -q /tmp/quicue-openapi.json /tmp/quicue-graph.jsonld /tmp/quicue-hydra.jsonld "$REMOTE:/tmp/"
ssh "$REMOTE" "pct push $CT /tmp/quicue-openapi.json /opt/quicue/quicue.ca/catalogue/public/openapi.json"
ssh "$REMOTE" "pct exec $CT -- bash -c '
  cp /tmp/quicue-graph.jsonld /var/lib/docker/volumes/server_deploy-data/_data/graph.jsonld
  cp /tmp/quicue-hydra.jsonld /var/lib/docker/volumes/server_deploy-data/_data/hydra.jsonld
'"
ssh "$REMOTE" "pct push $CT /tmp/quicue-graph.jsonld /tmp/quicue-graph.jsonld"
ssh "$REMOTE" "pct push $CT /tmp/quicue-hydra.jsonld /tmp/quicue-hydra.jsonld"
echo "  Data files pushed"

# Phase 3: Rebuild image (if requested)
if [[ "${1:-}" == "--rebuild" ]]; then
    echo "--- Syncing server code ---"
    rsync -avz --delete "$SCRIPT_DIR/app/" "$REMOTE:/tmp/quicue-server-app/"
    ssh "$REMOTE" "for f in \$(find /tmp/quicue-server-app -type f); do
      rel=\${f#/tmp/quicue-server-app/}
      dir=\$(dirname \$rel)
      pct exec $CT -- mkdir -p /opt/quicue/quicue.ca/server/app/\$dir
      pct push $CT \$f /opt/quicue/quicue.ca/server/app/\$rel
    done"
    echo "--- Rebuilding Docker image ---"
    ssh "$REMOTE" "pct exec $CT -- bash -c 'cd /opt/quicue/quicue.ca/server && docker compose build --no-cache api'"
    echo "--- Restarting ---"
    ssh "$REMOTE" "pct exec $CT -- bash -c 'cd /opt/quicue/quicue.ca/server && docker compose up -d api'"
else
    # Just restart to pick up new spec (auto-reload handles spec, but restart clears lock state)
    echo "--- Restarting API ---"
    ssh "$REMOTE" "pct exec $CT -- docker restart server-api-1"
fi

# Phase 4: Verify
echo "--- Verifying ---"
sleep 3
HEALTH=$(curl -sf https://api.quicue.ca/api/v1/healthz 2>/dev/null)
ROUTES=$(echo "$HEALTH" | python3 -c "import json,sys; print(json.load(sys.stdin)['route_count'])" 2>/dev/null)
echo "  api.quicue.ca: $ROUTES routes loaded"

echo ""
echo "=== Update complete ==="
