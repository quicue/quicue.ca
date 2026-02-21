#!/usr/bin/env python3
"""Convert a CycloneDX SBOM (JSON) to quicue.ca #InfraGraph input.

Maps CycloneDX components to typed graph resources and dependency
edges, with precomputed topological depth (Kahn's algorithm) so CUE
evaluation stays O(n) regardless of graph size.

Usage:
    # Write CUE to stdout
    python tools/cyclonedx2graph.py sbom.json

    # Write to a file
    python tools/cyclonedx2graph.py sbom.json -o examples/sbom/resources.cue

    # Specify package name (default: derived from filename)
    python tools/cyclonedx2graph.py sbom.json -p myproject

    # Include metadata fields (purl, version, license, hashes)
    python tools/cyclonedx2graph.py sbom.json --metadata

    # JSON output (for piping to other tools)
    python tools/cyclonedx2graph.py sbom.json --json

Output:
    CUE file with _resources (graph input) and _precomputed (depths),
    ready to wire into patterns.#InfraGraph.

Zero dependencies — stdlib Python only.
"""

import argparse
import collections
import json
import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# CycloneDX parsing
# ---------------------------------------------------------------------------

def load_bom(path: str) -> dict:
    """Load and validate a CycloneDX JSON BOM."""
    with open(path) as f:
        bom = json.load(f)
    if bom.get("bomFormat") != "CycloneDX":
        print(f"WARNING: bomFormat is '{bom.get('bomFormat')}', expected 'CycloneDX'",
              file=sys.stderr)
    return bom


def to_safe_id(s: str) -> str:
    """Convert a bom-ref or name to a #SafeID-compliant key.

    #SafeID = ^[a-zA-Z][a-zA-Z0-9_.-]*$
    """
    s = re.sub(r"[^a-zA-Z0-9_.-]", "-", s)
    s = re.sub(r"-+", "-", s)
    s = s.strip("-.")
    if not s:
        return "unnamed"
    if not s[0].isalpha():
        s = "c-" + s
    return s


# CycloneDX component type -> quicue.ca vocab @type
CDX_TYPE_MAP = {
    "application":          "SoftwareApplication",
    "framework":            "SoftwareFramework",
    "library":              "SoftwareLibrary",
    "container":            "SoftwareContainer",
    "platform":             "SoftwarePlatform",
    "operating-system":     "OperatingSystem",
    "firmware":             "SoftwareFirmware",
    "file":                 "SoftwareFile",
    "device":               "SoftwareApplication",      # no dedicated type
    "device-driver":        "SoftwareFirmware",          # closest match
    "machine-learning-model": "SoftwareFile",            # closest match
    "data":                 "SoftwareFile",              # closest match
    "cryptographic-asset":  "SoftwareFile",              # closest match
}


def extract_components(bom: dict) -> dict:
    """Extract components with their types and metadata.

    Returns: {safe_id: {name, @type, purl?, version?, ...}}
    """
    components = {}
    ref_to_id = {}  # bom-ref -> safe_id mapping

    # Include the root component from metadata if present
    meta_comp = bom.get("metadata", {}).get("component")
    if meta_comp:
        _add_component(meta_comp, components, ref_to_id)

    for comp in bom.get("components", []):
        _add_component(comp, components, ref_to_id)
        # Handle nested sub-components
        for sub in comp.get("components", []):
            _add_component(sub, components, ref_to_id)

    return components, ref_to_id


def _add_component(comp: dict, components: dict, ref_to_id: dict):
    """Add a single component to the components dict."""
    bom_ref = comp.get("bom-ref", comp.get("name", "unnamed"))
    safe_id = to_safe_id(bom_ref)

    # Handle collisions by appending version
    if safe_id in components:
        version = comp.get("version", "")
        if version:
            safe_id = to_safe_id(f"{bom_ref}-{version}")

    ref_to_id[bom_ref] = safe_id

    cdx_type = comp.get("type", "library")
    vocab_type = CDX_TYPE_MAP.get(cdx_type, "SoftwareLibrary")

    entry = {
        "name": safe_id,
        "@type": {vocab_type: True},
    }

    if comp.get("description"):
        entry["description"] = comp["description"]
    if comp.get("purl"):
        entry["purl"] = comp["purl"]
    if comp.get("version"):
        entry["version"] = comp["version"]

    # Extract license info
    licenses = comp.get("licenses", [])
    if licenses:
        ids = []
        for lic in licenses:
            if "license" in lic:
                lid = lic["license"].get("id") or lic["license"].get("name", "")
                if lid:
                    ids.append(lid)
            elif "expression" in lic:
                ids.append(lic["expression"])
        if ids:
            entry["license"] = ", ".join(ids)

    components[safe_id] = entry


