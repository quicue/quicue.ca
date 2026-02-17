"""Parse x-command strings into ConnectParams for Guacamole dispatch."""

from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class ConnectParams:
    protocol: str  # "ssh" | "vnc" | "ping" | "unsupported"
    hostname: str = ""
    username: str = ""
    port: int = 22
    command: str = ""  # remote command (e.g., 'pct enter 100')

    @property
    def guacamole_protocol(self) -> str:
        if self.protocol == "vnc":
            return "vnc"
        return "ssh"


# Patterns (ordered by specificity)
_PING_RE = re.compile(r"^ping\s+(?:-c\s+\d+\s+)?(\S+)$")
_SSH_PCT_RE = re.compile(
    r"^ssh\s+-t\s+(\S+)\s+'(pct enter \d+)'$"
)
_SSH_USER_RE = re.compile(r"^ssh\s+(\S+)@(\S+)$")
_VIRTCTL_RE = re.compile(
    r"^virtctl\s+(console|ssh|vnc)\s+(\S+)\s+-n\s+(\S+)$"
)


def parse_connect_command(command: str) -> ConnectParams:
    """Parse a connect-category x-command into structured params.

    Patterns handled:
      ping -c N IP          → protocol=ping
      ssh USER@HOST         → protocol=ssh
      ssh -t NODE 'pct enter CTID' → protocol=ssh, command='pct enter CTID'
      virtctl console|ssh|vnc NAME -n NS → protocol=ssh|vnc
      govc/powercli console → protocol=unsupported
    """
    cmd = command.strip()

    # ping
    m = _PING_RE.match(cmd)
    if m:
        return ConnectParams(protocol="ping", hostname=m.group(1))

    # ssh -t NODE 'pct enter CTID'
    m = _SSH_PCT_RE.match(cmd)
    if m:
        return ConnectParams(
            protocol="ssh",
            hostname=m.group(1),
            username="root",
            command=m.group(2),
        )

    # ssh USER@HOST
    m = _SSH_USER_RE.match(cmd)
    if m:
        return ConnectParams(
            protocol="ssh",
            hostname=m.group(2),
            username=m.group(1),
        )

    # virtctl console|ssh|vnc
    m = _VIRTCTL_RE.match(cmd)
    if m:
        sub = m.group(1)
        protocol = "vnc" if sub == "vnc" else "ssh"
        return ConnectParams(
            protocol=protocol,
            hostname=m.group(2),
            command=command,
        )

    # Anything else (govc vm.console, Connect-VIServer, etc.)
    return ConnectParams(protocol="unsupported")
