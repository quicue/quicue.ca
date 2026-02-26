#!/usr/bin/env bash
# Populate the CUE v0.15 module cache from vendored dependencies.
#
# CUE v0.15 resolves declared deps from ~/.cache/cue/mod/, not cue.mod/pkg/.
# Since apercue.ca isn't published to a CUE registry, we populate the cache
# from the vendored copy checked into the repo.
set -euo pipefail

cache_dir="$HOME/.cache/cue/mod/extract/apercue.ca@v0.0.1"
mkdir -p "$cache_dir"

if [ -d "cue.mod/pkg/apercue.ca@v0" ]; then
  cp -r cue.mod/pkg/apercue.ca@v0/* "$cache_dir/"
  # CUE needs a module.cue in the cached module root
  if [ ! -f "$cache_dir/cue.mod/module.cue" ]; then
    mkdir -p "$cache_dir/cue.mod"
    cat > "$cache_dir/cue.mod/module.cue" << 'MODEOF'
module: "apercue.ca@v0"
language: version: "v0.15.4"
source: kind: "self"
MODEOF
  fi
  echo "Cache populated: $(find "$cache_dir" -name '*.cue' | wc -l) CUE files"
else
  echo "WARNING: cue.mod/pkg/apercue.ca@v0 not found, skipping cache population"
fi
