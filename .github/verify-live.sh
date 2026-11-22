#!/usr/bin/env bash
# verify-live.sh URL FILE: fail unless URL serves exactly FILE.
#
# Both Cloudflare deploys used to run with continue-on-error, so a failed
# deploy left demo.quicue.ca and api.quicue.ca serving old builds while CI
# stayed green. apercue.ca had the same problem and the same fix: after
# deploying, compare what the live site serves with what was just built.
#
# Retries for about five minutes to allow for propagation.
set -euo pipefail

url="$1"
file="$2"
want=$(sha256sum "$file" | cut -d' ' -f1)
sep='?'
case "$url" in *\?*) sep='&' ;; esac

for _ in $(seq 1 20); do
    got=$(curl -fsSL "${url}${sep}v=${GITHUB_SHA:-local}" | sha256sum | cut -d' ' -f1 || true)
    if [ "$got" = "$want" ]; then
        echo "live: $url matches $file"
        exit 0
    fi
    sleep 15
done

echo "ERROR: $url does not serve the $file built from ${GITHUB_SHA:-this checkout}" >&2
exit 1
