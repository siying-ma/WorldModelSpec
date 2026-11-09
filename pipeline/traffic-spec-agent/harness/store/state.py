"""A run: its directories, options, notes files and iteration numbering."""
from __future__ import annotations
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from . import jsonl, paths
from ..model import corpus
from ..model.blueprint import Node

#: The feedback modes a run may name. A new run names one explicitly (`--feedback`); the dataclass
#: default `review` is the meaning of a saved run whose options name none (one started before a new
#: run had to name its mode), never a choice made for a new run.
FEEDBACK_MODES = ("review", "labels")


def feedback_refusal(mode) -> str | None:
    """Why a run cannot be launched with feedback mode `mode`, or None. Only a mode of FEEDBACK_MODES
    is accepted: every branch that routes by the mode (the node review, law-level acceptance, the
    record contexts) knows only those, so any other value would run another mode silently. A new mode
    enters FEEDBACK_MODES together with its routing, acceptance, dependency and run-version wiring."""
    if mode in FEEDBACK_MODES:
        return None
    return f"--feedback must be one of {' | '.join(FEEDBACK_MODES)} (given {mode!r})"


@dataclass
class Options:
    run_id: str
    laws: Path
    ontology: Path
    reading: Path
    model: Optional[str] = None
    max_iterations: int = 3
    plan_attempts: int = 2
    concept_attempts: int = 3      # coding attempts per concept, the first plus its repairs
    node_attempts: int = 2         # coding attempts per node, the first plus one after a node repair session
    repeat_limit: int = 3          # the same upheld divergence on the same words of a node, drawn this many times across the law's plans and repairs, blocks the law for the operator
    gate_budget: int = 6
    max_turns: int = 80
    session_timeout: float = 3600.0
    dry_run: bool = False          # render prompts and run the deterministic phases, launch no session
    plan_effort: Optional[str] = "high"      # `claude --effort` for the plan session (low|medium|high|xhigh|max)
    code_effort: Optional[str] = "high"      # for each coding session
    judge_effort: Optional[str] = "medium"   # for a concept's judge and the adjudicator
    session_budget_usd: Optional[float] = 20.0   # `--max-budget-usd` of a plan or coding session, and its reservation; None = uncapped
    repair_budget_usd: Optional[float] = 8.0     # the same for a concept or node repair session
    judge_budget_usd: Optional[float] = 2.0      # the same for a tool-less answer: a judge, an adjudication, a recheck
    session_retries: int = 2       # relaunches per task and attempt of a session that did not run or was cut off
    retry_wait: float = 900.0      # seconds between those relaunches
    plan_batch: int = 8            # laws per plan session; a law is planned after the laws it names are accepted or in its batch
    workers: int = 1               # coding tasks run at once (concepts, then nodes, each once its dependencies are accepted)
    plan_turns: int = 80           # turn cap for a plan or repair session (a coding session keeps `max_turns`)
    restart: bool = False          # discard an interrupted iteration instead of resuming it
    reviewer_model: Optional[str] = None   # a second vendor's model for the reviews (required): the concept review, and the node behaviour review under `feedback: review`
    review_effort: Optional[str] = "high"  # the reviewer's reasoning effort
    feedback: str = "review"               # one of FEEDBACK_MODES, named by every new run (`review` only fills a saved run that names none). `review`: a node is accepted on its behaviour review; `labels`: the node behaviour review and its Stage A/B are suspended, the concept review stays, and the label check scores the frozen library (`harness label_check`)
    aggregate_verifier_model: Optional[str] = None     # the second vendor's model that verifies an aggregate mapping (required under `feedback: labels`; else the reviewer's)
    aggregate_verifier_effort: Optional[str] = None    # its reasoning effort (else the reviewer's)
    aggregate_verifier_budget_usd: Optional[float] = None   # the run-wide limit on its calls, within the second vendor's limit
    allow_same_vendor: bool = False        # permit a reviewer from the planner's own vendor
    mode: str = "train"            # `train`: concepts may supersede; `test`: add-only over a base run
    base_run: Optional[str] = None # a run whose accepted nodes and concepts this run starts from, read-only
    definition_precedence: Optional[Path] = None   # the operator's declared definition precedence (default config/definition_precedence.json)
    acquisition_profile: Optional[str] = None      # the operator's acquisition profile of the recordings (config/acquisition_profiles.json): its reviewed parameter is every `heading_since` step bound; none, and no rule may read `heading_since`
    openai_budget_usd: Optional[float] = None      # the run-wide limit on the second vendor's calls; reached, the run pauses (`paused_budget`)
    claude_budget_usd: Optional[float] = None      # the run-wide limit on Claude's sessions, each reserved at its role's cap (required with it)
    total_budget_usd: Optional[float] = None       # the run-wide limit over both vendors (requires every role's cap)
    budget_peers: list = field(default_factory=list)   # the runs sharing this run's limits, the same group named by each; reservations take one lock
    reviewer_max_output_tokens: int = 64000        # the output-token limit of every OpenAI call, reasoning included
    max_divergences: int = 3                       # the most divergences one reviewer answer may carry
    model_prices: Optional[Path] = None            # the operator's price table (default config/model_prices.json)
    review_checks: int = 8                         # check calls of one reviewer session (each runs one divergence through Core)
    review_submissions: int = 3                    # submissions of one reviewer session; the last one stands
    review_passes: int = 2                         # reviewer sessions per rule review, one after another, their challenges joined
    force_takeover: bool = False                   # end the live child process groups an earlier owner of the library left, instead of refusing
    label_repair: bool = False                     # under `feedback: labels`, check each law whose plan is gated on the training recordings inside the loop and route its outcome (off: the library is only scored after the run)
    label_dataset: Optional[str] = None            # the training recordings the in-loop label check reads (required with `label_repair`)
    label_repair_attempts: int = 2                 # label repairs per law (a re-planned law keeps its count); each session call of one, its re-ask included, is capped by `repair_budget_usd`, and its planner and coder sessions by `session_budget_usd`
    label_deferred: bool = False                   # with `label_repair`: no training recording is read on this machine; a law whose plan is gated is kept, not accepted, and recorded `awaiting_labels` for a later launch with the recordings
    label_stage: bool = False                      # with `label_repair`: this launch only checks laws on the training recordings and repairs them; it plans and codes nothing new
    label_repair_budget: int = 10                  # label repairs over the whole run, all laws together (a count, not an amount: the run's spending limits still bound every session)


