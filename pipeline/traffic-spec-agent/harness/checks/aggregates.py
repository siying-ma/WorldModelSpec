"""Legal aggregates: the structural checks of the representation selection and of an aggregate's
class mapping. They decide neither the representation nor any membership.

A selection row (`aggregate_selection.jsonl`) is the planner's decision for one posted definition
and one term it defines, whichever laws use it:
  {"definition": "DEF-…", "term": "<term>", "representation": "aggregate" | "not_aggregate" | "gap",
   "target": "<definition>::<term slug>" (aggregate) | null, "quote": "<verbatim words of the
   definition>", "reason": "<why>"}
Every resolved (definition, term) of the run's resolution table has exactly one row. A definition
denoting an extensional set of tracked road-user classes is an aggregate. A relational role such
as who controls another entity is not an aggregate even though it may name a road user.

A mapping record classifies every road-user class of the active ontology:
  {"aggregate_id": "<definition>::<term slug>" | "<law id>:<span>::<term slug>", "term": …,
   "definition": "DEF-…" | null, "classifications": [{"class": "ru.<class>", "status": "included" |
   "excluded" | "covered" | "unresolved", "quotes": [{"definition": "DEF-…" | "<law id>", "words": "…"}],
   "reason": "…", "covered_by": ["ru.<class>", …], "basis": [{"class": "ru.<class>", "words": "…"}]}]}
Each class exactly once; no class that is not a road-user class of the ontology, and no other
aggregate (no nesting); an included or excluded status quotes words that decide it, an
unresolved one the closest words and a reason; every quote verbatim in the posted text it names,
which is the controlling definition, a definition its cross-references or nested defined terms
reach, or, for a law-local aggregate, the law itself.

`excluded` means the definition leaves the class out. `covered` means the definition admits members
of the class only as members of other classes the same mapping includes, so the class's own label
adds no membership evidence: a covered class names those classes in `covered_by` (at least one,
never itself, each proposed `included`), quotes in `basis`, verbatim, the class contracts that make
the coverage complete (of the covered class or of a covering one), and gives a reason. Only a
covered class carries `covered_by` and `basis`. A reading entry lists the classes included and
unresolved, which is all the evaluator reads, and the covered ones with their covering classes for
audit; a covered class is in neither executable list, so it never makes a road user a member nor
its membership unknown.
"""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

from ..model import definitions as definitions_mod
from ..model.ontology import Ontology

REPRESENTATIONS = ("aggregate", "not_aggregate", "gap")
STATUSES = ("included", "excluded", "covered", "unresolved")
SELECTION_KEYS = {"definition", "term", "representation", "target", "quote", "reason"}
RECORD_KEYS = {"aggregate_id", "term", "definition", "classifications"}
CLASS_KEYS = {"class", "status", "quotes", "reason", "covered_by", "basis"}
COVER_KEYS = {"covered_by", "basis"}
#: `ru.*` atoms that are attributes or relations of a road user, not classes.
NOT_CLASSES = {"ru.occupant_count", "ru.rider_posture", "ru.subject", "ru.aggregate"}


def load(path: Path) -> list[dict]:
    if not path.exists():
        return []
    out = []
    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines()):
        if line.strip():
            try:
                out.append(json.loads(line))
            except json.JSONDecodeError as e:
                raise ValueError(f"{path}:{i + 1}: not JSON: {e}")
    return out


