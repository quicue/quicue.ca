#!/usr/bin/env python3
"""Validate and sync registry data between .kb/ and wiki/docs_export.cue.

Compares the authoritative .kb/ CUE registries against the embedded data in
wiki/docs_export.cue and reports drift. With --diff, shows per-entry changes.

Usage:
    python3 wiki/sync_registries.py              # report drift
    python3 wiki/sync_registries.py --diff       # show per-entry details
    python3 wiki/sync_registries.py --generate   # emit replacement CUE blocks
"""

import json
import os
import subprocess
import sys


REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def cue_export(cwd, expr=None):
    """Run cue export in a directory, optionally with -e expr."""
    cmd = ["cue", "export", ".", "--out", "json"]
    if expr:
        cmd.extend(["-e", expr])
    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  ERROR: cue export in {cwd} failed: {result.stderr.strip()}", file=sys.stderr)
        return None
    return json.loads(result.stdout)


def get_docs_stats():
    """Export docs.stats from wiki/."""
    wiki_dir = os.path.join(REPO_ROOT, "wiki")
    return cue_export(wiki_dir, "docs.stats")


def get_docs_keys():
    """Export docs registry keys from wiki/ for per-entry comparison."""
    wiki_dir = os.path.join(REPO_ROOT, "wiki")
    # Export full docs to get actual keys
    data = cue_export(wiki_dir, "docs")
    if not data:
        return {}
    return {
        "modules": set(data.get("Modules", {}).keys()),
        "decisions": set(data.get("Decisions", {}).keys()),
        "patterns": set(data.get("Patterns", {}).keys()),
        "insights": set(data.get("Insights", {}).keys()),
        "downstream": set(data.get("Downstream", {}).keys()),
        "sites": set(data.get("Sites", {}).keys()),
    }


def get_kb_keys():
    """Export registry keys from .kb/ sources."""
    kb = os.path.join(REPO_ROOT, ".kb")
    result = {}

    # Modules, downstream, sites from .kb/ root
    root = cue_export(kb)
    if root:
        result["modules"] = set(root.get("modules", {}).keys())
        result["downstream"] = set(root.get("downstream", {}).keys())
        result["sites"] = set(root.get("sites", {}).keys())

    # Decisions from .kb/decisions/
    dec = cue_export(os.path.join(kb, "decisions"))
    if dec:
        result["decisions"] = set(dec.keys())

    # Patterns from .kb/patterns/
    pat = cue_export(os.path.join(kb, "patterns"))
    if pat:
        result["patterns"] = set(pat.keys())

    # Insights from .kb/insights/
    ins = cue_export(os.path.join(kb, "insights"))
    if ins:
        result["insights"] = set(ins.keys())

    return result


def report_drift(show_diff=False):
    """Compare .kb/ registries against wiki/docs_export.cue and report drift."""
    print("Syncing .kb/ registries → wiki/docs_export.cue\n")

    stats = get_docs_stats()
    if not stats:
        print("ERROR: Could not export docs.stats from wiki/", file=sys.stderr)
        return 1

    kb_keys = get_kb_keys()
    docs_keys = get_docs_keys() if show_diff else {}

    stat_map = {
        "modules":    ("total_modules",    ".kb/modules.cue"),
        "decisions":  ("total_decisions",   ".kb/decisions/"),
        "patterns":   ("total_patterns",    ".kb/patterns/"),
        "insights":   ("total_insights",    ".kb/insights/"),
        "downstream": ("total_downstream",  ".kb/downstream.cue"),
        "sites":      ("total_sites",       ".kb/sites.cue"),
    }

    drifted = False
    for registry, (stat_key, source) in stat_map.items():
        docs_count = stats.get(stat_key, 0)
        kb_count = len(kb_keys.get(registry, set()))

        if docs_count == kb_count:
            status = "OK"
        else:
            status = "DRIFT"
            drifted = True

        print(f"  {registry:12s}  docs={docs_count:3d}  kb={kb_count:3d}  [{status}]  ({source})")

        if show_diff and registry in docs_keys and registry in kb_keys:
            dk = docs_keys[registry]
            kk = kb_keys[registry]
            missing = kk - dk
            extra = dk - kk
            if missing:
                for m in sorted(missing):
                    print(f"    + {m} (in .kb/ but not in docs)")
            if extra:
                for e in sorted(extra):
                    print(f"    - {e} (in docs but not in .kb/)")

    print()
    if drifted:
        print("DRIFT DETECTED. Update wiki/docs_export.cue to match .kb/ registries.")
        return 1
    else:
        print("All registries in sync.")
        return 0


