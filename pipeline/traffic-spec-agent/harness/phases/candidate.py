"""A candidate transaction: a set of changes to the run's own library, checked on an isolated copy
of it together with everything they reach, and published whole or not at all.

Reason: a repair that changes shared records (a concept several laws call, a rule another composes,
a reading value) must be validated as one unit that can be rolled back, since a change that fixes one
law may break another.

What a transaction holds, under `iter-NNN/candidate/<id>/` of the run:
- `tree/library/`: a copy of the library with its build outputs, where every change is written and
  every check builds and runs;
- `reading.json`, the run's reading, and the base reading (inside the copied library when the base
  reading lies in the library, else `base_reading.json`), where reading proposals are entered;
- `mapping.json` and `admission.json`, the run's mapping index and admission cache as the
  candidate will leave them;
- `rulings.jsonl`, the rulings a check made on the candidate, published only with it;
- a view of the run's records (`view`), the run's accepted nodes and concepts with the changes;
- its own copies of the law ledger (`ledger`, bound to the view) and of the label states, so every
  check inside it reads the plans its changes make, and production's ledger is untouched until the
  commit merges the route derived from the verified results onto it.

Its life:
1. `Candidate.open` requires that the loop has paused scheduling and that no task or child process
   that may write the production tree runs (`Scheduling.drained`); it records the production
   baseline (`production_baseline`).
2. `apply` writes changes to the candidate only. A change may write only the two files of the record
   it names; an inherited record is read-only; an accepted concept keeps, under its id, its contract
   wording, its kind, its formals and its parameters. Every file a change may write joins the
   transaction's declared write set.
3. `affected` is the set to check again: every record whose dependency selection reaches a changed
   record, in the library before the change or in the candidate after it, and every record whose
   dependency context differs between the two (a reading value, an aggregate, a definition).
4. `verify` runs, inside the candidate, the validator on the affected records, the gate on each of
   them (its scope is the candidate's tree and the declared write set), the build of the whole
   candidate registry with every witness, and then the hooks (concept review, label non-regression).
   Every result is bound to the versions it ran on (`versions`).
5. `commit` publishes, only when every result passed on the current versions, scheduling is still
   drained and the production baseline is unchanged: the files are staged, a journal naming every
   replacement is written (the commit point), and the replacements are applied; `recover` completes a
   journal a stopped process left, so a reader sees the whole old or the whole new version.
   `rollback` publishes nothing and keeps the candidate's records, results and rulings as
   diagnostics; spend is recorded by the sessions themselves and is never rolled back.
"""
from __future__ import annotations

import copy
import hashlib
import json
import os
import shutil
import subprocess
import threading
import time
import uuid
from contextlib import contextmanager
from dataclasses import asdict, dataclass, field, replace
from pathlib import Path
from typing import Callable

from ..checks import gate
from ..lean import index_sync, lean
from ..model import nodeid
from ..model.blueprint import ConceptRecord, Node
from ..model.reading import Reading, same_meaning
from ..store import jsonl, owner, paths
from ..store.state import Run

JOURNAL = "candidate_journal.json"
#: The candidate's own task directories (a coding session for it, a plan inside it), beside its tree.
CANDIDATE_ITER = "iter-candidate"
#: The environment variable that points a gate a session runs at the candidate it codes in.
CANDIDATE_ENV = "TRAFFIC_SPEC_CANDIDATE"
#: Gate verdicts that judge nothing of a record: the toolchain did not run, the evaluation's cost, the budget.
UNJUDGED = (gate.INFRA, gate.GATE_TIMEOUT, "BUDGET_EXHAUSTED")
#: The run's state a transaction holds in its view, commits into the snapshot and leaves in the run's memory.
OWNED = ("accepted_nodes", "accepted_concepts", "fenced", "fence_history", "rechecked")
#: The versions a label check binds besides the candidate's own (the label check's data and contract).
LABEL_VERSIONS = ("data", "label_contract", "scoring", "limits")


class NotDrained(RuntimeError):
    """A transaction was opened or committed while a task or process that may write the production tree runs."""


class ChangeRefused(ValueError):
    """A change outside what a transaction may write; nothing of the change set was applied."""


class CommitRefused(RuntimeError):
    """A commit whose preconditions do not hold; the candidate stays open and production unchanged."""


# ---------------------------------------------------------------------------------------------
# Scheduling: the loop's pause, and the drain a transaction requires
# ---------------------------------------------------------------------------------------------
class Scheduling:
    """Whether the loop may start a task that may write the production tree (a coding, repair or
    review session and its gate). The loop runs each such task inside `task()`; `pause()` stops new
    ones and waits for the running ones to end. A transaction is opened and committed only while
    `drained()` is empty: paused, no task running, and no child process group of the library's owner
    alive."""

    def __init__(self):
        self._cv = threading.Condition()
        self._paused = False
        self._running = 0

    @property
    def paused(self) -> bool:
        return self._paused

    @contextmanager
    def task(self):
        with self._cv:
            if self._paused:
                raise NotDrained("scheduling is paused for a candidate transaction: no task starts")
            self._running += 1
        try:
            yield
        finally:
            with self._cv:
                self._running -= 1
                self._cv.notify_all()

    @contextmanager
    def pause(self, timeout: float | None = None):
        """Stop new tasks, wait until the running ones have ended (`NotDrained` after `timeout`
        seconds), and resume scheduling on leaving."""
        with self._cv:
            self._paused = True
            if not self._cv.wait_for(lambda: self._running == 0, timeout=timeout):
                self._paused = False
                raise NotDrained(f"{self._running} task(s) still running after {timeout}s")
        try:
            yield self
        finally:
            with self._cv:
                self._paused = False

    def drained(self) -> list[str]:
        """Why the production tree may still be written: empty when it may not."""
        out = []
        with self._cv:
            if not self._paused:
                out.append("scheduling is not paused")
            if self._running:
                out.append(f"{self._running} task(s) running")
        live = owner.children()
        if live:
            out.append(f"the owner's child process groups {live} are alive")
        return out


SCHEDULING = Scheduling()
_OPEN_LOCK = threading.Lock()
_OPEN: set[str] = set()


# ---------------------------------------------------------------------------------------------
# What a transaction applies, finds and reports
# ---------------------------------------------------------------------------------------------
@dataclass
class Change:
    """One record of the run's library as the transaction leaves it: `record` its new record (None
    withdraws it and removes its two files), `files` the new text of its own files, keyed by their
    path in the library (a file not named keeps its text)."""
    kind: str                       # "node" | "concept"
    ident: str
    record: dict | None = None
    files: dict[str, str] = field(default_factory=dict)


@dataclass
class CheckResult:
    """One check on the candidate: `status` is `pass`, `fail`, `unavailable` (the check did not
    judge) or `not_run`; `versions` the candidate's versions it ran on."""
    check: str
    subject: str
    status: str
    details: list[str] = field(default_factory=list)
    versions: dict = field(default_factory=dict)


@dataclass
class Affected:
    """`changed`: each record the changes write (id → kind), a withdrawn one included; `removed`:
    those withdrawn; `closure`: every record present in the candidate to check again (id → kind),
    the changed ones first; `why`: for each, the changed records it reaches or the part of its
    context that changed; `laws`: the laws whose nodes are in the closure or withdrawn."""
    changed: dict[str, str]
    removed: set[str]
    closure: dict[str, str]
    why: dict[str, list[str]]
    laws: list[str]


def own_files(kind: str, ident: str) -> tuple[str, str]:
    """A record's two files, relative to the library."""
    if kind == "concept":
        return nodeid.concept_path(ident), nodeid.concept_witness_path(ident)
    return nodeid.rule_path(ident), nodeid.witness_path(ident)


