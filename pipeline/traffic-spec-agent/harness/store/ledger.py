"""Per-law, per-concept and per-node states of a run. Written by the harness only.

A law's life cycle across attempts: `open` → `planned` (its plan registered) → at the end of an
attempt `returned`, `blocked`, `failed` or `accepted`; `returned` → `planned` again when a later
attempt registers a new plan, → `failed` when its budget is spent. `blocked` and `failed` leave only
by the operator (`reopen`, or a decided gap); `accepted` only by the operator's subset continuation.
Within one attempt (one iteration) a law's siblings' outcomes combine by severity — `failed`, then
`blocked`, then `returned`, then `planned` — so the order they are applied in never changes the
result and no sibling undoes a terminal outcome of the same attempt."""
from __future__ import annotations
import json
from dataclasses import dataclass, field, asdict
from pathlib import Path
from . import jsonl, paths
from ..model import nodeid

OPEN, PLANNED, RETURNED, ACCEPTED, BLOCKED, FAILED = "open", "planned", "returned", "accepted", "blocked", "failed"
TERMINAL = {ACCEPTED, BLOCKED, FAILED}
PLANNABLE = {OPEN, RETURNED}
SEVERITY = {PLANNED: 1, RETURNED: 2, BLOCKED: 3, FAILED: 4}   # within one attempt, the higher outcome stands
JUDGE_STAGES = {"concept_adjudication"}  # an invalid judge answer: two in a row close the item
#: Gates of one node or concept that ended on the evaluation's cost (the deadline reached while its
#: scenarios were evaluated, or a resource failure reproduced in isolation) before it is held for the
#: operator: after the first, the saved candidate is gated again (or, when its context changed, the
#: record is coded again) at the same deadline; the second holds it.
GATE_COST_BOUND = 2
#: Scope violations of one node or concept (its coding session changed a file outside its own two, or
#: left them unbuildable as files: missing, a foreign import, another namespace) before it is held for
#: the operator: they say nothing of its plan or contract, so none counts as an attempt; after the
#: first, the same record is coded again once the library is confirmed restored; the second holds it.
#: Two conditions are apart: the operator's `reopen` clears the count (and so this hold); only
#: restoring the files a session changed outside its own lifts the pause on a dirty library.
SCOPE_BOUND = 2


def _saved(e) -> dict:
    """An entry as it is saved: its last task directory relative to the repository (`paths.stored`)."""
    d = asdict(e)
    if d.get("last_task"):
        d["last_task"] = paths.stored(d["last_task"])
    return d


def _rows(entries) -> str:
    return "".join(json.dumps(_saved(e), ensure_ascii=False) + "\n" for e in entries)


def _load(path: Path, cls, key: str) -> dict:
    out = {}
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip():
                d = json.loads(line)
                if d.get("last_task") and paths.local(d["last_task"]).exists():   # the saved task directory, in this repository
                    d["last_task"] = str(paths.local(d["last_task"]))
                out[d[key]] = cls(**{k: v for k, v in d.items() if k in cls.__dataclass_fields__})
    return out


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
    charged_concepts: list[str] = field(default_factory=list)   # failed concepts whose failure already counted a dependency return
    dependency_returns: int = 0     # returns because concepts the law's nodes use failed; never counted as attempts
    dependency_iteration: int = 0   # the iteration whose dependency return already counted
    repeats: dict[str, int] = field(default_factory=dict)       # repeat identity ↦ count, across plans and repairs
    selection_corrections: int = 0  # times a plan of the law claimed an aggregate the selection did not admit
    outcome_iteration: int = 0      # the attempt (iteration) whose outcome the state records
    cost_failures: dict[str, int] = field(default_factory=dict)   # node ↦ its gates ended on the evaluation's cost; never counted as attempts
    core_panics: list[str] = field(default_factory=list)          # nodes whose gate's evaluation panicked in isolation; never counted as attempts
    waits_on: list[str] = field(default_factory=list)             # blocked only because it composes these laws' nodes while they wait for the operator
    scope_violations: dict[str, int] = field(default_factory=dict)  # node ↦ its coding sessions that ended SCOPE_VIOLATION; never counted as attempts
    own_gaps: list[str] = field(default_factory=list)  # the tokens of `gaps` the law was blocked on itself, never one it inherited from a law it waits on