def acceptance_by_law(opts) -> bool:
    """Whether a law's formal acceptance waits on more than its nodes' gates: under `feedback: labels`
    with `label_repair` a law is accepted only once its label check routes it there, so a node accepted
    on its gate is generated, not formally accepted; otherwise a node's acceptance is formal."""
    return getattr(opts, "feedback", "review") == "labels" and bool(getattr(opts, "label_repair", False))


#: The fields of a run's acceptance policy (what `acceptance_by_law` reads), each with the test of a
#: legal saved value: a saved contract holds every one, explicitly, with a legal value.
POLICY_FIELDS = {"feedback": lambda v: v in FEEDBACK_MODES, "label_repair": lambda v: isinstance(v, bool)}


def policy_defects(saved) -> list[str]:
    """Why a saved acceptance policy (a run's saved options, or the policy a handoff recorded) is not
    whole: a field missing, or a value of the wrong type or not legal. Nothing is filled by default."""
    if not isinstance(saved, dict):
        return ["it is not an object"]
    return [f"`{k}` is missing" if k not in saved else f"`{k}` is {saved[k]!r}, not a legal value"
            for k, legal in POLICY_FIELDS.items() if k not in saved or not legal(saved[k])]


def acceptance_policy(opts) -> dict:
    """What decides how a run's laws are accepted (`acceptance_by_law` reads it), from a launch's
    options or a saved contract that `policy_defects` found whole: fixed for the run's life."""
    get = opts.get if isinstance(opts, dict) else lambda k, d=None: getattr(opts, k, d)
    return {k: get(k) for k in POLICY_FIELDS}


def acceptance_policy_refusal(fixed, opts) -> str | None:
    """The one check of a run's acceptance policy: why a launch with options `opts` may not continue a
    run whose policy is `fixed` (its saved options, or the policy a handoff recorded), or None. A saved
    policy that is not whole (`policy_defects`) is refused, never completed by a default; any change
    is refused: a run accepts its laws on one policy, and another policy is a new run. Which stage a
    launch runs (`label_deferred`, `label_stage`), its dataset and its budgets are not part of it."""
    if fixed is None:
        return None
    bad = policy_defects(fixed)
    if bad:
        return "the run's saved acceptance policy is not whole (" + "; ".join(bad) + "); restore its checkpoint, or start a new run id"
    was, now = acceptance_policy(fixed), acceptance_policy(opts)
    changed = sorted(k for k in set(was) | set(now) if was.get(k) != now.get(k))
    if not changed:
        return None
    return ("the run's acceptance policy is fixed for its life (" + ", ".join(f"{k}: {was.get(k)!r} → {now.get(k)!r}" for k in changed)
            + "); start a new run id")