def _ws(s) -> str:
    return " ".join(str(s or "").split())


def interface(rec: dict) -> dict:
    """What a concept's callers rely on under its id: its contract's text, verbatim, its kind, its formals
    (name, sort and the admissible values of a literal formal), its parameters (name and unit), and the
    act it declares (whether its callers need an occasion, and over which boundary)."""
    c = ConceptRecord(rec)
    return {"contract": str(rec.get("contract") or ""), "kind": rec.get("kind"),
            "args": [(a.get("name"), a.get("sort"), list(a.get("values", [])) if a.get("sort") == "literal" else []) for a in c.args()],
            "params": [(p.get("name"), p.get("unit")) for p in c.params()],
            "act": act_declaration(rec.get("act"))}


def act_declaration(act) -> dict | None:
    """A concept's act declaration in the form compared under its id: each part with its whitespace
    normalized, the window only for a window boundary; None where the record declares no act."""
    if not isinstance(act, dict):
        return None
    ws = lambda v: " ".join(str(v or "").split())
    out = {k: ws(act.get(k)) for k in ("boundary", "onset", "recognition", "extent", "history")}
    if act.get("boundary") == "window":
        out["window"] = ws(act.get("window"))
    return out


ACCEPTED, DEPENDED_ON, UNBOUND = "accepted", "depended on by an accepted record", "neither accepted nor depended on by an accepted record"


def concept_state(run, cid: str) -> str:
    """Whether a concept is accepted, or an accepted record depends on it directly or through other
    concepts (the reverse closure of the run's accepted call graph), or neither: what decides what a
    revision may change under its id."""
    from ..loop import concept_closure, concept_deps
    prod = run.all_concepts()
    if cid in prod:
        return ACCEPTED
    refs = {c: set(ConceptRecord(r).refs()) for c, r in prod.items()}
    if any(cid in concept_closure(concept_deps(Node(r)), refs) for r in run.all_nodes().values()) \
            or any(cid in concept_closure(set(ConceptRecord(r).refs()), refs) for r in prod.values()):
        return DEPENDED_ON
    return UNBOUND


def same_id_defects(old: dict, new: dict) -> list[str]:
    """How a revision of an accepted concept under its own id changes what its callers rely on
    (`interface`); such a revision takes a new id that supersedes the old, and its callers migrate."""
    a, b = interface(old), interface(new)
    return [f"`{new.get('concept_id')}`: its {k} differs from the accepted version under the same id ({a[k]!r} → {b[k]!r}); "
            "a revision that changes it takes a new id that supersedes this one" for k in a if a[k] != b[k]]


def _sha(x) -> str:
    data = x if isinstance(x, bytes) else json.dumps(x, sort_keys=True, ensure_ascii=False, default=str).encode()
    return hashlib.sha256(data).hexdigest()


def _file_sha(p: Path) -> str | None:
    return hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None


#: The per-file digest of the production tree a candidate opened on (`production_baseline`'s `tree`
#: is its hash), kept in the candidate's directory: what names each production file a candidate's
#: session changed.
PRODUCTION_DIGEST = "production_digest.json"


def production_baseline(run: Run, tree: dict | None = None) -> dict:
    """What a commit requires unchanged since the transaction opened: every file of the pipeline tree
    a session could write (the gate's repository digest of the tree that holds the library, `tree`
    when already computed) and the run's own files the commit replaces or appends to."""
    files = {name: _file_sha(run.dir / name) for name in ("state.json", "reading.json", "mapping.json", "admission.json", "rulings.jsonl")}
    files["base_reading"] = _file_sha(Path(run.opts.reading))
    return {"tree": _sha(gate.repo_digest(paths.LIBRARY.parent) if tree is None else tree), **files}


class _View(Run):
    """A run's records as a candidate holds them: the run's own accepted records with the changes,
    its fences, and the candidate's reading and mapping index; everything else is the run's."""

    @property
    def reading_file(self) -> Path:
        return self._candidate_reading

    @property
    def mapping_file(self) -> Path:
        return self._candidate_mapping

    @property
    def iter(self) -> Path:
        """Where a session or a coding task run for the candidate keeps its directory."""
        return self._candidate_iter

    @property
    def rulings_file(self) -> Path:
        """The candidate's rulings: the run's as they stood when it opened, then every ruling a review,
        a replay or an adjudication made on the candidate; published whole only with it."""
        return self._candidate_rulings

    @property
    def admission_file(self) -> Path:
        """The candidate's admission evidence: the run's as it stood when the candidate opened, with
        the entries the candidate's own gates write at its commit."""
        return self._candidate_rulings.with_name("admission.json")


#: The fields of a law's ledger entry a commit publishes from its route: what the law's state means.
#: Every other field (attempts, charges, repeats, counts) is the live entry's at the commit.
LEDGER_SEMANTIC = ("state", "nodes", "gaps", "own_gaps", "waits_on", "reasons")


def transaction_ledger(run: Run):
    """A copy of the run's live law ledger (its entries as the loop holds them, else as its file
    holds them), for a transaction to check and route on without touching production's."""
    from ..store.ledger import Ledger, Entry, _load
    entries = run.law_entries if run.law_entries is not None else _load(run.ledger_file, Entry, "law")
    led = Ledger.__new__(Ledger)
    led.path, led.plan_attempts, led.attempt = None, run.opts.plan_attempts, run.iteration
    led.entries = copy.deepcopy(entries)
    return led


def _view(run: Run, area: Path, base_reading: Path, base: dict | None = None) -> _View:
    v = object.__new__(_View)
    v.__dict__.update(run.__dict__)
    v.base = base                                     # Core and the ontology, copied unchanged: production's digests
    for k in OWNED:
        setattr(v, k, copy.deepcopy(getattr(run, k)))
    v.unverified_concepts = set()                     # the concepts this candidate adds or changes, not committed
    v.opts = replace(run.opts, reading=base_reading)
    v._candidate_reading, v._candidate_mapping, v._candidate_iter = area / "reading.json", area / "mapping.json", area / CANDIDATE_ITER
    v._candidate_rulings = area / "rulings.jsonl"
    return v


# ---------------------------------------------------------------------------------------------
# Hooks: the checks later stages add (the concept review, the label non-regression check)
# ---------------------------------------------------------------------------------------------
#: A hook is called inside the candidate (its library and scope in force) once every record of the
#: closure passed, as `hook(candidate, affected)`, and returns its results; any result that is not
#: `pass` refuses the commit.
Hook = Callable[["Candidate", Affected], list[CheckResult]]


