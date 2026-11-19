"""Returns asked of a node that does not declare a case another node reads.

A composition naming a case its target does not declare is never read as absent: the validator
returns the caller (`validate_a.MISSING_CASE`), and the target goes back to its planner with the
request. A request is counted per (caller, target, case) and per version of the target: at most
`LIMIT` returns of one version, and the count starts again when the target's version changes. After
the limit a gap is filed on the caller, naming the caller, the target, the case, the target's
version and the returns made, and the caller is blocked on it. The target's return counts one of
its plan attempts, so its versions are bounded by its budget and no request loops."""
from __future__ import annotations
import json
from pathlib import Path

#: The returns of one target version asked by one (caller, case) before a gap is filed on the caller.
LIMIT = 2


def key(caller: str, target: str, case: str) -> str:
    return f"{caller}|{target}|{case}"


def decide(state: dict, caller: str, target: str, case: str, version: str) -> tuple[str, int]:
    """`("return", n)` when the target goes back to its planner (the n-th return of this version), or
    `("gap", n)` once `LIMIT` returns of this version were made; `state` is updated."""
    k = key(caller, target, case)
    e = state.get(k)
    if e is None or e.get("version") != version:
        e = {"version": version, "returns": 0}
    if e["returns"] < LIMIT:
        e["returns"] += 1
        state[k] = e
        return "return", e["returns"]
    e["gap"] = True
    state[k] = e
    return "gap", e["returns"]


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}


def save(path: Path, state: dict) -> None:
    path.write_text(json.dumps(state, indent=1, sort_keys=True) + "\n", encoding="utf-8")


def target_version(nodes: dict[str, dict], target: str) -> str:
    """The version of the target a request is counted against: the digest of its accepted record, or
    `unaccepted`."""
    from .integrate import _digest, semantic_record
    rec = nodes.get(target)
    return _digest(semantic_record(rec))[:24] if rec is not None else "unaccepted"
