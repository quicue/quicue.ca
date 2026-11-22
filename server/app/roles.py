"""Operator roles: which action categories each role may run live.

Mirrors ou/roles.cue (#Roles), which scopes the Hydra document per role.
tests/test_roles.py checks the two agree when cue is installed.
"""

from __future__ import annotations

ROLE_CATEGORIES: dict[str, frozenset[str]] = {
    "ops": frozenset({"info", "connect", "monitor", "admin"}),
    "dev": frozenset({"info", "connect"}),
    "readonly": frozenset({"info"}),
}

# Only this role may run actions flagged destructive (and it still needs
# the X-Confirm-Destructive: yes header).
DESTRUCTIVE_ROLE = "ops"


def can_run(role: str | None, category: str, destructive: bool) -> tuple[bool, str]:
    """Return (allowed, reason) for a live action."""
    if role is None:
        return False, "no role"
    allowed = ROLE_CATEGORIES.get(role, frozenset())
    if category not in allowed:
        return False, f"role '{role}' cannot run {category} actions"
    if destructive and role != DESTRUCTIVE_ROLE:
        return False, f"role '{role}' cannot run destructive actions"
    return True, ""
