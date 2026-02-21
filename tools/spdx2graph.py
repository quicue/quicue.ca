#!/usr/bin/env python3
"""Convert an SPDX 2.3 SBOM (JSON) to quicue.ca #InfraGraph input.

Maps SPDX packages to typed graph resources and dependency edges,
with precomputed topological depth (Kahn's algorithm) so CUE
evaluation stays O(n) regardless of graph size.

Usage:
    # Write CUE to stdout
    python tools/spdx2graph.py sbom.spdx.json

    # Write to a file
    python tools/spdx2graph.py sbom.spdx.json -o examples/sbom/resources.cue

    # Specify package name (default: derived from filename)
    python tools/spdx2graph.py sbom.spdx.json -p myproject

    # Include metadata fields (spdxId, version, license, supplier, downloadLocation)
    python tools/spdx2graph.py sbom.spdx.json --metadata

    # JSON output (for piping to other tools)
    python tools/spdx2graph.py sbom.spdx.json --json

    # Print stats
    python tools/spdx2graph.py sbom.spdx.json --stats

Output:
    CUE file with _resources (graph input) and _precomputed (depths),
    ready to wire into patterns.#InfraGraph.

Zero dependencies — stdlib Python only.
"""

import argparse
import json
import sys
from pathlib import Path

from lib.adapter import BaseAdapter, to_safe_id, compute_depths, render_cue, render_json


# SPDX 2.3 primaryPackagePurpose -> quicue.ca vocab @type mapping
SPDX_TYPE_MAP = {
    "APPLICATION": "SoftwareApplication",
    "FRAMEWORK": "SoftwareFramework",
    "LIBRARY": "SoftwareLibrary",
    "CONTAINER": "SoftwareContainer",
    "OPERATING_SYSTEM": "OperatingSystem",
    "DEVICE": "SoftwareApplication",
    "DEVICE_DRIVER": "SoftwareFirmware",
    "FIRMWARE": "SoftwareFirmware",
    "SOURCE": "SoftwareFile",
    "ARCHIVE": "SoftwareFile",
    "FILE": "SoftwareFile",
    "INSTALL": "SoftwareFile",
    "SOURCE_REPOSITORY": "SoftwareFile",
}


class SpdxAdapter(BaseAdapter):
    """SPDX 2.3 SBOM to #InfraGraph adapter."""

    name = "spdx"
    description = "Convert SPDX 2.3 SBOM (JSON) to #InfraGraph"
    metadata_fields = ["spdxId", "version", "license", "supplier", "downloadLocation"]

    def parse(self, path: str, args: argparse.Namespace) -> tuple[dict, dict]:
        """Parse SPDX JSON SBOM and extract components + dependencies.

        Returns: (components, deps) where:
            components = {safe_id: {name, @type, ...metadata}}
            deps = {safe_id: {dep_safe_id: True, ...}}
        """
        with open(path) as f:
            sbom = json.load(f)

        # Validate SPDX format
        spdx_version = sbom.get("spdxVersion", "")
        if not spdx_version.startswith("SPDX-2"):
            raise ValueError(
                f"Expected SPDX-2.x format, got: {spdx_version}"
            )

        components = {}
        spdx_id_to_safe = {}

        # Extract packages
        for pkg in sbom.get("packages", []):
            self._add_package(pkg, components, spdx_id_to_safe)

        # Extract dependencies from relationships
        deps = self._extract_dependencies(sbom, spdx_id_to_safe)

        return components, deps

    def _add_package(self, pkg: dict, components: dict, spdx_id_to_safe: dict) -> None:
        """Add a single SPDX package to components."""
        spdx_id = pkg.get("SPDXID", pkg.get("name", "unnamed"))
        safe_id = to_safe_id(spdx_id)

        # Handle collisions by appending version
        if safe_id in components:
            version = pkg.get("versionInfo", "")
            if version:
                safe_id = to_safe_id(f"{spdx_id}-{version}")

        spdx_id_to_safe[spdx_id] = safe_id

        # Map SPDX purpose to @type
        purpose = pkg.get("primaryPackagePurpose", "LIBRARY")
        vocab_type = SPDX_TYPE_MAP.get(purpose, "SoftwareLibrary")

        entry = {
            "name": safe_id,
            "@type": {vocab_type: True},
        }

        # Extract metadata fields
        if pkg.get("SPDXID"):
            entry["spdxId"] = pkg["SPDXID"]
        if pkg.get("versionInfo"):
            entry["version"] = pkg["versionInfo"]
        if pkg.get("supplier"):
            entry["supplier"] = pkg["supplier"]
        if pkg.get("downloadLocation"):
            entry["downloadLocation"] = pkg["downloadLocation"]

        # Extract license
        licenses = []
        if pkg.get("licenseConcluded"):
            licenses.append(pkg["licenseConcluded"])
        if pkg.get("licenseDeclared"):
            licenses.append(pkg["licenseDeclared"])
        if licenses:
            entry["license"] = ", ".join(licenses)

        components[safe_id] = entry

    def _extract_dependencies(self, sbom: dict, spdx_id_to_safe: dict) -> dict:
        """Extract depends_on maps from SPDX relationships.

        Handles: DEPENDS_ON, BUILD_TOOL_OF, DEV_DEPENDENCY_OF, RUNTIME_DEPENDENCY_OF.
        """
        deps = {}
        dep_types = {
            "DEPENDS_ON",
            "BUILD_TOOL_OF",
            "DEV_DEPENDENCY_OF",
            "RUNTIME_DEPENDENCY_OF",
            "OPTIONAL_DEPENDENCY_OF",
            "PROVIDED_BY",
        }

        for rel in sbom.get("relationships", []):
            rel_type = rel.get("relationshipType", "")
            if rel_type not in dep_types:
                continue

            spdx_from = rel.get("spdxElementId", "")
            spdx_to = rel.get("relatedSpdxElement", "")

            safe_from = spdx_id_to_safe.get(spdx_from)
            safe_to = spdx_id_to_safe.get(spdx_to)

            if not safe_from or not safe_to:
                continue

            if safe_from not in deps:
                deps[safe_from] = {}
            deps[safe_from][safe_to] = True

        return deps


if __name__ == "__main__":
    SpdxAdapter().run()
