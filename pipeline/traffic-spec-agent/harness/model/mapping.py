"""The run's mapping index: normalized span text → the atoms accepted nodes mapped it to (T6)."""
from __future__ import annotations
import json
import re
from pathlib import Path


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"\[[A-Z]+-[^\]]+\]", "", text)).strip().lower()


class MappingIndex:
    def __init__(self, path: Path):
        self.path = path
        self.index: dict[str, dict] = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(self.index, indent=1, ensure_ascii=False, sort_keys=True), encoding="utf-8")

    def record(self, span_text: str, atoms: set[str], node_id: str, role: str | None = None) -> None:
        self.index[normalize(span_text)] = {"atoms": sorted(atoms), "node": node_id, **({"role": role} if role else {})}

    def entry(self, span_text: str) -> dict | None:
        return self.index.get(normalize(span_text))

    def render(self) -> str:
        if not self.index:
            return "(no mappings accepted yet)\n"
        out = ["| words | atoms | node |", "|---|---|---|"]
        for k in sorted(self.index):
            e = self.index[k]
            out.append(f"| {k[:100]} | {', '.join(e['atoms'])} | {e['node']} |")
        return "\n".join(out) + "\n"
