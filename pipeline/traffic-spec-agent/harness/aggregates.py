"""Legal aggregates derived from the corpus definitions by the plan phase (`aggregates.jsonl`).

A record maps one defined term to the ontology's classes:
  {"word": "vehicle", "definition": "DEF-…", "classes": ["ru.motor_vehicle", "motor vehicle", …],
   "justification": "<the definition's words that admit or exclude each>", "unresolved": [{"text": …, "why": …}]}
A member is an `ru.*` id or another defined word (expanded transitively by `Reading.aggregate`).
The harness validates every record against the definitions the planner was given, the ontology and
the reading, and merges the accepted ones into the run's reading, where the operator's own
`aggregates` (written in the base reading) take precedence. Nothing in the repository declares
what "vehicle" covers: the run derives it from the definitions and the operator reviews it.
"""
from __future__ import annotations
import json
from pathlib import Path
from .ontology import Ontology
from .reading import Reading

REQUIRED = ("word", "definition", "classes", "justification")


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


def validate(records: list[dict], definitions: list[dict], onto: Ontology, base: Reading) -> tuple[list[dict], list[str]]:
    """(accepted records, reasons for the rejected ones)."""
    def_ids = {d.get("id") for d in definitions}
    words_here = {r.get("word") for r in records if r.get("word")}
    known_words = words_here | base.aggregate_words()
    accepted, errs = [], []
    for r in records:
        w = r.get("word", "?")
        missing = [k for k in REQUIRED if k not in r]
        if missing:
            errs.append(f"aggregate `{w}`: missing {missing}"); continue
        if not isinstance(r["classes"], list) or not all(isinstance(c, str) for c in r["classes"]):
            errs.append(f"aggregate `{w}`: `classes` must be a list of strings"); continue
        if r["definition"] not in def_ids:
            errs.append(f"aggregate `{w}`: definition `{r['definition']}` is not among the definitions given"); continue
        bad = [c for c in r["classes"] if not ((c.startswith("ru.") and c in onto.atom_ids) or (not c.startswith("ru.") and c in known_words))]
        if bad:
            errs.append(f"aggregate `{w}`: {bad} are neither `ru.*` ids of the ontology nor defined words (a class the ontology lacks goes under `unresolved`)"); continue
        if w in r["classes"]:
            errs.append(f"aggregate `{w}`: names itself"); continue
        if not r["classes"] and not r.get("unresolved"):
            errs.append(f"aggregate `{w}`: covers nothing and reports nothing unresolved"); continue
        if base.has_aggregate(w):
            errs.append(f"aggregate `{w}`: the operator's reading already declares it; the operator's declaration stands")
            continue
        accepted.append(r)
    # a defined word used as a member must itself be accepted or the operator's
    ok_words = {r["word"] for r in accepted} | base.aggregate_words()
    final = []
    for r in accepted:
        dangling = [c for c in r["classes"] if not c.startswith("ru.") and c not in ok_words]
        if dangling:
            errs.append(f"aggregate `{r['word']}`: members {dangling} were rejected"); continue
        final.append(r)
    return final, errs


def merge(reading_path: Path, records: list[dict], run_id: str, iteration: int) -> list[dict]:
    """Write the accepted records into the run's reading (replacing earlier derived records of the
    same word); returns the reading's derived aggregates after the merge."""
    data = json.loads(reading_path.read_text(encoding="utf-8"))
    aggs = [a for a in data.get("aggregates", []) if not a.get("derived") or a["word"] not in {r["word"] for r in records}]
    for r in records:
        aggs.append({"word": r["word"], "classes": r["classes"], "source": r["definition"],
                     "convention": r.get("justification", ""), "unresolved": r.get("unresolved", []),
                     "derived": f"{run_id}/iter-{iteration:03d}"})
    data["aggregates"] = aggs
    reading_path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    flat = Reading(reading_path)
    for a in aggs:
        a["expands_to"] = flat.expand(a["word"])      # informational: the classes after nested words are resolved
    data["aggregates"] = aggs
    reading_path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return [a for a in aggs if a.get("derived")]


def render(reading: Reading) -> str:
    """The aggregates a planner may name: the operator's, then those derived in earlier iterations."""
    aggs = reading.data.get("aggregates", [])
    if not aggs:
        return "(none declared yet: derive every aggregate word the laws use from the definitions, see the rules)\n"
    out = []
    for a in aggs:
        who = f"derived in {a['derived']} from `{a.get('source')}`" if a.get("derived") else "declared by the operator"
        out.append(f"- `{a['word']}` ({who}): {', '.join(a.get('classes', []))}")
    return "\n".join(out) + "\n"
