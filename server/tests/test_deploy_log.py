"""Tests for the deployment log module."""

from __future__ import annotations

import json
import time
from pathlib import Path
from unittest.mock import patch

import pytest

from app.deploy import log
from app.deploy.log import LogEntry


@pytest.fixture(autouse=True)
def log_file(tmp_path: Path):
    """Point log module at a temp JSONL file."""
    log_path = tmp_path / "deploy.jsonl"
    with patch.object(log, "_log_path", return_value=log_path):
        yield log_path


# -- append --


def test_append_creates_file(log_file: Path):
    entry = LogEntry(
        timestamp=time.time(),
        resource="router-core",
        provider="vyos",
        action="show_interfaces",
        command="ssh vyos@198.51.100.1 'show interfaces'",
        mode="mock",
    )
    log.append(entry)
    assert log_file.exists()
    lines = log_file.read_text().strip().split("\n")
    assert len(lines) == 1
    data = json.loads(lines[0])
    assert data["resource"] == "router-core"
    assert data["mode"] == "mock"


def test_append_multiple_entries(log_file: Path):
    for i in range(3):
        log.append(LogEntry(
            timestamp=time.time() + i,
            resource=f"res-{i}",
            provider="test",
            action="action",
            command="cmd",
            mode="mock",
        ))
    lines = log_file.read_text().strip().split("\n")
    assert len(lines) == 3


# -- read_history --


def test_read_history_empty():
    result = log.read_history()
    assert result == []


def test_read_history_newest_first(log_file: Path):
    for i in range(3):
        log.append(LogEntry(
            timestamp=1000.0 + i,
            resource=f"res-{i}",
            provider="test",
            action="action",
            command="cmd",
            mode="mock",
        ))
    entries = log.read_history()
    assert len(entries) == 3
    assert entries[0]["resource"] == "res-2"  # newest
    assert entries[2]["resource"] == "res-0"  # oldest


def test_read_history_limit():
    for i in range(10):
        log.append(LogEntry(
            timestamp=1000.0 + i,
            resource=f"res-{i}",
            provider="test",
            action="action",
            command="cmd",
            mode="mock",
        ))
    entries = log.read_history(limit=3)
    assert len(entries) == 3


def test_read_history_filter_by_resource():
    log.append(LogEntry(
        timestamp=1000.0,
        resource="alpha",
        provider="p1",
        action="a1",
        command="c1",
        mode="mock",
    ))
    log.append(LogEntry(
        timestamp=1001.0,
        resource="beta",
        provider="p2",
        action="a2",
        command="c2",
        mode="live",
    ))
    entries = log.read_history(resource="beta")
    assert len(entries) == 1
    assert entries[0]["resource"] == "beta"


def test_read_history_filter_by_since():
    log.append(LogEntry(
        timestamp=1000.0,
        resource="old",
        provider="p",
        action="a",
        command="c",
        mode="mock",
    ))
    log.append(LogEntry(
        timestamp=2000.0,
        resource="new",
        provider="p",
        action="a",
        command="c",
        mode="mock",
    ))
    entries = log.read_history(since=1500.0)
    assert len(entries) == 1
    assert entries[0]["resource"] == "new"


def test_read_history_skips_corrupt_lines(log_file: Path):
    log.append(LogEntry(
        timestamp=1000.0,
        resource="good",
        provider="p",
        action="a",
        command="c",
        mode="mock",
    ))
    with open(log_file, "a") as f:
        f.write("not valid json\n")
    log.append(LogEntry(
        timestamp=1002.0,
        resource="also-good",
        provider="p",
        action="a",
        command="c",
        mode="mock",
    ))
    entries = log.read_history()
    assert len(entries) == 2


# -- record_execution --


def test_record_execution_basic(log_file: Path):
    log.record_execution(
        resource="router-core",
        provider="vyos",
        action="show_interfaces",
        command="ssh vyos@198.51.100.1 'show interfaces'",
        mode="live",
        returncode=0,
        duration_ms=42,
        output="eth0: up\n",
    )
    entries = log.read_history()
    assert len(entries) == 1
    assert entries[0]["mode"] == "live"
    assert entries[0]["returncode"] == 0
    assert entries[0]["duration_ms"] == 42


def test_record_execution_truncates_long_output():
    long_output = "x" * 5000
    log.record_execution(
        resource="test",
        provider="p",
        action="a",
        command="c",
        mode="live",
        output=long_output,
    )
    entries = log.read_history()
    assert len(entries[0]["output"]) == 2000


def test_record_execution_preserves_short_output():
    log.record_execution(
        resource="test",
        provider="p",
        action="a",
        command="c",
        mode="live",
        output="short",
    )
    entries = log.read_history()
    assert entries[0]["output"] == "short"


def test_record_execution_destructive_flag():
    log.record_execution(
        resource="vcenter",
        provider="govc",
        action="vm_power_off",
        command="govc vm.power -off",
        mode="blocked",
        destructive=True,
    )
    entries = log.read_history()
    assert entries[0]["destructive"] is True
