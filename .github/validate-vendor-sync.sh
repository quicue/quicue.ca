#!/usr/bin/env bash
# validate-vendor-sync.sh — Verify vendored apercue.ca@v0 is internally consistent.
#
# Checks that the vendored copy has:
#   1. All expected subdirectories (patterns, vocab, charter, views)
#   2. A minimum number of CUE files (catches incomplete syncs)
#   3. A recorded checksum that matches the vendored content
#
# If APERCUE_SOURCE is set (path to upstream apercue repo), also validates
# that the vendored copy matches upstream. This is optional — CI runs
# without it, but developers can run it locally after syncing.
#
# Usage:
#   bash .github/validate-vendor-sync.sh                    # CI mode
#   APERCUE_SOURCE=~/apercue bash .github/validate-vendor-sync.sh  # full sync check
set -euo pipefail

VENDOR_DIR="cue.mod/pkg/apercue.ca@v0"
CHECKSUM_FILE=".github/apercue-vendor.sha256"

FAIL=0

echo "=== Vendor Sync Validation ==="

# 1. Vendor directory exists
if [ ! -d "$VENDOR_DIR" ]; then
    echo "FAIL: $VENDOR_DIR does not exist"
    exit 1
fi

# 2. Required subdirectories
for sub in patterns vocab charter views; do
    if [ ! -d "$VENDOR_DIR/$sub" ]; then
        echo "FAIL: $VENDOR_DIR/$sub missing"
        FAIL=$((FAIL + 1))
    fi
done

# 3. Minimum file count (catches incomplete syncs)
FILE_COUNT=$(find "$VENDOR_DIR" -name '*.cue' | wc -l)
echo "Vendored CUE files: $FILE_COUNT"
if [ "$FILE_COUNT" -lt 20 ]; then
    echo "FAIL: Only $FILE_COUNT CUE files (expected >= 20). Incomplete vendor?"
    FAIL=$((FAIL + 1))
fi

# 4. Checksum validation
CURRENT_CHECKSUM=$(find "$VENDOR_DIR" -name '*.cue' -exec sha256sum {} + | sort -k2 | sha256sum | cut -d' ' -f1)
echo "Vendor checksum: $CURRENT_CHECKSUM"

if [ -f "$CHECKSUM_FILE" ]; then
    RECORDED=$(cat "$CHECKSUM_FILE" | tr -d '[:space:]')
    if [ "$CURRENT_CHECKSUM" = "$RECORDED" ]; then
        echo "PASS: Checksum matches recorded value"
    else
        echo "WARN: Checksum differs from recorded value"
        echo "  Recorded: $RECORDED"
        echo "  Current:  $CURRENT_CHECKSUM"
        echo "  If you intentionally updated the vendor, run:"
        echo "    echo '$CURRENT_CHECKSUM' > $CHECKSUM_FILE"
    fi
else
    echo "INFO: No checksum file yet. Creating $CHECKSUM_FILE"
    echo "$CURRENT_CHECKSUM" > "$CHECKSUM_FILE"
    echo "  Recorded: $CURRENT_CHECKSUM"
fi

# 5. Optional: full upstream comparison
if [ -n "${APERCUE_SOURCE:-}" ]; then
    echo ""
    echo "=== Upstream Comparison ==="
    if [ ! -d "$APERCUE_SOURCE" ]; then
        echo "WARN: APERCUE_SOURCE=$APERCUE_SOURCE does not exist, skipping"
    else
        DRIFT=0
        for sub in patterns vocab charter views; do
            if [ -d "$APERCUE_SOURCE/$sub" ]; then
                DIFF=$(diff -rq "$VENDOR_DIR/$sub" "$APERCUE_SOURCE/$sub" --exclude='*.pyc' 2>/dev/null || true)
                if [ -n "$DIFF" ]; then
                    echo "DRIFT in $sub:"
                    echo "$DIFF" | head -10
                    DRIFT=$((DRIFT + 1))
                fi
            fi
        done
        if [ "$DRIFT" -eq 0 ]; then
            echo "PASS: Vendored copy matches upstream"
        else
            echo "WARN: $DRIFT subdirectory(ies) have drifted from upstream"
            FAIL=$((FAIL + 1))
        fi
    fi
fi

echo ""
if [ "$FAIL" -gt 0 ]; then
    echo "FAILED: $FAIL issue(s) found"
    exit 1
else
    echo "Vendor validation passed."
fi
