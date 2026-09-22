"""The law corpus as posted law: id, title, text, source. Nothing else is read from it."""
from __future__ import annotations
import json
from dataclasses import dataclass
from pathlib import Path

POSTED = ("id", "title", "text", "source")


@dataclass(frozen=True)
class Law:
    id: str
    title: str
    text: str
    source: str


def _rows(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(l) for l in path.read_text(encoding="utf-8").splitlines() if l.strip()]


def load_laws(path: Path) -> list[Law]:
    laws = []
    for r in _rows(path):
        extra = set(r) - set(POSTED)
        if extra:
            raise ValueError(f"{path.name}: {r.get('id')} carries fields that are not posted law: {sorted(extra)}")
        laws.append(Law(r["id"], r.get("title", ""), r["text"], r.get("source", "")))
    return laws


def load_definitions(laws_path: Path) -> list[dict]:
    return _rows(laws_path.with_name("definitions.jsonl"))


def render_laws(laws: list[Law]) -> str:
    if not laws:
        return "(no laws to plan)\n"
    return "\n".join(f"### `{l.id}` — {l.title}\n_{l.source}_\n\n{l.text.strip()}\n" for l in laws)


def render_definitions(defs: list[dict]) -> str:
    if not defs:
        return "(no definitions)\n"
    return "\n".join(f"### `{d['id']}` — {d.get('title', '')}\n_{d.get('source', '')}_\n\n{d.get('text', '').strip()}\n" for d in defs)