def generate_cue_value(val, indent=2):
    """Convert a Python value to CUE source text."""
    prefix = "\t" * indent
    if isinstance(val, str):
        if "\n" in val:
            return f'"""\n{prefix}\t{val}\n{prefix}\t"""'
        return json.dumps(val)
    elif isinstance(val, bool):
        return "true" if val else "false"
    elif isinstance(val, (int, float)):
        return str(val)
    elif isinstance(val, list):
        if not val:
            return "[]"
        items = ", ".join(json.dumps(v) if isinstance(v, str) else generate_cue_value(v, indent) for v in val)
        return f"[{items}]"
    elif isinstance(val, dict):
        if not val:
            return "{}"
        # Check if it's a struct-as-set (all values are true)
        if all(v is True for v in val.values()):
            items = ", ".join(f"{json.dumps(k)}: true" for k in val)
            return "{" + items + "}"
        lines = []
        for k, v in val.items():
            cue_val = generate_cue_value(v, indent + 1)
            # Quote keys that need it
            if k.startswith("@") or "-" in k or not k.replace("_", "").isalnum():
                k = json.dumps(k)
            lines.append(f"{prefix}\t{k}: {cue_val}")
        return "{\n" + "\n".join(lines) + f"\n{prefix}}}"
    return str(val)


def generate_block(registry_name, data, entry_indent=1):
    """Generate a CUE block for a registry."""
    lines = []
    prefix = "\t" * entry_indent
    for key, entry in data.items():
        # Quote keys with special chars
        if "-" in key or key.startswith("@") or not key.replace("_", "").isalnum():
            key_str = json.dumps(key)
        else:
            key_str = key
        lines.append(f"{prefix}{key_str}: {{")
        for field, val in entry.items():
            if field.startswith("@"):
                field_str = json.dumps(field)
            else:
                field_str = field
            cue_val = generate_cue_value(val, entry_indent + 1)
            lines.append(f"{prefix}\t{field_str}: {cue_val}")
        lines.append(f"{prefix}}}")
    return "\n".join(lines)


def generate_replacement():
    """Generate replacement CUE source blocks from .kb/ registries."""
    kb = os.path.join(REPO_ROOT, ".kb")
    print("// Generated by wiki/sync_registries.py — do not edit manually\n")

    # Modules
    root = cue_export(kb)
    if root and "modules" in root:
        print("_modules: {")
        print(generate_block("modules", root["modules"]))
        print("}\n")

    # Decisions
    dec = cue_export(os.path.join(kb, "decisions"))
    if dec:
        print("_decisions: {")
        print(generate_block("decisions", dec))
        print("}\n")

    # Patterns
    pat = cue_export(os.path.join(kb, "patterns"))
    if pat:
        print("_patterns: {")
        print(generate_block("patterns", pat))
        print("}\n")

    # Insights
    ins = cue_export(os.path.join(kb, "insights"))
    if ins:
        print("_insights: {")
        print(generate_block("insights", ins))
        print("}\n")

    # Downstream
    if root and "downstream" in root:
        print("_downstream: {")
        print(generate_block("downstream", root["downstream"]))
        print("}\n")

    # Sites
    if root and "sites" in root:
        print("_sites: {")
        print(generate_block("sites", root["sites"]))
        print("}\n")


def main():
    show_diff = "--diff" in sys.argv
    generate = "--generate" in sys.argv

    if generate:
        generate_replacement()
        return 0

    return report_drift(show_diff=show_diff)


if __name__ == "__main__":
    sys.exit(main())