def node_reviews(opts) -> bool:
    """Whether the node behaviour review, its Stage A/B and the node obligations it upholds are in
    use: not under `feedback: labels`, where a node is accepted on its gate and its law is scored by
    the label check; the concept review is in use either way."""
    return getattr(opts, "feedback", "review") != "labels"


@dataclass
class Run:
    opts: Options
    iteration: int = 0
    accepted_nodes: dict[str, dict] = field(default_factory=dict)
    accepted_concepts: dict[str, dict] = field(default_factory=dict)
    base_nodes: dict[str, dict] = field(default_factory=dict)      # from `base_run`, read-only
    base_concepts: dict[str, dict] = field(default_factory=dict)
    deferred_nodes: list[dict] = field(default_factory=list)       # validated nodes held for a later iteration (a composed node, a concept under repair, a pause)
    deferred_concepts: list[dict] = field(default_factory=list)    # concepts coded and reviewed again next iteration (a deferred review, a pause)
    aggregate_failures: dict[str, int] = field(default_factory=dict)   # selection or verification failures per (definition, term) or aggregate id
    fenced: dict[str, dict] = field(default_factory=dict)   # node or concept versions no new record may use: id → {kind, reason, evidence, run, record, ...}
    fence_history: list[dict] = field(default_factory=list)  # fences of versions no longer in the effective view (a replaced record), kept as evidence
    provenance: dict[str, str] = field(default_factory=dict)   # an inherited record's id → the run that accepted it
    base_chain: list[str] = field(default_factory=list)       # the base runs, the oldest first
    rechecked: dict[str, str] = field(default_factory=dict)   # an inherited record's id → the context it was last found sound on
    pending_notices: list[str] = field(default_factory=list)  # operator notices from a loop start, delivered by the next iteration
    label_states: dict[str, dict] = field(default_factory=dict)   # with `label_repair`: each checked law's routed outcome and the check it rests on
    law_entries: Optional[dict] = None   # the live law ledger's entries (law ↦ entry), bound by the loop; else read from the ledger file

    @classmethod
    def load(cls, run_id: str) -> "Run":
        """A run as its `options.json` records it, with its accepted nodes and concepts loaded:
        what a command run outside the loop (the draft validator, the gate) works against. A library
        left in the middle of a candidate's commit is completed first by an owner, and refused to any
        other reader."""
        from ..phases import candidate
        if candidate.pending() is not None:               # a library in the middle of a commit is never read as a whole
            from . import owner
            if not owner.holds():
                raise SystemExit("the library holds a candidate transaction committed and not yet applied: any command that takes "
                                 "the library (the loop, verify, index) completes it first")
            candidate.recover_pending()
        f = paths.run_dir(run_id) / "options.json"
        if not f.exists():
            raise SystemExit(f"no run `{run_id}` under {paths.RESULTS}")
        d = json.loads(f.read_text(encoding="utf-8"))
        paths.register_roots(d.get("repo_roots"))
        fields = {k for k in Options.__dataclass_fields__}
        kw = {k: v for k, v in d.items() if k in fields}
        kw["laws"], kw["ontology"] = paths.local(d["laws"]), paths.local(d["ontology"])
        for k in ("definition_precedence", "model_prices"):
            if kw.get(k):
                kw[k] = paths.local(kw[k])
        kw["reading"] = paths.local(d.get("base_reading") or d["reading"])
        run = cls(Options(**kw))
        run.restore_state()
        run.load_accepted()
        return run

    @property
    def dir(self) -> Path:
        return paths.run_dir(self.opts.run_id)

    @property
    def iter(self) -> Path:
        return paths.iter_dir(self.opts.run_id, self.iteration)

    @property
    def reading_file(self) -> Path:
        """The run's reading: the operator's base reading plus the aggregates the run derived."""
        return self.dir / "reading.json"

    @property
    def rulings_file(self) -> Path:
        """The run's rulings: append-only, every review's, judge's and replay's."""
        return self.dir / "rulings.jsonl"

    @property
    def node_ledger_file(self) -> Path:
        """Nodes the gate or the review returned, awaiting a repair session or spent."""
        return self.dir / "node_ledger.jsonl"

    @property
    def state_file(self) -> Path:
        """The run's authoritative state: one snapshot, replaced atomically at every commit. The
        ledgers and the accepted records on disk are projections written from it after it."""
        return self.dir / "state.json"

    def load_state(self) -> dict | None:
        return jsonl.read_json(self.state_file, None)

    def restore_state(self) -> dict | None:
        """Rewrite the projections from the snapshot, so a commit cut short between the snapshot
        and its projections is completed before anything reads them; returns the snapshot."""
        snap = self.load_state()
        if snap is None:
            return None
        rows = lambda xs: "".join(json.dumps(x, ensure_ascii=False) + "\n" for x in xs)
        jsonl.write_atomic(self.ledger_file, rows(snap.get("ledger", [])))
        jsonl.write_atomic(self.concept_ledger_file, rows(snap.get("concept_ledger", [])))
        jsonl.write_atomic(self.node_ledger_file, rows(snap.get("node_ledger", [])))
        jsonl.write_atomic(self.accepted_file, rows(snap.get("accepted_nodes", {}).values()))
        jsonl.write_atomic(self.accepted_concepts_file, rows(snap.get("accepted_concepts", {}).values()))
        self.deferred_nodes = list(snap.get("deferred_nodes", []))
        self.deferred_concepts = list(snap.get("deferred_concepts", []))
        self.aggregate_failures = dict(snap.get("aggregate_failures", {}))
        self.fenced = fences_of(snap, self.opts.run_id)
        self.fence_history = list(snap.get("fence_history", []))
        self.rechecked = dict(snap.get("rechecked", {}))
        self.pending_notices = list(snap.get("pending_notices", []))
        self.label_states = dict(snap.get("label_states", {}))
        self.iteration = int(snap.get("iteration", 0))
        if snap.get("prog"):
            snap["prog"] = prog_paths(snap["prog"], paths.local)
        return snap

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

    @property
    def accepted_concepts_file(self) -> Path:
        return self.dir / "accepted_concepts.jsonl"

    @property
    def concept_ledger_file(self) -> Path:
        return self.dir / "concept_ledger.jsonl"

    @staticmethod
    def _load_jsonl(path: Path, key: str) -> dict[str, dict]:
        out: dict[str, dict] = {}
        if path.exists():
            for l in path.read_text(encoding="utf-8").splitlines():
                if l.strip():
                    d = json.loads(l); out[d[key]] = d
        return out

    def load_accepted(self) -> None:
        """This run's accepted nodes and concepts, and the effective view of its base chain
        (`base_view`). A base node of a law this run lists is not taken: the law is planned again.
        A base node that composes one not taken stops the run, since its law is not planned here.
        The base chain's fences are inherited; this run's own fences stand over them."""
        self.accepted_nodes = self._load_jsonl(self.accepted_file, "node_id")
        self.accepted_concepts = self._load_jsonl(self.accepted_concepts_file, "concept_id")
        if self.opts.base_run:
            view = base_view(self.opts.base_run, frozenset({self.opts.run_id}))
            listed = listed_laws(self.opts.laws)
            nodes = view["nodes"]
            self.base_nodes = {k: d for k, d in nodes.items() if d["law_refs"][0] not in listed}
            dropped = set(nodes) - set(self.base_nodes)
            broken = sorted(k for k, d in self.base_nodes.items() if {c.get("rule") for c in Node(d).dependencies()} & dropped)
            if broken:
                raise SystemExit(f"base run `{self.opts.base_run}`: node(s) {broken} compose a node of a law this run plans again "
                                 f"({sorted(dropped)}); list their laws too")
            self.inherit_declarations(enter=False)
            self.base_concepts = view["concepts"]
            self.provenance = {k: v for k, v in view["provenance"].items() if k in self.base_nodes or k in self.base_concepts}
            self.base_chain = view["chain"]
            for k, ev in view["fenced"].items():
                self.fenced.setdefault(k, ev)
            self.fence_history += [f for f in view["history"] if f not in self.fence_history]
        self.reconcile_fences()

    def inherit_declarations(self, enter: bool = True) -> None:
        """Every declared-fact id an inherited base node reads, checked against the reading with the
        meaning the node's record carries: a record with no meaning, or a meaning other than the
        reading's, stops the run, naming the id, both meanings and the nodes; no meaning is guessed.
        With `enter` (the loop's start only), an id the reading lacks is entered `proposed` as
        inherited."""
        from ..model.reading import Reading, same_meaning
        targets = [self.reading_file] + ([Path(self.opts.reading)] if getattr(self.opts, "reading", None) else [])
        have = Reading(self.reading_file).declarations()
        conflicts, enter_ids = [], {}
        for nid, d in sorted(self.base_nodes.items()):
            for x in (d.get("assumptions") or []) + (d.get("intentions") or []):
                if not isinstance(x, dict) or not x.get("id"):
                    continue
                cid, meaning = x["id"], x.get("meaning")
                known = have.get(cid) or enter_ids.get(cid)
                if not isinstance(meaning, str) or not meaning.strip():
                    conflicts.append(f"`{cid}` of `{nid}` carries no meaning")
                elif known is None:
                    enter_ids[cid] = {"id": cid, "meaning": meaning, "node": nid}
                elif not same_meaning(known.get("meaning"), meaning):
                    conflicts.append(f"`{cid}`: `{nid}` means {meaning!r}, the reading or `{known.get('node', 'the reading')}` {known.get('meaning')!r}")
        if conflicts:
            raise SystemExit(f"base run `{self.opts.base_run}`: declared ids inherited without one meaning: " + "; ".join(conflicts))
        for d in (enter_ids.values() if enter else []):
            for target in targets:
                Reading.add_declarations(target, [d], f"inherited {self.opts.base_run} {d['node']}")

    def _records(self) -> dict[str, dict]:
        return {**self.base_nodes, **self.base_concepts, **self.accepted_nodes, **self.accepted_concepts}

    def accepted_by(self, ident: str) -> str | None:
        """The run that accepted a record of the effective view: this run, or a run of its base chain."""
        if ident in self.accepted_nodes or ident in self.accepted_concepts:
            return self.opts.run_id
        return self.provenance.get(ident)

    def fence(self, ident: str, kind: str, reason: str, **fields) -> dict:
        """Fence the version of a record the effective view holds now: the fence names that version
        (`record`, its semantic digest) and the run that accepted it, so a replacement accepted later
        under the same id is not fenced by it."""
        rec = self._records().get(ident)
        f = {"kind": kind, "reason": reason, **fields, "run": self.opts.run_id,
             "record": record_digest(rec) if rec is not None else None, "accepted_by": self.accepted_by(ident)}
        self.fenced[ident] = f
        return f

    def reconcile_fences(self) -> list[str]:
        """Move every fence whose version is no longer the effective record of its id (the record was
        replaced, or left the view) to `fence_history`; returns the ids moved."""
        order = list(self.base_chain) + [self.opts.run_id]
        recs, moved = self._records(), []
        for ident, f in list(self.fenced.items()):
            if not fence_applies(f, recs.get(ident), self.accepted_by(ident), order):
                self.fence_history.append({**f, "id": ident})
                del self.fenced[ident]
                moved.append(ident)
        return moved

    def usable_nodes(self, for_law: str | None) -> dict[str, dict]:
        """The one rule of when a node may be composed (by a plan, a scheduled coding task, a registry
        entry a caller relies on): the accepted nodes (`all_nodes`) a node of law `for_law` may use.
        When a law's formal acceptance is the law's (`acceptance_by_law`), a node this run accepted on
        its gate is usable only by a node of its own law (a sibling, built in dependency order inside
        the pending law) until its law is `accepted`; an inherited node and a node of a law outside
        this run's ledger stay usable. Otherwise every accepted node is usable. Concepts are not
        governed here: an accepted concept is usable by every law. Generated nodes stay in
        `all_nodes` for the label check, integration and the library."""
        nodes = self.all_nodes()
        if not acceptance_by_law(self.opts):
            return nodes
        entries = self.law_entries
        if entries is None:
            from .ledger import Entry, _load
            entries = _load(self.ledger_file, Entry, "law")
        out = {}
        for nid, rec in nodes.items():
            law = Node(rec).law
            e = entries.get(law)
            if nid not in self.accepted_nodes or law == for_law or e is None or e.state == "accepted":
                out[nid] = rec
        return out

    def all_nodes(self) -> dict[str, dict]:
        """Accepted nodes the plan may compose: the base chain's, then this run's; a fenced version
        carries `fenced` (its reason and evidence)."""
        return self._annotated({**self.base_nodes, **self.accepted_nodes})

    def all_concepts(self) -> dict[str, dict]:
        """Accepted concepts: the base chain's, then this run's; a fenced version carries `fenced`
        (its reason and evidence), and no new record may claim it."""
        return self._annotated({**self.base_concepts, **self.accepted_concepts})

    def _annotated(self, records: dict[str, dict]) -> dict[str, dict]:
        """`records` with each fenced version's fence; read over a copy of the fences, which the loop's
        own thread may add to while a task's thread reads the view."""
        out = dict(records)
        for ident, ev in list(self.fenced.items()):
            if ident in out:
                out[ident] = {**out[ident], "fenced": ev}
        return out

    def save_accepted(self) -> None:
        jsonl.write_atomic(self.accepted_file, "".join(json.dumps(d, ensure_ascii=False) + "\n" for d in self.accepted_nodes.values()))
        jsonl.write_atomic(self.accepted_concepts_file, "".join(json.dumps(d, ensure_ascii=False) + "\n" for d in self.accepted_concepts.values()))

    def next_iteration(self) -> int:
        """The iteration after the last one the snapshot committed. A directory of that number holds
        nothing committed (the run stopped between allocating it and committing it): it is set aside
        as `_uncommitted-iter-NNN-<k>` and the number is used again, so the iteration bound counts
        only iterations that began. A run with no snapshot takes the number after its highest
        directory."""
        snap = self.load_state()
        if snap is None:
            existing = [int(p.name.split("-")[1]) for p in self.dir.glob("iter-*") if p.is_dir()]
            self.iteration = (max(existing) + 1) if existing else 1
        else:
            self.iteration = int(snap.get("iteration", 0)) + 1
            if self.iter.exists():
                k = 1
                while (self.dir / f"_uncommitted-iter-{self.iteration:03d}-{k}").exists():
                    k += 1
                self.iter.rename(self.dir / f"_uncommitted-iter-{self.iteration:03d}-{k}")
        self.iter.mkdir(parents=True, exist_ok=True)
        return self.iteration

    def read_notes(self) -> str:
        return self.auto_notes.read_text(encoding="utf-8") if self.auto_notes.exists() else "(first iteration: no feedback yet)\n"

    @property
    def hints_file(self) -> Path:
        return self.dir / "user_hints.json"

    def pin_hints(self) -> None:
        """Record the operator's hints (`USER_HINTS.md`) as a new run first reads them, with their
        digest: every later session of the run, on this machine or after a handoff, reads this record,
        never the file as it stands then. A file missing at that start is recorded as absent, with
        empty text. Only a new run (no committed snapshot yet) writes the record: a run that has one
        and lost its record stops (`DataIntegrityError`), the record never rebuilt from the file as it
        stands now nor as absent."""
        if self.hints_file.exists():
            return
        if self.state_file.exists():
            raise jsonl.DataIntegrityError(self.hints_file, None, "the run's pinned hints are missing; they are never recorded "
                                           "again after the run's start: restore this file from the run's checkpoint")
        import hashlib
        present = paths.USER_HINTS.is_file()
        text = paths.USER_HINTS.read_text(encoding="utf-8") if present else ""
        jsonl.write_atomic(self.hints_file, json.dumps({"present": present, "sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
                                                        "text": text}, ensure_ascii=False, indent=1))

    def read_hints(self) -> str:
        """The run's pinned hints (`pin_hints`); `(none)` when the file was absent at the run's start."""
        import hashlib
        self.pin_hints()
        try:
            d = json.loads(self.hints_file.read_text(encoding="utf-8"))
            ok = hashlib.sha256(str(d["text"]).encode("utf-8")).hexdigest() == d["sha256"]
        except (json.JSONDecodeError, KeyError, TypeError):
            ok = False
        if not ok:
            raise jsonl.DataIntegrityError(self.hints_file, None, "the pinned hints do not match their digest")
        return d["text"] if d.get("present") else "(none)\n"