def slug(term: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", term.lower()).strip("_")


def aggregate_id(definition: str, term: str) -> str:
    return f"{definition}::{slug(term)}"


def law_local(aid: str) -> bool:
    return "::" in aid and not aid.startswith("DEF-")


def road_user_classes(onto: Ontology) -> list[str]:
    return sorted(a for a in onto.atom_ids if a.startswith("ru.") and a not in NOT_CLASSES)


def _ws(s) -> str:
    return " ".join(str(s or "").split())


def _verbatim(words: str, text: str) -> bool:
    """The words occur in the text, quotation marks and spacing aside. A quote elided with `…`,
    `...` or `[...]` occurs when every fragment does, in order, and the fragments together carry at
    least three words — the review's rule for a quotation."""
    norm = lambda s: _ws(re.sub(r"[`\"“”]", "", str(s or ""))).lower()
    frags = [f for f in (norm(x).strip(" .,;:") for x in re.split(r"\[\s*(?:\u2026|\.\.\.)\s*\]|\u2026|\.\.\.", str(words or ""))) if f]
    if not frags or (len(frags) > 1 and sum(len(f.split()) for f in frags) < 3):
        return False
    h, pos = norm(text), 0
    for f in frags:
        i = h.find(f, pos)
        if i < 0:
            return False
        pos = i + len(f)
    return True


def pairs_of(table: dict) -> dict[tuple[str, str], list[str]]:
    """(definition, term) → the laws that use it, over the resolved rows of the resolution table."""
    out: dict[tuple[str, str], list[str]] = {}
    for law, rows in table.get("laws", {}).items():
        for r in rows:
            if r.get("status") == "resolved" and r.get("definition"):
                out.setdefault((r["definition"], r["term"]), []).append(law)
    return out


def resolution_of(table: dict, definition: str) -> dict:
    return definitions_mod.resolution_closure(table, definition)


def selection_defects(row: dict, defs_by_id: dict[str, dict], table: dict) -> list[str]:
    where = f"selection {row.get('definition')} / {row.get('term')!r}"
    errs = []
    extra, missing = sorted(set(row) - SELECTION_KEYS), sorted(SELECTION_KEYS - set(row))
    if extra or missing:
        errs.append(f"{where}: keys are exactly {sorted(SELECTION_KEYS)}" + (f"; extra {extra}" if extra else "") + (f"; missing {missing}" if missing else ""))
    rep = row.get("representation")
    if rep not in REPRESENTATIONS:
        errs.append(f"{where}: representation is one of {list(REPRESENTATIONS)}")
    if rep == "aggregate" and row.get("target") != aggregate_id(str(row.get("definition")), str(row.get("term"))):
        errs.append(f"{where}: an aggregate's target is `{aggregate_id(str(row.get('definition')), str(row.get('term')))}`")
    if rep in ("not_aggregate", "gap") and row.get("target") is not None:
        errs.append(f"{where}: `target` is null for {rep}")
    controlling = resolution_of(table, str(row.get("definition"))).get("chain", [])
    texts = " ".join(_ws(defs_by_id.get(d, {}).get("text")) for d in controlling)
    if not _verbatim(row.get("quote", ""), texts):
        errs.append(f"{where}: `quote` is not verbatim in the definition")
    if not _ws(row.get("reason")):
        errs.append(f"{where}: `reason` is empty")
    return errs


def validate_selection(rows: list[dict], table: dict, defs_by_id: dict[str, dict]) -> tuple[dict[tuple[str, str], dict], list[str]]:
    """(the valid rows by (definition, term), the defects): exactly one row per resolved pair."""
    pairs = pairs_of(table)
    seen: dict[tuple[str, str], dict] = {}
    errs = []
    for r in rows:
        key = (str(r.get("definition")), str(r.get("term")))
        if key not in pairs:
            errs.append(f"selection {key[0]} / {key[1]!r}: no law resolves this term to this definition"); continue
        if key in seen:
            errs.append(f"selection {key[0]} / {key[1]!r}: written twice"); continue
        e = selection_defects(r, defs_by_id, table)
        if e:
            errs += e; continue
        seen[key] = r
    return seen, errs


def missing_pairs(selected: dict, table: dict) -> list[tuple[str, str]]:
    return sorted(set(pairs_of(table)) - set(selected))


def record_defects(rec: dict, onto: Ontology, allowed_sources: dict[str, str]) -> list[str]:
    """Structural defects of a class mapping: the schema, every class exactly once, the statuses,
    and every quote verbatim in a source it may quote (`allowed_sources`: id → posted text)."""
    aid = rec.get("aggregate_id", "?")
    errs = []
    extra, missing = sorted(set(rec) - RECORD_KEYS), sorted(RECORD_KEYS - set(rec))
    if extra or missing:
        errs.append(f"aggregate `{aid}`: keys are exactly {sorted(RECORD_KEYS)}" + (f"; extra {extra}" if extra else "") + (f"; missing {missing}" if missing else ""))
    cls = rec.get("classifications")
    if not isinstance(cls, list):
        return errs + [f"aggregate `{aid}`: `classifications` is a list"]
    want = road_user_classes(onto)
    got = [c.get("class") for c in cls if isinstance(c, dict)]
    dup = sorted({c for c in got if got.count(c) > 1})
    if dup:
        errs.append(f"aggregate `{aid}`: classified twice: {dup}")
    unknown = sorted(set(got) - set(want))
    if unknown:
        errs.append(f"aggregate `{aid}`: {unknown} are not road-user classes of the ontology (an aggregate classifies classes, never another aggregate)")
    absent = sorted(set(want) - set(got))
    if absent:
        errs.append(f"aggregate `{aid}`: every road-user class is classified; missing {absent}")
    for c in cls:
        if not isinstance(c, dict):
            errs.append(f"aggregate `{aid}`: a classification is an object"); continue
        where = f"aggregate `{aid}` {c.get('class')}"
        if set(c) - CLASS_KEYS or not {"class", "status", "quotes"} <= set(c):
            errs.append(f"{where}: keys are class, status, quotes, (for unresolved and covered) reason and (for covered) covered_by and basis")
        if c.get("status") not in STATUSES:
            errs.append(f"{where}: status is one of {list(STATUSES)}")
        if c.get("status") == "covered":
            errs += _cover_defects(c, where, cls, onto, set(want))
        elif COVER_KEYS & set(c):
            errs.append(f"{where}: only a covered class carries `covered_by` and `basis`")
        qs = c.get("quotes")
        if not isinstance(qs, list) or not qs:
            errs.append(f"{where}: quotes the controlling words"); continue
        for q in qs:
            src = q.get("definition") if isinstance(q, dict) else None
            if src not in allowed_sources:
                errs.append(f"{where}: quotes `{src}`, which is not its controlling definition or resolved definition dependency")
            elif not _verbatim(q.get("words", ""), allowed_sources[src]):
                errs.append(f"{where}: the quote \"{_ws(q.get('words'))[:80]}\" is not verbatim in `{src}`")
        if c.get("status") == "unresolved" and not _ws(c.get("reason")):
            errs.append(f"{where}: an unresolved status explains why the words decide neither inclusion nor exclusion")
    return errs


def _cover_defects(c: dict, where: str, cls: list, onto: Ontology, classes: set[str]) -> list[str]:
    """A covered classification's own fields: `covered_by` names at least one other road-user class,
    each proposed `included` in the same mapping (so no covered class rests on another covered one);
    `basis` quotes, verbatim, the contract of the covered class or of a covering one; a reason."""
    errs = []
    by = c.get("covered_by")
    proposed = {x.get("class"): x.get("status") for x in cls if isinstance(x, dict)}
    if not isinstance(by, list) or not by or not all(isinstance(t, str) for t in by):
        errs.append(f"{where}: `covered_by` is a non-empty list of the included classes that cover it")
        by = []
    if len(set(by)) != len(by):
        errs.append(f"{where}: `covered_by` names a class twice")
    for t in by:
        if t == c.get("class"):
            errs.append(f"{where}: `covered_by` names the class itself")
        elif t not in classes:
            errs.append(f"{where}: `covered_by` names `{t}`, which is not a road-user class of the ontology")
        elif proposed.get(t) != "included":
            errs.append(f"{where}: `covered_by` names `{t}`, which the mapping does not include (it is {proposed.get(t)})")
    basis = c.get("basis")
    if not isinstance(basis, list) or not basis:
        errs.append(f"{where}: `basis` quotes the class contracts that make the coverage complete")
        basis = []
    for b in basis:
        k = b.get("class") if isinstance(b, dict) else None
        if k != c.get("class") and k not in by:
            errs.append(f"{where}: `basis` quotes `{k}`, which is neither the class nor one of its covering classes")
        elif not _verbatim(b.get("words", ""), onto.contract(k)):
            errs.append(f"{where}: the basis \"{_ws(b.get('words'))[:80]}\" is not verbatim in the contract of `{k}`")
    if not _ws(c.get("reason")):
        errs.append(f"{where}: a covered status explains why every member the words admit carries a covering class")
    return errs


def digest(obj) -> str:
    return hashlib.sha256(json.dumps(obj, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()


def ontology_digest(onto: Ontology) -> str:
    return digest({c: onto.contract(c) for c in road_user_classes(onto)})


def admitted(rec: dict, statuses: dict[str, str]) -> dict:
    """The reading entry of an admitted mapping (`statuses`: class → final admitted status, after the
    gate's downgrades): the classes included and unresolved, which the evaluator reads, and, when
    any, the covered classes with their covering classes, definition words and contract basis,
    which it does not."""
    entry = {"id": rec["aggregate_id"], "term": rec.get("term"), "definition": rec.get("definition"),
             "included": sorted(c for c, s in statuses.items() if s == "included"),
             "unresolved": sorted(c for c, s in statuses.items() if s == "unresolved")}
    by_class = {c["class"]: c for c in rec["classifications"]}
    covered = [{"class": c, "covered_by": sorted(by_class[c]["covered_by"]), "quotes": by_class[c]["quotes"],
                "basis": by_class[c]["basis"]} for c in sorted(statuses) if statuses[c] == "covered"]
    if covered:
        entry["covered"] = covered
    return entry


def _term(row: dict) -> str:
    """A resolved term as the planner's table names it, with the law's words where it was found split."""
    return row["term"] + (f" (found split: \"{row['words']}\")" if row.get("match") == "split" else "")


def render(reading, rows_by_law: dict[str, list[dict]] | None = None, selection: dict | None = None) -> str:
    """For a planner: per law, each defined term with the definition that applies, the planner's
    representation and, for an admitted aggregate, its id; read-only."""
    if not rows_by_law:
        return "(no defined term of these laws has an applicable posted definition)\n"
    out = ["| law | term | applicable definition | representation | aggregate id (admitted) |", "|---|---|---|---|---|"]
    for law, rows in rows_by_law.items():
        for r in rows:
            if r.get("status") == "resolved":
                sel = (selection or {}).get((r["definition"], r["term"]), {})
                rep = sel.get("representation", "(not selected)")
                aid = sel.get("target") if rep == "aggregate" and reading.aggregate(sel.get("target") or "") else ""
                out.append(f"| {law} | {_term(r)} | `{r['definition']}` | {rep} | {'`' + aid + '`' if aid else ''} |")
            elif r.get("status") == "ambiguous":
                out.append(f"| {law} | {_term(r)} | ambiguous: {', '.join('`' + c + '`' for c in r.get('candidates', []))} (each states its own scope) | — | |")
            else:
                out.append(f"| {law} | {_term(r)} | none applies | — | |")
    return "\n".join(out) + "\n"
