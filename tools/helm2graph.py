#!/usr/bin/env python3
"""Convert a Helm Chart.yaml (and optionally Chart.lock) to quicue.ca #InfraGraph input.

Maps Helm chart metadata to a typed graph resource with @type {SoftwareApplication: true}.
Each dependency in the chart becomes a separate resource with @type {SoftwareLibrary: true}.
The main chart depends on all its sub-charts (dependencies).

Chart.lock is used to resolve exact dependency versions if present in the same directory.
The --recursive flag walks the charts/ subdirectory to include any local sub-charts.

Usage:
    # Write CUE to stdout
    python tools/helm2graph.py Chart.yaml

    # Write to a file
    python tools/helm2graph.py Chart.yaml -o examples/helm/resources.cue

    # Specify package name (default: derived from chart name)
    python tools/helm2graph.py Chart.yaml -p mychart

    # Include metadata fields (version, appVersion, chartType, repository)
    python tools/helm2graph.py Chart.yaml --metadata

    # JSON output (for piping to other tools)
    python tools/helm2graph.py Chart.yaml --json

    # Recursively include sub-charts from charts/ directory
    python tools/helm2graph.py Chart.yaml --recursive

Output:
    CUE file with _resources (graph input) and _precomputed (depths),
    ready to wire into patterns.#InfraGraph.

Requires:
    PyYAML — install with: pip install PyYAML
"""

import argparse
import sys
from pathlib import Path

from lib.adapter import BaseAdapter, to_safe_id


class HelmAdapter(BaseAdapter):
    """Convert Helm Chart.yaml to #InfraGraph."""

    name = "helm"
    description = "Convert Helm Chart.yaml to #InfraGraph"
    metadata_fields = ["version", "appVersion", "chartType", "repository"]

    def add_arguments(self, parser: argparse.ArgumentParser) -> None:
        """Add Helm-specific CLI arguments."""
        parser.add_argument(
            "--recursive",
            action="store_true",
            help="Walk charts/ subdirectory to include local sub-charts"
        )

    def parse(self, path: str, args: argparse.Namespace) -> tuple[dict, dict]:
        """Parse Chart.yaml and optional Chart.lock, return (components, deps)."""
        # Try to import PyYAML
        try:
            import yaml
        except ImportError:
            print(
                "ERROR: PyYAML is required. Install with: pip install PyYAML",
                file=sys.stderr,
            )
            sys.exit(1)

        chart_path = Path(path)
        if not chart_path.exists():
            raise FileNotFoundError(f"Chart.yaml not found: {path}")

        # Load Chart.yaml
        with open(chart_path) as f:
            chart = yaml.safe_load(f)

        if not chart:
            raise ValueError(f"Empty or invalid Chart.yaml: {path}")

        components = {}
        deps = {}

        # Main chart as a component
        chart_name = chart.get("name", "helm-chart")
        chart_id = to_safe_id(chart_name)

        main_component = {
            "name": chart_id,
            "@type": {"SoftwareApplication": True},
        }

        # Add metadata fields if present
        if chart.get("version"):
            main_component["version"] = chart["version"]
        if chart.get("appVersion"):
            main_component["appVersion"] = chart["appVersion"]
        if chart.get("type"):
            main_component["chartType"] = chart["type"]

        components[chart_id] = main_component

        # Load Chart.lock if present (for resolved versions)
        lock_versions = {}
        lock_path = chart_path.parent / "Chart.lock"
        if lock_path.exists():
            with open(lock_path) as f:
                lock_data = yaml.safe_load(f)
            if lock_data and "dependencies" in lock_data:
                for dep_lock in lock_data["dependencies"]:
                    dep_name = dep_lock.get("name", "")
                    dep_version = dep_lock.get("version", "")
                    if dep_name and dep_version:
                        lock_versions[dep_name] = dep_version

        # Process dependencies from Chart.yaml
        dep_ids = set()
        for dep in chart.get("dependencies", []):
            dep_name = dep.get("name", "")
            if not dep_name:
                continue

            dep_id = to_safe_id(dep_name)

            dep_component = {
                "name": dep_id,
                "@type": {"SoftwareLibrary": True},
            }

            # Use version from Chart.lock if available, otherwise from Chart.yaml
            dep_version = lock_versions.get(dep_name) or dep.get("version", "")
            if dep_version:
                dep_component["version"] = dep_version

            # Add repository if present
            if dep.get("repository"):
                dep_component["repository"] = dep.get("repository")

            components[dep_id] = dep_component
            dep_ids.add(dep_id)

        # Main chart depends on all its dependencies
        if dep_ids:
            deps[chart_id] = {dep_id: True for dep_id in dep_ids}

        # Recursively include local sub-charts if --recursive is set
        if args.recursive:
            charts_dir = chart_path.parent / "charts"
            if charts_dir.exists() and charts_dir.is_dir():
                for subchart_file in charts_dir.glob("*/Chart.yaml"):
                    _, subchart_deps = self.parse(str(subchart_file), args)
                    for comp_id, comp_data in self._parse_subchart(subchart_file).items():
                        if comp_id not in components:
                            components[comp_id] = comp_data

        return components, deps

    def _parse_subchart(self, path: Path) -> dict:
        """Parse a single sub-chart and return components dict."""
        try:
            import yaml
        except ImportError:
            return {}

        with open(path) as f:
            chart = yaml.safe_load(f)

        if not chart:
            return {}

        components = {}
        chart_name = chart.get("name", "helm-chart")
        chart_id = to_safe_id(chart_name)

        component = {
            "name": chart_id,
            "@type": {"SoftwareApplication": True},
        }

        if chart.get("version"):
            component["version"] = chart["version"]
        if chart.get("appVersion"):
            component["appVersion"] = chart["appVersion"]
        if chart.get("type"):
            component["chartType"] = chart["type"]

        components[chart_id] = component
        return components


if __name__ == "__main__":
    HelmAdapter().run()