def fences_of(snap: dict, run_id: str) -> dict[str, dict]:
    """A snapshot's fences, each naming the run that wrote it (the snapshot's run when it does not
    say). A snapshot written before fences had their own map holds the concept versions an
    adjudicated report found defective under `defective_concepts`: read as fences of reason
    `dependency_defect`."""
    out = {k: {"run": run_id, **dict(v)} for k, v in (snap.get("fenced") or {}).items()}
    for cid, ev in (snap.get("defective_concepts") or {}).items():
        out.setdefault(cid, {"kind": "concept", "reason": "dependency_defect", "run": run_id, **(ev if isinstance(ev, dict) else {"evidence": str(ev)})})
    return out


#: Record fields that are not what the record means: its recorded context, the accepted callers and
#: planned users other records add to it, its fence and its inheritance.
NOT_SEMANTIC = ("context", "callers", "used_by", "fenced", "provenance")


def record_digest(rec: dict) -> str:
    """The digest of what a record means, without the fields other records or the harness write onto it."""
    import hashlib
    return hashlib.sha256(json.dumps({k: v for k, v in rec.items() if k not in NOT_SEMANTIC}, sort_keys=True,
                                     ensure_ascii=False, default=str).encode()).hexdigest()


def fence_applies(fence: dict, rec: dict | None, accepted_by: str | None, order: list[str]) -> bool:
    """Whether a fence holds the effective record of its id: the record exists and is the version the
    fence names (`record`). A fence written before fences named their version holds unless a run
    after the fencing run (in the chain's order, `order`) accepted the record: a replacement."""
    if rec is None:
        return False
    if fence.get("record"):
        return fence["record"] == record_digest(rec)
    by, at = fence.get("run"), accepted_by
    if by in order and at in order:
        return order.index(at) <= order.index(by)
    return True


