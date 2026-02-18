#!/usr/bin/env bash
# Build a static version of the API from pre-computed CUE exports.
# All answers are already known — this just shapes them as HTTP responses.
#
# Usage: ./build-static-api.sh [output_dir]
# Requires: cue, python3, jq

set -euo pipefail

OUT="${1:-/tmp/static-api}"
DCDIR="./examples/datacenter"
REPOROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPOROOT"

echo "Building static API from $DCDIR → $OUT"
rm -rf "$OUT"
mkdir -p "$OUT/api/v1" "$OUT/api/v1/resources" "$OUT/api/v1/deploy"

# ─── Step 1: Export everything from CUE ──────────────────────────────────────
echo "Exporting from CUE..."
BULK=$(mktemp)
OPENAPI=$(mktemp)

cue export "$DCDIR" -e _bulk --out json \
  -t timestamp="$(date -u +'%Y-%m-%d %H:%M UTC')" > "$BULK"
cue export "$DCDIR" -e openapi_spec --out json > "$OPENAPI"

# ─── Step 2: Root endpoint ───────────────────────────────────────────────────
cat > "$OUT/index.json" << 'EOF'
{
  "service": "quicue-api",
  "version": "0.1.0",
  "mode": "static (pre-computed from CUE)",
  "data_source": "examples/datacenter/ (RFC 5737 TEST-NET)",
  "explorer": "https://demo.quicue.ca",
  "docs": "/docs/index.html",
  "health": "/api/v1/healthz",
  "spec": "/api/v1/spec-info",
  "hydra": "/api/v1/hydra",
  "graph": "/api/v1/graph.jsonld"
}
EOF

# ─── Step 2b: API version index (now generated from CUE as Hydra EntryPoint) ─

# ─── Step 3: Health endpoints ────────────────────────────────────────────────
ROUTE_COUNT=$(jq '.bound_commands | [to_entries[].value | to_entries | length] | add' "$BULK")

cat > "$OUT/api/v1/healthz.json" << EOF
{
  "status": "ok",
  "spec_loaded": true,
  "route_count": $ROUTE_COUNT,
  "spec_mtime": null
}
EOF
cp "$OUT/api/v1/healthz.json" "$OUT/api/v1/readyz.json"

# ─── Step 4: Spec info ───────────────────────────────────────────────────────
python3 << PYEOF > "$OUT/api/v1/spec-info.json"
import json, sys
with open("$BULK") as f:
    bulk = json.load(f)
with open("$OPENAPI") as f:
    spec = json.load(f)

# Count categories and providers from the OpenAPI spec paths
categories = {}
providers = {}
destructive = 0
for path, methods in spec.get("paths", {}).items():
    for method, op in methods.items():
        tags = op.get("tags", [])
        for tag in tags:
            categories[tag] = categories.get(tag, 0) + 1
        prov = op.get("x-provider", "unknown")
        providers[prov] = providers.get(prov, 0) + 1
        if op.get("x-destructive", False):
            destructive += 1

json.dump({
    "route_count": sum(categories.values()),
    "spec_mtime": None,
    "last_reload": None,
    "categories": categories,
    "providers": providers,
    "destructive_count": destructive,
}, sys.stdout, indent=2)
PYEOF

# ─── Step 5: Semantic endpoints ──────────────────────────────────────────────
jq '.hydra' "$BULK" > "$OUT/api/v1/hydra.json"
jq '.hydra_entrypoint' "$BULK" > "$OUT/api/v1/index.json"
jq '.hydra_collection' "$BULK" > "$OUT/api/v1/resources/index.json"
jq '.graph_jsonld' "$BULK" > "$OUT/api/v1/graph.jsonld.json"
jq '.skos_types' "$BULK" > "$OUT/api/v1/types.json"

# ─── Step 6: Pre-generate all 654 mock action responses ─────────────────────
echo "Generating mock responses for all resource/provider/action combos..."
python3 << PYEOF
import json, os

with open("$OPENAPI") as f:
    spec = json.load(f)

out_dir = "$OUT/api/v1/resources"
count = 0

