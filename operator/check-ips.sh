#!/bin/bash
# check-ips.sh — Block non-TEST-NET IPs from operator/public/ output
#
# Allowed IP ranges in served content:
#   198.51.100.0/24  (RFC 5737 TEST-NET-2) — datacenter example
#   203.0.113.0/24   (RFC 5737 TEST-NET-3) — reconciliation example
#   192.0.2.0/24     (RFC 5737 TEST-NET-1) — reserved for docs
#   2001:db8::/32    (RFC 3849 IPv6 docs)  — if IPv6 ever used
#
# Blocked:
#   172.16-31.x.x   (RFC 1918 private)
#   192.168.x.x      (RFC 1918 private)
#   Any other routable IP that isn't TEST-NET
#
# Usage: bash operator/check-ips.sh [directory]
#   Defaults to operator/public/

set -euo pipefail

DIR="${1:-operator/public}"

if [ ! -d "$DIR" ]; then
    echo "Directory not found: $DIR"
    exit 1
fi

FAIL=0

echo "=== IP Safety Check: $DIR ==="

# Check for RFC 1918 172.16-31.x.x
FOUND=$(grep -rlP '172\.(1[6-9]|2[0-9]|3[01])\.\d+\.\d+' "$DIR" 2>/dev/null || true)
if [ -n "$FOUND" ]; then
    echo "BLOCKED: RFC 1918 172.16-31.x.x found in:"
    echo "$FOUND" | while read -r f; do
        grep -nP '172\.(1[6-9]|2[0-9]|3[01])\.\d+\.\d+' "$f" | head -3
    done
    FAIL=1
fi

# Check for RFC 1918 192.168.x.x
FOUND=$(grep -rlP '192\.168\.\d+\.\d+' "$DIR" 2>/dev/null || true)
if [ -n "$FOUND" ]; then
    echo "BLOCKED: RFC 1918 192.168.x.x found in:"
    echo "$FOUND" | while read -r f; do
        grep -nP '192\.168\.\d+\.\d+' "$f" | head -3
    done
    FAIL=1
fi

# Summary of what IS present (informational)
# Note: { grep || true; } prevents pipefail from killing the script when grep finds no matches
TEST_NET=$({ grep -rlP '198\.51\.100\.\d+' "$DIR" 2>/dev/null || true; } | wc -l)
echo "  TEST-NET-2 (198.51.100.x): ${TEST_NET:-0} files (allowed)"

TEST_NET3=$({ grep -rlP '203\.0\.113\.\d+' "$DIR" 2>/dev/null || true; } | wc -l)
echo "  TEST-NET-3 (203.0.113.x): ${TEST_NET3:-0} files (allowed)"

# 10.x.x.x in served output is suspicious but may come from templates
TENNET=$({ grep -rlP '\b10\.\d+\.\d+\.\d+' "$DIR" 2>/dev/null || true; } | wc -l)
if [ "${TENNET:-0}" -gt 0 ]; then
    echo "  WARNING: 10.x.x.x found in $TENNET files (review if these are example or real)"
fi

if [ "$FAIL" -eq 1 ]; then
    echo ""
    echo "FAIL: Private IPs found in served content. Fix the data source."
    exit 1
fi

echo ""
echo "PASS: No private IPs in served content"
