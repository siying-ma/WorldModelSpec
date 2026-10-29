"""Publish a reference-closed subset of the corpus as a run directory.

    python -m nrs_tools.subset <name> <law id> [<law id> ...] [--split train|test|full]
                                                                  # from pipeline/ontology_provenance

Writes laws/example/<name>/laws.jsonl and definitions.jsonl in posted form. The subset is closed
under the bracketed law references of its texts (a law that names another law brings it in), so a
run on it never composes a law it was not given. Every law of the closure must belong to the named
split (default train), so a subset never carries a line of the other side.

Its definitions are those the pipeline's definition resolver reaches from its lines
(`harness/model/definitions.py`, under the operator's precedence in
`config/definition_precedence.json`): every definition a text cites by its bracketed id, every
definition a defined term of a line resolves to or is ambiguous between, and, transitively, every
definition the defined terms of those definitions resolve to.

The records are copied from laws/full_list/ unchanged; no definition is written or edited here.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
LAWS_ROOT = HERE.parents[1] / "traffic-spec-agent" / "laws"
CORPUS_DIR = LAWS_ROOT / "full_list"
SPLIT_DIR = LAWS_ROOT / "example"


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
        todo += [r for r in _corpus().cited_law_ids(laws[i]["text"]) if r not in out]
    return out


def _corpus():
    """The pipeline's own reader of posted text, so a subset closes over the references the
    pipeline's dependency order and reference checks read."""
    sys.path.insert(0, str(LAWS_ROOT.parent))
    from harness.model import corpus
    return corpus


def definitions_for(subset: list[dict], defs: list[dict]) -> list[dict]:
    """The posted definitions the definition resolver reaches from `subset` (see the header)."""
    sys.path.insert(0, str(LAWS_ROOT.parent))
    from harness.model import corpus, definitions as resolver
    laws = [corpus.Law(x["id"], x.get("title", ""), x["text"], x.get("source", "")) for x in subset]
    table = resolver.resolve_table(laws, defs, resolver.load_precedence())
    used = {r for x in subset for r in corpus.bracketed_ids(x["text"]) if r.startswith("DEF-")}
    for row in [r for rows in table["laws"].values() for r in rows] + [d for deps in table["dependencies"].values() for d in deps]:
        used |= set(row.get("chain") or []) | set(row.get("candidates") or [])
    return [d for d in defs if d["id"] in used]


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
    chosen = closure(ids, laws)
    if split != "full":
        side = {r["id"] for r in load(SPLIT_DIR / split / "laws.jsonl")}
        outside = [i for i in chosen if i not in side]
        if outside:
            raise SystemExit(f"not in the {split} split: {outside}")
    subset = [laws[i] for i in sorted(chosen)]
    chosen_defs = definitions_for(subset, defs)
    dump(SPLIT_DIR / name / "laws.jsonl", subset)
    dump(SPLIT_DIR / name / "definitions.jsonl", chosen_defs)
    added = [i for i in chosen if i not in ids]
    print(f"laws/example/{name}: {len(subset)} law(s)" + (f" ({len(added)} brought in by reference: {added})" if added else "")
          + f", {len(chosen_defs)} definition(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
