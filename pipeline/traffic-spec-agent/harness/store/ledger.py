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
    reasons: list[str] = field(default_factory=list)
    nodes: list[str] = field(default_factory=list)
    gaps: list[str] = field(default_factory=list)
    iteration: int = 0
    charged_iteration: int = 0     # the iteration whose return already counted an attempt
    charged_concepts: list[str] = field(default_factory=list)   # failed concepts whose failure already counted an attempt
    repeats: dict[str, int] = field(default_factory=dict)       # outcome key (`review:<node>:<span>:<verdict>`) ↦ times drawn, across plans and repairs


class Ledger:
    def __init__(self, path: Path, law_ids: list[str], plan_attempts: int, repeat_limit: int = 3):
        self.path = path
        self.plan_attempts = plan_attempts
        self.repeat_limit = repeat_limit
        self.entries: dict[str, Entry] = {}
        if path.exists():
            for line in path.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    d = json.loads(line)
                    self.entries[d["law"]] = Entry(**{k: v for k, v in d.items() if k in Entry.__dataclass_fields__})
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

    def _charge(self, e: Entry, reasons: list[str], iteration: int) -> bool:
        """One attempt per law per iteration: a second return in the same iteration adds its
        reasons and counts nothing. Returns whether an attempt was counted."""
        if e.charged_iteration == iteration and e.state in (RETURNED, FAILED):
            e.reasons = e.reasons + [r for r in reasons if r not in e.reasons]
            return False
        e.attempts += 1
        e.charged_iteration = iteration
        e.reasons = reasons
        return True

    def return_law(self, law: str, reasons: list[str], iteration: int) -> None:
        e = self.entries[law]
        if not self._charge(e, reasons, iteration):
            return
        e.state = FAILED if e.attempts >= self.plan_attempts else RETURNED
        if e.state == FAILED:
            e.reasons = [f"attempt budget ({self.plan_attempts}) spent"] + reasons

    def return_uncharged(self, law: str, reasons: list[str]) -> None:
        """The law goes back to the planner with these reasons and no attempt counted: its record
        was right when written and another law's re-plan invalidated it."""
        e = self.entries[law]
        if e.state not in TERMINAL:
            e.state, e.reasons = RETURNED, reasons

    def return_for_concepts(self, law: str, concepts: list[str], reasons: list[str], iteration: int) -> None:
        """The law is returned because concepts its nodes use failed. A concept's failure counts
        one attempt against the law, however many iterations later the law is still waiting on
        it; a return for concepts that already counted adds its reasons and counts nothing."""
        e = self.entries[law]
        fresh = [c for c in concepts if c not in e.charged_concepts]
        if not fresh:
            e.reasons = e.reasons + [r for r in reasons if r not in e.reasons]
            if e.state not in TERMINAL:
                e.state = RETURNED
            return
        e.charged_concepts = e.charged_concepts + fresh
        self.return_law(law, reasons, iteration)

    def defer(self, law: str, reasons: list[str]) -> None:
        """The law goes back to `open` without an attempt counted: nothing judged its plan or its code."""
        e = self.entries[law]
        e.state, e.reasons = OPEN, reasons

    def hold(self, law: str, iteration: int) -> None:
        """A node of the law waits for a node it composes: the law stays `planned`, its node list
        unchanged, and no attempt is counted. A law already returned or failed this iteration
        (another node of it was rejected) keeps that state: the held node waits as deferred, and
        the planner sees the law."""
        e = self.entries[law]
        if e.state in (RETURNED, FAILED) and e.charged_iteration == iteration:
            e.iteration = iteration
            return
        e.state, e.iteration = PLANNED, iteration

    def record_outcomes(self, law: str, keys: list[str], limit: int | None = None) -> list[str]:
        """Count the outcomes a node of the law drew, across its plans and repairs; the keys whose
        count reaches the limit (the repeat limit unless given) are returned, each with its count —
        the law is not converging and the operator decides."""
        e = self.entries[law]
        hit = []
        for k in keys:
            e.repeats[k] = e.repeats.get(k, 0) + 1
            if e.repeats[k] >= (limit or self.repeat_limit):
                hit.append(f"{k} ×{e.repeats[k]}")
        return hit

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
        """Operator action: failed laws, and laws blocked for the operator's decision (every token
        `decision:<law>`), back to open with a fresh budget — and with a decided law, every law
        blocked on its token. A law blocked on a gap waits for the gap's decision instead."""
        def decided_only(e: Entry) -> bool:
            return e.state == BLOCKED and bool(e.gaps) and all(g.startswith("decision:") for g in e.gaps)
        out, tokens = [], set()
        for e in self.entries.values():
            if (laws is None or e.law in laws) and (e.state not in (ACCEPTED, BLOCKED) or decided_only(e)):
                tokens |= {g for g in e.gaps if g.startswith("decision:")}
                e.state, e.attempts, e.reasons, e.charged_concepts, e.repeats, e.gaps = OPEN, 0, [], [], {}, []
                out.append(e.law)
        for e in self.entries.values():
            if decided_only(e) and set(e.gaps) <= tokens:
                e.state, e.attempts, e.reasons, e.charged_concepts, e.repeats, e.gaps = OPEN, 0, [f"reopened with {sorted(tokens)}"], [], {}, []
                out.append(e.law)
        return out

    def reopen_for_gaps(self, decided: dict[str, tuple[str, str]]) -> list[tuple[str, list[str]]]:
        """A blocked law reopens once the operator has decided every gap it waits on: retired (the
        ontology or the reading now carries the span) or rejected (the span can be carried as it is;
        the decision is the reason the next plan is shown). Returns (law, reasons)."""
        out = []
        for e in self.entries.values():
            if e.state == BLOCKED and e.gaps and all(g in decided for g in e.gaps):
                reasons = [f"gap {g} {decided[g][0]}" + (f": {decided[g][1]}" if decided[g][1] else "") for g in e.gaps]
                e.state, e.gaps, e.reasons = OPEN, [], reasons
                out.append((e.law, reasons))
        return out

    def counts(self) -> dict[str, int]:
        c: dict[str, int] = {}
        for e in self.entries.values():
            c[e.state] = c.get(e.state, 0) + 1
        return c


