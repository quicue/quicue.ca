"""Tests for connect command parser."""

from __future__ import annotations

from app.executor.parser import parse_connect_command


def test_ping() -> None:
    p = parse_connect_command("ping -c 3 198.51.100.10")
    assert p.protocol == "ping"
    assert p.hostname == "198.51.100.10"


def test_ping_no_count() -> None:
    p = parse_connect_command("ping 198.51.100.10")
    assert p.protocol == "ping"
    assert p.hostname == "198.51.100.10"


def test_ssh_user_host() -> None:
    p = parse_connect_command("ssh root@198.51.100.10")
    assert p.protocol == "ssh"
    assert p.hostname == "198.51.100.10"
    assert p.username == "root"
    assert p.command == ""


def test_ssh_pct_enter() -> None:
    p = parse_connect_command("ssh -t pve-node1 'pct enter 100'")
    assert p.protocol == "ssh"
    assert p.hostname == "pve-node1"
    assert p.username == "root"
    assert p.command == "pct enter 100"


def test_virtctl_console() -> None:
    p = parse_connect_command("virtctl console legacy-workload -n kubevirt")
    assert p.protocol == "ssh"
    assert p.hostname == "legacy-workload"


def test_virtctl_vnc() -> None:
    p = parse_connect_command("virtctl vnc legacy-workload -n kubevirt")
    assert p.protocol == "vnc"
    assert p.hostname == "legacy-workload"


def test_virtctl_ssh() -> None:
    p = parse_connect_command("virtctl ssh legacy-workload -n kubevirt")
    assert p.protocol == "ssh"
    assert p.hostname == "legacy-workload"


def test_govc_console_unsupported() -> None:
    p = parse_connect_command("govc vm.console /DC1/vm/web-server")
    assert p.protocol == "unsupported"


def test_powercli_connect_unsupported() -> None:
    p = parse_connect_command(
        "Connect-VIServer -Server vcenter.dc.example.com -User admin -Password x"
    )
    assert p.protocol == "unsupported"


def test_open_vm_console_unsupported() -> None:
    p = parse_connect_command("Open-VMConsoleWindow -VM web-server")
    assert p.protocol == "unsupported"


def test_guacamole_protocol_ssh() -> None:
    p = parse_connect_command("ssh root@198.51.100.10")
    assert p.guacamole_protocol == "ssh"


def test_guacamole_protocol_vnc() -> None:
    p = parse_connect_command("virtctl vnc legacy-workload -n kubevirt")
    assert p.guacamole_protocol == "vnc"
