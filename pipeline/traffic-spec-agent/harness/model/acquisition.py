"""The operator's acquisition profiles (`config/acquisition_profiles.json`): for the recordings of one
acquisition standard, the reading parameter that bounds the integration step of `heading_since`.

`heading_since` integrates a road user's yaw rate since its onset rose, and its step bound limits every
sampling interval it integrates over: a sampling standard of the recordings, shared by every rule a run
checks on them, never a property of one law. A run names one profile (`Options.acquisition_profile`);
the node gate requires every `heading_since` step bound of a rule, its concept calls expanded, to be
that profile's parameter, and accepts it only once the operator has reviewed its value in the reading.
No plan or repair proposes a parameter any profile names. The file names parameters, never values.

Format: {"profiles": {"<profile>": {"covers": "<which recordings>", "heading_since_step": "p.<name>"}}}."""
from __future__ import annotations
import hashlib
import json
import re
from pathlib import Path

PROFILES = Path(__file__).resolve().parents[2] / "config" / "acquisition_profiles.json"
_NAME = re.compile(r"[a-z][a-z0-9_]*")
_PARAM = re.compile(r"p\.[a-z][a-z0-9_]*")


class ProfileError(ValueError):
    """The profiles file cannot be read, an entry is malformed, or a profile is not in it."""


def load(path: Path | None = None) -> dict[str, dict]:
    """Every profile by name (from `path`, by default the operator's file), each checked whole;
    `ProfileError` names the first defect."""
    path = Path(path or PROFILES)
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise ProfileError(f"the acquisition profiles file {path} does not exist") from None
    except (OSError, json.JSONDecodeError) as e:
        raise ProfileError(f"the acquisition profiles file {path} cannot be read: {e}") from None
    profiles = data.get("profiles") if isinstance(data, dict) else None
    if not isinstance(profiles, dict) or not profiles:
        raise ProfileError(f"{path}: `profiles` is not a non-empty object")
    for name, entry in profiles.items():
        if not _NAME.fullmatch(str(name)):
            raise ProfileError(f"{path}: profile name {name!r} is not lower snake case")
        if not isinstance(entry, dict) or not str(entry.get("covers") or "").strip():
            raise ProfileError(f"{path}: profile `{name}` states no `covers` (which recordings it is the standard of)")
        if not _PARAM.fullmatch(str(entry.get("heading_since_step") or "")):
            raise ProfileError(f"{path}: profile `{name}` names {entry.get('heading_since_step')!r} as its `heading_since_step`, "
                               "not a reading parameter of the form `p.<snake_case>`")
    return profiles


def step_parameter(profile: str | None, path: Path | None = None) -> str:
    """The reading parameter that bounds `heading_since`'s step under `profile`; `ProfileError` when
    no profile is named, the file is not readable whole, or the profile is not in it."""
    if not profile:
        raise ProfileError("the run names no acquisition profile (`--acquisition_profile`), so no reviewed parameter bounds "
                           "the step of `heading_since`")
    profiles = load(path)
    if profile not in profiles:
        raise ProfileError(f"acquisition profile `{profile}` is not in {path or PROFILES} (profiles: {', '.join(sorted(profiles))})")
    return profiles[profile]["heading_since_step"]


def reserved_parameters(path: Path | None = None) -> dict[str, list[str]]:
    """Each parameter some profile names, with the profiles naming it: the operator's, never a
    session's to propose. Empty when the file is absent or unreadable (the gate refuses any use
    of `heading_since` then)."""
    try:
        profiles = load(path)
    except ProfileError:
        return {}
    out: dict[str, list[str]] = {}
    for name, entry in sorted(profiles.items()):
        out.setdefault(entry["heading_since_step"], []).append(name)
    return out


def review_defects(param: str, reading_data: dict) -> list[str]:
    """Why the reading does not hold `param` as an operator-reviewed time: absent, still marked
    `proposed`, not in a unit of time, or not a positive number (Core reads a step bound that is not
    positive as malformed, every verdict on it unknown). Empty when it does."""
    import math
    from .units import FACTORS
    entry = next((p for p in (reading_data or {}).get("params", []) if isinstance(p, dict) and p.get("name") == param), None)
    if entry is None:
        return [f"the reading has no `{param}`: the operator enters its reviewed value"]
    if entry.get("proposed"):
        return [f"the reading holds `{param}` only as a proposal ({entry.get('proposed')}): the operator reviews its value"]
    if FACTORS.get(str(entry.get("unit")), ("",))[0] != "second":
        return [f"the reading gives `{param}` in {entry.get('unit')!r}, not a unit of time"]
    v = entry.get("value")
    if isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v) or v <= 0:
        return [f"the reading gives `{param}` the value {v!r}: a step bound is a positive time"]
    return []


def standard_note(profile: str | None, path: Path | None = None) -> str:
    """The run's acquisition standard as its planning, repair and coding sessions are shown it: the
    profile and the reviewed parameter every `headingSince` step bound is, or that none resolves and
    no rule may read `headingSince`."""
    try:
        param = step_parameter(profile, path)
    except ProfileError as e:
        return f"\nAcquisition standard: {e}; no rule of this run may read `headingSince`.\n"
    return (f"\nAcquisition standard: profile `{profile}`. Every `headingSince` step bound in a rule is exactly "
            f"`.param \"{param}\"`, the operator's reviewed parameter: name it as it is, never propose it or a value for it.\n")


def standard_digest(profile: str | None, path: Path | None = None) -> str:
    """What a run's results rest on: the profile it names and the parameter that profile resolves to
    (`none` when it names no profile, `unresolved: <why>` when it does not resolve)."""
    if not profile:
        resolved = "none"
    else:
        try:
            resolved = step_parameter(profile, path)
        except ProfileError as e:
            resolved = f"unresolved: {e}"
    return hashlib.sha256(json.dumps({"profile": profile, "heading_since_step": resolved}, sort_keys=True).encode()).hexdigest()[:24]