def extract_dependencies(bom: dict, ref_to_id: dict) -> dict:
    """Build depends_on maps from the CycloneDX dependencies array.

    Returns: {safe_id: {dep_safe_id: True, ...}}
    """
    deps = {}
    for dep_entry in bom.get("dependencies", []):
        ref = dep_entry.get("ref", "")
        safe_id = ref_to_id.get(ref)
        if not safe_id:
            continue

        depends_on = {}
        for target_ref in dep_entry.get("dependsOn", []):
            target_id = ref_to_id.get(target_ref)
            if target_id:
                depends_on[target_id] = True

        if depends_on:
            deps[safe_id] = depends_on

    return deps


# ---------------------------------------------------------------------------
# Topological sort (Kahn's algorithm)
# ---------------------------------------------------------------------------

def compute_depths(components: dict, deps: dict) -> dict:
    """Compute topological depth for each node via Kahn's algorithm.

    Root nodes (no dependencies) have depth 0.
    A node's depth = max(depth of dependencies) + 1.
    """
    # Build adjacency and in-degree
    in_degree = {cid: 0 for cid in components}
    forward = collections.defaultdict(list)  # dep -> [dependents]

    for cid, dep_map in deps.items():
        for dep_id in dep_map:
            if dep_id in components:
                in_degree[cid] = in_degree.get(cid, 0)  # ensure exists
                forward[dep_id].append(cid)

    # Count actual in-edges (from deps perspective: who depends on me)
    in_degree = {cid: 0 for cid in components}
    for cid, dep_map in deps.items():
        for dep_id in dep_map:
            if dep_id in components:
                pass  # forward edges already tracked
        in_degree[cid] = len([d for d in dep_map if d in components])

    # Kahn's
    depth = {}
    queue = collections.deque()
    for cid in components:
        if in_degree.get(cid, 0) == 0:
            queue.append(cid)
            depth[cid] = 0

    while queue:
        node = queue.popleft()
        for dependent in forward[node]:
            new_depth = depth[node] + 1
            if dependent not in depth or new_depth > depth[dependent]:
                depth[dependent] = new_depth
            in_degree[dependent] -= 1
            if in_degree[dependent] == 0:
                queue.append(dependent)

    # Handle cycles — assign max_depth + 1 to any unvisited nodes
    if len(depth) < len(components):
        max_d = max(depth.values()) if depth else 0
        for cid in components:
            if cid not in depth:
                depth[cid] = max_d + 1

    return depth


# ---------------------------------------------------------------------------
# CUE output
# ---------------------------------------------------------------------------

def escape_cue_string(s: str) -> str:
    """Escape a string for CUE output."""
    return s.replace("\\", "\\\\").replace('"', '\\"')


