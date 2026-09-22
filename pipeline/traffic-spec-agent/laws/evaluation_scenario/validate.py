"""Check scenarios.jsonl against the corpus and the ontology.

    python validate.py            # from laws/evaluation_scenario

Fails on: a corpus line with no scenario, a scenario with no corpus line, a duplicate id, an
order that does not follow laws.jsonl, a title or source that disagrees with the corpus line, a
subject, theme or tier that disagrees with audit_and_scripts/laws_meta.jsonl, an
`atom` that is not in ontology/ATOMS.md, a `kind` outside the closed set, or an empty
required_observations / activation_conditions / timing_requirements.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
LAWS = HERE.parent / "full_list" / "laws.jsonl"
LAWS_META = HERE.parent / "audit_and_scripts" / "laws_meta.jsonl"   # subject, theme, tier: analysis, not law
ATOMS_MD = HERE.parents[1] / "ontology" / "ATOMS.md"

KINDS = {"point_event", "continuous", "duration", "ordering", "until", "advance", "civil_time", "span"}
META_LAW = ("title", "source")
META_SIDECAR = ("subject", "theme", "tier")


def load(path):
    return [json.loads(l) for l in path.read_text(encoding="utf-8").splitlines() if l.strip()]


def main() -> int:
    laws = load(LAWS)
    meta = {m["id"]: m for m in load(LAWS_META)}
    rows = load(HERE / "scenarios.jsonl")
    atoms = set(re.findall(r"^\|\s*`((?:ru|kin|st|dev|sig|env|rel|drv)\.[a-z_0-9]+)`",
                           ATOMS_MD.read_text(encoding="utf-8"), re.M))
    errors: list[str] = []

    by_law = {x["id"]: x for x in laws}
    seen = set()
    for i, r in enumerate(rows):
        rid = r.get("id")
        if rid in seen:
            errors.append(f"duplicate id {rid}")
        seen.add(rid)
        if rid not in by_law:
            errors.append(f"{rid}: not a line of {LAWS.name}")
            continue
        if i >= len(laws) or laws[i]["id"] != rid:
            errors.append(f"{rid}: out of corpus order at row {i}")
        for k in META_LAW:
            if r.get(k) != by_law[rid].get(k):
                errors.append(f"{rid}: {k} disagrees with the corpus line")
        for k in META_SIDECAR:
            if r.get(k) != meta.get(rid, {}).get(k):
                errors.append(f"{rid}: {k} disagrees with laws_meta.jsonl")
        for field in ("required_observations", "activation_conditions", "timing_requirements"):
            if not r.get(field):
                errors.append(f"{rid}: {field} is empty")
        for o in r.get("required_observations", []):
            if o.get("atom") not in atoms:
                errors.append(f"{rid}: unknown atom {o.get('atom')}")
            if not o.get("note"):
                errors.append(f"{rid}: {o.get('atom')} has no note")
        for t in r.get("timing_requirements", []):
            if t.get("kind") not in KINDS:
                errors.append(f"{rid}: unknown timing kind {t.get('kind')}")
            if not t.get("requirement"):
                errors.append(f"{rid}: timing entry with no requirement")

    for x in laws:
        if x["id"] not in seen:
            errors.append(f"{x['id']}: corpus line with no scenario")

    for e in errors:
        print("FAIL", e)
    print(f"{len(rows)} scenarios, {len(laws)} corpus lines, {len(atoms)} atoms in ATOMS.md: "
          f"{'OK' if not errors else str(len(errors)) + ' problems'}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