class ReopenRefused(ValueError):
    """An operator's reopen that may not run as asked; nothing of it was applied."""

    def __init__(self, reasons: list[str]):
        super().__init__("; ".join(reasons))
        self.reasons = reasons


class Ledger:
    def __init__(self, path: Path, law_ids: list[str], plan_attempts: int):
        self.path = path
        self.plan_attempts = plan_attempts
        self.attempt = 0            # the current iteration, set by the loop: the attempt outcomes belong to
        self.entries: dict[str, Entry] = _load(path, Entry, "law")
        for lid in law_ids:
            self.entries.setdefault(lid, Entry(lid))

    def save(self) -> None:
        jsonl.write_atomic(self.path, _rows(self.entries.values()))

    def _settles(self, e: Entry, new: str) -> bool:
        """Whether an outcome `new` of the current attempt may set the law's state: never over an
        accepted law or a terminal state of an earlier attempt, never below a higher outcome of
        this attempt."""
        if e.state == ACCEPTED:
            return False
        if e.outcome_iteration != self.attempt:
            return e.state not in (BLOCKED, FAILED)
        return SEVERITY.get(new, 0) >= SEVERITY.get(e.state, 0)

    def _set(self, e: Entry, state: str, reasons: list[str] | None = None) -> bool:
        if not self._settles(e, state):
            if reasons:
                e.reasons = e.reasons + [r for r in reasons if r not in e.reasons]
            return False
        e.state, e.outcome_iteration = state, self.attempt
        if reasons is not None:
            e.reasons = reasons
        return True

    def plannable(self) -> list[Entry]:
        return [e for e in self.entries.values() if e.state in PLANNABLE]

    def mark_planned(self, law: str, node_ids: list[str], iteration: int) -> bool:
        """A new attempt registers the law's plan: from `open` or `returned` (or a re-registration
        of the same attempt), never over a terminal state. Returns whether it was registered."""
        e = self.entries[law]
        if e.state in TERMINAL:
            return False
        e.state, e.nodes, e.iteration = PLANNED, node_ids, iteration
        return True

    @staticmethod
    def _charge(e: Entry, iteration: int) -> bool:
        """Whether this iteration still counts an attempt: at most one per law per iteration,
        whatever states the law passed through in it (a repair's withdrawal and the new plan of the
        same iteration are one attempt). Returns whether an attempt was counted."""
        if e.charged_iteration == iteration:
            return False
        e.attempts += 1
        e.charged_iteration = iteration
        return True

    def return_law(self, law: str, reasons: list[str], iteration: int) -> None:
        """The law's attempt ends returned, or failed when its budget is spent. Counting and
        recording are apart: a later return of the same iteration counts nothing, adds its reasons,
        and still records the outcome."""
        e = self.entries[law]
        if not self._settles(e, RETURNED):
            e.reasons = e.reasons + [r for r in reasons if r not in e.reasons]
            return
        if self._charge(e, iteration):
            e.reasons = reasons
        else:
            e.reasons = e.reasons + [r for r in reasons if r not in e.reasons]
        if e.attempts >= self.plan_attempts:
            self._set(e, FAILED, [f"attempt budget ({self.plan_attempts}) spent"] + reasons)
        else:
            self._set(e, RETURNED)

    def return_uncharged(self, law: str, reasons: list[str]) -> None:
        """The law goes back to the planner with these reasons and no attempt counted: nothing judged
        its plan (another law's re-plan invalidated its record, or the plan session was cut off before
        it wrote the law's node)."""
        self._set(self.entries[law], RETURNED, reasons)

    def return_for_concepts(self, law: str, concepts: list[str], reasons: list[str], iteration: int) -> None:
        """The law is returned because concepts its nodes use failed. Its plan attempts count only
        its own plans and nodes, and a concept has its own budget: a failure counts one dependency
        return against the law, however many iterations later the law is still waiting on it, at
        most one per iteration, and a return for concepts that already counted adds its reasons and
        counts nothing. `concepts` are the concepts that cause this return only, never one still
        pending. The law fails on its dependencies once its dependency returns exceed the plan
        attempts (`dependency_returns > plan_attempts`): with two plan attempts, two returns caused by
        dependencies are re-planned and the third closes the law."""
        e = self.entries[law]
        fresh = [c for c in concepts if c not in e.charged_concepts]
        if not fresh:
            if not self._set(e, RETURNED):
                return
            e.reasons = e.reasons + [r for r in reasons if r not in e.reasons]
            return
        e.charged_concepts = e.charged_concepts + fresh
        if not self._settles(e, RETURNED):
            e.reasons = e.reasons + [r for r in reasons if r not in e.reasons]
            return
        if e.dependency_iteration != iteration:
            e.dependency_returns += 1
            e.dependency_iteration = iteration
            e.reasons = reasons
        else:
            e.reasons = e.reasons + [r for r in reasons if r not in e.reasons]
        if e.dependency_returns > self.plan_attempts:
            self._set(e, FAILED, [f"dependency budget ({self.plan_attempts}) spent: {', '.join(e.charged_concepts)}"] + reasons)
        else:
            self._set(e, RETURNED)

    def gate_cost(self, law: str, node: str, panic: bool) -> bool:
        """A gate of the law's node judged nothing of its mapping: the evaluation panicked in
        isolation (a Core defect), or it reached the deadline or a resource failure reproduced in
        isolation (the evaluation's cost). Counted apart from the plan attempts and the node's
        codings, and never charged. Returns whether the node is now held for the operator: a panic at
        once, a cost failure once `GATE_COST_BOUND` are counted for the node."""
        e = self.entries[law]
        if panic:
            if node not in e.core_panics:
                e.core_panics = e.core_panics + [node]
            return True
        e.cost_failures = {**e.cost_failures, node: e.cost_failures.get(node, 0) + 1}
        return e.cost_failures[node] >= GATE_COST_BOUND

    def scope_violation(self, law: str, node: str) -> bool:
        """A coding session of the law's node ended `SCOPE_VIOLATION`: counted apart from the plan
        attempts and the node's codings, never charged. Returns whether the node is now held for the
        operator (`SCOPE_BOUND` reached)."""
        e = self.entries[law]
        e.scope_violations = {**e.scope_violations, node: e.scope_violations.get(node, 0) + 1}
        return e.scope_violations[node] >= SCOPE_BOUND

    def defer(self, law: str, reasons: list[str]) -> None:
        """Nothing judged the law's plan or its code (an outage): its state and plan stay, no attempt
        is counted, the reasons are added; its held work is resumed, never re-planned."""
        e = self.entries[law]
        e.reasons = e.reasons + [r for r in reasons if r not in e.reasons]

    def selection_correction(self, law: str) -> bool:
        """A plan of the law claimed an aggregate the selection did not admit. Returns True when it
        happened before: the law is then closed by the caller (`planning_protocol_failure`)."""
        e = self.entries[law]
        e.selection_corrections += 1
        return e.selection_corrections > 1

    def hold(self, law: str, iteration: int) -> None:
        """A node of the law waits for a node it composes: the law stays `planned`, its node list
        unchanged, and no attempt is counted. A law already returned or failed this iteration
        (another node of it was rejected) keeps that state: the held node waits as deferred, and
        the planner sees the law."""
        e = self.entries[law]
        if e.state == PLANNED:
            e.iteration = iteration

    def record_outcomes(self, law: str, keys: list[str], limit: int) -> list[str]:
        """Count the outcomes the law drew, across its plans and repairs, once per completed gate run
        or plan session (the caller applies an outcome once); the keys whose count reaches `limit` are
        returned, each with its count — the law is not converging, or the words cannot be stated. A
        key is an occurrence of the law's words, or the law's own outcome."""
        e = self.entries[law]
        hit = []
        for k in keys:
            e.repeats[k] = e.repeats.get(k, 0) + 1
            if e.repeats[k] >= limit:
                hit.append(f"{k} ×{e.repeats[k]}")
        return hit

    def block(self, law: str, gap_ids: list[str], reasons: list[str], inherited: bool = False) -> None:
        """Block the law on tokens (gap ids, `decision:<law>`), recorded where they come from: a token
        the law is blocked on itself joins `own_gaps` too; one it inherits from a law it waits on
        (`inherited`) joins `gaps` only, except `decision:<law>`, which is always the law's own."""
        e = self.entries[law]
        own = [g for g in gap_ids if not inherited or g == f"decision:{law}"]
        was_blocked = e.state == BLOCKED
        merged = e.gaps + [g for g in gap_ids if g not in e.gaps] if was_blocked else list(gap_ids)
        mine = e.own_gaps + [g for g in own if g not in e.own_gaps] if was_blocked else list(own)
        if self._set(e, BLOCKED, reasons):
            e.gaps = merged
            e.own_gaps = [g for g in mine if g in merged]

    def fail(self, law: str, reasons: list[str]) -> None:
        self._set(self.entries[law], FAILED, reasons)

    def accept(self, law: str, node_ids: list[str]) -> None:
        e = self.entries[law]
        if e.state == PLANNED:
            e.state, e.nodes, e.reasons = ACCEPTED, node_ids, []

    def roots(self, law: str, also=frozenset()) -> set[str]:
        """The laws whose own blocks hold `law`, through the laws it waits on: a failed law is its own
        root, and so is a blocked law with a token of its own (`own_gaps`) and a law in `also` (a
        planned law whose gap-carrying records wait on gaps filed in this iteration, not yet blocked
        on them); a law's roots are itself where that holds, and the roots of every law in its
        `waits_on` (each law visited once, so two laws that wait on each other are both roots)."""
        out, seen, stack = set(), set(), [law]
        while stack:
            l = stack.pop()
            if l in seen or l not in self.entries:
                continue
            seen.add(l)
            e = self.entries[l]
            if e.state == FAILED or (e.state == BLOCKED and e.own_gaps) or l in also:
                out.add(l)
            if e.state == BLOCKED:
                stack += list(e.waits_on)
        return out

    def reopen_refusals(self, laws: list[str] | None = None) -> list[str]:
        """Why an operator's reopen of `laws` (every failed or blocked law when None) may not run, the
        whole request checked before anything changes: a law blocked on a gap not yet decided (only
        `gap decide` decides it, for every law that holds it), and a law whose roots (`roots`) are not
        all in the request. Empty when every part of it may run."""
        asked = [e.law for e in self.entries.values() if e.state in (BLOCKED, FAILED)] if laws is None else list(laws)
        out = []
        for law in asked:
            e = self.entries.get(law)
            if e is None:                                   # a name the ledger does not hold reopens nothing
                continue
            if e.state == BLOCKED:
                gaps = [g for g in e.gaps if not g.startswith("decision:")]
                if gaps:
                    out.append(f"`{law}` is blocked on gap(s) {gaps} not yet decided: a reopen never decides a gap — decide each with "
                               "`python -m harness gap decide <id> --state retired|rejected --decision \"...\"`, which releases every law "
                               "that holds it")
                    continue
            missing = sorted(self.roots(law) - set(asked))
            if missing:
                out.append(f"`{law}` waits on root law(s) {missing}, which hold it: reopen them in the same request")
        return out

    def reopen(self, laws: list[str] | None = None) -> list[str]:
        """Operator action: failed laws, and laws blocked for the operator's decision (every token
        `decision:<…>`), back to open with a fresh budget. The request is checked whole first
        (`reopen_refusals`): any refusal raises `ReopenRefused` naming every reason, nothing changed.
        Reopening a law decides only its own decision tokens (`decision:<law>`, and the `decision:`
        tokens of its `own_gaps`), never a gap id: every blocked law loses the decided tokens, and one
        left with none reopens too."""
        why = self.reopen_refusals(laws)
        if why:
            raise ReopenRefused(why)
        out, tokens = [], set()
        for e in self.entries.values():
            if (laws is None or e.law in laws) and e.state != ACCEPTED:
                tokens |= {g for g in e.own_gaps if g.startswith("decision:")} | {f"decision:{e.law}"}
                self._fresh(e, [])
                out.append(e.law)
        for e in self.entries.values():
            if e.state == BLOCKED and set(e.gaps) & tokens:
                left = [g for g in e.gaps if g not in tokens]
                if left:
                    e.gaps, e.own_gaps = left, [g for g in e.own_gaps if g in left]
                else:
                    self._fresh(e, [f"reopened with {sorted(tokens & set(e.gaps))}"])
                    out.append(e.law)
        return out

    def revoke(self, law: str, reasons: list[str]) -> bool:
        """An accepted law whose acceptance no longer holds (a provider it composes became unusable)
        goes back to `planned`, its plan, attempts, counts and spend untouched, the reasons added once.
        Nothing happens to a law that is not accepted. Returns whether it was revoked."""
        e = self.entries[law]
        if e.state != ACCEPTED:
            return False
        e.state = PLANNED
        e.reasons = e.reasons + [r for r in reasons if r not in e.reasons]
        return True

    @staticmethod
    def _fresh(e: Entry, reasons: list[str]) -> None:
        e.state, e.attempts, e.reasons, e.charged_concepts, e.repeats, e.gaps, e.own_gaps = OPEN, 0, reasons, [], {}, [], []
        e.outcome_iteration, e.charged_iteration = 0, 0
        e.dependency_returns, e.dependency_iteration = 0, 0
        e.cost_failures, e.core_panics, e.waits_on, e.scope_violations = {}, [], [], {}

    def reopen_for_gaps(self, decided: dict[str, tuple[str, str]]) -> list[tuple[str, list[str]]]:
        """A blocked law reopens once the operator has decided every gap it waits on: retired (the
        ontology or the reading now carries the span) or rejected (the span can be carried as it is;
        the decision is the reason the next plan is shown), its nodes' gate-cost counts cleared as by
        `reopen`. A decided gap of a law that still waits on others (a gap or a decision token) is
        struck from its list, so the law reopens with the last one. Returns (law, reasons)."""
        out = []
        for e in self.entries.values():
            if e.state == BLOCKED and any(g in decided for g in e.gaps):
                reasons = [f"gap {g} {decided[g][0]}" + (f": {decided[g][1]}" if decided[g][1] else "") for g in e.gaps if g in decided]
                left = [g for g in e.gaps if g not in decided]
                if left:                                   # a decided gap is struck; the law waits on the rest
                    e.gaps, e.reasons = left, e.reasons + [r for r in reasons if r not in e.reasons]
                    e.own_gaps = [g for g in e.own_gaps if g in left]
                    continue
                e.state, e.gaps, e.own_gaps, e.reasons = OPEN, [], [], reasons
                e.cost_failures, e.core_panics, e.waits_on, e.scope_violations = {}, [], [], {}
                out.append((e.law, reasons))
        return out

    def paused(self) -> set[str]:
        """The laws blocked for the operator's decision on their own token (`decision:<law>`)."""
        return {e.law for e in self.entries.values() if e.state == BLOCKED and f"decision:{e.law}" in e.gaps}

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
    state: str = OPEN            # open | planned (with `waiting`) | returned | accepted | failed
    attempts: int = 0            # coding attempts the gate or the review returned; a validator's return counts none
    reasons: list[str] = field(default_factory=list)
    used_by: list[str] = field(default_factory=list)
    iteration: int = 0
    last_task: str = ""            # the task directory of the last coding attempt, for a repair session
    judge_failures: dict[str, int] = field(default_factory=dict)   # judge stage ↦ consecutive invalid answers
    waiting: list[str] = field(default_factory=list)   # pending concepts it calls: not coded until they are accepted
    cost_failures: int = 0       # its gates that ended on the evaluation's cost; never counted as attempts
    core_panics: int = 0         # its gates whose evaluation panicked in isolation; never counted as attempts
    held_laws: list[str] = field(default_factory=list)   # the laws its hold for the operator paused (directly or through other concepts) and still pauses
    scope_violations: int = 0    # its coding sessions that ended SCOPE_VIOLATION; never counted as attempts