def chain_laws(run: Run) -> dict[str, "corpus.Law"]:
    """The posted laws of the base chain's corpora (each run's `options.json` names its laws file),
    the later run's text over the earlier's: where an inherited node's law is read from."""
    out: dict = {}
    for rid in getattr(run, "base_chain", []) or []:
        lf = (jsonl.read_json(paths.run_dir(rid) / "options.json", None) or {}).get("laws")
        if lf and paths.local(lf).exists():
            out.update({l.id: l for l in corpus.load_laws(paths.local(lf))})
    return out


def listed_laws(laws: Path | str | None) -> set[str]:
    """The law ids a run's corpus file lists (empty when the file is gone)."""
    return {l.id for l in corpus.load_laws(Path(laws))} if laws and Path(laws).exists() else set()


def base_view(run_id: str, seen: frozenset = frozenset()) -> dict:
    """The records a run holds for the runs that start from it: {"nodes", "concepts", "fenced",
    "provenance", "chain"}. It is built generation by generation down the `base_run` chain: the
    run's own subset exclusions (a base node of a law it lists is not taken) apply to its ancestors'
    records before its own acceptances are added, so a law a generation re-planned and did not
    replace stays out of every later one. Each run's records and fences are read from its committed
    snapshot (`state.json`), its projections only when it has none, and nothing of it is rewritten.
    A later run's record overrides an earlier one of the same id; every record names the run that
    accepted it; fences are inherited, a later run's standing over an earlier one's, and a fence holds
    only the version it names (`fence_applies`): one whose record was replaced is history. A cycle
    in the chain stops the run, and so does a run of the chain whose directory holds no
    `options.json`: its records cannot be read, and an empty view would pass for a complete one."""
    if run_id in seen:
        raise SystemExit(f"the base_run chain returns to `{run_id}`: {sorted(seen)}")
    d = paths.run_dir(run_id)
    if not (d / "options.json").exists():
        raise SystemExit(f"the base_run chain names `{run_id}`, but {d} holds no options.json: its records cannot be read")
    opts = jsonl.read_json(d / "options.json", None) or {}
    if opts.get("base_run"):
        view = base_view(opts["base_run"], seen | {run_id})
    else:
        view = {"nodes": {}, "concepts": {}, "fenced": {}, "history": [], "provenance": {}, "chain": []}
    listed = listed_laws(opts.get("laws"))
    nodes = {k: v for k, v in view["nodes"].items() if v["law_refs"][0] not in listed}
    snap = jsonl.read_json(d / "state.json", None) or {}
    # the committed snapshot is the authority; the projections stand only for a run without one
    own_nodes = dict(snap["accepted_nodes"]) if "accepted_nodes" in snap else Run._load_jsonl(d / "accepted_nodes.jsonl", "node_id")
    own_concepts = dict(snap["accepted_concepts"]) if "accepted_concepts" in snap else Run._load_jsonl(d / "accepted_concepts.jsonl", "concept_id")
    provenance = {k: v for k, v in view["provenance"].items() if k in nodes or k in view["concepts"]}
    provenance.update({k: run_id for k in list(own_nodes) + list(own_concepts)})
    nodes, concepts = {**nodes, **own_nodes}, {**view["concepts"], **own_concepts}
    order = view["chain"] + [run_id]
    history = list(view["history"]) + list(snap.get("fence_history", []))
    fenced = {}
    for k, f in {**view["fenced"], **fences_of(snap, run_id)}.items():   # a fence holds only the version it names
        if fence_applies(f, nodes.get(k) or concepts.get(k), provenance.get(k), order):
            fenced[k] = f
        else:
            history.append({**f, "id": k})
    return {"nodes": nodes, "concepts": concepts, "fenced": fenced, "history": history,
            "provenance": provenance, "chain": order}


