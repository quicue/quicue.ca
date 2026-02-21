#!/usr/bin/env python3
"""Convert SARIF 2.1.0 (Static Analysis Results Interchange Format) JSON to quicue.ca #InfraGraph input.

Maps SARIF runs (security tools) to typed graph resources:
  - Each run → component with @type {SecurityTool: true}
  - Each rule in run.tool.driver.rules → component with @type {SecurityPolicy: true}
  - Each result in run.results → component with @type based on level:
      * "error" → {SecurityVulnerability: true}
      * "warning" → {SecurityPolicy: true}
      * "note" → {SecurityPolicy: true}

Dependencies:
  - Results depend on their rule (via ruleId)
  - Rules depend on their run/tool

Usage:
    # Write CUE to stdout
    python tools/sarif2graph.py report.sarif

    # Write to a file
    python tools/sarif2graph.py report.sarif -o examples/security/resources.cue

    # Specify package name (default: derived from filename)
    python tools/sarif2graph.py report.sarif -p mysecurity

    # Include metadata fields (severity, ruleId, message, location)
    python tools/sarif2graph.py report.sarif --metadata

    # JSON output (for piping to other tools)
    python tools/sarif2graph.py report.sarif --json

    # Print statistics
    python tools/sarif2graph.py report.sarif --stats

Output:
    CUE file with _resources (graph input) and _precomputed (depths),
    ready to wire into patterns.#InfraGraph.

Zero dependencies — stdlib Python only.
"""

import json
import sys
from pathlib import Path

from lib.adapter import BaseAdapter, to_safe_id


class SarifAdapter(BaseAdapter):
    """Adapter for SARIF 2.1.0 static analysis results."""

    name = "sarif"
    description = "Convert SARIF 2.1.0 results to #InfraGraph"
    metadata_fields = ["severity", "ruleId", "message", "location"]

    def parse(self, path: str, args) -> tuple[dict, dict]:
        """Parse a SARIF JSON file and extract components and dependencies.

        Args:
            path: Path to SARIF JSON file
            args: Parsed command-line arguments (from BaseAdapter)

        Returns:
            (components, deps) tuple suitable for render_cue/render_json
        """
        with open(path) as f:
            sarif = json.load(f)

        # Validate SARIF structure
        version = sarif.get("version")
        if version != "2.1.0":
            print(f"WARNING: SARIF version is '{version}', expected '2.1.0'",
                  file=sys.stderr)

        schema = sarif.get("$schema", "")
        if "sarif" not in schema.lower():
            print(f"WARNING: $schema does not contain 'sarif': {schema}",
                  file=sys.stderr)

        components = {}
        deps = {}

        # Process each run (security tool execution)
        for run_idx, run in enumerate(sarif.get("runs", [])):
            tool = run.get("tool", {})
            driver = tool.get("driver", {})

            # Tool name
            tool_name = driver.get("name", f"tool-{run_idx}")
            tool_id = to_safe_id(tool_name)

            # Create component for the tool/run
            components[tool_id] = {
                "name": tool_id,
                "@type": {"SecurityTool": True},
            }

            # Process rules in this tool
            rules = driver.get("rules", [])
            for rule in rules:
                rule_id_str = rule.get("id", f"rule-{len(components)}")
                rule_safe_id = to_safe_id(f"{tool_name}-{rule_id_str}")

                # Avoid collisions by appending index if needed
                if rule_safe_id in components:
                    rule_safe_id = to_safe_id(f"{tool_name}-{rule_id_str}-{hash(rule_id_str) % 9999}")

                components[rule_safe_id] = {
                    "name": rule_safe_id,
                    "@type": {"SecurityPolicy": True},
                }

                # Rule depends on tool
                if tool_id not in deps:
                    deps[tool_id] = {}
                deps[tool_id][rule_safe_id] = True

                # Process results for this rule
                for result_idx, result in enumerate(run.get("results", [])):
                    result_rule_id = result.get("ruleId")
                    if result_rule_id != rule_id_str:
                        continue

                    # Determine result type based on level
                    level = result.get("level", "warning")
                    if level == "error":
                        result_type = "SecurityVulnerability"
                    else:  # warning, note, pass, notApplicable, open, review
                        result_type = "SecurityPolicy"

                    # Build result component ID
                    locations = result.get("locations", [])
                    location_str = ""
                    if locations:
                        location = locations[0]
                        artifact = location.get("physicalLocation", {}).get("artifactLocation", {})
                        uri = artifact.get("uri", "")
                        if uri:
                            location_str = uri.replace("/", "-").replace(".", "-")

                    msg = result.get("message", {}).get("text", "")
                    msg_slug = to_safe_id(msg[:50]) if msg else ""

                    result_id = to_safe_id(
                        f"{tool_name}-result-{result_idx}-{msg_slug}-{location_str}"
                    )

                    # Avoid collisions
                    if result_id in components:
                        result_id = to_safe_id(
                            f"{tool_name}-result-{result_idx}-{hash(msg) % 9999}"
                        )

                    components[result_id] = {
                        "name": result_id,
                        "@type": {result_type: True},
                    }

                    # Attach metadata
                    if level:
                        components[result_id]["severity"] = level
                    if result_rule_id:
                        components[result_id]["ruleId"] = result_rule_id
                    if msg:
                        components[result_id]["message"] = msg

                    # Build location string for metadata
                    if locations:
                        location = locations[0]
                        artifact = location.get("physicalLocation", {}).get("artifactLocation", {})
                        region = location.get("physicalLocation", {}).get("region", {})

                        uri = artifact.get("uri", "")
                        line = region.get("startLine", "")
                        col = region.get("startColumn", "")

                        loc_parts = []
                        if uri:
                            loc_parts.append(uri)
                        if line:
                            loc_parts.append(f"line {line}")
                        if col:
                            loc_parts.append(f"col {col}")
                        if loc_parts:
                            components[result_id]["location"] = ", ".join(loc_parts)

                    # Result depends on rule
                    if rule_safe_id not in deps:
                        deps[rule_safe_id] = {}
                    deps[rule_safe_id][result_id] = True

        return components, deps


if __name__ == "__main__":
    SarifAdapter().run()
