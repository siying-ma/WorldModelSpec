"""Shims for incompatibilities between `carla_sgg` and its pinned dependencies,
and for CARLA client API renames across server versions.

Applied by `runner` before `carla_sgg` is imported. Kept here, rather than by
editing `carla_sgg/`, so the vendored generator stays byte-identical to upstream
and the schema claims in `traffic-spec-agent/carla/schema.json` — which cite
`carla_sgg` line numbers — keep pointing at the right lines.
"""

from __future__ import annotations

import numpy as np


def patch_nan_to_num() -> bool:
    """Let `np.nan_to_num(x, 0)` keep working under NumPy 2.

    `carla_sgg/sgg.py:334` calls

        np.nan_to_num(180 - np.rad2deg(np.arccos(...)), 0)

    intending "replace NaN with zero". But `nan_to_num`'s second *positional*
    parameter is `copy`, not `nan`, so that 0 has always meant `copy=False`.
    NumPy 1.x tolerated it; NumPy 2 raises

        ValueError: Unable to avoid copy while creating an array as requested

    and the map indexing dies before a single frame is captured. Dropping the
    stray positional argument gives `nan=0.0`, which is both the default and
    what the call was written to mean, so the numerical result is unchanged
    from the NumPy 1.x behaviour.

    Returns True when the patch was installed.
    """
    if getattr(np.nan_to_num, "_carlaspec_patched", False):
        return False
    if np.__version__.startswith("1."):
        return False

    original = np.nan_to_num

    def nan_to_num(x, *args, **kwargs):
        # A legacy call passes `copy` positionally, meaning `nan`; both readings
        # agree on zero, which is the default.
        if args:
            args = ()
        return original(x, **kwargs)

    nan_to_num._carlaspec_patched = True          # type: ignore[attr-defined]
    np.nan_to_num = nan_to_num                    # type: ignore[assignment]
    return True


def keep_right_rule_percentage(tm, actor, percentage: float) -> None:
    """Set the Traffic Manager's keep-to-the-slower-lane percentage.

    CARLA renamed this method between server versions: 0.9.14 — the version
    `sim/` ships and the only one with a client wheel in
    `sim/PythonAPI/carla/dist/` — calls it `keep_right_rule_percentage`, and
    0.9.15 renamed it to `keep_slow_lane_rule_percentage`. Scenarios call this
    helper so a capture is not tied to one server version by a method name.

    Raises rather than degrading to a no-op: `emergency_pull_right` uses this to
    decide which lane the ego holds, which is the whole difference between its
    compliant and its violating counterpart. Silently skipping it would record
    two captures that differ in nothing and label one of them wrong.
    """
    for name in ("keep_right_rule_percentage", "keep_slow_lane_rule_percentage"):
        method = getattr(tm, name, None)
        if method is not None:
            method(actor, percentage)
            return
    raise AttributeError(
        "this carla.TrafficManager has neither keep_right_rule_percentage "
        "(0.9.14) nor keep_slow_lane_rule_percentage (0.9.15+); a scenario that "
        "depends on lane choice cannot be recorded against it")


def apply_all() -> list[str]:
    applied = []
    if patch_nan_to_num():
        applied.append("np.nan_to_num legacy positional argument (NumPy 2)")
    return applied