#: The keys of an iteration's progress that hold task directories: a plan directory, and each repair's
#: directory by the concept or node it repaired.
PROG_PATHS = ("plan_dir",)
PROG_PATH_MAPS = ("repairs", "node_repairs")


def prog_paths(prog: dict, how) -> dict:
    """A copy of an iteration's progress with its task directories passed through `how`
    (`paths.stored` when saved, `paths.local` when read back)."""
    out = dict(prog)
    for k in PROG_PATHS:
        if out.get(k):
            out[k] = str(how(out[k]))
    for k in PROG_PATH_MAPS:
        if isinstance(out.get(k), dict):
            out[k] = {i: str(how(v)) if v else v for i, v in out[k].items()}
    return out


_COMMIT_LOCK = __import__("threading").Lock()


#: The fields of a run's snapshot (`commit_state` writes each one) with their types; `label_states`
#: and `prog` are written only once the run has them, so they are checked only when present.
SNAPSHOT_FIELDS = {"schema": int, "run_id": str, "iteration": int, "ledger": list, "concept_ledger": list, "node_ledger": list,
                   "accepted_nodes": dict, "accepted_concepts": dict, "deferred_nodes": list, "deferred_concepts": list,
                   "aggregate_failures": dict, "fenced": dict, "fence_history": list, "rechecked": dict, "pending_notices": list}