class ConceptLedger:
    def __init__(self, path: Path, attempts: int):
        self.path = path
        self.attempts = attempts
        self.entries: dict[str, ConceptEntry] = _load(path, ConceptEntry, "concept")

    def save(self) -> None:
        jsonl.write_atomic(self.path, _rows(self.entries.values()))

    def planned(self, cid: str, used_by: list[str], iteration: int, planned_laws: set[str] | None = None) -> None:
        """A failed concept stays failed (only the operator's `reopen` of its laws clears it), and an
        accepted one stays accepted. The users given replace those of the laws this iteration planned
        (`planned_laws`; None: every law); a user of a law it did not plan stays, since that law's
        plan still uses the concept."""
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        if e.state in (FAILED, ACCEPTED):
            return
        kept = [] if planned_laws is None else [u for u in e.used_by if nodeid.law_of(str(u))[0] not in planned_laws and u not in used_by]
        e.state, e.used_by, e.iteration, e.waiting = PLANNED, kept + list(used_by), iteration, []

    def wait(self, cid: str, on: list[str], reasons: list[str]) -> None:
        """The concept calls concepts still pending: it stays `planned`, uncharged, with the scheduling
        flag `waiting`, and is coded once they are accepted."""
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        if e.state in (FAILED, ACCEPTED):
            return
        e.state, e.waiting, e.reasons = PLANNED, sorted(on), reasons

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
        if e.state == ACCEPTED:
            return
        e.reasons = reasons
        if e.state != FAILED:
            e.state = RETURNED

    def fail(self, cid: str, reasons: list[str]) -> None:
        """The concept is closed with these reasons, whatever its budget: its repair session withdrew it."""
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        e.state, e.reasons = FAILED, reasons

    def defer_judge(self, cid: str, stage: str, reasons: list[str], bound: int = 2) -> bool:
        """The concept's review was left without a valid answer at `stage`: it goes back to
        `planned`, its users and attempts unchanged, to be coded and reviewed again. Only that
        stage's consecutive count grows (the other stages answered). Returns True when the count
        reaches `bound`: for a judge stage the concept is then failed (`judge_protocol_failure`)."""
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        e.judge_failures = {stage: e.judge_failures.get(stage, 0) + 1}
        if e.judge_failures[stage] >= bound:
            if stage in JUDGE_STAGES:
                e.state = FAILED
                e.reasons = [f"judge_protocol_failure: the {stage} judge left the review without a valid answer twice in a row"] + reasons
            return True
        e.state, e.reasons = PLANNED, reasons
        return False

    def gate_cost(self, cid: str, panic: bool) -> bool:
        """The concept's gate judged nothing of its record (as `Ledger.gate_cost`): its state, users
        and attempts stay. Returns whether its users are now held for the operator: on a panic at
        once, on a cost failure once `GATE_COST_BOUND` are counted."""
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        if panic:
            e.core_panics += 1
            return True
        e.cost_failures += 1
        return e.cost_failures >= GATE_COST_BOUND

    def scope_violation(self, cid: str) -> bool:
        """A coding session of the concept ended `SCOPE_VIOLATION`: its state, users and attempts stay.
        Returns whether its users are now held for the operator (`SCOPE_BOUND` reached)."""
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        e.scope_violations += 1
        return e.scope_violations >= SCOPE_BOUND

    def held(self, cid: str) -> bool:
        """Whether the concept is held for the operator by its gate: a panic, the cost bound or the
        scope bound reached."""
        e = self.entries.get(cid)
        return e is not None and (e.core_panics > 0 or e.cost_failures >= GATE_COST_BOUND or e.scope_violations >= SCOPE_BOUND)

    def release(self, reopened: list[str], paused: set[str]) -> tuple[list[str], dict[str, list[str]]]:
        """Laws were reopened (`reopened`; `paused` are the laws still blocked for the operator's
        decision after it). A concept whose gate counts concern one of them (its direct users' laws or
        the laws its hold paused) keeps, among the laws its hold paused, only those still paused; once
        none is, its counts and hold are cleared, whether its laws were reopened together or one at a
        time. A user blocked or failed for another reason never keeps it held. Returns the concepts
        released, and each concept left held with the laws it still waits on."""
        out, waiting = [], {}
        for e in self.entries.values():
            if not (e.cost_failures or e.core_panics or e.scope_violations or e.held_laws):
                continue
            if not (set(e.held_laws) | {nodeid.law_of(str(u))[0] for u in e.used_by}) & set(reopened):
                continue
            e.held_laws = [l for l in e.held_laws if l in paused]
            if e.held_laws:
                waiting[e.concept] = list(e.held_laws)
            else:
                e.cost_failures, e.core_panics, e.scope_violations = 0, 0, 0
                out.append(e.concept)
        return out, waiting

    def clear_judge(self, cid: str) -> None:
        e = self.entries.get(cid)
        if e is not None:
            e.judge_failures = {}

    def repairable(self) -> list[ConceptEntry]:
        """Concepts a repair session may re-propose: returned by the gate or the review, with a
        coding attempt on record and budget left."""
        return [e for e in self.entries.values() if e.state == RETURNED and e.last_task]

    def accepted(self, cid: str, last_task: str = "") -> None:
        """Accepted, with the coding task kept, so a later integration return leaves it repairable."""
        e = self.entries.setdefault(cid, ConceptEntry(cid))
        e.state, e.reasons, e.waiting = ACCEPTED, [], []
        if last_task:
            e.last_task = last_task

    def counts(self) -> dict[str, int]:
        c: dict[str, int] = {}
        for e in self.entries.values():
            c[e.state] = c.get(e.state, 0) + 1
        return c


