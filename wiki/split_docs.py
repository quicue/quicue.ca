#!/usr/bin/env python3
"""Split bulk CUE docs export into individual markdown files.

One CUE evaluation produces all documentation as JSON. This script
splits it into the individual files that MkDocs expects.

Usage: python3 wiki/split_docs.py /tmp/docs-bulk.json docs/
"""

import json
import os
import sys


def write_text(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <docs-bulk.json> <output_dir>", file=sys.stderr)
        sys.exit(1)

    bulk_path = sys.argv[1]
    out_dir = sys.argv[2]

    with open(bulk_path) as f:
        bulk = json.load(f)

    files = bulk.get("files", {})
    stats = bulk.get("stats", {})
    written = 0

    for fpath, entry in files.items():
        content = entry if isinstance(entry, str) else entry.get("content", "")
        full = os.path.join(out_dir, fpath)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        write_text(full, content)
        written += 1

    print(f"  Docs: {written} files written to {out_dir}/")
    if stats:
        print(f"  Modules: {stats.get('total_modules', '?')}")
        print(f"  Decisions: {stats.get('total_decisions', '?')}")
        print(f"  Patterns: {stats.get('total_patterns', '?')}")
        print(f"  Insights: {stats.get('total_insights', '?')}")
        print(f"  Types: {stats.get('total_types', '?')}")
        print(f"  Sites: {stats.get('total_sites', '?')}")


if __name__ == "__main__":
    main()