SNAPSHOT_OPTIONAL = {"label_states": dict, "prog": dict}


def snapshot_defects(snap, run_id: str) -> list[str]:
    """Why a snapshot is not one a resume may restore: not an object, a field missing or of the wrong
    type, another schema, or another run's. A complete snapshot whose collections are empty (a run's
    first commit) is whole; a partial one is never read as empty state."""
    if not isinstance(snap, dict):
        return ["it is not an object"]
    out = [f"`{k}` is missing" if k not in snap else f"`{k}` is not a {t.__name__}"
           for k, t in SNAPSHOT_FIELDS.items() if k not in snap or not isinstance(snap[k], t) or isinstance(snap[k], bool)]
    out += [f"`{k}` is not a {t.__name__}" for k, t in SNAPSHOT_OPTIONAL.items() if k in snap and not isinstance(snap[k], t)]
    if isinstance(snap.get("schema"), int) and snap["schema"] != 1:
        out.append(f"its schema is {snap['schema']}, not 1")
    if isinstance(snap.get("run_id"), str) and snap["run_id"] != run_id:
        out.append(f"it is run `{snap['run_id']}`'s, not `{run_id}`'s")
    if isinstance(snap.get("iteration"), int) and snap["iteration"] < 0:
        out.append("its iteration is negative")
    return out


