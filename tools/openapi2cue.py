#!/usr/bin/env python3
"""Generate quicue.ca provider templates from OpenAPI specifications.

Takes an OpenAPI 3.x JSON spec and produces a CUE template directory
with #ActionDef entries for each operation, ready for use with
#BindCluster.

Usage:
    # From a local spec file
    python tools/openapi2cue.py spec.json \\
        --name netbox \\
        --types IPAMService,DCIMService \\
        --url-field netbox_url \\
        --auth-field netbox_token \\
        --auth-type api-key \\
        --auth-header "Authorization: Token"

    # Filter by OpenAPI tags
    python tools/openapi2cue.py cloudflare.json \\
        --name cloudflare \\
        --types CDNService,DNSService \\
        --url-field cf_api_url \\
        --auth-field cf_api_token \\
        --tags "Zones,DNS Records"

    # Dry run (print CUE to stdout)
    python tools/openapi2cue.py spec.json --name demo \\
        --types Service --url-field api_url \\
        --auth-field api_token --dry-run

Output:
    template/<name>/
        patterns/<name>.cue   — #<Name>Registry with #ActionDef entries
        meta/meta.cue         — #ProviderMatch type declarations

Zero dependencies — stdlib Python only.
"""

import argparse
import json
import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# OpenAPI parsing
# ---------------------------------------------------------------------------

def load_spec(path: str) -> dict:
    with open(path) as f:
        return json.load(f)


def resolve_ref(spec: dict, ref: str) -> dict:
    parts = ref.lstrip("#/").split("/")
    obj = spec
    for p in parts:
        obj = obj.get(p, {})
    return obj


def extract_operations(
    spec: dict,
    tags: list[str] | None = None,
    path_prefix: str | None = None,
) -> list[dict]:
    ops = []
    for path, path_item in spec.get("paths", {}).items():
        if path_prefix and not path.startswith(path_prefix):
            continue

        # Collect path-level parameters
        path_params = []
        for p in path_item.get("parameters", []):
            if "$ref" in p:
                p = resolve_ref(spec, p["$ref"])
            path_params.append(p)

        for method in ("get", "post", "put", "patch", "delete"):
            if method not in path_item:
                continue
            op = path_item[method]
            op_tags = op.get("tags", [])

            if tags and not any(t in op_tags for t in tags):
                continue

            # Merge path + operation params (operation takes precedence)
            params = list(path_params)
            for p in op.get("parameters", []):
                if "$ref" in p:
                    p = resolve_ref(spec, p["$ref"])
                params.append(p)

            ops.append({
                "method": method.upper(),
                "path": path,
                "operation_id": op.get("operationId", ""),
                "summary": op.get("summary", ""),
                "description": op.get("description", ""),
                "tags": op_tags,
                "parameters": params,
                "has_body": op.get("requestBody") is not None,
            })
    return ops


# ---------------------------------------------------------------------------
# Naming and classification
# ---------------------------------------------------------------------------