def render_cue(components: dict, deps: dict, depths: dict,
               package: str, source: str, include_metadata: bool) -> str:
    """Render the full CUE file."""
    lines = []
    lines.append(f'// {package} — generated from CycloneDX SBOM')
    lines.append(f'// Source: {source}')
    lines.append(f'// Components: {len(components)}')
    lines.append(f'//')
    lines.append(f'// Generated by: tools/cyclonedx2graph.py')
    lines.append(f'')
    lines.append(f'package {package}')
    lines.append(f'')
    lines.append(f'import (')
    lines.append(f'\t"quicue.ca/patterns@v0"')
    lines.append(f')')
    lines.append(f'')

    # Resources
    lines.append(f'_resources: {{')
    for cid in sorted(components, key=lambda k: depths.get(k, 0)):
        comp = components[cid]
        lines.append(f'\t"{cid}": {{')
        lines.append(f'\t\tname: "{cid}"')

        # @type
        types = sorted(comp["@type"].keys())
        type_str = ", ".join(f"{t}: true" for t in types)
        lines.append(f'\t\t"@type": {{{type_str}}}')

        # depends_on
        if cid in deps and deps[cid]:
            dep_ids = sorted(deps[cid].keys())
            dep_str = ", ".join(f'"{d}": true' for d in dep_ids)
            lines.append(f'\t\tdepends_on: {{{dep_str}}}')

        # Metadata fields
        if include_metadata:
            if comp.get("description"):
                lines.append(f'\t\tdescription: "{escape_cue_string(comp["description"])}"')
            if comp.get("version"):
                lines.append(f'\t\tversion: "{escape_cue_string(comp["version"])}"')
            if comp.get("purl"):
                lines.append(f'\t\tpurl: "{escape_cue_string(comp["purl"])}"')
            if comp.get("license"):
                lines.append(f'\t\tlicense: "{escape_cue_string(comp["license"])}"')

        lines.append(f'\t}}')

    lines.append(f'}}')
    lines.append(f'')

    # Precomputed depths
    lines.append(f'_precomputed: {{')
    lines.append(f'\tdepth: {{')
    for cid in sorted(depths, key=lambda k: (depths[k], k)):
        lines.append(f'\t\t"{cid}": {depths[cid]}')
    lines.append(f'\t}}')
    lines.append(f'}}')
    lines.append(f'')

    # Graph wiring
    lines.append(f'infra: patterns.#InfraGraph & {{')
    lines.append(f'\tInput:       _resources')
    lines.append(f'\tPrecomputed: _precomputed')
    lines.append(f'}}')

    return "\n".join(lines) + "\n"


def render_json(components: dict, deps: dict, depths: dict) -> str:
    """Render as JSON (for piping to other tools)."""
    output = {
        "resources": {},
        "precomputed": {"depth": depths},
    }
    for cid, comp in components.items():
        entry = {
            "name": cid,
            "@type": comp["@type"],
        }
        if cid in deps:
            entry["depends_on"] = deps[cid]
        for field in ("description", "version", "purl", "license"):
            if comp.get(field):
                entry[field] = comp[field]
        output["resources"][cid] = entry

    return json.dumps(output, indent=2) + "\n"


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Convert CycloneDX SBOM (JSON) to quicue.ca #InfraGraph input",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("input", help="Path to CycloneDX JSON file")
    parser.add_argument("-o", "--output", help="Output file (default: stdout)")
    parser.add_argument("-p", "--package", help="CUE package name (default: derived from filename)")
    parser.add_argument("--metadata", action="store_true",
                        help="Include version, purl, license, description fields")
    parser.add_argument("--json", action="store_true",
                        help="Output JSON instead of CUE")
    parser.add_argument("--stats", action="store_true",
                        help="Print stats to stderr")

    args = parser.parse_args()

    # Load and parse
    bom = load_bom(args.input)
    components, ref_to_id = extract_components(bom)
    deps = extract_dependencies(bom, ref_to_id)
    depths = compute_depths(components, deps)

    # Package name
    package = args.package
    if not package:
        package = re.sub(r"[^a-zA-Z0-9]", "", Path(args.input).stem.lower())
        if not package or not package[0].isalpha():
            package = "sbom"

    # Stats
    if args.stats:
        n_edges = sum(len(d) for d in deps.values())
        max_depth = max(depths.values()) if depths else 0
        roots = sum(1 for d in depths.values() if d == 0)
        print(f"Components: {len(components)}", file=sys.stderr)
        print(f"Edges: {n_edges}", file=sys.stderr)
        print(f"Max depth: {max_depth}", file=sys.stderr)
        print(f"Roots: {roots}", file=sys.stderr)

    # Render
    if args.json:
        output = render_json(components, deps, depths)
    else:
        output = render_cue(components, deps, depths, package,
                            Path(args.input).name, args.metadata)

    # Write
    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        Path(args.output).write_text(output)
        print(f"Wrote {args.output} ({len(components)} components)", file=sys.stderr)
    else:
        sys.stdout.write(output)


if __name__ == "__main__":
    main()
