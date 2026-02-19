#!/bin/bash
# operator/build.sh — Build the demo.quicue.ca execution surface
#
# Single CUE evaluation exports all data as JSON (including the index
# page as a CUE string projection). Python splits into individual files.
#
# Requirements: cue CLI, python3
# Usage: bash operator/build.sh           # build only
#        bash operator/build.sh --deploy  # build + deploy to Cloudflare Pages

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLIC_DIR="$SCRIPT_DIR/public"
BULK_TMP="/tmp/quicue-bulk-$$.json"

cd "$ROOT_DIR"

# Clean generated files — preserve hand-crafted HTML views (browse, graph, planner, explore)
rm -f "$PUBLIC_DIR"/{plan.json,cluster-summary.json,.bound_commands.json,.build-stats.json}
rm -f "$PUBLIC_DIR"/{notebook.ipynb,rundeck-jobs.yaml,deploy.sh,ops.json}
rm -f "$PUBLIC_DIR"/{graph.jsonld,hydra.jsonld,interaction.json}
rm -f "$PUBLIC_DIR"/index.html
rm -rf "$PUBLIC_DIR"/wiki
mkdir -p "$PUBLIC_DIR/wiki"

GENERATED_AT=$(date -u +"%Y-%m-%d %H:%M UTC")

echo "=== demo.quicue.ca Build ==="
echo ""

# ============================================================================
# Phase 1: Single CUE export (all data + index HTML in one evaluation)
# ============================================================================
echo "--- Exporting all data (single evaluation) ---"

if ! cue export ./examples/datacenter/ -e _bulk --out json \
    -t timestamp="$GENERATED_AT" > "$BULK_TMP" 2>&1; then
    echo "ERROR: CUE export failed"
    cat "$BULK_TMP"
    rm -f "$BULK_TMP"
    exit 1
fi

BULK_SIZE=$(stat -c%s "$BULK_TMP" 2>/dev/null || echo 0)
echo "  Bulk export: ${BULK_SIZE}B"
echo ""

# ============================================================================
# Phase 2: Split into individual files (JSON, YAML, text, HTML)
# ============================================================================
echo "--- Splitting into output files ---"

python3 "$SCRIPT_DIR/split_bulk.py" "$BULK_TMP" "$PUBLIC_DIR"
rm -f "$BULK_TMP"
echo ""

# ============================================================================
# Phase 3: Render wiki (MkDocs → static HTML)
# ============================================================================
if command -v mkdocs &>/dev/null; then
    echo "--- Rendering wiki (MkDocs) ---"
    WIKI_SRC="$PUBLIC_DIR/wiki"
    WIKI_OUT="/tmp/quicue-wiki-$$"
    (cd "$WIKI_SRC" && mkdocs build --quiet --site-dir "$WIKI_OUT" 2>&1)
    rm -rf "$WIKI_SRC"
    mv "$WIKI_OUT" "$WIKI_SRC"
    echo "  Wiki rendered to $WIKI_SRC"
    echo ""
else
    echo "--- mkdocs not found, wiki stays as raw markdown ---"
    echo ""
fi

# ============================================================================
# Phase 4: Safety check — no real IPs in output
# ============================================================================
echo "--- IP safety check ---"
LEAKED=$(grep -rl '172\.20\.' "$PUBLIC_DIR" 2>/dev/null || true)
if [ -n "$LEAKED" ]; then
    echo "ERROR: Real IPs (172.20.x.x) found in output files:"
    echo "$LEAKED"
    echo ""
    echo "This build uses examples/datacenter/ which should only have RFC 5737 TEST-NET IPs."
    echo "Check that the CUE source has no private data."
    exit 1
fi
echo "  No 172.20.x.x IPs found — clean"
echo ""

# ============================================================================
# Summary
# ============================================================================
echo "=== Build complete ==="
echo ""
echo "To preview: python3 -m http.server -d $PUBLIC_DIR 8081"
echo "To deploy:  wrangler pages deploy $PUBLIC_DIR --project-name quicue-demo"