for path, methods in spec.get("paths", {}).items():
    for method, op in methods.items():
        # path looks like /resources/{resource}/{provider}/{action}
        # operationId looks like resource--provider--action
        op_id = op.get("operationId", "")
        parts = op_id.split("--")
        if len(parts) != 3:
            continue
        resource, provider, action = parts

        # Create directory structure: resources/{resource}/{provider}/
        resource_dir = os.path.join(out_dir, resource, provider)
        os.makedirs(resource_dir, exist_ok=True)

        response = {
            "mode": "mock",
            "path": f"/resources/{resource}/{provider}/{action}",
            "command": op.get("x-command", ""),
            "provider": provider,
            "category": op.get("tags", ["info"])[0] if op.get("tags") else "info",
            "output": None,
            "returncode": None,
            "duration_ms": None,
            "destructive": op.get("x-destructive", False),
            "idempotent": op.get("x-idempotent", True),
        }

        with open(os.path.join(resource_dir, f"{action}.json"), "w") as f:
            json.dump(response, f, indent=2)
        count += 1

print(f"Generated {count} mock action responses")
PYEOF

# ─── Step 7: Deploy endpoints (static mock state) ───────────────────────────
echo '{"entries": [], "count": 0}' > "$OUT/api/v1/deploy/history.json"
echo '{"locked": false, "operator": null, "acquired_at": null, "expires_at": null}' > "$OUT/api/v1/deploy/lock.json"

# ─── Step 8: OpenAPI spec + Swagger UI ───────────────────────────────────────
# Patch OpenAPI spec for static serving:
# 1. Change POST → GET (static files can't accept POST)
# 2. Prefix paths with /api/v1 (to match the static file layout)
python3 << PYEOF > "$OUT/openapi.json"
import json, sys

with open("$OPENAPI") as f:
    spec = json.load(f)

# Rewrite paths: POST → GET, add /api/v1 prefix
new_paths = {}
for path, methods in spec.get("paths", {}).items():
    new_path = f"/api/v1{path}"
    new_methods = {}
    for method, op in methods.items():
        # Change POST to GET for static serving
        new_method = "get" if method.lower() == "post" else method.lower()
        op["description"] = op.get("description", "") or op.get("summary", "")
        if method.lower() == "post":
            op["description"] += " (static mock response)"
        new_methods[new_method] = op
    new_paths[new_path] = new_methods
spec["paths"] = new_paths

# Update server info
spec["servers"] = [{"url": "https://api.quicue.ca", "description": "Static API (pre-computed from CUE)"}]
spec["info"]["description"] = (
    "654 pre-computed mock responses from the representative datacenter example. "
    "All data uses RFC 5737 TEST-NET IPs. Every response was generated at build time by CUE."
)

json.dump(spec, sys.stdout, indent=2)
PYEOF

mkdir -p "$OUT/docs"

cat > "$OUT/docs/index.html" << 'SWAGGEREOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Datacenter Operations API</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
  <style>
    body { margin: 0; background: #fafafa; }
    #swagger-ui .topbar { display: none; }
  </style>
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      url: '/openapi.json',
      dom_id: '#swagger-ui',
      presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
      layout: 'BaseLayout',
      deepLinking: true,
    });
  </script>
</body>
</html>
SWAGGEREOF

# ─── Step 9: Resource listing endpoint ───────────────────────────────────────
# Now generated from CUE as hydra:Collection (Step 5) — /api/v1/resources/index.json

# ─── Step 10: Per-resource detail endpoints ──────────────────────────────────
python3 << PYEOF
import json, os, sys

with open("$BULK") as f:
    bulk = json.load(f)

out_dir = "$OUT/api/v1/resources"
graph = bulk.get("plan", {}).get("Graph", {})
bound = bulk.get("bound_commands", {})

for name, res in graph.get("resources", graph.get("Input", {})).items():
    res_dir = os.path.join(out_dir, name)
    os.makedirs(res_dir, exist_ok=True)

    # Resource detail
    detail = {
        "@id": res.get("@id", f"https://infra.example.com/resources/{name}"),
        "name": name,
        "@type": list(res.get("@type", {}).keys()),
        "depends_on": list(res.get("depends_on", {}).keys()),
        "commands_url": f"/api/v1/resources/{name}/commands",
    }
    # Include all non-internal fields
    for k, v in res.items():
        if k not in ("@type", "depends_on", "@id", "name") and not k.startswith("_"):
            detail[k] = v

    with open(os.path.join(res_dir, "index.json"), "w") as f:
        json.dump(detail, f, indent=2)

    # Commands listing
    cmds = bound.get(name, {})
    with open(os.path.join(res_dir, "commands.json"), "w") as f:
        json.dump({"resource": name, "commands": cmds, "count": len(cmds)}, f, indent=2)

print(f"Generated detail + commands for {len(graph.get('resources', graph.get('Input', {})))} resources")
PYEOF