def concept_review(txn: "Candidate", aff: Affected) -> list[CheckResult]:
    """The concept review inside the candidate, on its library, reading, registry and rulings:
    - every concept the candidate adds or changes passes the existing review (the second vendor's
      challenges run on its body, the concept adjudicator's rulings, and first the replay of its
      earlier upheld challenges): `accepted` passes, `returned` (an upheld item) fails, `deferred` or a
      review that could not run decides nothing (`unavailable`). A review whose inputs are unchanged
      (its saved outcome in the candidate) is taken back, not asked again;
    - every record the change reaches without changing it, whose dependency context changed, has its
      recorded obligations certified again on the candidate (the context check), and its new context
      recorded there; one whose context did not change is reused as it is.
    Every ruling is written to the candidate's rulings, published with it or never."""
    from . import review as review_phase, integrate
    from ..agents import session
    from ..loop import context_base, semantic_inputs
    from ..model import corpus
    from ..store.state import chain_laws
    view, out = txn.view, []
    for cid, kind in aff.changed.items():
        if kind != "concept" or cid in aff.removed:
            continue
        rec = ConceptRecord(view.accepted_concepts[cid])
        extras = {**view.accepted_concepts[cid], **txn.extras.get(cid, {})}
        try:
            o = review_phase.review_concept(view, rec, extras, txn.area / "review" / cid.replace(".", "_"))
        except session.SessionUnavailable as e:
            out.append(CheckResult("concept_review", cid, "unavailable", [str(e)[:300]]))
            continue
        status = {"accepted": "pass", "returned": "fail"}.get(o.status, "unavailable")
        out.append(CheckResult("concept_review", cid, status, (o.reasons or o.advisories)[:6]))
        if status == "pass":
            notes = [x for x in o.advisories if x != "reviewer off"]
            if notes:
                txn.extras.setdefault(cid, {})["approximations"] = notes
    unchanged = {i for i in aff.closure if i not in aff.changed}
    if unchanged:
        laws = {**chain_laws(view), **({l.id: l for l in corpus.load_laws(view.opts.laws)} if Path(view.opts.laws).exists() else {})}
        base = context_base(view.opts, semantic_inputs(view.opts))
        fences = (dict(view.fenced), list(view.fence_history))    # a failure refuses the candidate; it fences nothing
        try:
            ok, failing, unresolved = integrate.recheck_contexts(view, txn.reading, base, laws, only=unchanged)
        finally:
            view.fenced, view.fence_history = fences
        named = lambda lines: {l.split("`")[1]: l for l in lines if l.count("`") >= 2}
        bad, open_ = named(failing), named(unresolved)
        for i in sorted(unchanged):
            if i in bad:
                out.append(CheckResult("context", i, "fail", [bad[i][:400]]))
            elif i in open_:
                out.append(CheckResult("context", i, "unavailable", [open_[i][:400]]))
            else:
                out.append(CheckResult("context", i, "pass", ["certified again" if i in ok else "context unchanged: reused"]))
    return out


def label_check_pending(txn: "Candidate", aff: Affected) -> list[CheckResult]:
    """Every law the change reaches keeps the matches it had; until the label check runs in the
    candidate, its result is `not_run`, which refuses the commit."""
    return [CheckResult("label_non_regression", law, "not_run", ["the label check does not run in a candidate yet"]) for law in aff.laws]


DEFAULT_HOOKS: tuple[Hook, ...] = (concept_review, label_check_pending)


def validate_records(txn: "Candidate", nodes: list[Node], concepts: list[ConceptRecord]) -> list[CheckResult]:
    """The plan validator on the affected records, in the candidate: each concept against the
    candidate's other concepts and nodes, each node against the run's corpus (its base chain's laws
    included), the candidate's reading, mapping index and records."""
    from ..checks import validate_a
    from ..model import corpus, definitions as definitions_mod, ontology
    from ..model.mapping import MappingIndex
    from ..store.gaps import GapLedger
    from ..store.state import chain_laws
    view = txn.view
    onto = ontology.load(view.opts.ontology)
    out = []
    try:
        if concepts:
            cids = {c.id for c in concepts}
            accepted = {k: v for k, v in view.all_concepts().items() if k not in cids}
            users = [Node(r) for r in view.all_nodes().values()]
            for o in validate_a.validate_concepts(concepts, corpus.load_definitions(view.opts.laws), onto, accepted, users, view.opts.mode):
                out.append(CheckResult("validate", o.concept.id, "pass" if o.kind == validate_a.ACCEPT else "fail", list(o.reasons)))
        if nodes:
            nids = {n.id for n in nodes}
            laws = {**chain_laws(view), **({l.id: l for l in corpus.load_laws(view.opts.laws)} if Path(view.opts.laws).exists() else {})}
            accepted_n = {k: Node(v) for k, v in view.all_nodes().items() if k not in nids}
            for o in validate_a.validate(nodes, laws, onto, txn.reading, MappingIndex(view.mapping_file), accepted_n, view.all_concepts(), [],
                                         rejected_gaps=GapLedger.for_run(paths.GAPS_DIR, view).rejected(),
                                         sources=definitions_mod.source_texts(view)):
                out.append(CheckResult("validate", o.node.id, "pass" if o.kind == validate_a.ACCEPT else "fail", list(o.reasons)))
    except validate_a.ValidatorFault as e:
        out.append(CheckResult("validate", "validator", "unavailable", [str(e)]))
    return out


def unavailable_compositions(view: Run, idents, gated=()) -> dict[str, dict[str, str]]:
    """Each node of `idents` that composes, directly or through the nodes it composes, a node that is
    not usable for building it in the transaction's view (`Run.provider_code`: fenced, superseded,
    missing, not yet published, its law planned again or held for the operator, without admission
    evidence): its id → {that dependency: its code}. `gated`: the records whose admission is this
    transaction's own gate (its changed records and the closure it checks again)."""
    from ..store.state import Availability, USABLE
    nodes, out = view.all_nodes(), {}
    av = Availability(view, gated=gated)
    for ident in idents:
        if ident not in nodes:
            continue
        n = Node(nodes[ident])
        bad = {str(c.get("rule")): av.code(str(c.get("rule")), n.law) for c in n.dependencies() if c.get("rule")}
        bad = {d: c for d, c in bad.items() if c != USABLE}
        if bad:
            out[ident] = bad
    return out


Validator = Callable[["Candidate", list[Node], list[ConceptRecord]], list[CheckResult]]


