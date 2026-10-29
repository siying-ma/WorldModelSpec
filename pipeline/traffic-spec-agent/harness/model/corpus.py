"""The law corpus as posted law: id, title, text, source. Nothing else is read from it, except the
bracketed ids by which a law's text names another law (`[NRS-…]`), which order the planning."""
from __future__ import annotations
import json
import re
from dataclasses import dataclass
from pathlib import Path

POSTED = ("id", "title", "text", "source")
BRACKET = re.compile(r"\[([^\]]*)\]")
CITED_ID = re.compile(r"\b[A-Z]+-[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*")


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


def bracketed_ids(text: str) -> list[str]:
    """Every id a text names in brackets, in order, once each: a bracket may name several, and may
    hold other words (`[(c) is appended below, <id>]`)."""
    out: list[str] = []
    for b in BRACKET.findall(text):
        for i in CITED_ID.findall(b):
            if i not in out:
                out.append(i)
    return out


def cited_law_ids(text: str) -> list[str]:
    """The law ids a text names in brackets, in order (a definition, `DEF-…`, is not a law)."""
    return [r for r in bracketed_ids(text) if not r.startswith("DEF-")]


def references(law: Law, ids: set[str]) -> set[str]:
    """The ids of other laws of the corpus the text names in brackets."""
    return {r for r in cited_law_ids(law.text) if r in ids and r != law.id}


def load_definitions(laws_path: Path) -> list[dict]:
    return _rows(laws_path.with_name("definitions.jsonl"))


def render_laws(laws: list[Law]) -> str:
    if not laws:
        return "(no laws to plan)\n"
    return "\n".join(f"### `{l.id}` — {l.title}\n_{l.source}_\n\n{l.text.strip()}\n" for l in laws)


def render_definitions(defs: list[dict]) -> str:
    if not defs:
        return "(no definitions)\n"
    return "\n".join(f"### `{d['id']}` — {d.get('title', '')}\n_{d.get('source', '')}_\n\n{d.get('text', '').strip()}\n"
                     + (f"\n{split_note(d)}\n" if d.get("split") else "") for d in defs)


def split_note(d: dict) -> str:
    """How a session is told that a definition's term was found split in the law's words."""
    return (f"(Found split: the law's words \"{d['split']}\" use this defined term in the copular form, "
            "not as one contiguous phrase.)" if d.get("split") else "")
