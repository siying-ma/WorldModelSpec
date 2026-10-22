"""Check the reference snapshot against its source files.

For every document in manifest.json: the source file exists and its sha256 matches.
For every passage:
  - its id is unique and starts with its document id;
  - a `verbatim` passage: every sentence of its text occurs in the source's text layer
    (pdftotext, whitespace collapsed, page numbers and running headers removed);
  - a `table` or `figure` passage: every number in its text occurs on its cited PDF page(s);
  - every figure's condition ids are conditions of the passage;
  - it carries no corpus law id.
The topic index lists exactly the passages that name each topic.

Usage: python3 -I check_snapshot.py [snapshot dir]   (needs `pdftotext` on PATH)
"""
from __future__ import annotations
import hashlib, json, re, subprocess, sys
from pathlib import Path

LAW_ID = re.compile(r"\bNRS[\s_-]*\d|\bDEF-NRS|\b484[AB][._-]?\d")
NUMBER = re.compile(r"\d[\d,]*(?:\.\d+)?")
PAGE_LINE = re.compile(r"^\s*(?:[ivxlc]{1,5}|\d{1,4})\s*$")
HEADER = re.compile(r"^\s*(?:Page \d+\s+MUTCD.*|MUTCD 11th Edition.*Page \d+|(?:December|January) 20\d\d\s+Sect\..*|Sect\..*(?:December|January) 20\d\d|Rev\. 1)\s*$")


def norm(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def pages_of(pdf: Path, layout: bool) -> list[str]:
    args = ["pdftotext"] + (["-layout"] if layout else []) + [str(pdf), "-"]
    out = subprocess.run(args, capture_output=True, text=True, errors="replace").stdout
    return out.split("\f")


def body(pages: list[str]) -> str:
    lines = [l for p in pages for l in p.splitlines() if not PAGE_LINE.match(l) and not HEADER.match(l)]
    return norm("\n".join(lines))


def chunks(text: str) -> list[str]:
    parts = re.split(r"(?<=[.;:])\s+|\s*•\s*|\s+—\s+", text)
    return [p for p in (norm(x) for x in parts) if len(p) >= 12]


def page_numbers(locator: dict) -> list[int]:
    v = str(locator.get("pdf_page", ""))
    nums = [int(x) for x in re.findall(r"\d+", v)]
    return list(range(nums[0], nums[-1] + 1)) if nums else []


def main(root: Path) -> int:
    errors: list[str] = []
    manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    docs = {d["id"]: d for d in manifest["documents"]}
    texts: dict[str, tuple[list[str], str, str]] = {}
    for d in docs.values():
        f = root / d["file"]
        if not f.exists():
            errors.append(f"{d['id']}: source file {d['file']} missing"); continue
        if hashlib.sha256(f.read_bytes()).hexdigest() != d["sha256"]:
            errors.append(f"{d['id']}: sha256 does not match {d['file']}")
        lay = pages_of(f, True)
        texts[d["id"]] = (lay, body(lay), body(pages_of(f, False)))
    seen: set[str] = set()
    by_topic: dict[str, set[str]] = {}
    for pf in sorted((root / "passages").glob("*.json")):
        data = json.loads(pf.read_text(encoding="utf-8"))
        doc = data["document"]
        if doc not in docs:
            errors.append(f"{pf.name}: document {doc} not in the manifest"); continue
        lay, b_lay, b_raw = texts.get(doc, ([], "", ""))
        for p in data["passages"]:
            pid = p["id"]
            if pid in seen:
                errors.append(f"{pid}: duplicate id")
            seen.add(pid)
            if not pid.startswith(doc + "#"):
                errors.append(f"{pid}: id does not start with {doc}#")
            for t in p["topics"]:
                by_topic.setdefault(t, set()).add(pid)
            if LAW_ID.search(json.dumps(p, ensure_ascii=False)):
                errors.append(f"{pid}: carries a corpus law id")
            if p["transcription"] == "verbatim":
                for c in chunks(p["text"]):
                    if c not in b_lay and c not in b_raw:
                        errors.append(f"{pid}: not found verbatim in the source: {c[:90]!r}")
            else:
                page_text = " ".join(lay[i - 1] for i in page_numbers(p["locator"]) if 0 < i <= len(lay))
                found = set(NUMBER.findall(page_text))
                for n in NUMBER.findall(p["text"]):
                    if n not in found:
                        errors.append(f"{pid}: number {n} not on the cited page(s) {p['locator'].get('pdf_page')}")
            cond_ids = {c["id"] for c in p["conditions"]}
            for fig in p["figures"]:
                missing = set(fig["condition_ids"]) - cond_ids
                if missing:
                    errors.append(f"{pid}: figure {fig['text']!r} names unknown conditions {sorted(missing)}")
    index = json.loads((root / "index.json").read_text(encoding="utf-8"))
    for t in index["topics"]:
        listed = {r["passage"] for r in t["passages"]}
        if listed != by_topic.get(t["topic"], set()):
            errors.append(f"index topic {t['topic']}: lists {sorted(listed ^ by_topic.get(t['topic'], set()))} wrongly")
    for e in errors:
        print("ERROR", e)
    print(f"{len(docs)} documents, {len(seen)} passages, {len(errors)} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent))
