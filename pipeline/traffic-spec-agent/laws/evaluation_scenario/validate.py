"""Check scenarios.jsonl, with the test lines' records beside the test split
(../example/test/scenarios.jsonl), against the corpus and the ontology.

    python validate.py            # from laws/evaluation_scenario

Fails on: a corpus line with no scenario, a scenario with no corpus line, a duplicate id, a file
whose order does not follow laws.jsonl, a test line's record outside the test file or a training
line's record inside it, a title or source that disagrees with the corpus line, a
subject, theme or tier that disagrees with audit_and_scripts/laws_meta.jsonl, an
`atom` that is neither an atom or primitive of ontology/ATOMS.md nor a well-formed concept id
(`drv.<family>.<name>`, concepts being catalogued per run), a `kind` outside the closed set, or an
empty required_observations / activation_conditions / timing_requirements.
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
TEST_ROWS = HERE.parent / "example" / "test" / "scenarios.jsonl"   # the test lines' records, beside the test split
TEST_LAWS = HERE.parent / "example" / "test" / "laws.jsonl"

KINDS = {"point_event", "continuous", "duration", "ordering", "until", "advance", "civil_time", "span"}
CONCEPT_ID = re.compile(r"^drv\.(?:motion|position|lane|interaction|road|control|user|env)\.[a-z][a-z_]*[a-z](?:_v[1-9]\d*)?$")
LEGACY_CONCEPT = re.compile(r"^drv\.[a-z_0-9]+$")   # the ontology's former derived-concept ids, one segment
META_LAW = ("title", "source")
META_SIDECAR = ("subject", "theme", "tier")


def load(path):
    return [json.loads(l) for l in path.read_text(encoding="utf-8").splitlines() if l.strip()]


def main() -> int:
    laws = load(LAWS)
    meta = {m["id"]: m for m in load(LAWS_META)}
    main_rows = load(HERE / "scenarios.jsonl")
    test_rows = load(TEST_ROWS) if TEST_ROWS.exists() else []
    test_ids = {x["id"] for x in load(TEST_LAWS)} if TEST_LAWS.exists() else set()
    rows = main_rows + test_rows
    atoms = set(re.findall(r"^\|\s*`((?:ru|kin|st|dev|sig|env|rel|prim)\.[a-z_0-9]+)`",
                           ATOMS_MD.read_text(encoding="utf-8"), re.M))
    errors: list[str] = []

    by_law = {x["id"]: x for x in laws}
    order = {x["id"]: k for k, x in enumerate(laws)}
    for name, part, want_test in (("scenarios.jsonl", main_rows, False), ("test/scenarios.jsonl", test_rows, True)):
        ks = [order[r["id"]] for r in part if r.get("id") in order]
        if ks != sorted(ks):
            errors.append(f"{name}: records out of corpus order")
        wrong = [r.get("id") for r in part if (r.get("id") in test_ids) != want_test]
        if wrong:
            errors.append(f"{name}: {'training' if want_test else 'test'} line(s) in the wrong file: {wrong}")
    seen = set()
    for r in rows:
        rid = r.get("id")
        if rid in seen:
            errors.append(f"duplicate id {rid}")
        seen.add(rid)
        if rid not in by_law:
            errors.append(f"{rid}: not a line of {LAWS.name}")
            continue
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
            a = str(o.get("atom", ""))
            if a not in atoms and not CONCEPT_ID.match(a) and not LEGACY_CONCEPT.match(a):
                errors.append(f"{rid}: unknown atom {a}")
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
