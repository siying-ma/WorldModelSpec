"""The run's reading: every number a statute did not state, named once, with its convention; and the
legal aggregates the run admitted.

Format (JSON; `Decode.reading` in Core decodes the same fields):
{"run": "<name>",
 "params": [{"name": "p.<name>", "value": 1.5, "unit": "s", "convention": "<where the value comes from>"}],
   (a param whose value equals a figure a law of the corpus states also carries "figure_review": "<why it is a
    convention, not that figure>"; the doctor lists every such param until it does)
 "aggregates": [{"id": "<definition id>::<term>", "included": ["ru.*", ...], "unresolved": ["ru.*", ...], ...}],
 "declarations": [{"id": "asm.<name>" | "int.<name>", "meaning": "<what the id states>", "proposed": "<origin>"?}]}
A declaration is a fact a trace supplies and no camera observes, an assumption (`asm.*`) or a declared
intention (`int.*`): one catalogue for both, so an id has one meaning and an adapter can read every id
it must supply. A plan proposes an id with its meaning; the harness enters it `proposed` when the node
is coded, and the operator reviews it by removing the marker.
An aggregate is admitted per run by the aggregate gate (`harness/phases/aggregate.py`) into
results/<run>/reading.json, keyed by its legal source; every class it lists neither as included nor
as unresolved is excluded. The operator's base reading declares parameters, never aggregates.
Units: m, s, m/s, m/s2, deg, deg/s, ratio, count.
"""
from __future__ import annotations
import json
import re
from pathlib import Path

def _spellings() -> list[str]:
    from .units import spellings
    return spellings()


TEMPLATE = {
    "run": "<run id>",
    "params": [],
    "aggregates": [],
    "declarations": [],
    "_fields": {
        "params": "name (p.<name>), value (number), unit (one of Core's spellings: " + "|".join(_spellings()) + "), convention (text), "
                  "figure_review (optional: why a value that equals a figure some law states is a convention, not that figure)",
        "aggregates": "admitted by the run's aggregate gate, never written by hand: id (<definition id>::<term>), included and unresolved ru.* classes",
        "declarations": "id (asm.<name> or int.<name>), meaning (what the id states); proposed (the run, iteration and node that proposed it, until reviewed)",
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
    decls = data.get("declarations", [])
    if not isinstance(decls, list):
        return errs + ["`declarations` is not a list"]
    seen_ids = set()
    for i, d in enumerate(decls):
        if not isinstance(d, dict) or not isinstance(d.get("id"), str) or not DECLARED_ID.match(d["id"]):
            errs.append(f"declarations[{i}]: the id is not `asm.<name>` or `int.<name>`"); continue
        if not isinstance(d.get("meaning"), str) or not d["meaning"].strip():
            errs.append(f"declarations[{i}] `{d['id']}`: no meaning")
        if d["id"] in seen_ids:
            errs.append(f"declarations[{i}] `{d['id']}`: the id is given twice")
        seen_ids.add(d["id"])
    return errs


#: A declared-fact id: an assumption or a declared intention, `asm.` or `int.` and a snake-case name.
DECLARED_ID = re.compile(r"^(asm|int)\.[a-z0-9_]+$")

#: A citation in a declared fact's meaning: a section sign; a code's abbreviation and a section
#: number with dotted parts or bracketed subsections; an id of a corpus record (an abbreviation and
#: hyphenated parts with a digit) or of a posted definition; a section, chapter or title named by its
#: number; or a bare section number with dotted parts. A meaning states the fact or state the source
#: supplies, so it names no law, no definition and no provision.
MEANING_CITATION = re.compile(
    r"§"
    r"|\b[A-Z]{2,}\s*\d+[A-Z]?(?:\.\d+[A-Za-z]?)+(?:\([0-9A-Za-z]+\))*"
    r"|\b[A-Z]{2,}(?:-[A-Za-z0-9]+)*-\d[A-Za-z0-9]*(?:-[A-Za-z0-9]+)*"
    r"|\bDEF-"
    r"|\b(?:[Ss]ection|[Ss]ubsection|[Cc]hapter|[Tt]itle|[Pp]aragraph)s?\s+\d+[A-Z]?(?:\.\d+)*"
    r"|\b\d+[A-Z]\.\d+|\b\d+\.\d+\.\d+")


def meaning_citations(meaning: str) -> list[str]:
    """The citations a declared fact's meaning carries (`MEANING_CITATION`), in order."""
    return [m.group(0) for m in MEANING_CITATION.finditer(meaning or "")]


def same_meaning(a, b) -> bool:
    """Two meanings are the same when they are equal up to whitespace."""
    return isinstance(a, str) and isinstance(b, str) and " ".join(a.split()) == " ".join(b.split())


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

    def declarations(self) -> dict[str, dict]:
        """The catalogue of declared-fact ids, `asm.*` and `int.*`, by id."""
        return {d["id"]: d for d in self.data.get("declarations", []) if isinstance(d, dict) and d.get("id")}

    @staticmethod
    def add_declarations(path: Path, decls: list[dict], origin: str) -> list[dict]:
        """Enter declared-fact ids into the reading at `path`: an id it lacks becomes a `declarations`
        entry with its meaning, marked `proposed: <origin>` until the operator reviews it. An id it
        has with the same meaning is left as it is; one with another meaning is a broken invariant
        (validation gives every record its catalogue's meaning) and raises. Returns the entries added."""
        data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"params": [], "aggregates": []}
        have = {d.get("id"): d for d in data.get("declarations", []) if isinstance(d, dict)}
        added = []
        for d in decls:
            old = have.get(d["id"])
            if old is not None:
                if same_meaning(old.get("meaning"), d.get("meaning")):
                    continue
                raise ValueError(f"declaration `{d['id']}`: the reading means {old.get('meaning')!r}, a record {d.get('meaning')!r}")
            entry = {"id": d["id"], "meaning": " ".join(str(d.get("meaning", "")).split()), "proposed": origin}
            data.setdefault("declarations", []).append(entry); have[d["id"]] = entry; added.append(entry)
        if added:
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