def to_snake(s: str) -> str:
    s = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s)
    s = re.sub(r"[^a-zA-Z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s)
    return s.lower().strip("_")


def action_key(method: str, path: str, op_id: str) -> str:
    if op_id:
        return to_snake(op_id)
    parts = [p for p in path.split("/") if p and not p.startswith("{")]
    key = method.lower() + "_" + "_".join(parts[-2:]) if parts else method.lower()
    return re.sub(r"[^a-z0-9_]", "_", key)


def infer_category(method: str, summary: str) -> str:
    low = summary.lower()
    if any(w in low for w in ("monitor", "metric", "health", "stat", "alert", "log")):
        return "monitor"
    if method in ("GET", "HEAD", "OPTIONS"):
        return "info"
    # For non-GET: only classify as "info" for genuine read operations,
    # not for creates/updates that happen to mention "list" in their summary
    if method == "POST" and any(w in low for w in ("search", "query", "check", "find")):
        return "info"
    if method in ("POST", "PUT", "PATCH", "DELETE"):
        return "admin"
    return "admin"


def truncate_description(s: str, max_len: int = 80) -> str:
    """Truncate at word boundary, escape double quotes."""
    s = s.replace('"', '\\"').replace("\n", " ").strip()
    if len(s) <= max_len:
        return s
    truncated = s[:max_len].rsplit(" ", 1)[0]
    return truncated.rstrip(".,;: ")


# ---------------------------------------------------------------------------
# CUE generation
# ---------------------------------------------------------------------------

def build_action(
    op: dict,
    url_field: str,
    auth_field: str,
    auth_type: str,
    auth_header: str,
) -> dict:
    method = op["method"]
    path = op["path"]
    summary = truncate_description(
        op["summary"] or op["description"] or f"{method} {path}"
    )
    key = action_key(method, path, op["operation_id"])
    category = infer_category(method, summary)

    # --- params ---
    params: dict[str, dict] = {}
    params["api_url"] = {"from_field": url_field}
    params["api_token"] = {"from_field": auth_field}

    # Path parameters → runtime params
    path_params = [p for p in op["parameters"] if p.get("in") == "path"]
    for p in path_params:
        pkey = to_snake(p["name"])
        params[pkey] = {}

    # Body placeholder for mutating methods
    if method in ("POST", "PUT", "PATCH") and op["has_body"]:
        params[f"{key}_json"] = {}

    # --- command_template ---
    curl_path = path
    for p in path_params:
        curl_path = curl_path.replace(
            "{" + p["name"] + "}", "{" + to_snake(p["name"]) + "}"
        )

    if auth_type == "bearer":
        auth_h = "-H 'Authorization: Bearer {api_token}'"
    elif auth_type == "api-key":
        # auth_header may be "X-API-Key" or "Authorization: Token"
        if ":" in auth_header:
            auth_h = f"-H '{auth_header} {{api_token}}'"
        else:
            auth_h = f"-H '{auth_header}: {{api_token}}'"
    else:
        auth_h = "-H 'Authorization: {api_token}'"

    parts = ["curl -s"]
    if method != "GET":
        parts.append(f"-X {method}")
    parts.append(auth_h)

    if method in ("POST", "PUT", "PATCH") and op["has_body"]:
        parts.append("-H 'Content-Type: application/json'")
        parts.append(f"-d '{{{key}_json}}'")

    parts.append(f"{{api_url}}{curl_path}")
    template = " ".join(parts)

    return {
        "key": key,
        "description": summary,
        "category": category,
        "params": params,
        "command_template": template,
        "idempotent": method in ("GET", "HEAD", "OPTIONS", "PUT"),
        "destructive": method == "DELETE",
    }


def format_params(params: dict) -> str:
    if not params:
        return "\t\tparams: {}"
    lines = ["\t\tparams: {"]
    for name, pdef in params.items():
        if "from_field" in pdef:
            lines.append(f'\t\t\t{name}: {{from_field: "{pdef["from_field"]}"}}')
        else:
            lines.append(f"\t\t\t{name}: {{}}")
    lines.append("\t\t}")
    return "\n".join(lines)


def render_registry(provider: str, actions: list[dict]) -> str:
    reg = "".join(w.capitalize() for w in provider.split("_"))
    lines = [
        f"// {provider} — auto-generated from OpenAPI spec",
        "//",
        "// Generated by: tools/openapi2cue.py",
        "// Review from_field mappings and adjust before use.",
        "//",
        f'// Usage:',
        f'//   import "quicue.ca/template/{provider}/patterns"',
        "",
        "package patterns",
        "",
        'import "quicue.ca/vocab"',
        "",
        f"#{reg}Registry: {{",
    ]

    for a in actions:
        lines.append(f'\t{a["key"]}: vocab.#ActionDef & {{')
        lines.append(f'\t\tname:             "{a["key"]}"')
        lines.append(f'\t\tdescription:      "{a["description"]}"')
        lines.append(f'\t\tcategory:         "{a["category"]}"')
        lines.append(format_params(a["params"]))
        lines.append(f'\t\tcommand_template: "{a["command_template"]}"')
        if a["idempotent"]:
            lines.append("\t\tidempotent:       true")
        if a["destructive"]:
            lines.append("\t\tdestructive:      true")
        lines.append("\t}")
        lines.append("")

    lines.append("\t...")
    lines.append("}")
    return "\n".join(lines) + "\n"


def render_meta(provider: str, types: list[str]) -> str:
    type_lines = "\n".join(f"\t\t{t}: true" for t in types)
    return f"""// {provider} provider type matching
package meta

import "quicue.ca/vocab"

match: vocab.#ProviderMatch & {{
\ttypes: {{
{type_lines}
\t}}
\tprovider: "{provider}"
}}
"""


def render_readme(provider: str, types: list[str], action_count: int) -> str:
    types_str = ", ".join(types)
    return f"""# {provider}

Auto-generated provider template for {provider}.

## Resource types

Matches resources with any of: `{types_str}`

## Actions

{action_count} actions generated from OpenAPI spec.

## Usage

```cue
import "quicue.ca/template/{provider}/patterns"

// Use in #BindCluster:
providers: {{
    {provider}: {{
        types: {{ /* ... */ }}
        registry: patterns.#{provider.replace("_", " ").title().replace(" ", "")}Registry
    }}
}}
```

## Post-generation checklist

1. Review `from_field` mappings — add bindings for path params that correspond to resource fields
2. Add any new resource types to `vocab/types.cue`
3. Validate: `cue vet ./template/{provider}/...`
4. Remove actions that aren't useful for your use case
5. Adjust categories (info/connect/admin/monitor) where the inference was wrong
"""


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Generate quicue.ca provider template from OpenAPI spec",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
Examples:
  python tools/openapi2cue.py netbox.json \\
      --name netbox --types IPAMService,DCIMService \\
      --url-field netbox_url --auth-field netbox_token \\
      --auth-type api-key --auth-header "Authorization: Token"

  python tools/openapi2cue.py cloudflare.json \\
      --name cloudflare --types CDNService,DNSService \\
      --url-field cf_api_url --auth-field cf_api_token \\
      --tags "Zones,DNS Records" --dry-run
""",
    )
    parser.add_argument("spec", help="Path to OpenAPI 3.x spec (JSON)")
    parser.add_argument("--name", required=True, help="Provider name (e.g., netbox)")
    parser.add_argument(
        "--types", required=True,
        help="Comma-separated resource types this provider serves",
    )
    parser.add_argument("--url-field", required=True, help="Resource field for base URL")
    parser.add_argument("--auth-field", required=True, help="Resource field for auth token")
    parser.add_argument(
        "--auth-type", default="bearer",
        choices=["bearer", "api-key", "basic"],
        help="Authentication type (default: bearer)",
    )
    parser.add_argument(
        "--auth-header", default="Authorization",
        help="Header name for api-key auth (default: Authorization)",
    )
    parser.add_argument("--tags", help="Comma-separated OpenAPI tags to include")
    parser.add_argument("--path-prefix", help="Only include paths starting with this")
    parser.add_argument(
        "--max-ops", type=int, default=50,
        help="Max operations to include (default: 50)",
    )
    parser.add_argument(
        "--out", help="Output directory (default: template/<name>/)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print CUE to stdout without writing files",
    )
    args = parser.parse_args()

    spec = load_spec(args.spec)
    tags = [t.strip() for t in args.tags.split(",")] if args.tags else None
    types = [t.strip() for t in args.types.split(",")]

    ops = extract_operations(spec, tags=tags, path_prefix=args.path_prefix)
    if not ops:
        print("No operations found matching filters.", file=sys.stderr)
        sys.exit(1)

    if len(ops) > args.max_ops:
        print(
            f"Found {len(ops)} operations, limiting to {args.max_ops}. "
            f"Use --max-ops to increase.",
            file=sys.stderr,
        )
        ops = ops[: args.max_ops]

    # Build actions, dedup keys
    actions = []
    seen = set()
    for op in ops:
        a = build_action(
            op,
            url_field=args.url_field,
            auth_field=args.auth_field,
            auth_type=args.auth_type,
            auth_header=args.auth_header,
        )
        key = a["key"]
        if key in seen:
            key = f"{key}_{a['category']}"
            a["key"] = key
        if key in seen:
            continue  # skip true duplicates
        seen.add(key)
        actions.append(a)

    registry = render_registry(args.name, actions)
    meta = render_meta(args.name, types)
    readme = render_readme(args.name, types, len(actions))

    out_dir = Path(args.out) if args.out else Path(f"template/{args.name}")

    if args.dry_run:
        print(f"=== {out_dir}/patterns/{args.name}.cue ===")
        print(registry)
        print(f"=== {out_dir}/meta/meta.cue ===")
        print(meta)
        print(f"Generated {len(actions)} actions from {len(ops)} operations.")
        return

    (out_dir / "patterns").mkdir(parents=True, exist_ok=True)
    (out_dir / "meta").mkdir(parents=True, exist_ok=True)

    (out_dir / "patterns" / f"{args.name}.cue").write_text(registry)
    (out_dir / "meta" / "meta.cue").write_text(meta)
    (out_dir / "README.md").write_text(readme)

    print(f"Generated {len(actions)} actions → {out_dir}/")
    print(f"  {out_dir}/patterns/{args.name}.cue")
    print(f"  {out_dir}/meta/meta.cue")
    print(f"  {out_dir}/README.md")
    print()
    print("Next steps:")
    print(f"  1. Review from_field mappings in patterns/{args.name}.cue")
    print(f"  2. Add resource types to vocab/types.cue if new")
    print(f"  3. Validate: cue vet ./template/{args.name}/...")


if __name__ == "__main__":
    main()
