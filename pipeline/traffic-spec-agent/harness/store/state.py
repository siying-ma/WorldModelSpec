"""A run: its directories, options, notes files and iteration numbering."""
from __future__ import annotations
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from . import jsonl, paths
from ..model import corpus
from ..model.blueprint import Node

#: The run version this harness writes into a run's semantic inputs (`options.json` → `semantic` →
#: `run_version`). A run is read and resumed only by the version that started it: a change that makes
#: the records, their identities or the meaning of the saved options of earlier runs unsafe to
#: continue raises it, whether or not any digest changed. Version 3: a run has no feedback mode (a
#: gated node is accepted on its gate, its law by the label check when `label_repair` is on); a run of
#: another version, or one that records none, is never taken for this one.
RUN_VERSION = 3


def run_version_refusal(saved_semantic: dict | None) -> str | None:
    """Why a run whose saved semantic inputs are `saved_semantic` cannot be read or resumed by this
    harness, or None when it was started by this run version. A missing or unknown version is refused,
    never read as this one."""
    was = (saved_semantic or {}).get("run_version") if isinstance(saved_semantic, dict) else None
    if was == RUN_VERSION:
        return None
    return (f"it was started by harness run version {was if was is not None else '1 (recorded before run versions)'} and this "
            f"harness is version {RUN_VERSION}: a run is resumed only by the version that started it, and both stages of a split "
            "run (remote and local) run that same version — start a new run id (a fresh run), or resume from a checkout of the "
            "code the run started on")


