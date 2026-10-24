"""Write a development run's subset corpus: `results/<run>/laws/laws.jsonl`, holding the rows of the
named laws as the corpus file has them, with the corpus's `definitions.jsonl` copied beside it.

    python -m scripts.subset_laws <run id> <corpus laws.jsonl> <law id> [<law id> ...]

The rows are copied byte for byte and in the corpus's order; a law id the corpus lacks stops the
script, and so does a subset file already written with other contents.
"""
from __future__ import annotations
import json, sys
from pathlib import Path

from harness.store import paths


def subset(run_id: str, corpus: Path, law_ids: list[str]) -> Path:
    rows = [l for l in corpus.read_text(encoding="utf-8").splitlines() if l.strip()]
    keep = [l for l in rows if json.loads(l)["id"] in set(law_ids)]
    missing = sorted(set(law_ids) - {json.loads(l)["id"] for l in keep})
    if missing:
        raise SystemExit(f"{corpus}: no law {missing}")
    out = paths.run_dir(run_id) / "laws"
    files = {out / "laws.jsonl": "".join(l + "\n" for l in keep),
             out / "definitions.jsonl": corpus.with_name("definitions.jsonl").read_text(encoding="utf-8")}
    for f, text in files.items():
        if f.exists() and f.read_text(encoding="utf-8") != text:
            raise SystemExit(f"{f} exists with other contents; a run's subset is written once")
    out.mkdir(parents=True, exist_ok=True)
    for f, text in files.items():
        f.write_text(text, encoding="utf-8")
    return out / "laws.jsonl"


if __name__ == "__main__":
    if len(sys.argv) < 4:
        raise SystemExit(__doc__)
    print(subset(sys.argv[1], Path(sys.argv[2]), sys.argv[3:]))
