"""Publish a reference-closed subset of the corpus as a run directory.

    python -m nrs_tools.subset <name> <law id> [<law id> ...] [--split train|test|full]
                                                                  # from pipeline/ontology_provenance

Writes laws/example/<name>/laws.jsonl and definitions.jsonl in posted form. The subset is closed
under the bracketed law references of its texts (a law that names another law brings it in), so a
run on it never composes a law it was not given. Every law of the closure must belong to the named
split (default train), so a subset never carries a line of the other side.

Its definitions are those the law itself makes applicable to its lines: every definition a text
cites by its bracketed id, and every term definition whose term occurs in the text or title of a
line that the definition's own applicability clause reaches:

- NRS 484A.015-.320 (NRS 484A.010): lines of NRS 484A to 484E;
- NRS 484B.007-.077 (NRS 484B.003): lines of NRS 484B;
- NRS 486.015-.057 (NRS 486.011): lines of NRS 486.011 to 486.381;
- LVMC 11.02 (LVMC 11.02.010): lines of LVMC Title 11;
- NRS 484A to 484E (LVMC 11.02.020): lines of LVMC Title 11, for a word LVMC 11.02 does not define;
- a definition whose text begins "As used in this section": lines of that section only.

The records are copied from laws/full_list/ unchanged; no definition is written or edited here.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
LAWS_ROOT = HERE.parents[1] / "traffic-spec-agent" / "laws"
CORPUS_DIR = LAWS_ROOT / "full_list"
AUDIT_DIR = LAWS_ROOT / "audit_and_scripts"
SPLIT_DIR = LAWS_ROOT / "example"
REF = re.compile(r"\[([A-Z]+-[A-Za-z0-9-]+)\]")
CITATION = re.compile(r"^(NRS|LVMC) (\d+[A-Z]?)\.(\d+)")
NRS_TRAFFIC_CHAPTERS = ("484A", "484B", "484C", "484D", "484E")


def load(path: Path) -> list[dict]:
    return [json.loads(l) for l in path.read_text(encoding="utf-8").splitlines() if l.strip()]


def dump(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8")


def closure(ids: list[str], laws: dict[str, dict]) -> list[str]:
    out, todo = [], list(ids)
    while todo:
        i = todo.pop(0)
        if i in out:
            continue
        if i not in laws:
            raise SystemExit(f"{i} is not a law of the corpus")
        out.append(i)
        todo += [r for r in REF.findall(laws[i]["text"]) if not r.startswith("DEF-") and r not in out]
    return out


def citation(source: str) -> tuple[str, str, int]:
    """(body, chapter or title, section number) of a posted citation such as "NRS 484B.250(1)"."""
    m = CITATION.match(source)
    if not m:
        raise SystemExit(f"cannot read the citation {source!r}")
    return m.group(1), m.group(2), int(m.group(3))


def applies(d: dict, line: dict, lvmc_terms: set[str], terms: list[str]) -> bool:
    """Whether the applicability clause of definition `d` reaches corpus line `line`."""
    dbody, dch, dsec = citation(d["source"])
    lbody, lch, lsec = citation(line["source"])
    if d["text"].lstrip().startswith("As used in this section"):
        return (dbody, dch, dsec) == (lbody, lch, lsec)
    if dbody == "LVMC":
        return lbody == "LVMC" and dch == lch == "11"
    if lbody == "LVMC":
        return lch == "11" and dch in NRS_TRAFFIC_CHAPTERS and not any(t in lvmc_terms for t in terms)
    if dch == "484A":
        return lch in NRS_TRAFFIC_CHAPTERS
    if dch == "486":
        return lch == "486" and 11 <= lsec <= 381
    return dch == lch


def definitions_for(subset: list[dict], defs: list[dict], meta: dict[str, dict]) -> list[dict]:
    cited = {r for x in subset for r in REF.findall(x["text"]) if r.startswith("DEF-")}
    lvmc_terms = {t.lower() for d in defs if d["source"].startswith("LVMC 11.02.")
                  for t in (meta.get(d["id"], {}).get("terms") or [])}
    out = []
    for d in defs:
        terms = [t.lower() for t in (meta.get(d["id"], {}).get("terms") or [])]
        used = any(applies(d, x, lvmc_terms, terms)
                   and any(re.search(r"\b" + re.escape(t) + r"s?\b", (x["text"] + " " + x["title"]).lower()) for t in terms)
                   for x in subset)
        if d["id"] in cited or used:
            out.append(d)
    return out


def main(argv: list[str]) -> int:
    split = "train"
    if "--split" in argv:
        k = argv.index("--split")
        split, argv = argv[k + 1], argv[:k] + argv[k + 2:]
    if len(argv) < 2 or split not in ("train", "test", "full"):
        print(__doc__); return 2
    name, ids = argv[0], argv[1:]
    laws = {r["id"]: r for r in load(CORPUS_DIR / "laws.jsonl")}
    defs = load(CORPUS_DIR / "definitions.jsonl")
    meta = {m["id"]: m for m in load(AUDIT_DIR / "definitions_meta.jsonl")}
    chosen = closure(ids, laws)
    if split != "full":
        side = {r["id"] for r in load(SPLIT_DIR / split / "laws.jsonl")}
        outside = [i for i in chosen if i not in side]
        if outside:
            raise SystemExit(f"not in the {split} split: {outside}")
    subset = [laws[i] for i in sorted(chosen)]
    chosen_defs = definitions_for(subset, defs, meta)
    dump(SPLIT_DIR / name / "laws.jsonl", subset)
    dump(SPLIT_DIR / name / "definitions.jsonl", chosen_defs)
    added = [i for i in chosen if i not in ids]
    print(f"laws/example/{name}: {len(subset)} law(s)" + (f" ({len(added)} brought in by reference: {added})" if added else "")
          + f", {len(chosen_defs)} definition(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