def saved_version_refusal(run_dir: Path) -> str | None:
    """Why the run saved in `run_dir` was not started by this run version, read from its raw
    `options.json` before anything of it is loaded, recovered, restored or written; None when it was.
    Options that cannot be read, or that record no version, are refused."""
    f = Path(run_dir) / "options.json"
    try:
        saved = json.loads(f.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return "its options.json, which records the run version that started it, is missing"
    except (OSError, ValueError) as e:
        return f"its options.json cannot be read ({e})"
    if not isinstance(saved, dict):
        return "its options.json is not an object"
    why = run_version_refusal(saved.get("semantic"))
    return f"its options.json records that {why}" if why else None


def chain_version_refusal(base_run: str, run_id: str | None = None) -> str | None:
    """Why a `base_run` chain cannot be read by this harness: a run of the chain, read from its raw
    `options.json` before any of its records, that another run version started or whose options are
    missing or unreadable, or a chain that returns to a run; None when every run of the chain was
    started by this version. The whole chain is checked by version, never by which files a run holds."""
    seen = {run_id} if run_id else set()
    rid = base_run
    while rid:
        if rid in seen:
            return f"the base_run chain returns to `{rid}`"
        seen.add(rid)
        why = saved_version_refusal(paths.run_dir(rid))
        if why:
            return f"the base_run chain names `{rid}`: {why}"
        rid = json.loads((paths.run_dir(rid) / "options.json").read_text(encoding="utf-8")).get("base_run")
    return None


def stored_run_refusal(run_id: str) -> str | None:
    """Why the run `run_id`, read from its raw `options.json` and those of its base chain, cannot be
    read by this harness (`saved_version_refusal`, then `chain_version_refusal`), or None: what every
    command that reads or writes a stored run checks before it takes the library or reads anything
    else of the run."""
    d = paths.run_dir(run_id)
    why = saved_version_refusal(d)
    if why is None:
        base = json.loads((d / "options.json").read_text(encoding="utf-8")).get("base_run")
        why = chain_version_refusal(base, run_id) if base else None
    return why


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
    reviewer_model: Optional[str] = None   # a second vendor's model for the concept review (required)
    review_effort: Optional[str] = "high"  # the reviewer's reasoning effort
    aggregate_verifier_model: Optional[str] = None     # the second vendor's model that verifies an aggregate mapping (required)
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
    model_prices: Optional[Path] = None            # the operator's price table (default config/model_prices.json)
    review_checks: int = 8                         # check calls of one reviewer session (each runs one divergence through Core)
    review_submissions: int = 3                    # submissions of one reviewer session; the last one stands
    force_takeover: bool = False                   # end the live child process groups an earlier owner of the library left, instead of refusing
    label_repair: bool = False                     # check each law whose plan is gated on the training recordings inside the loop and route its outcome (off: a gated node is accepted, and the library is only scored after the run)
    label_dataset: Optional[str] = None            # the training recordings the in-loop label check reads (required with `label_repair`)
    label_repair_attempts: int = 2                 # label repairs per law (a re-planned law keeps its count); each session call of one, its re-ask included, is capped by `repair_budget_usd`, and its planner and coder sessions by `session_budget_usd`
    label_deferred: bool = False                   # with `label_repair`: no training recording is read on this machine; a law whose plan is gated is kept, not accepted, and recorded `awaiting_labels` for a later launch with the recordings
    label_stage: bool = False                      # with `label_repair`: this launch only checks laws on the training recordings and repairs them; it plans and codes nothing new
    label_repair_budget: int = 10                  # label repairs over the whole run, all laws together (a count, not an amount: the run's spending limits still bound every session)
    dependency: str = "build_usable_v1"            # the cross-law dependency policy (`DEPENDENCY_POLICY`), declared by the code: fixed for the run's life


#: The cross-law dependency policy this harness implements: a node of one law may compose another
#: law's node once that node is usable for building (`Run.provider_code`), whatever the formal
#: acceptance of its law; a law's acceptance is checked on the usability of everything it reaches.
DEPENDENCY_POLICY = "build_usable_v1"

#: The fields of a run's acceptance policy (whether a law is accepted by its label check, and the
#: dependency policy its generation follows), each with the test of a legal saved value: a saved contract holds every
#: one, explicitly, with a legal value; a missing field is never filled by a default.
POLICY_FIELDS = {"label_repair": lambda v: isinstance(v, bool), "dependency": lambda v: v == DEPENDENCY_POLICY}


def policy_defects(saved) -> list[str]:
    """Why a saved acceptance policy (a run's saved options, or the policy a handoff recorded) is not
    whole: a field missing, or a value of the wrong type or not legal. Nothing is filled by default."""
    if not isinstance(saved, dict):
        return ["it is not an object"]
    return [f"`{k}` is missing" if k not in saved else f"`{k}` is {saved[k]!r}, not a legal value"
            for k, legal in POLICY_FIELDS.items() if k not in saved or not legal(saved[k])]


def acceptance_policy(opts) -> dict:
    """What decides how a run's laws are accepted, from a launch's
    options or a saved contract: the policy fields `opts` holds, as it holds them. A field it lacks is
    left out, never filled, so `policy_defects` reports it missing; fixed for the run's life."""
    if isinstance(opts, dict):
        return {k: opts[k] for k in POLICY_FIELDS if k in opts}
    return {k: getattr(opts, k) for k in POLICY_FIELDS if hasattr(opts, k)}


def acceptance_policy_refusal(fixed, opts) -> str | None:
    """The one check of a run's acceptance policy: why a launch with options `opts` may not continue a
    run whose policy is `fixed` (its saved options, or the policy a handoff recorded), or None. Both
    sides must be whole (`policy_defects`) before they are compared: a side that is not is refused,
    never completed by a default or coerced. Any change is refused, a value of another type included
    (`1` is not `True`): a run accepts its laws on one policy, and another policy is a new run. Which
    stage a launch runs (`label_deferred`, `label_stage`), its dataset and its budgets are not part of it."""
    if fixed is None:
        return None
    bad = policy_defects(fixed)
    if bad:
        return "the run's saved acceptance policy is not whole (" + "; ".join(bad) + "); restore its checkpoint, or start a new run id"
    was, now = acceptance_policy(fixed), acceptance_policy(opts)
    bad = policy_defects(now)
    if bad:
        return "the options' acceptance policy is not whole (" + "; ".join(bad) + "); give each field a legal value"
    changed = sorted(k for k in POLICY_FIELDS if type(was[k]) is not type(now[k]) or was[k] != now[k])
    if not changed:
        return None
    return ("the run's acceptance policy is fixed for its life (" + ", ".join(f"{k}: {was.get(k)!r} → {now.get(k)!r}" for k in changed)
            + "); start a new run id")


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
        f = paths.run_dir(run_id) / "options.json"
        if not f.exists():
            raise SystemExit(f"no run `{run_id}` under {paths.RESULTS}")
        why = saved_version_refusal(f.parent)              # its raw version, before anything is recovered, restored or written
        d = json.loads(f.read_text(encoding="utf-8")) if why is None else {}
        why = why or (chain_version_refusal(d["base_run"], run_id) if d.get("base_run") else None)
        bad = policy_defects(d) if why is None else []
        if bad:                                            # the policy the run was started on, read raw: never completed
            why = "its options.json holds no whole acceptance policy (" + "; ".join(bad) + ")"
        if why:
            raise SystemExit(f"run `{run_id}` cannot be read by this harness: {why} — nothing of it was read or rewritten")
        if candidate.pending() is not None:               # a library in the middle of a commit is never read as a whole
            from . import owner
            if not owner.holds():
                raise SystemExit("the library holds a candidate transaction committed and not yet applied: any command that takes "
                                 "the library (the loop, verify, index) completes it first")
            candidate.recover_pending()
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
        """Nodes the gate returned, awaiting a repair session or spent."""
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

    def usable_nodes(self, for_law: str | None, **view) -> dict[str, dict]:
        """The one rule of when a node may be composed (by a plan, a scheduled coding task, a registry
        entry a caller relies on): the published nodes (`all_nodes`) whose `provider_code` for a node
        of `for_law` is `USABLE` (`for_law` None: a caller of no law). A fenced or superseded node, one
        whose law waits for the operator or is planned again, and one without admission evidence are
        left out; a law's formal acceptance plays no part. `view` as `Availability` takes it."""
        av = Availability(self, **view)
        return {nid: rec for nid, rec in self.all_nodes().items() if av.code(nid, for_law) == USABLE}

    def provider_code(self, nid: str, for_law: str | None, **view) -> str:
        """Whether node `nid` may be used to build a node of `for_law` (`USABLE`), or why not: the code
        of `Availability.code`, computed from the run's state as it is now (`view` as
        `Availability` takes it)."""
        return Availability(self, **view).code(nid, for_law)

    @property
    def admission_file(self) -> Path:
        """The admission evidence of the run's records (`integrate.admission_recheck`)."""
        return self.dir / "admission.json"

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


# ---------------------------------------------------------------------------------------------
# Build usability: whether one record may be used to build another, apart from formal acceptance
# ---------------------------------------------------------------------------------------------
USABLE, OPERATOR, REPLANNING, FENCED, SUPERSEDED, UNPUBLISHED, MISSING, UNJUDGED = (
    "usable", "operator", "replanning", "fenced", "superseded", "unpublished", "missing", "unjudged")
#: A record composing another law's node whose pin (`planned_on`) is not that node's current record.
PIN_MISMATCH = "pin_mismatch"
#: Codes that end only by the operator (`OPERATOR`, a fenced node), by the planner (`SUPERSEDED`,
#: `MISSING`), or by waiting for generation, a publication or a later admission check.
WAITING_CODES = (UNPUBLISHED, REPLANNING, UNJUDGED)
PLANNER_CODES = (SUPERSEDED, MISSING, PIN_MISMATCH)


def base_code(code: str) -> str:
    """The code of a dependency's own unavailability, without its `via:<id>:` prefixes."""
    return code.rsplit(":", 1)[-1]


class Availability:
    """Whether a node may be used to build a node of a given law: one pure computation over a run's
    state as it is now (its view of nodes and concepts, its fences, its live law ledger, its base
    records and the admission evidence on disk), with what it computed kept only for its own life.
    It reads no model, recording or label, so another clone of the run gives the same codes.

    `code(nid, for_law)` decides, in this order, with no caller exempt:
    1. the owner law (from the record, else from the id) is in the ledger and blocked or failed:
       `OPERATOR`; open or returned: `REPLANNING`;
    2. owner planned or accepted: `FENCED` when the node is fenced; `SUPERSEDED` when it is published
       but not in the owner's current plan (`nodes`); not published: `UNPUBLISHED` when the plan
       lists it, else `MISSING`;
    3. owner outside the ledger (an inherited node, a law the run does not list): `MISSING` when not
       published, `FENCED` when fenced;
    4. its closure: every node it composes and every concept it calls, directly or through others,
       through the same rules (a concept fenced or not published is `FENCED`); the first that is not
       `USABLE` gives its code with the prefix `via:<id>:`; a node fenced only for composing a fenced
       node names that node the same way;
    5. `UNJUDGED` without admission evidence: a verdict `OK` in the admission file under the record's
       current admission key, or, in the view a caller gives, a gate passed within it (`gated`).
    The one exemption: `siblings`, the records of the current iteration whose gate passed and which
    are not yet published, count as published for a node of their own law (after steps 1–2), never
    for another law's (`UNPUBLISHED`)."""

    def __init__(self, run, *, siblings: dict[str, dict] | None = None, gated=(), entries: dict | None = None):
        self.run = run
        self.siblings = dict(siblings or {})
        self.gated = set(gated) | set(getattr(run, "gated_ids", None) or ())   # a transaction's records its own gates passed
        if entries is None:
            entries = run.law_entries
        if entries is None:
            from .ledger import Entry, _load
            entries = _load(run.ledger_file, Entry, "law")
        self.entries = entries
        self.nodes, self.concepts = run.all_nodes(), run.all_concepts()
        self.fenced = dict(run.fenced)
        self._memo: dict = {}
        self._keys: dict = {}
        self._cache = None
        self._key_inputs = None

    # -- admission evidence ------------------------------------------------------------------------
    def admission(self) -> dict:
        if self._cache is None:
            from ..phases.integrate import read_admission
            self._cache = read_admission(self.run)
        return self._cache

    def evidence(self, kind: str, ident: str) -> bool:
        """Whether the record has admission evidence: a gate passed within this view (`gated`), or a
        verdict `OK` in the admission file under its admission key as the run holds it now."""
        if ident in self.gated:
            return True
        hit = self.admission().get(ident)
        if not isinstance(hit, dict) or hit.get("verdict") != "OK":
            return False
        if ident not in self._keys:
            from ..phases import integrate
            if self._key_inputs is None:
                from ..model.reading import Reading
                base = getattr(self.run, "base", None)
                if not base:
                    from ..loop import semantic_inputs
                    sem = semantic_inputs(self.run.opts)
                    base = {"core": sem["core"], "ontology": sem["ontology"]}
                self._key_inputs = (Reading(self.run.reading_file), base, integrate.gate_digest())
            reading, base, gd = self._key_inputs
            try:
                self._keys[ident] = integrate.admission_key(self.run, kind, ident, reading, base, gate_value=gd)
            except (ValueError, KeyError, OSError):
                self._keys[ident] = None
        return self._keys[ident] is not None and hit.get("key") == self._keys[ident]

    # -- codes -------------------------------------------------------------------------------------
    def concept_code(self, cid: str, seen: frozenset = frozenset()) -> str:
        if cid in self._memo:
            return self._memo[cid]
        if cid in seen:
            return USABLE                                  # visited: each record is still judged once
        rec = self.concepts.get(cid)
        if rec is None or cid in self.fenced:
            code = FENCED
        else:
            from ..model.blueprint import ConceptRecord
            from ..model.nodeid import is_concept_id
            code = USABLE
            for r in sorted(ConceptRecord(rec).refs()):
                if is_concept_id(r):                       # a primitive of the ontology is no record
                    c = self.concept_code(r, seen | {cid})
                    if c != USABLE:
                        code = f"via:{r}:{c}"
                        break
            if code == USABLE and not self.evidence("concept", cid):
                code = UNJUDGED
        self._memo[cid] = code
        return code

    def _fenced(self, nid: str, for_law: str | None, seen: frozenset) -> str:
        """A fenced node's code: a node fenced only for composing a fenced node (reason `dependency`)
        names that provider (`via:<provider>:`), so the code ends at the record the fence comes from."""
        p = self.fenced[nid].get("provider")
        if self.fenced[nid].get("reason") == "dependency" and isinstance(p, str) and p in self.nodes and (p, None) not in seen:
            pc = self.code(p, for_law, seen | {(nid, None)})
            if pc != USABLE:
                return f"via:{p}:{pc}"
        return FENCED

    def code(self, nid: str, for_law: str | None, seen: frozenset = frozenset()) -> str:
        from ..model import nodeid
        rec = self.nodes.get(nid)
        sibling = self.siblings.get(nid) if rec is None else None
        owner = Node(rec or sibling).law if (rec or sibling) else nodeid.law_of(nid)[0]
        same = owner == for_law
        key = (nid, same)
        if key in self._memo:
            return self._memo[key]
        if (nid, None) in seen:
            return USABLE
        e = self.entries.get(owner)
        code, evidence_given = None, False
        if e is not None:
            if e.state in ("blocked", "failed"):
                code = OPERATOR
            elif e.state in ("open", "returned"):
                code = REPLANNING
            elif nid in self.fenced:
                code = self._fenced(nid, for_law, seen)
            elif rec is not None and nid not in e.nodes:
                code = SUPERSEDED
            elif rec is None:
                if sibling is not None and same and nid in e.nodes:
                    rec, evidence_given = sibling, True
                else:
                    code = UNPUBLISHED if nid in e.nodes else MISSING
        elif rec is None:
            code = MISSING
        elif nid in self.fenced:
            code = self._fenced(nid, for_law, seen)
        if code is None:
            code = USABLE
            n = Node(rec)
            for c in n.dependencies():
                r = c.get("rule")
                if not isinstance(r, str) or not r:
                    continue
                dc = self.code(r, for_law, seen | {(nid, None)})
                if dc != USABLE:
                    code = f"via:{r}:{dc}"
                    break
            if code == USABLE:
                for cid in sorted(n.claimed_concepts()):
                    cc = self.concept_code(cid)
                    if cc != USABLE:
                        code = f"via:{cid}:{cc}"
                        break
            if code == USABLE and not evidence_given and not self.evidence("node", nid):
                code = UNJUDGED
        self._memo[key] = code
        return code


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
#: planned users other records add to it, its fence, its inheritance, and the versions of other laws'
#: records it was planned on (`planned_on`).
NOT_SEMANTIC = ("context", "callers", "used_by", "fenced", "provenance", "planned_on")


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
    bad = policy_defects(opts)
    if bad:                                              # every run of the chain was built on the same, whole policy
        raise SystemExit(f"the base_run chain names `{run_id}`, whose options.json holds no whole acceptance policy ("
                         + "; ".join(bad) + "): its records were not built on this harness's dependency policy")
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
