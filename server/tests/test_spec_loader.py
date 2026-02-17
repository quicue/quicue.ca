"""Tests for spec_loader module."""

from __future__ import annotations

from pathlib import Path

from app.spec_loader import RouteEntry, build_route_key, load_spec


def test_load_spec_parses_routes(spec_file: Path) -> None:
    state = load_spec(spec_file)
    assert len(state.routes) == 5


def test_load_spec_categories(spec_file: Path) -> None:
    state = load_spec(spec_file)
    assert state.categories["info"] == 1
    assert state.categories["admin"] == 1
    assert state.categories["connect"] == 3


def test_load_spec_providers(spec_file: Path) -> None:
    state = load_spec(spec_file)
    assert state.providers["vyos"] == 1
    assert state.providers["govc"] == 1
    assert state.providers["proxmox"] == 3


def test_load_spec_destructive_count(spec_file: Path) -> None:
    state = load_spec(spec_file)
    assert state.destructive_count == 1


def test_route_entry_fields(spec_file: Path) -> None:
    state = load_spec(spec_file)
    key = "/resources/router-core/vyos/show_interfaces"
    entry = state.routes[key]
    assert entry.resource == "router-core"
    assert entry.provider == "vyos"
    assert entry.action == "show_interfaces"
    assert entry.category == "info"
    assert entry.idempotent is True
    assert entry.destructive is False
    assert "show interfaces" in entry.command


def test_destructive_entry(spec_file: Path) -> None:
    state = load_spec(spec_file)
    key = "/resources/vcenter/govc/vm_power_off_hard"
    entry = state.routes[key]
    assert entry.destructive is True
    assert entry.category == "admin"


def test_build_route_key() -> None:
    assert (
        build_route_key("router-core", "vyos", "show_interfaces")
        == "/resources/router-core/vyos/show_interfaces"
    )


def test_mtime_set(spec_file: Path) -> None:
    state = load_spec(spec_file)
    assert state.mtime > 0


def test_last_reload_set(spec_file: Path) -> None:
    state = load_spec(spec_file)
    assert state.last_reload != ""
