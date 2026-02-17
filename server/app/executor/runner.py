"""Async subprocess command execution."""

from __future__ import annotations

import asyncio
import logging
import time
from dataclasses import dataclass

log = logging.getLogger(__name__)


@dataclass(frozen=True, slots=True)
class CommandResult:
    stdout: str
    stderr: str
    returncode: int
    duration_ms: int


async def run_command(command: str, timeout: int = 30) -> CommandResult:
    """Execute a shell command asynchronously with timeout.

    All commands come from the CUE-generated openapi.json spec,
    which resolves templates at build time. No user input is interpolated
    at runtime.
    """
    start = time.monotonic()
    try:
        proc = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout_bytes, stderr_bytes = await asyncio.wait_for(
            proc.communicate(), timeout=timeout
        )
        returncode = proc.returncode or 0
    except asyncio.TimeoutError:
        proc.kill()  # type: ignore[union-attr]
        await proc.wait()  # type: ignore[union-attr]
        elapsed = int((time.monotonic() - start) * 1000)
        return CommandResult(
            stdout="",
            stderr=f"Command timed out after {timeout}s",
            returncode=-1,
            duration_ms=elapsed,
        )

    elapsed = int((time.monotonic() - start) * 1000)
    return CommandResult(
        stdout=stdout_bytes.decode("utf-8", errors="replace"),
        stderr=stderr_bytes.decode("utf-8", errors="replace"),
        returncode=returncode,
        duration_ms=elapsed,
    )