# ---------------------------------------------------------------------------------------------
# Concepts: one entry per proposed concept id, states as for laws. Written by the harness only.
# ---------------------------------------------------------------------------------------------
@dataclass
class ConceptEntry:
    concept: str
    state: str = OPEN            # open | planned | returned | accepted | failed
    attempts: int = 0            # coding attempts the gate or the review returned; a validator's return counts none
    reasons: list[str] = field(default_factory=list)
    used_by: list[str] = field(default_factory=list)
    iteration: int = 0
    last_task: str = ""            # the task directory of the last coding attempt, for a repair session


class ConceptLedger:
    def __init__(self, path: Path, attempts: int):
        self.path = path
        self.attempts = attempts
        self.entries: dict[str, ConceptEntry] = {}
        if path.exists():
            for line in path.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    d = json.loads(line)
                    self.entries[d["concept"]] = ConceptEntry(**d)

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text("".join(json.dumps(asdict(e), ensure_ascii=False) + "\n" for e in self.entries.values()), encoding="utf-8")

    def planned(self, cid: str, used_by: list[str], iteration: int) -> None:
        """A failed concept stays failed: only the operator's `reopen` of its laws clears it."""
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        if e.state == FAILED:
            return
        e.state, e.used_by, e.iteration = PLANNED, used_by, iteration

    def forget(self, cids: list[str]) -> None:
        """Drop concepts from the ledger, so a re-plan may propose them afresh."""
        for c in cids:
            self.entries.pop(c, None)

    def returned(self, cid: str, reasons: list[str], last_task: str = "") -> None:
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        e.attempts += 1
        e.reasons = reasons
        if last_task:
            e.last_task = last_task
        e.state = FAILED if e.attempts >= self.attempts else RETURNED

    def noted(self, cid: str, reasons: list[str]) -> None:
        """The concept goes back with these reasons, no coding attempt counted: the validator or a
        dependency returned it before any session coded it."""
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        e.reasons = reasons
        if e.state != FAILED:
            e.state = RETURNED

    def fail(self, cid: str, reasons: list[str]) -> None:
        """The concept is closed with these reasons, whatever its budget: its repair session withdrew it."""
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        e.state, e.reasons = FAILED, reasons

    def repairable(self) -> list[ConceptEntry]:
        """Concepts a repair session may re-propose: returned by the gate or the review, with a
        coding attempt on record and budget left."""
        return [e for e in self.entries.values() if e.state == RETURNED and e.last_task]

    def accepted(self, cid: str) -> None:
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        e.state, e.reasons = ACCEPTED, []

    def counts(self) -> dict[str, int]:
        c: dict[str, int] = {}
        for e in self.entries.values():
            c[e.state] = c.get(e.state, 0) + 1
        return c