# ---------------------------------------------------------------------------------------------
# The transaction
# ---------------------------------------------------------------------------------------------
class Candidate:
    """One transaction over a run's library and state (see the module's description). Opened with
    `Candidate.open`; usable as a context manager, which rolls back a transaction left open."""

    def __init__(self, run: Run, area: Path, base: dict, validator: Validator, hooks, scheduling: Scheduling):
        self.run, self.area, self.base = run, area, base
        self.validator, self.hooks, self.scheduling = validator, tuple(hooks), scheduling
        self.id = area.name
        self.tree = area / "tree"
        self.library = self.tree / "library"
        self.status = "open"
        self.changed: dict[str, str] = {}
        self.write_set: set[str] = set()
        self.results: list[CheckResult] = []
        self.gated: dict[str, str] = {}            # id → kind of every record whose gate passed in the last `verify`
        self.extras: dict[str, dict] = {}          # what a passing gate returned, for each changed record
        self.bound: dict = {k: None for k in LABEL_VERSIONS}
        self.label_checks: dict = {}               # law → the label check a hook made on the candidate, for the caller to publish
        self.ledger = None                         # the transaction's own copy of the law ledger, bound to its view
        self.label_states: dict = {}               # its own copy of the label states
        self.plans: dict | None = None             # the plans given to the label hook, part of what results rest on
        self.baseline: dict = {}
        self.scope_baseline: dict = {}
        self.view: _View
        self.base_reading: Path

    # -- opening ---------------------------------------------------------------------------------
    @classmethod
    def open(cls, run: Run, *, base: dict | None = None, validator: Validator | None = None,
             hooks=DEFAULT_HOOKS, scheduling: Scheduling = SCHEDULING) -> "Candidate":
        """Copy the run's library and state into a new candidate. `base` is what every dependency
        context is computed against besides the record (Core and the ontology; by default the run's
        current semantic inputs); `validator` the validator the affected records go through
        (`validate_records` by default); `hooks` the checks run after the gates and witnesses."""
        why = scheduling.drained()
        if why:
            raise NotDrained("a candidate opens only while the loop's scheduling is paused and drained: " + "; ".join(why))
        with _OPEN_LOCK:
            if run.opts.run_id in _OPEN:
                raise NotDrained(f"run `{run.opts.run_id}` already has an open candidate")
            _OPEN.add(run.opts.run_id)
        try:
            if base is None:
                from ..loop import semantic_inputs
                sem = semantic_inputs(run.opts)
                base = {"core": sem["core"], "ontology": sem["ontology"]}
            area = run.iter / "candidate" / f"{time.strftime('%Y%m%d-%H%M%S')}-{uuid.uuid4().hex[:6]}"
            txn = cls(run, area, base, validator or validate_records, hooks, scheduling)
            txn._copy()
            return txn
        except BaseException:
            with _OPEN_LOCK:
                _OPEN.discard(run.opts.run_id)
            raise

    def _copy(self) -> None:
        run = self.run
        prod_tree = gate.repo_digest(paths.LIBRARY.parent)
        self.baseline = production_baseline(run, prod_tree)  # taken before anything is copied
        self.tree.mkdir(parents=True)
        jsonl.write_atomic(self.area / PRODUCTION_DIGEST, json.dumps(prod_tree))
        cp = subprocess.run(["cp", "-a", "--reflink=auto", str(paths.LIBRARY), str(self.library)], capture_output=True, text=True)
        if cp.returncode != 0:
            raise RuntimeError(f"the library could not be copied into {self.tree}: {cp.stderr.strip()}")
        base_reading = Path(run.opts.reading).resolve()
        if base_reading.is_relative_to(paths.LIBRARY.resolve()):
            rel = base_reading.relative_to(paths.LIBRARY.resolve()).as_posix()
            self.base_reading = self.library / rel
            self.write_set.add(gate.lib_rel(rel))       # the transaction may enter proposals into it
        else:
            self.base_reading = self.area / "base_reading.json"
            if base_reading.exists():
                shutil.copy2(base_reading, self.base_reading)
        copies = (("reading.json", run.reading_file), ("mapping.json", run.mapping_file), ("admission.json", run.dir / "admission.json"),
                  ("rulings.jsonl", run.dir / "rulings.jsonl"))
        for name, src in copies:
            if src.exists():
                shutil.copy2(src, self.area / name)
        self.view = _view(run, self.area, self.base_reading, self.base)
        self.ledger = transaction_ledger(run)
        self.view.law_entries = self.ledger.entries          # every check inside it reads its own plans, never production's
        self.label_states = copy.deepcopy(run.label_states)
        self.scope_baseline = gate.repo_digest(self.tree)
        # the copy is the production the baseline names: production unchanged since, and the copy equal to it
        moved = sorted(k for k, v in production_baseline(run).items() if self.baseline.get(k) != v)
        prod = {k: v for k, v in gate.repo_digest(paths.LIBRARY.parent).items() if k.startswith("library/")}
        differ = sorted(k for k in set(prod) | set(self.scope_baseline) if prod.get(k) != self.scope_baseline.get(k))
        differ += [name for name, src in copies if _file_sha(src) != _file_sha(self.area / name)]
        if moved or differ:
            raise NotDrained(f"production changed while candidate {self.id} was copied ({', '.join((moved + differ)[:6])})")
        self._status({"opened": time.strftime("%Y-%m-%dT%H:%M:%S"), "iteration": run.iteration, "baseline": self.baseline})

    def _status(self, extra: dict | None = None) -> None:
        f = self.area / "status.json"
        d = jsonl.read_json(f, {}) or {}
        d.update({"id": self.id, "run": self.run.opts.run_id, "status": self.status, "changed": self.changed,
                  "write_set": sorted(self.write_set), **(extra or {})})
        jsonl.write_atomic(f, json.dumps(d, ensure_ascii=False, indent=1))

    def _require_open(self) -> None:
        if self.status != "open":
            raise CommitRefused(f"candidate {self.id} is {self.status}")

    @contextmanager
    def inside(self):
        """The candidate's library in force for the duration: every library location of the harness
        points at the copy. The locations are the whole process's, so this holds only while
        scheduling is drained (`NotDrained` otherwise)."""
        why = self.scheduling.drained()
        if why:
            raise NotDrained("the candidate's library is put in force only while scheduling is paused and drained: " + "; ".join(why))
        with paths.at_library(self.library):
            yield

    @property
    def reading(self) -> Reading:
        return Reading(self.view.reading_file)

    @property
    def scope(self) -> gate.CandidateScope:
        return gate.CandidateScope(self.tree, frozenset(self.write_set))

    # -- changes ---------------------------------------------------------------------------------
    def refusals(self, changes: list[Change], declarations: list[dict] | None = None) -> list[str]:
        """Why a change set, with the declared ids proposed beside it, may not be applied (empty when
        it may)."""
        run, out, seen = self.run, [], set()
        decls = Reading(self.view.reading_file).declarations()
        for d in declarations or []:
            have = decls.get(d.get("id")) if isinstance(d, dict) else None
            if have is not None and not same_meaning(have.get("meaning"), d.get("meaning")):
                out.append(f"declaration `{d.get('id')}` proposed as {d.get('meaning')!r}, the reading means {have.get('meaning')!r}")
        for ch in changes:
            if ch.kind not in ("node", "concept"):
                out.append(f"`{ch.ident}`: kind {ch.kind!r} is neither node nor concept"); continue
            if ch.ident in seen:
                out.append(f"`{ch.ident}`: changed twice in one change set")
            seen.add(ch.ident)
            if ch.kind == "concept" and not nodeid.is_concept_id(ch.ident):
                out.append(f"`{ch.ident}`: not a concept id"); continue
            key = "concept_id" if ch.kind == "concept" else "node_id"
            if ch.record is not None and ch.record.get(key) != ch.ident:
                out.append(f"`{ch.ident}`: the record's {key} is {ch.record.get(key)!r}")
            mine = set(own_files(ch.kind, ch.ident))
            stray = sorted(set(ch.files) - mine)
            if stray:
                out.append(f"`{ch.ident}`: writes {stray}, outside the record's own files {sorted(mine)}")
            if ch.record is None and ch.files:
                out.append(f"`{ch.ident}`: a withdrawn record writes no file")
            own = run.accepted_concepts if ch.kind == "concept" else run.accepted_nodes
            inherited = run.base_concepts if ch.kind == "concept" else run.base_nodes
            if ch.ident in inherited and ch.ident not in own:
                out.append(f"`{ch.ident}`: inherited from `{run.provenance.get(ch.ident, run.opts.base_run)}`, read-only in this run")
            if ch.kind == "concept" and ch.record is not None:
                out += self._same_id(ch, changes)
            if ch.kind == "node" and ch.record is not None:
                for d in ch.record.get("assumptions", []) + ch.record.get("intentions", []):
                    have = decls.get(d.get("id")) if isinstance(d, dict) else None
                    if have is not None and not same_meaning(have.get("meaning"), d.get("meaning")):
                        out.append(f"`{ch.ident}`: declares `{d.get('id')}` as {d.get('meaning')!r}, the reading means {have.get('meaning')!r}")
        return out

    def _same_id(self, ch: Change, changes: list[Change]) -> list[str]:
        """The one same-id rule for a concept, by its state. A concept that is accepted, or that an
        accepted record depends on directly or through other concepts (the reverse closure of the
        run's accepted call graph), keeps its contract text, kind, formals and parameters. Any other
        concept may change its interface only where every record that calls it, directly or through
        other concepts, is updated with it (in the same change set, so the closure validates them
        together): a caller of the candidate missing from the changes is refused, and so is a planned
        or held caller, which a candidate cannot update (it is replaced or re-planned instead)."""
        from ..loop import concept_closure, concept_deps
        run, view = self.run, self.view
        prod = run.all_concepts()
        if concept_state(run, ch.ident) != UNBOUND:
            old = prod.get(ch.ident) or view.accepted_concepts.get(ch.ident)
            return same_id_defects(old, ch.record) if old else []
        pending = {d.get("concept_id"): d for d in run.deferred_concepts if isinstance(d, dict)}
        old = view.accepted_concepts.get(ch.ident) or pending.get(ch.ident)
        if not old or interface(old) == interface(ch.record):
            return []
        refs_now = {c: set(ConceptRecord(r).refs()) for c, r in {**pending, **view.all_concepts()}.items()}
        reach = lambda deps: ch.ident in concept_closure(set(deps), refs_now)
        updated = {c.ident for c in changes}                 # updated with the change, in the same change set
        out = []
        for d in run.deferred_nodes + [x for x in run.deferred_concepts if x.get("concept_id") != ch.ident]:
            ident = d.get("node_id") or d.get("concept_id")
            deps = concept_deps(Node(d)) if "node_id" in d else ConceptRecord(d).refs()
            if reach(deps):
                out.append(f"`{ch.ident}`: its interface changes, and the planned or held record `{ident}` that calls it cannot be "
                           "updated in a candidate: replace the concept under a new id, or re-plan its callers")
        for ident, r in {**view.all_nodes(), **view.all_concepts()}.items():
            deps = concept_deps(Node(r)) if ident in view.all_nodes() else ConceptRecord(r).refs()
            if ident != ch.ident and reach(deps) and ident not in updated:
                out.append(f"`{ch.ident}`: its interface changes, and `{ident}`, which calls it directly or through other concepts, "
                           "is not updated with it")
        return out

    def write_scope(self) -> Path:
        """The candidate's scope as a gate run from a session reads it (`CANDIDATE_ENV` names the
        candidate's directory): its tree, its declared write set, its readings and its records."""
        f = self.area / "scope.json"
        jsonl.write_atomic(f, json.dumps({"tree": str(self.tree), "write_set": sorted(self.write_set),
                                          "reading": str(self.view.reading_file), "base_reading": str(self.base_reading),
                                          "concepts": self.view.all_concepts(), "accepted_nodes": self.view.accepted_nodes,
                                          "accepted_concepts": self.view.accepted_concepts}, default=str))
        return f

    def apply(self, changes: list[Change], params: list[dict] | None = None, declarations: list[dict] | None = None,
              origin: str | None = None, plans: dict[str, list[str]] | None = None) -> None:
        """Apply a change set to the candidate, whole or (`ChangeRefused`) not at all, and the reading
        proposals with it: each changed node's own parameter proposals and declared ids, and `params`
        and `declarations` as `origin` proposes them; all enter the candidate's readings only. Each
        law with a node change has its plan updated in the transaction's ledger: `plans[law]` when
        given (a re-plan), else its plan less the nodes withdrawn, with its new nodes added.
        Earlier results no longer describe the candidate and are dropped."""
        from ..loop import enter_proposed
        self._require_open()
        why = self.refusals(changes, declarations)
        if why:
            raise ChangeRefused("; ".join(why))
        view = self.view
        with self.inside():
            for ch in changes:
                records = view.accepted_concepts if ch.kind == "concept" else view.accepted_nodes
                if ch.kind == "concept":
                    view.unverified_concepts.add(ch.ident)
                old = records.get(ch.ident) or {}
                files = own_files(ch.kind, ch.ident)
                if ch.record is None:
                    for rel in files:
                        (self.library / rel).unlink(missing_ok=True)
                    records.pop(ch.ident, None)
                else:
                    for rel, text in ch.files.items():
                        (self.library / rel).parent.mkdir(parents=True, exist_ok=True)
                        (self.library / rel).write_text(text, encoding="utf-8")
                    rec = {k: v for k, v in ch.record.items() if k not in ("context", "fenced")}
                    for k in ("callers", "used_by", "provenance"):        # what other records wrote onto it
                        if k in old and k not in rec:
                            rec[k] = old[k]
                    records[ch.ident] = rec
                    if ch.kind == "node":
                        enter_proposed(view, view.opts, Node(rec))
                if ch.kind == "node":
                    self._callers(ch.ident, old, ch.record)
                    self._plan(ch, old, plans)
                self.write_set |= {gate.lib_rel(r) for r in files}
                self.changed[ch.ident] = ch.kind
            if params or declarations:
                for target in (view.reading_file, view.opts.reading):
                    Reading.add_proposals(target, list(params or []), origin or f"{view.opts.run_id}/candidate-{self.id}")
                    Reading.add_declarations(target, list(declarations or []), origin or f"{view.opts.run_id}/candidate-{self.id}")
            view.reconcile_fences()
            index_sync.set_inactive(set(view.fenced), view.opts.run_id)
        self.results, self.gated, self.extras = [], {}, {}
        with open(self.area / "changes.jsonl", "a", encoding="utf-8") as f:
            for ch in changes:
                f.write(json.dumps(asdict(ch), ensure_ascii=False) + "\n")
        self._status()

    def _plan(self, ch: Change, old: dict, plans: dict | None) -> None:
        """The plan of the changed node's law in the transaction's ledger."""
        law = Node(ch.record or old or {"node_id": ch.ident, "law_refs": [nodeid.law_of(ch.ident)[0]]}).law
        e = self.ledger.entries.get(law)
        if e is None:
            return
        if plans and law in plans:
            e.nodes = list(plans[law])
        elif ch.record is None:
            e.nodes = [i for i in e.nodes if i != ch.ident]
        elif ch.ident not in e.nodes:
            e.nodes = list(e.nodes) + [ch.ident]

    def _callers(self, nid: str, old: dict, new: dict | None) -> None:
        """Each of the run's own accepted concepts lists the accepted nodes that call it: a changed
        node leaves the lists of the concepts it no longer calls and joins those it now calls."""
        from ..loop import concept_deps
        was = concept_deps(Node(old)) if old else set()
        now = concept_deps(Node(new)) if new is not None else set()
        for cid in was | now:
            rec = self.view.accepted_concepts.get(cid)
            if rec is None:
                continue
            cur = rec.get("callers", [])
            callers = [c for c in cur if c != nid or cid in now] + ([nid] if cid in now and nid not in cur else [])
            if callers != cur:
                rec["callers"] = callers

    def stage_rulings(self, rows: list[dict]) -> None:
        """Rulings a check made on the candidate: appended to the candidate's rulings, published with
        it, kept only here when it is rolled back."""
        self._require_open()
        for r in rows:
            jsonl.append_atomic(self.view.rulings_file, r)

    def bind(self, **versions) -> None:
        """Bind a version a later check depends on (`data`, `label_contract`, `scoring`, `limits`); a
        result verified before a binding that changes a version is stale at the commit, whether the key
        was unbound or bound to another value."""
        unknown = set(versions) - set(LABEL_VERSIONS)
        if unknown:
            raise ValueError(f"unknown version(s) {sorted(unknown)}")
        self.bound.update(versions)

    # -- versions --------------------------------------------------------------------------------
    def versions(self) -> dict:
        """What every result is bound to: the candidate's content (its library's files, its records,
        its readings and mapping index), Core and the toolchain as the copy holds them, the reading,
        the gate's implementation, the versions a later check binds (`bind`), and `dependency`: each
        law's state, plan, tokens and waits in the transaction's ledger, the admission evidence's keys
        and verdicts, and the plans given to the label hook (bookkeeping counts are not part of it)."""
        from .integrate import gate_digest
        tree = gate.repo_digest(self.tree)
        text = lambda p: p.read_text(encoding="utf-8") if p.is_file() else None
        from ..store.state import record_digest              # what a record means: a recorded context or caller list is no content
        records = {"nodes": {k: record_digest(r) for k, r in self.view.accepted_nodes.items()},
                   "concepts": {k: record_digest(r) for k, r in self.view.accepted_concepts.items()}, "fenced": sorted(self.view.fenced)}
        adm = jsonl.read_json(self.view.admission_file, {}) or {}
        dependency = _sha({"ledger": sorted((law, e.state, list(e.nodes), list(e.gaps), list(e.own_gaps), list(e.waits_on))
                                            for law, e in self.ledger.entries.items()),
                           "admission": sorted((k, v.get("key"), v.get("verdict")) for k, v in adm.items() if isinstance(v, dict)),
                           "plans": self.plans})
        return {"candidate": _sha({"tree": tree, "records": records, "reading": text(self.view.reading_file),
                                   "base_reading": text(self.base_reading), "mapping": text(self.view.mapping_file)}),
                "dependency": dependency,
                "core": _sha({k: v for k, v in tree.items() if k.startswith("library/TrafficSpec/Core/")}),
                "toolchain": _sha({k: tree.get(f"library/{k}") for k in ("lean-toolchain", "lake-manifest.json", "lakefile.lean")}),
                "reading": _sha(text(self.view.reading_file) or ""),
                "gate": gate_digest(), **self.bound}

    # -- the closure -----------------------------------------------------------------------------
    def affected(self) -> Affected:
        """The records to check again: the changed records still present, every record whose
        dependency selection (`integrate.admission_selection`: the nodes it composes and the
        concepts it calls, transitively) reaches a changed record before the change (in the run) or
        after it (in the candidate), and every record whose dependency context
        (`integrate.context_version`: its record, files, what it calls and composes with their own
        contexts, the reading values and aggregates it reads) differs between the two."""
        from .integrate import admission_selection, context_version
        run, view, changed = self.run, self.view, dict(self.changed)

        def scan(r: Run, reading: Reading) -> tuple[dict[str, str], dict[str, set[str]], dict[str, str | None]]:
            kinds = {**{k: "node" for k in r.all_nodes()}, **{k: "concept" for k in r.all_concepts()}}
            reach, ctx = {}, {}
            for ident, kind in kinds.items():
                sel = admission_selection(r, kind, ident)
                reach[ident] = (set(sel["nodes"]) | set(sel["concepts"])) - {ident}
                try:
                    ctx[ident] = context_version(r, kind, ident, reading, self.base)
                except (ValueError, KeyError):
                    ctx[ident] = None
            return kinds, reach, ctx

        before_k, before_r, before_c = scan(run, Reading(run.reading_file))
        with self.inside():
            after_k, after_r, after_c = scan(view, self.reading)
        closure, why = {}, {}
        for ident, kind in after_k.items():
            hits = sorted((before_r.get(ident, set()) | after_r[ident]) & set(changed))
            reasons = (["changed"] if ident in changed else []) + [f"reaches `{h}`" for h in hits]
            if not reasons and (after_c[ident] is None or before_c.get(ident) != after_c[ident]):
                reasons.append("its dependency context changed")
            if reasons:
                closure[ident], why[ident] = kind, reasons
        closure = {**{i: closure[i] for i in closure if i in changed}, **{i: k for i, k in closure.items() if i not in changed}}
        removed = {i for i in changed if i not in after_k}
        laws = {Node(view.all_nodes()[i]).law for i, k in closure.items() if k == "node"}
        laws |= {Node(run.all_nodes()[i]).law for i in removed if changed[i] == "node" and i in run.all_nodes()}
        return Affected(changed, removed, closure, why, sorted(laws))

    # -- checks ----------------------------------------------------------------------------------
    def verify(self) -> list[CheckResult]:
        """Every check of the closure, in the candidate: the validator on every affected record; the
        availability of every changed node's compositions to its own law (`unavailable_compositions`),
        however its Lean was written; the gate on each one those passed whose dependencies passed, concepts before their
        callers and nodes after what they compose, each registering only its own dependency
        selection; the whole candidate registry built with every witness run; then the hooks. Every
        result is bound to the versions it ran on, and kept in `checks.jsonl`."""
        from ..loop import concept_order, topological
        from .integrate import admission_selection, verify_library
        self._require_open()
        aff = self.affected()
        v0 = self.versions()
        view, results = self.view, []
        self.gated, self.extras = {}, {}
        with self.inside(), gate.candidate_scope(self.scope):
            concepts = concept_order([ConceptRecord(view.all_concepts()[i]) for i, k in aff.closure.items() if k == "concept"])
            nodes = topological([Node(view.all_nodes()[i]) for i, k in aff.closure.items() if k == "node"])
            results += self.validator(self, nodes, concepts)
            for ident, bad in unavailable_compositions(view, [i for i, k in aff.changed.items() if k == "node"], gated=set(aff.closure)).items():
                results.append(CheckResult("availability", ident, "fail", ["composes " + ", ".join(f"{d} ({c})" for d, c in sorted(bad.items()))
                                                                          + ": not usable for building"]))
            failed = {r.subject for r in results if r.status != "pass"}
            if "validator" in failed:
                failed |= set(aff.closure)
            reading = self.reading
            for rec in [("concept", c) for c in concepts] + [("node", n) for n in nodes]:
                kind, r = rec
                sel = admission_selection(view, kind, r.id)
                blocked = sorted(((set(sel["nodes"]) | set(sel["concepts"])) - {r.id}) & failed)
                if r.id in failed or blocked:
                    results.append(CheckResult("gate", r.id, "not_run", [f"not gated: {'it' if r.id in failed else ', '.join(blocked)} "
                                                                          "did not pass"]))
                    failed.add(r.id)
                    continue
                work = self.area / "gates" / (r.id.replace(".", "_"))
                work.mkdir(parents=True, exist_ok=True)
                (work / "registry.json").write_text(json.dumps(sel), encoding="utf-8")
                if kind == "concept":
                    v = gate.run_concept_gate(r, reading, self.scope_baseline, work, 0, 1, mode=view.opts.mode,
                                              accepted={k: x for k, x in view.all_concepts().items() if k != r.id})
                else:
                    v = gate.run_gate(r, reading, self.scope_baseline, work, 0, 1, accepted_concepts=view.all_concepts(),
                                      acquisition=view.opts.acquisition_profile)
                (work / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1, default=str), encoding="utf-8")
                status = "pass" if v.verdict == "OK" else "unavailable" if v.verdict in UNJUDGED else "fail"
                results.append(CheckResult("gate", r.id, status, [v.verdict] + v.details[:8]))
                if status == "pass":
                    self.gated[r.id] = kind
                    if r.id in aff.changed:
                        self.extras[r.id] = v.extras
                else:
                    failed.add(r.id)
            if not failed:
                st, problems, _owners = verify_library(self.area / "verify", reading, only_nodes=sorted(view.all_nodes()),
                                                       only_concepts=sorted(view.all_concepts()))
                results.append(CheckResult("witnesses", "library", {"verified": "pass", "failed": "fail"}.get(st, "unavailable"), problems[:12]))
            if all(r.status == "pass" for r in results):
                for hook in self.hooks:                       # in order; a hook that did not pass ends the checks
                    results += hook(self, aff)
                    if any(r.status != "pass" for r in results):
                        break
        if self.versions() != v0:
            raise RuntimeError(f"candidate {self.id} changed while it was checked")
        for r in results:
            r.versions = v0
        self.results = results
        with open(self.area / "checks.jsonl", "a", encoding="utf-8") as f:
            for r in results:
                f.write(json.dumps(asdict(r), ensure_ascii=False, default=str) + "\n")
        return results

    # -- the route a commit carries -------------------------------------------------------------
    def route(self, target: str | None, nodes: list[str]):
        """The ledger the commit publishes, derived only from the transaction's ledger as verified and
        its verified label checks (`label_checks`): the target law routed by its check (`route_entry`,
        its plan `nodes`), every other law checked again routed by its own (an operator's hold kept),
        then the acceptances that no longer hold revoked and routed (`revalidate_acceptance`), on a copy.
        The copy names what it was derived for (`routed_for`) and carries the label states revoking
        changed (`label_changes`) and the operator's lines (`said`)."""
        from ..loop import LABEL_ROUTES, label_state, route_entry, revalidate_acceptance
        routed = copy.deepcopy(self.ledger)
        said: list[str] = []
        for other, chk in sorted(self.label_checks.items()):
            if other == target or other not in routed.entries:
                continue
            e = routed.entries[other]
            if e.state in ("blocked", "failed"):
                continue
            new = {"accepted": "accepted", "waiting": "planned", "awaiting_label_repair": "planned", "failed": "blocked"}[LABEL_ROUTES[chk.outcome]]
            if new != e.state:
                e.state = new
                if new == "blocked":
                    e.gaps = sorted(set(e.gaps) | {f"decision:{other}"})
                    e.own_gaps = sorted(set(e.own_gaps) | {f"decision:{other}"})
        if target is not None and target in self.label_checks:
            chk = self.label_checks[target]
            routed.entries[target].nodes = list(nodes)
            route_entry(self.view, routed, target, chk, list(nodes), label_state(self.view, target, chk, list(nodes), self.area / "label", self.id), said)
        saved = (self.view.law_entries, self.view.label_states)
        self.view.law_entries, self.view.label_states = routed.entries, copy.deepcopy(self.label_states)
        self.view.gated_ids = set(self.gated)             # what its own gates passed is admitted with its commit
        try:
            with self.inside():
                revoked = revalidate_acceptance(self.view, routed, said)
            changes = {law: self.view.label_states[law] for law in revoked if law in self.view.label_states}
        finally:
            self.view.law_entries, self.view.label_states = saved
            self.view.gated_ids = None
        routed.routed_for, routed.label_changes, routed.said = (target, list(nodes)), changes, said
        return routed

    # -- commit and rollback ---------------------------------------------------------------------
    def commit(self, extra_state: dict | None = None, routed=None, label_updates: dict | None = None) -> dict:
        """Publish the candidate: its changed files, the registries regenerated from them, its
        readings, mapping index and admission cache, its staged rulings, and the run's snapshot with
        its records and fences (and `extra_state`, keys the caller commits with it). The snapshot is
        the run's committed one: the caller commits its own state first. Refused
        (`CommitRefused`, the candidate staying open) unless every result passed on the current
        versions, scheduling is drained, and the production baseline is the one the candidate
        opened on. The ledger it publishes is `routed` (else the route derived with no target),
        refused unless it is exactly `route` recomputed for what it names: its semantic fields
        (`LEDGER_SEMANTIC`) are merged onto the live ledger, every count of it kept as it stands now.
        `label_updates` (law ↦ fields, `None` removing one) and the label states the route revoked
        are merged onto the live label states the same way."""
        from .integrate import admission_key
        self._require_open()
        run, view = self.run, self.view
        if not self.results:
            raise CommitRefused(f"candidate {self.id} was not verified")
        bad = [f"{r.check} {r.subject}: {r.status}" + (f" ({r.details[0]})" if r.details else "") for r in self.results if r.status != "pass"]
        if bad:
            raise CommitRefused("checks did not pass: " + "; ".join(bad[:8]))
        now = self.versions()
        stale = sorted({k for r in self.results for k in set(now) | set(r.versions) if r.versions.get(k) != now.get(k)})
        if stale:
            raise CommitRefused(f"results bound to other versions ({', '.join(stale)}): verify again")
        why = self.scheduling.drained()
        if why:
            raise NotDrained("a candidate commits only while scheduling is paused and drained: " + "; ".join(why))
        moved = sorted(k for k, v in production_baseline(run).items() if self.baseline.get(k) != v)
        if moved:
            raise CommitRefused(f"the production baseline moved since candidate {self.id} opened ({', '.join(moved)})")
        snap = run.load_state()
        if snap is None:
            raise CommitRefused(f"run `{run.opts.run_id}` has no committed snapshot to commit onto")
        derived = self.route(*(routed.routed_for if routed is not None and hasattr(routed, "routed_for") else (None, [])))
        if routed is not None and [asdict(e) for e in routed.entries.values()] != [asdict(e) for e in derived.entries.values()]:
            raise CommitRefused("the route carried is not the one the verified results derive: verify again")
        from ..store.ledger import Entry
        live = run.law_entries if run.law_entries is not None else {d["law"]: Entry(**{k: v for k, v in d.items() if k in Entry.__dataclass_fields__})
                                                                    for d in snap.get("ledger", [])}
        # what the commit publishes is built on copies: the live ledger and label states are touched only past
        # the commit point, so a commit that stops before it leaves them as they were
        published = copy.deepcopy(live)
        for law, e in derived.entries.items():
            if law in published:
                published[law].__dict__.update({k: copy.deepcopy(getattr(e, k)) for k in LEDGER_SEMANTIC})
        states = copy.deepcopy(run.label_states)
        for law, upd in {**derived.label_changes, **(label_updates or {})}.items():
            st = dict(states.get(law, {}))
            for k, v in upd.items():
                if v is None:
                    st.pop(k, None)
                else:
                    st[k] = v
            states[law] = st
        self.published = {"ledger": live, "said": derived.said}      # `live` holds the published fields once committed
        # what the gates found, onto the changed records; their admission keys as published
        for ident, ex in self.extras.items():
            records = view.accepted_concepts if self.changed.get(ident) == "concept" else view.accepted_nodes
            rec = records.get(ident)
            if rec is None:
                continue
            if self.changed[ident] == "concept":
                rec.update({"reads": ex.get("reads", []), "refs": ex.get("refs", sorted(ConceptRecord(rec).refs())),
                            "canonical_body": ex.get("canonical_body"), "body_json": ex.get("body_json")})
                if ex.get("approximations"):                  # what its review found it computes as built
                    rec["approximations"] = ex["approximations"]
                rec["accepted_in"] = f"{run.opts.run_id}/iter-{run.iteration:03d}/candidate-{self.id}"
            added = [n for n in ex.get("narrowings_added", []) if n not in rec.get("narrowings", [])]
            if added:
                rec["narrowings"] = list(rec.get("narrowings", [])) + added
        cache = jsonl.read_json(self.area / "admission.json", {}) or {}
        with self.inside():
            for ident in self.changed:
                cache.pop(ident, None)
            for ident, kind in self.gated.items():
                if ident not in view.fenced:
                    cache[ident] = {"key": admission_key(view, kind, ident, self.reading, self.base), "verdict": "OK",
                                    "details": [f"accepted by the gate in candidate {self.id}"]}
        jsonl.write_atomic(self.area / "admission.json", json.dumps(cache, indent=1, ensure_ascii=False))
        from ..store.ledger import _saved
        snap.update({**{k: getattr(view, k) for k in OWNED}, "ledger": [_saved(e) for e in published.values()], **(extra_state or {})})
        if states:
            snap["label_states"] = states
        stage = self.area / "commit"
        if stage.exists():
            shutil.rmtree(stage)
        ops: list[dict] = []

        def put(text: bytes, to: Path, name: str) -> None:
            f = stage / name
            f.parent.mkdir(parents=True, exist_ok=True)
            with open(f, "wb") as fh:
                fh.write(text); fh.flush(); os.fsync(fh.fileno())
            ops.append({"put": str(f), "to": str(to)})
        for key in sorted(self.write_set):
            rel = key[len("library/"):]
            src = self.library / rel
            if src.exists():
                put(src.read_bytes(), paths.LIBRARY / rel, f"library/{rel}")
            else:
                ops.append({"delete": str(paths.LIBRARY / rel)})
        inactive = self.library / ".inactive.json"
        if inactive.exists() and _file_sha(inactive) != _file_sha(paths.LIBRARY / ".inactive.json"):
            put(inactive.read_bytes(), paths.LIBRARY / ".inactive.json", "library/.inactive.json")
        for name, to in (("reading.json", run.reading_file), ("mapping.json", run.mapping_file), ("admission.json", run.dir / "admission.json")):
            if (self.area / name).exists():
                put((self.area / name).read_bytes(), to, f"run/{name}")
        if not self.base_reading.is_relative_to(self.library) and self.base_reading.exists():
            put(self.base_reading.read_bytes(), Path(run.opts.reading), "run/base_reading.json")
        if _file_sha(self.view.rulings_file) != _file_sha(run.dir / "rulings.jsonl") and self.view.rulings_file.exists():
            put(self.view.rulings_file.read_bytes(), run.dir / "rulings.jsonl", "run/rulings.jsonl")   # the run's rows, then the candidate's
        put(json.dumps(snap, ensure_ascii=False).encode(), run.state_file, "run/state.json")
        journal = {"candidate": self.id, "area": str(self.area), "status": "committed", "ops": ops, "run_id": run.opts.run_id}
        self.status = "committing"                        # from here on, only `recover` decides: never rolled back
        self._status()
        jsonl.write_atomic(pending_file(), json.dumps({"journal": str(run.dir / JOURNAL)}))      # what any later owner completes first
        jsonl.write_atomic(run.dir / JOURNAL, json.dumps(journal, ensure_ascii=False, indent=1))     # the commit point
        # past the commit point the new version is the run's: the run in memory as committed, its ledger's entries
        # updated in place (every holder of them sees it), before the replacements a recovery would complete
        for law, e in published.items():
            if law in live:
                live[law].__dict__.update({k: copy.deepcopy(getattr(e, k)) for k in LEDGER_SEMANTIC})
        for k in OWNED:
            setattr(run, k, copy.copy(snap[k]))
        if states:
            run.label_states = states
        _apply(journal, run.dir / JOURNAL, run)
        self.status = "committed"
        self._close()
        return {"candidate": self.id, "changed": dict(self.changed), "files": len(ops), "affected": [r.subject for r in self.results if r.check == "gate"]}

    def close(self, reason: str) -> None:
        """End a candidate that changed nothing (a measurement on the library as it is): nothing is
        published and nothing is rolled back."""
        self._require_open()
        if self.changed:
            raise CommitRefused(f"candidate {self.id} changed {sorted(self.changed)}: commit or roll it back")
        self.status = "closed"
        self._close({"reason": reason})

    def rollback(self, reason: str) -> None:
        """Publish nothing: production keeps its version; the candidate's records, results and staged
        rulings stay in its directory as diagnostics."""
        self._require_open()
        self.status = "rolled_back"
        self._close({"reason": reason})

    def _close(self, extra: dict | None = None) -> None:
        shutil.rmtree(self.library / ".lake", ignore_errors=True)    # the copy's build outputs: large, and rebuilt from the sources
        self._status({"closed": time.strftime("%Y-%m-%dT%H:%M:%S"), **(extra or {})})
        with _OPEN_LOCK:
            _OPEN.discard(self.run.opts.run_id)

    def __enter__(self) -> "Candidate":
        return self

    def __exit__(self, *exc) -> bool:
        if self.status == "open":
            self.rollback("left open" if exc[0] is None else f"stopped by {exc[0].__name__}: {exc[1]}")
        return False


