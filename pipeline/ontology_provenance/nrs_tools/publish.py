"""Publish the corpus as posted law plus sidecars — the last step after make_laws.py.

    python -m nrs_tools.publish        # from pipeline/ontology_provenance

The agent-facing files under laws/full_list/ carry exactly what a government website shows and a
person can supply: `source` (the citation), `title`, `text` (verbatim, with the bracketed
resolutions and appended paragraphs the person is asked to make explicit) and the `id` derived
from the citation. Everything the corpus construction inferred — who is bound, the theme, the
judgement tier, the overlap decisions, the reference resolution — is analysis, not law, and lives
beside the audit under laws/audit_and_scripts/:

  laws_meta.jsonl         id + subject, theme, tier, supersedes, refs, unresolved, reinstated_for
  definitions_meta.jsonl  id + kind, applies_to, terms, term_in_corpus, note, used_by
  excluded.jsonl, unobservable.jsonl, unresolvable.jsonl, laws_full.jsonl   the lines kept out, and
                          the excluded lines, with their analysis fields

Nothing in the pipeline reads the sidecars: the plan phase renders id, title and text, and the
validator reads ids. The split, the evaluation scenarios and the audits read them. `bucket`
(concrete/judgement) is dropped everywhere: it duplicated `tier`.

Idempotent: a record already in posted form keeps its analysis from the existing sidecar.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
LAWS_ROOT = HERE.parents[1] / "traffic-spec-agent" / "laws"
CORPUS_DIR = LAWS_ROOT / "full_list"
AUDIT_DIR = LAWS_ROOT / "audit_and_scripts"

POSTED = ("id", "title", "text", "source")
LAW_META = ("subject", "theme", "tier", "supersedes", "refs", "unresolved", "reinstated_for", "excluded_reason",
            "unobservable_reason", "blocking")
DEF_META = ("kind", "applies_to", "terms", "term_in_corpus", "note", "used_by")


def load(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(l) for l in path.read_text(encoding="utf-8").splitlines() if l.strip()]


def dump(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8")


def split_record(rec: dict, meta_keys: tuple[str, ...], old_meta: dict | None) -> tuple[dict, dict]:
    posted = {k: rec[k] for k in POSTED if k in rec}
    meta = {"id": rec["id"]}
    for k in meta_keys:
        if k in rec:
            meta[k] = rec[k]
        elif old_meta and k in old_meta:
            meta[k] = old_meta[k]
    return posted, meta


def main() -> int:
    old_law_meta = {m["id"]: m for m in load(AUDIT_DIR / "laws_meta.jsonl")}
    old_def_meta = {m["id"]: m for m in load(AUDIT_DIR / "definitions_meta.jsonl")}

    laws = load(CORPUS_DIR / "laws.jsonl")
    posted, meta = [], []
    for rec in laws:
        p, m = split_record(rec, LAW_META, old_law_meta.get(rec["id"]))
        posted.append(p); meta.append(m)
    dump(CORPUS_DIR / "laws.jsonl", posted)

    # the analysis-bearing views move beside the audit; their lines keep their fields (minus bucket)
    for name in ("excluded", "unobservable", "unresolvable", "laws_full"):
        src = CORPUS_DIR / f"{name}.jsonl"
        rows = load(src) or load(AUDIT_DIR / f"{name}.jsonl")
        for r in rows:
            r.pop("bucket", None)
        dump(AUDIT_DIR / f"{name}.jsonl", rows)
        if src.exists():
            src.unlink()
        if name != "laws_full":
            for r in rows:                      # excluded/unresolvable lines' analysis, for completeness
                if r["id"] not in {m["id"] for m in meta}:
                    _, m = split_record(r, LAW_META, old_law_meta.get(r["id"]))
                    m["view"] = name
                    meta.append(m)
    dump(AUDIT_DIR / "laws_meta.jsonl", meta)

    defs = load(CORPUS_DIR / "definitions.jsonl")
    dposted, dmeta = [], []
    for rec in defs:
        p, m = split_record(rec, DEF_META, old_def_meta.get(rec["id"]))
        dposted.append(p); dmeta.append(m)
    dump(CORPUS_DIR / "definitions.jsonl", dposted)
    dump(AUDIT_DIR / "definitions_meta.jsonl", dmeta)

    print(f"published {len(posted)} laws and {len(dposted)} definitions in posted form; "
          f"{len(meta)} law metas and {len(dmeta)} definition metas beside the audit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
