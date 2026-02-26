#!/usr/bin/env bash
# Build per-tier JSON data files from CUE definitions
#
# Each tier exports: vizData, commands, deployment_plan, impact, spof, summary
# Same topology, different providers — that's the whole point.

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${DIR}/data"

mkdir -p "$OUT"

cd "$DIR"

echo "Building tier data..."
for tier in desktop node cluster enterprise; do
    echo "  ${tier}..."
    cue export ./ -e "${tier}" --out json > "${OUT}/${tier}.json"
done

echo ""
echo "Done. $(ls "${OUT}"/*.json | wc -l) files in ${OUT}/"
ls -lh "${OUT}"/*.json

echo ""
echo "Topology (shared across all tiers):"
cue export ./ -e desktop.vizData.metrics --out json
