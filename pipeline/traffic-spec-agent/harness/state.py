"""A run: its directories, options, notes files and iteration numbering."""
from __future__ import annotations
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from . import paths


@dataclass
class Options:
    run_id: str
    laws: Path
    ontology: Path
    reading: Path
    model: Optional[str] = None
    max_iterations: int = 3
    plan_attempts: int = 2
    gate_budget: int = 6
    max_turns: int = 80
    session_timeout: float = 3600.0
    judge: bool = True
    dry_run: bool = False          # render prompts and run the deterministic phases, launch no session


@dataclass
class Run:
    opts: Options
    iteration: int = 0
    accepted_nodes: dict[str, dict] = field(default_factory=dict)

    @property
    def dir(self) -> Path:
        return paths.run_dir(self.opts.run_id)

    @property
    def iter(self) -> Path:
        return paths.iter_dir(self.opts.run_id, self.iteration)

    @property
    def ledger_file(self) -> Path:
        return self.dir / "ledger.jsonl"

    @property
    def mapping_file(self) -> Path:
        return self.dir / "mapping.json"

    @property
    def auto_notes(self) -> Path:
        return self.dir / "AUTO_NOTES.md"

    @property
    def accepted_file(self) -> Path:
        return self.dir / "accepted_nodes.jsonl"

    def load_accepted(self) -> None:
        self.accepted_nodes = {}
        if self.accepted_file.exists():
            for l in self.accepted_file.read_text(encoding="utf-8").splitlines():
                if l.strip():
                    d = json.loads(l); self.accepted_nodes[d["node_id"]] = d

    def save_accepted(self) -> None:
        self.accepted_file.write_text("".join(json.dumps(d, ensure_ascii=False) + "\n" for d in self.accepted_nodes.values()), encoding="utf-8")

    def next_iteration(self) -> int:
        existing = [int(p.name.split("-")[1]) for p in self.dir.glob("iter-*") if p.is_dir()]
        self.iteration = (max(existing) + 1) if existing else 1
        self.iter.mkdir(parents=True, exist_ok=True)
        return self.iteration

    def read_notes(self) -> str:
        return self.auto_notes.read_text(encoding="utf-8") if self.auto_notes.exists() else "(first iteration: no feedback yet)\n"

    def read_hints(self) -> str:
        return paths.USER_HINTS.read_text(encoding="utf-8") if paths.USER_HINTS.exists() else "(none)\n"