# ---------------------------------------------------------------------------------------------
# Nodes: one entry per node the gate or the review returned, for the node repair path. A node has
# `attempts` coding sessions (default 2: the first and one after a repair); while it has budget
# its law is held, not charged. Written by the harness only.
# ---------------------------------------------------------------------------------------------
REPAIRED = "repaired"


@dataclass
class NodeEntry:
    node: str
    law: str
    state: str = RETURNED        # returned | repaired | failed
    attempts: int = 0            # coding sessions that ended in a return
    reasons: list[str] = field(default_factory=list)
    last_task: str = ""          # the task directory of the last coding attempt, for the repair session
    iteration: int = 0


class NodeLedger:
    def __init__(self, path: Path, attempts: int):
        self.path = path
        self.attempts = attempts
        self.entries: dict[str, NodeEntry] = {}
        if path.exists():
            for line in path.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    d = json.loads(line)
                    self.entries[d["node"]] = NodeEntry(**d)

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text("".join(json.dumps(asdict(e), ensure_ascii=False) + "\n" for e in self.entries.values()), encoding="utf-8")

    def budget_left(self, node: str) -> bool:
        """Whether another coding of the node may follow a repair: a node has `attempts` codings,
        so a return is repaired while the returns so far are fewer than `attempts - 1`."""
        e = self.entries.get(node)
        return (e.attempts if e else 0) < self.attempts - 1

    def returned(self, node: str, law: str, reasons: list[str], last_task: str, iteration: int) -> None:
        e = self.entries.setdefault(node, NodeEntry(node, law))
        e.attempts += 1
        e.state, e.reasons, e.last_task, e.iteration = RETURNED, reasons, last_task, iteration

    def repairable(self, planned_laws: set[str]) -> list[NodeEntry]:
        """Nodes a repair session may revise: returned, with a coding attempt on record, whose law
        is still held (`planned`); a law the planner re-plans takes its nodes with it."""
        return [e for e in self.entries.values() if e.state == RETURNED and e.last_task and e.law in planned_laws]

    def repaired(self, node: str) -> None:
        if node in self.entries:
            self.entries[node].state = REPAIRED

    def drop_law(self, law: str) -> None:
        """A law the planner plans afresh takes its nodes with it: the entries of its old nodes go,
        so a re-planned node under the same id has a fresh budget."""
        for nid in [n for n, e in self.entries.items() if e.law == law]:
            del self.entries[nid]

    def failed(self, node: str, reasons: list[str]) -> None:
        e = self.entries.setdefault(node, NodeEntry(node, ""))
        e.state, e.reasons = FAILED, reasons

    def counts(self) -> dict[str, int]:
        c: dict[str, int] = {}
        for e in self.entries.values():
            c[e.state] = c.get(e.state, 0) + 1
        return c