def commit_state(run: Run, ledger, concept_ledger, node_ledger, prog: dict | None = None) -> None:
    """One commit: the snapshot first, replaced atomically, then its projections (the three
    ledgers and the accepted records). A process stopped between the two leaves a snapshot that
    `Run.restore_state` projects again; what the snapshot does not hold did not happen."""
    from dataclasses import asdict
    with _COMMIT_LOCK:
        snap = run.load_state() or {}
        from .ledger import _saved
        snap.update({"schema": 1, "run_id": run.opts.run_id, "iteration": run.iteration,
                     "ledger": [_saved(e) for e in ledger.entries.values()],
                     "concept_ledger": [_saved(e) for e in concept_ledger.entries.values()],
                     "node_ledger": [_saved(e) for e in node_ledger.entries.values()],
                     "accepted_nodes": run.accepted_nodes, "accepted_concepts": run.accepted_concepts,
                     "deferred_nodes": run.deferred_nodes, "deferred_concepts": run.deferred_concepts,
                     "aggregate_failures": run.aggregate_failures, "fenced": run.fenced,
                     "fence_history": run.fence_history, "rechecked": run.rechecked, "pending_notices": run.pending_notices})
        snap.pop("defective_concepts", None)
        if run.label_states:
            snap["label_states"] = run.label_states
        if prog is not None:
            snap["prog"] = prog_paths(prog, paths.stored)
        jsonl.write_atomic(run.state_file, json.dumps(snap, ensure_ascii=False))
        ledger.save(); concept_ledger.save(); node_ledger.save(); run.save_accepted()