def _replace(src: Path, dst: Path) -> None:
    """`dst` replaced by a copy of `src` through a temporary file beside it, flushed and renamed."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    tmp = dst.with_name(f".{dst.name}.tmp-candidate")
    with open(tmp, "wb") as fh:
        fh.write(src.read_bytes()); fh.flush(); os.fsync(fh.fileno())
    os.replace(tmp, dst)


def pending_file() -> Path:
    """The library's pointer to a committed transaction not yet applied (a harness file, no session's)."""
    return paths.LIBRARY / owner.PENDING_FILE


def _apply(journal: dict, journal_file: Path, run: Run | None = None) -> None:
    """Apply a committed journal: every replacement and removal (each idempotent), the registries
    regenerated over the library as it now is, the snapshot's projections written when the run is
    given (any later load writes them from the snapshot otherwise); then the journal is marked
    applied and the library's pointer to it removed."""
    for op in journal["ops"]:
        if "put" in op:
            _replace(Path(op["put"]), Path(op["to"]))
        else:
            Path(op["delete"]).unlink(missing_ok=True)
    with lean.library_lock(paths.LIBRARY):
        index_sync.write_index()
    if run is not None:
        Run(run.opts).restore_state()                 # the projections, leaving the caller's own state in memory as it is
    jsonl.write_atomic(journal_file, json.dumps({**journal, "status": "applied"}, ensure_ascii=False, indent=1))
    pending_file().unlink(missing_ok=True)