# ---------------------------------------------------------------------------------------------
# Nodes: one entry per node the gate returned, for the node repair path. A node has
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
        self.entries: dict[str, NodeEntry] = _load(path, NodeEntry, "node")
        blank = sorted(n for n, e in self.entries.items() if not e.law)
        if blank:
            raise jsonl.DataIntegrityError(path, None, f"node entries without a law: {blank}; migrate them from the law's plan")

    def save(self) -> None:
        jsonl.write_atomic(self.path, _rows(self.entries.values()))

    def budget_left(self, node: str) -> bool:
        """Whether another coding of the node may follow a repair: a node has `attempts` codings,
        so a return is repaired while the returns so far are fewer than `attempts - 1`."""
        e = self.entries.get(node)
        return (e.attempts if e else 0) < self.attempts - 1

    def returned(self, node: str, law: str, reasons: list[str], last_task: str, iteration: int) -> None:
        e = self.entries.setdefault(node, NodeEntry(node, law))
        e.attempts += 1
        e.law = e.law or law
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

    def failed(self, node: str, law: str, reasons: list[str], last_task: str = "", iteration: int = 0) -> None:
        """Failed, with the node's context kept: its law, its last task and its iteration are never
        erased, and an entry created here carries them."""
        e = self.entries.setdefault(node, NodeEntry(node, law))
        e.law = e.law or law
        e.state, e.reasons = FAILED, reasons
        e.last_task = last_task or e.last_task
        e.iteration = iteration or e.iteration
