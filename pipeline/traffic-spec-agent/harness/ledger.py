"""Per-law states of a run (design §8a). Written by the harness only."""
from __future__ import annotations
import json
from dataclasses import dataclass, field, asdict
from pathlib import Path

OPEN, PLANNED, RETURNED, ACCEPTED, BLOCKED, FAILED = "open", "planned", "returned", "accepted", "blocked", "failed"
TERMINAL = {ACCEPTED, BLOCKED, FAILED}
PLANNABLE = {OPEN, RETURNED}


@dataclass
class Entry:
    law: str
    state: str = OPEN
    attempts: int = 0
    judge_failures: int = 0
    reasons: list[str] = field(default_factory=list)
    nodes: list[str] = field(default_factory=list)
    gaps: list[str] = field(default_factory=list)
    iteration: int = 0


class Ledger:
    def __init__(self, path: Path, law_ids: list[str], plan_attempts: int):
        self.path = path
        self.plan_attempts = plan_attempts
        self.entries: dict[str, Entry] = {}
        if path.exists():
            for line in path.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    d = json.loads(line)
                    self.entries[d["law"]] = Entry(**d)
        for lid in law_ids:
            self.entries.setdefault(lid, Entry(lid))

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text("".join(json.dumps(asdict(e), ensure_ascii=False) + "\n" for e in self.entries.values()), encoding="utf-8")

    def plannable(self) -> list[Entry]:
        return [e for e in self.entries.values() if e.state in PLANNABLE]

    def mark_planned(self, law: str, node_ids: list[str], iteration: int) -> None:
        e = self.entries[law]
        e.state, e.nodes, e.iteration = PLANNED, node_ids, iteration

    def return_law(self, law: str, reasons: list[str]) -> None:
        e = self.entries[law]
        e.attempts += 1
        e.reasons = reasons
        e.state = FAILED if e.attempts >= self.plan_attempts else RETURNED
        if e.state == FAILED:
            e.reasons = [f"attempt budget ({self.plan_attempts}) spent"] + reasons

    def defer(self, law: str, reasons: list[str]) -> None:
        """The law goes back to `open` without an attempt counted: nothing judged its plan or its code."""
        e = self.entries[law]
        e.state, e.reasons = OPEN, reasons

    def judge_failed(self, law: str, reasons: list[str]) -> None:
        e = self.entries[law]
        e.judge_failures += 1
        e.attempts += 1
        e.reasons = reasons
        e.state = FAILED if e.judge_failures >= 2 or e.attempts >= self.plan_attempts else RETURNED
        if e.state == FAILED and e.judge_failures >= 2:
            e.reasons = ["alignment judge failed twice"] + reasons

    def block(self, law: str, gap_ids: list[str], reasons: list[str]) -> None:
        e = self.entries[law]
        e.state, e.gaps, e.reasons = BLOCKED, gap_ids, reasons

    def fail(self, law: str, reasons: list[str]) -> None:
        e = self.entries[law]
        e.state, e.reasons = FAILED, reasons

    def accept(self, law: str, node_ids: list[str]) -> None:
        e = self.entries[law]
        e.state, e.nodes, e.reasons = ACCEPTED, node_ids, []

    def reopen(self, laws: list[str] | None = None) -> list[str]:
        """Operator action: failed (or all non-accepted) laws back to open with a fresh budget."""
        out = []
        for e in self.entries.values():
            if (laws is None or e.law in laws) and e.state not in (ACCEPTED, BLOCKED):
                e.state, e.attempts, e.judge_failures, e.reasons = OPEN, 0, 0, []
                out.append(e.law)
        return out

    def reopen_for_gaps(self, retired: set[str]) -> list[str]:
        out = []
        for e in self.entries.values():
            if e.state == BLOCKED and e.gaps and all(g in retired for g in e.gaps):
                e.state, e.gaps, e.reasons = OPEN, [], []
                out.append(e.law)
        return out

    def counts(self) -> dict[str, int]:
        c: dict[str, int] = {}
        for e in self.entries.values():
            c[e.state] = c.get(e.state, 0) + 1
        return c
