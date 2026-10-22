"""The run's reading: every number a statute did not state, named once, with its convention; and the
legal aggregates the run admitted.

Format (JSON; `Decode.reading` in Core decodes the same fields):
{"run": "<name>",
 "params": [{"name": "p.<name>", "value": 1.5, "unit": "s", "convention": "<where the value comes from>"}],
   (a param whose value equals a figure a law of the corpus states also carries "figure_review": "<why it is a
    convention, not that figure>"; the doctor lists every such param until it does)
 "aggregates": [{"id": "<definition id>::<term>", "included": ["ru.*", ...], "unresolved": ["ru.*", ...], ...}]}
An aggregate is admitted per run by the aggregate gate (`harness/phases/aggregate.py`) into
results/<run>/reading.json, keyed by its legal source; every class it lists neither as included nor
as unresolved is excluded. The operator's base reading declares parameters, never aggregates.
Units: m, s, m/s, m/s2, deg, deg/s, ratio, count.
"""
from __future__ import annotations
import json
from pathlib import Path

def _spellings() -> list[str]:
    from .units import spellings
    return spellings()


TEMPLATE = {
    "run": "<run id>",
    "params": [],
    "aggregates": [],
    "_fields": {
        "params": "name (p.<name>), value (number), unit (one of Core's spellings: " + "|".join(_spellings()) + "), convention (text), "
                  "figure_review (optional: why a value that equals a figure some law states is a convention, not that figure)",
        "aggregates": "admitted by the run's aggregate gate, never written by hand: id (<definition id>::<term>), included and unresolved ru.* classes",
    },
}


def reading_defects(data) -> list[str]:
    """Every defect that keeps a reading from being read whole, as Core decodes it: a parameter
    without a non-empty name, a finite number for its value, or a unit Core knows, a name given
    twice, and an aggregate without an id, given twice, or whose classes are not lists of ids. A
    reading with a defect is not evaluated: nothing falls back to an empty reading."""
    import math
    from .units import FACTORS
    if not isinstance(data, dict):
        return ["the reading is not a JSON object"]
    errs, seen = [], set()
    params = data.get("params", [])
    if not isinstance(params, list):
        return ["`params` is not a list"]
    for i, p in enumerate(params):
        where = f"params[{i}]" + (f" `{p.get('name')}`" if isinstance(p, dict) and isinstance(p.get("name"), str) else "")
        if not isinstance(p, dict) or not isinstance(p.get("name"), str) or not p["name"].strip():
            errs.append(f"{where}: no name"); continue
        v = p.get("value")
        if isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v):
            errs.append(f"{where}: the value {v!r} is not a finite number")
        if p.get("unit") not in FACTORS:
            errs.append(f"{where}: the unit {p.get('unit')!r} is not one Core knows")
        if p["name"] in seen:
            errs.append(f"{where}: the name is given twice")
        seen.add(p["name"])
    ids = set()
    aggs = data.get("aggregates", [])
    if not isinstance(aggs, list):
        return errs + ["`aggregates` is not a list"]
    for i, a in enumerate(aggs):
        if not isinstance(a, dict) or not isinstance(a.get("id"), str) or not a["id"]:
            errs.append(f"aggregates[{i}]: no id"); continue
        if a["id"] in ids:
            errs.append(f"aggregates[{i}] `{a['id']}`: the id is given twice")
        ids.add(a["id"])
        for k in ("included", "unresolved"):
            if not isinstance(a.get(k, []), list) or not all(isinstance(x, str) for x in a.get(k, [])):
                errs.append(f"aggregates[{i}] `{a['id']}`: `{k}` is not a list of class ids")
    return errs


class Reading:
    def __init__(self, path: Path):
        self.path = path
        self.data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"params": [], "aggregates": []}
        self.params = {p["name"]: p for p in self.data.get("params", [])}

    def has(self, name: str) -> bool:
        return name in self.params

    @staticmethod
    def own_proposal(entry: dict | None, law: str) -> bool:
        """Whether a catalogue entry is a value a node of `law` proposed and the operator has not
        reviewed: that law's repair or re-plan may still change it, since a value its own review
        refuted must not bind its correction."""
        from .nodeid import law_of
        origin = str((entry or {}).get("proposed") or "").split()
        return bool(origin) and law_of(origin[-1])[0] == law

    @staticmethod
    def add_proposals(path: Path, proposals: list[dict], origin: str) -> list[dict]:
        """Enter a planner's parameter proposals into the reading at `path` as the proposed tier:
        each becomes a `params` entry carrying `proposed: <origin>` (the run, iteration and node
        that proposed it), its convention and source, until the operator reviews it by removing
        the marker or changing the value. A name the reading already has is left as it is, except
        an unreviewed value a node of the same law proposed, which the new proposal replaces.
        Returns the entries added or replaced."""
        from .nodeid import law_of
        data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"params": [], "aggregates": []}
        have = {p.get("name"): p for p in data.get("params", [])}
        law = law_of(origin.split()[-1])[0] if origin.split() else ""
        added = []
        for pr in proposals:
            entry = {"name": pr["name"], "value": pr["value"], "unit": pr["unit"], "convention": pr.get("convention", ""),
                     "source": pr.get("source", ""), "proposed": origin}
            old = have.get(pr.get("name"))
            if old is not None:
                if not Reading.own_proposal(old, law) or (old.get("value"), old.get("unit")) == (pr["value"], pr["unit"]):
                    continue
                old.clear(); old.update(entry); added.append(entry)
                continue
            data.setdefault("params", []).append(entry); have[pr["name"]] = entry; added.append(entry)
        if added:                                     # replaced whole, so a stop midway leaves the previous reading
            from ..store import jsonl
            jsonl.write_atomic(path, json.dumps(data, ensure_ascii=False, indent=1) + "\n")
        return added

    def aggregate_ids(self) -> set[str]:
        return {a.get("id") for a in self.data.get("aggregates", []) if a.get("id")}

    def aggregate(self, aid: str) -> dict | None:
        """The admitted aggregate with this id."""
        return next((a for a in self.data.get("aggregates", []) if a.get("id") == aid), None)

    def lean_json(self) -> str:
        """The reading as the Lean decoder expects it (no private fields)."""
        return json.dumps({k: v for k, v in self.data.items() if not k.startswith("_")}, ensure_ascii=False)


def write_template(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        from ..store import jsonl
        jsonl.write_atomic(path, json.dumps(TEMPLATE, indent=1, ensure_ascii=False) + "\n")
