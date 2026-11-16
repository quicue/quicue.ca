#!/usr/bin/env bash
# check-provider-counts.sh: provider counts in docs must match the source.
#   templates:  directories under template/ (the provider template set)
#   datacenter: providers declared in examples/datacenter/datacenter.cue
# "N provider templates" always means the template set. "N providers" on a
# line (or in a file) about the datacenter example means the datacenter
# count; elsewhere it means the template set. Tutorial counts in
# docs/getting-started.md (its own 3-resource example) are not checked.
set -uo pipefail
cd "$(dirname "$0")/.."

TEMPLATES=$(find template -mindepth 1 -maxdepth 1 -type d | wc -l)
DATACENTER=$(awk '/^_providers: \{/{f=1;next} f&&/^\}/{exit} f&&/^\t[a-z0-9_]+: patterns\.#ProviderDecl/{n++} END{print n}' examples/datacenter/datacenter.cue)
echo "provider templates: $TEMPLATES, datacenter providers: $DATACENTER"

FAIL=0
fail() { echo "  FAIL: $*"; FAIL=$((FAIL+1)); }
FILES="README.md docs/*.md examples/datacenter/README.md examples/datacenter/datacenter.cue"
while IFS= read -r hit; do
    file=${hit%%:*}; rest=${hit#*:}; line=${rest%%:*}; text=${rest#*:}
    for n in $(echo "$text" | grep -oE '\[?\b[0-9]+ provider templates' | grep -oE '[0-9]+'); do
        [ "$n" = "$TEMPLATES" ] || fail "$file:$line: '$n provider templates', expected $TEMPLATES"
    done
    for n in $(echo "$text" | grep -oE '\b[0-9]+ (of [0-9]+ )?providers\b' | grep -oE '^[0-9]+'); do
        if echo "$text $file" | grep -qiE 'datacenter|30 resources|30-resource'; then want=$DATACENTER; else want=$TEMPLATES; fi
        [ "$n" = "$want" ] || fail "$file:$line: '$n providers', expected $want"
    done
    for n in $(echo "$text" | grep -oE '\bof (the )?\[?[0-9]+ provider' | grep -oE '[0-9]+'); do
        [ "$n" = "$TEMPLATES" ] || fail "$file:$line: 'of $n', expected of $TEMPLATES"
    done
done < <(grep -nHE '\b[0-9]+ (of [0-9]+ )?(provider templates|providers)\b' $FILES | grep -v '^docs/getting-started.md:3:')

[ "$FAIL" -eq 0 ] && echo "provider counts: all match" || { echo "provider counts: $FAIL stale"; exit 1; }