def pending() -> Path | None:
    """The journal of a committed transaction the library still waits on, or None."""
    p = pending_file()
    try:
        j = Path(json.loads(p.read_text(encoding="utf-8"))["journal"]) if p.exists() else None
    except (OSError, ValueError, KeyError, TypeError):
        return p
    return j if j is not None and (jsonl.read_json(j, {}) or {}).get("status") == "committed" else None


def recover_pending() -> str | None:
    """At the library's ownership boundary (every owner, any run, before anything reads or builds the
    library): a transaction committed and not yet applied is applied whole; a pointer left by one
    stopped before its commit point is removed, since nothing of it was published. Returns what was
    completed, or None."""
    p = pending_file()
    if not p.exists():
        return None
    j = pending()
    if j is None or j == p:
        p.unlink(missing_ok=True)
        return None
    journal = jsonl.read_json(j, {})
    _apply(journal, j)
    area = Path(journal.get("area", ""))
    if (area / "status.json").exists():
        jsonl.write_atomic(area / "status.json", json.dumps({**(jsonl.read_json(area / "status.json", {}) or {}), "status": "committed"},
                                                            ensure_ascii=False, indent=1))
    return f"candidate {journal.get('candidate')} of run `{journal.get('run_id')}`: its commit was completed"


def recover(run: Run) -> str | None:
    """At a loop's start, after the library's ownership boundary: a journal of this run committed and
    not yet applied is applied (`recover_pending` does it for whichever run left it), and any other
    candidate a stopped process left open or committing published nothing and is marked abandoned, its
    build copy removed. Returns what was completed, or None."""
    done = recover_pending()
    if done:
        Run(run.opts).restore_state()                  # the projections of the snapshot the completed commit wrote
    j = jsonl.read_json(run.dir / JOURNAL, None)
    if j and j.get("status") == "committed":
        _apply(j, run.dir / JOURNAL, run)
        done = f"candidate {j.get('candidate')}: its commit was completed"
    for status in run.dir.glob("iter-*/candidate/*/status.json"):
        d = jsonl.read_json(status, {}) or {}
        if d.get("status") not in ("open", "committing") or run.opts.run_id in _OPEN:
            continue
        shutil.rmtree(status.parent / "tree" / "library" / ".lake", ignore_errors=True)
        state = "committed" if j and Path(j.get("area", "")) == status.parent else "abandoned"
        jsonl.write_atomic(status, json.dumps({**d, "status": state}, ensure_ascii=False, indent=1))
    return done