# ─── Step 11: CF Pages headers and redirects ────────────────────────────────
cat > "$OUT/_headers" << 'EOF'
/*
  Access-Control-Allow-Origin: *
  Access-Control-Allow-Methods: GET, OPTIONS
  Access-Control-Allow-Headers: Content-Type

/*.json
  Content-Type: application/json

/
  Link: </api/v1/hydra>; rel="http://www.w3.org/ns/hydra/core#apiDocumentation"

/index.json
  Link: </api/v1/hydra>; rel="http://www.w3.org/ns/hydra/core#apiDocumentation"

/api/v1/hydra.json
  Content-Type: application/ld+json

/api/v1/hydra
  Content-Type: application/ld+json

/api/v1/graph.jsonld.json
  Content-Type: application/ld+json

/api/v1/graph.jsonld
  Content-Type: application/ld+json

/api/v1/types.json
  Content-Type: application/ld+json

/api/v1/types
  Content-Type: application/ld+json

/api/v1/index.json
  Content-Type: application/ld+json
  Link: </api/v1/hydra>; rel="http://www.w3.org/ns/hydra/core#apiDocumentation"

/api/v1/
  Content-Type: application/ld+json
  Link: </api/v1/hydra>; rel="http://www.w3.org/ns/hydra/core#apiDocumentation"

/api/v1
  Content-Type: application/ld+json
  Link: </api/v1/hydra>; rel="http://www.w3.org/ns/hydra/core#apiDocumentation"

/api/v1/resources/index.json
  Content-Type: application/ld+json
  Link: </api/v1/hydra>; rel="http://www.w3.org/ns/hydra/core#apiDocumentation"
  Link: <http://www.w3.org/ns/ldp#BasicContainer>; rel="type"

/api/v1/resources
  Content-Type: application/ld+json
  Link: </api/v1/hydra>; rel="http://www.w3.org/ns/hydra/core#apiDocumentation"
  Link: <http://www.w3.org/ns/ldp#BasicContainer>; rel="type"

/api/v1/resources/*/index.json
  Content-Type: application/json
  Link: </api/v1/hydra>; rel="http://www.w3.org/ns/hydra/core#apiDocumentation"
  Link: <http://www.w3.org/ns/ldp#Resource>; rel="type"

/api/v1/resources/*
  Content-Type: application/json
  Link: </api/v1/hydra>; rel="http://www.w3.org/ns/hydra/core#apiDocumentation"
  Link: <http://www.w3.org/ns/ldp#Resource>; rel="type"
EOF

cat > "$OUT/_redirects" << 'EOF'
# Root → index.json
/ /index.json 200

# API version index
/api/v1 /api/v1/index.json 200
/api/v1/ /api/v1/index.json 200

# API endpoints → pre-computed JSON
/api/v1/healthz /api/v1/healthz.json 200
/api/v1/readyz /api/v1/readyz.json 200
/api/v1/spec-info /api/v1/spec-info.json 200
/api/v1/hydra /api/v1/hydra.json 200
/api/v1/graph.jsonld /api/v1/graph.jsonld.json 200
/api/v1/types /api/v1/types.json 200
/api/v1/deploy/history /api/v1/deploy/history.json 200
/api/v1/deploy/lock /api/v1/deploy/lock.json 200
/docs /docs/index.html 200

# Resource listing
/api/v1/resources /api/v1/resources/index.json 200

# Per-resource endpoints — with /api/v1/ prefix
/api/v1/resources/:resource /api/v1/resources/:resource/index.json 200
/api/v1/resources/:resource/commands /api/v1/resources/:resource/commands.json 200
/api/v1/resources/:resource/:provider/:action /api/v1/resources/:resource/:provider/:action.json 200

# Non-prefixed aliases (Swagger compat)
/resources/:resource /api/v1/resources/:resource/index.json 200
/resources/:resource/commands /api/v1/resources/:resource/commands.json 200
/resources/:resource/:provider/:action /api/v1/resources/:resource/:provider/:action.json 200
EOF

# ─── Done ────────────────────────────────────────────────────────────────────
rm -f "$BULK" "$OPENAPI"

FILE_COUNT=$(find "$OUT" -type f | wc -l)
SIZE=$(du -sh "$OUT" | cut -f1)
echo ""
echo "Static API built: $FILE_COUNT files, $SIZE"
echo "Deploy with: wrangler pages deploy $OUT --project-name quicue-api"
