"""Tests for command executor."""

from __future__ import annotations

import pytest

from app.executor.runner import run_command


@pytest.mark.asyncio
async def test_run_command_success() -> None:
    result = await run_command("echo hello")
    assert result.returncode == 0
    assert result.stdout.strip() == "hello"
    assert result.duration_ms >= 0


@pytest.mark.asyncio
async def test_run_command_failure() -> None:
    result = await run_command("false")
    assert result.returncode != 0


@pytest.mark.asyncio
async def test_run_command_timeout() -> None:
    result = await run_command("sleep 10", timeout=1)
    assert result.returncode == -1
    assert "timed out" in result.stderr.lower()


@pytest.mark.asyncio
async def test_run_command_stderr() -> None:
    result = await run_command("echo err >&2")
    assert "err" in result.stderr


@pytest.mark.asyncio
async def test_run_command_captures_both() -> None:
    result = await run_command("echo out && echo err >&2")
    assert "out" in result.stdout
    assert "err" in result.stderr
