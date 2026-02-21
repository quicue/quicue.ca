#!/usr/bin/env python3
"""Convert an AsyncAPI 2.x/3.x specification to quicue.ca #InfraGraph input.

Maps AsyncAPI components (servers, channels, operations) to typed graph
resources and dependency edges, with precomputed topological depth
(Kahn's algorithm) so CUE evaluation stays O(n) regardless of graph size.

AsyncAPI spec structure:
  - API (root): info.title → SoftwareApplication
  - Servers: server objects → NetworkService
  - Channels: channel objects → MessageQueue
  - Dependencies: channels depend on servers, API depends on channels

Supports both AsyncAPI 2.x (channels with subscribe/publish) and
3.x (channels + operations as separate constructs).

Usage:
    # Write CUE to stdout
    python tools/asyncapi2graph.py asyncapi.json

    # Write to a file
    python tools/asyncapi2graph.py asyncapi.yaml -o examples/async/resources.cue

    # Specify package name (default: derived from filename)
    python tools/asyncapi2graph.py spec.json -p myapis

    # Include metadata fields (protocol, description, operationType)
    python tools/asyncapi2graph.py spec.yaml --metadata

    # JSON output (for piping to other tools)
    python tools/asyncapi2graph.py spec.json --json

    # Print stats
    python tools/asyncapi2graph.py spec.json --stats

Output:
    CUE file with _resources (graph input) and _precomputed (depths),
    ready to wire into patterns.#InfraGraph.

Requires:
    - Python 3.10+
    - PyYAML (optional; JSON always works)

Zero external dependencies for JSON; PyYAML optional for YAML support.
"""

import argparse
import json
import sys
from pathlib import Path

from lib.adapter import BaseAdapter, to_safe_id, compute_depths, render_cue, render_json

# Try to import YAML support; gracefully degrade to JSON-only
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


class AsyncApiAdapter(BaseAdapter):
    """AsyncAPI 2.x/3.x to #InfraGraph adapter."""

    name = "asyncapi"
    description = "Convert AsyncAPI spec to #InfraGraph"
    metadata_fields = ["protocol", "description", "operationType"]

    def parse(self, path: str, args: argparse.Namespace) -> tuple[dict, dict]:
        """Parse AsyncAPI spec and extract components + dependencies.

        Returns: (components, deps) where:
            components = {safe_id: {name, @type, ...metadata}}
            deps = {safe_id: {dep_safe_id: True, ...}}
        """
        spec = self._load_spec(path)

        # Detect AsyncAPI version
        version = spec.get("asyncapi", "")
        if not version:
            raise ValueError("Missing 'asyncapi' field in spec")

        major_version = int(version.split(".")[0]) if version else 0
        if major_version not in (2, 3):
            raise ValueError(f"Unsupported AsyncAPI version: {version}")

        components = {}
        deps = {}

        # Extract API root component
        api_name = self._extract_api(spec, components)

        # Extract servers
        server_ids = self._extract_servers(spec, components)

        # Extract channels and operations
        channel_ids = self._extract_channels(spec, major_version, components)

        # Build dependencies
        self._build_dependencies(spec, major_version, api_name, server_ids, channel_ids, deps)

        return components, deps

    def _load_spec(self, path: str) -> dict:
        """Load spec from JSON or YAML."""
        path_obj = Path(path)
        suffix = path_obj.suffix.lower()

        with open(path) as f:
            if suffix == ".yaml" or suffix == ".yml":
                if not HAS_YAML:
                    raise ImportError(
                        "PyYAML is required for YAML support. "
                        "Install with: pip install PyYAML"
                    )
                return yaml.safe_load(f) or {}
            else:
                return json.load(f)

    def _extract_api(self, spec: dict, components: dict) -> str:
        """Extract API root component from info.title.

        Returns: safe_id of the API component
        """
        info = spec.get("info", {})
        title = info.get("title", "AsyncAPI")
        description = info.get("description", "")
        api_id = to_safe_id(title)

        entry = {
            "name": api_id,
            "@type": {"SoftwareApplication": True},
        }
        if description:
            entry["description"] = description

        components[api_id] = entry
        return api_id

    def _extract_servers(self, spec: dict, components: dict) -> dict:
        """Extract servers from spec.servers.

        Returns: {server_name: safe_id, ...}
        """
        server_ids = {}
        servers = spec.get("servers", {})

        # Handle both dict-style (v2/v3) and list-style (early drafts)
        if isinstance(servers, dict):
            items = servers.items()
        else:
            items = [(s.get("name", f"server-{i}"), s) for i, s in enumerate(servers)]

        for server_name, server_obj in items:
            if not isinstance(server_obj, dict):
                continue

            safe_id = to_safe_id(server_name)
            url = server_obj.get("url", "")
            description = server_obj.get("description", "")
            protocol = server_obj.get("protocol", "")

            entry = {
                "name": safe_id,
                "@type": {"NetworkService": True},
            }
            if description:
                entry["description"] = description
            if protocol:
                entry["protocol"] = protocol
            if url:
                entry["url"] = url

            components[safe_id] = entry
            server_ids[server_name] = safe_id

        return server_ids

    def _extract_channels(self, spec: dict, major_version: int, components: dict) -> dict:
        """Extract channels from spec.channels (v2 & v3).

        For v2: channel object contains subscribe/publish operations.
        For v3: channels are separate; operations are in channels[].operations.

        Returns: {channel_name: safe_id, ...}
        """
        channel_ids = {}
        channels = spec.get("channels", {})

        # Handle both dict-style and list-style channels
        if isinstance(channels, dict):
            items = channels.items()
        else:
            items = [(c.get("address", f"channel-{i}"), c) for i, c in enumerate(channels)]

        for channel_name, channel_obj in items:
            if not isinstance(channel_obj, dict):
                continue

            safe_id = to_safe_id(channel_name)
            description = channel_obj.get("description", "")

            entry = {
                "name": safe_id,
                "@type": {"MessageQueue": True},
            }
            if description:
                entry["description"] = description

            components[safe_id] = entry
            channel_ids[channel_name] = safe_id

        return channel_ids

    def _build_dependencies(
        self,
        spec: dict,
        major_version: int,
        api_id: str,
        server_ids: dict,
        channel_ids: dict,
        deps: dict,
    ) -> None:
        """Build dependency edges.

        Relationships:
          - Channels depend on servers (via server references)
          - API depends on channels
        """
        channels = spec.get("channels", {})

        # Handle dict-style channels
        if isinstance(channels, dict):
            for channel_name, channel_obj in channels.items():
                if not isinstance(channel_obj, dict):
                    continue

                channel_safe_id = channel_ids.get(channel_name)
                if not channel_safe_id:
                    continue

                # Channels depend on servers they reference
                if channel_safe_id not in deps:
                    deps[channel_safe_id] = {}

                channel_servers = channel_obj.get("servers", [])
                if isinstance(channel_servers, str):
                    channel_servers = [channel_servers]

                for server_name in channel_servers:
                    server_safe_id = server_ids.get(server_name)
                    if server_safe_id:
                        deps[channel_safe_id][server_safe_id] = True

        # API depends on all channels
        if channel_ids:
            if api_id not in deps:
                deps[api_id] = {}
            for channel_safe_id in channel_ids.values():
                deps[api_id][channel_safe_id] = True


if __name__ == "__main__":
    AsyncApiAdapter().run()
