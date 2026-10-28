"""A run: its directories, options, notes files and iteration numbering."""
from __future__ import annotations
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from . import jsonl, paths
from ..model import corpus


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
    session_budget_usd: Optional[float] = None   # `--max-budget-usd` per session; None = uncapped
    session_retries: int = 2       # relaunches per task and attempt of a session that did not run or was cut off
    retry_wait: float = 900.0      # seconds between those relaunches
    plan_batch: int = 8            # laws per plan session; a law is planned after the laws it names are accepted or in its batch
    workers: int = 1               # coding sessions run at once (concepts, then nodes, in dependency waves)
    plan_turns: int = 80           # turn cap for a plan or repair session (a coding session keeps `max_turns`)
    restart: bool = False          # discard an interrupted iteration instead of resuming it
    reviewer_model: Optional[str] = None   # a second vendor's model for the behaviour review, every node's acceptance check (required)
    review_effort: Optional[str] = "high"  # the reviewer's reasoning effort
    allow_same_vendor: bool = False        # permit a reviewer from the planner's own vendor
    mode: str = "train"            # `train`: concepts may supersede; `test`: add-only over a base run
    base_run: Optional[str] = None # a run whose accepted nodes and concepts this run starts from, read-only
    definition_precedence: Optional[Path] = None   # the operator's declared definition precedence (default config/definition_precedence.json)
    openai_budget_usd: Optional[float] = None      # the run-wide limit on the second vendor's calls; reached, the run pauses (`paused_budget`)
    reviewer_max_output_tokens: int = 64000        # the output-token limit of every OpenAI call, reasoning included
    max_divergences: int = 3                       # the most divergences one reviewer answer may carry
    model_prices: Optional[Path] = None            # the operator's price table (default config/model_prices.json)
    review_checks: int = 8                         # check calls of one reviewer session (each runs one divergence through Core)
    review_submissions: int = 3                    # submissions of one reviewer session; the last one stands
    review_passes: int = 2                         # independent reviewer sessions per rule review, their challenges joined
    force_takeover: bool = False                   # end the live child process groups an earlier owner of the library left, instead of refusing


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

    @classmethod
    def load(cls, run_id: str) -> "Run":
        """A run as its `options.json` records it, with its accepted nodes and concepts loaded:
        what a command run outside the loop (the draft validator, the gate) works against."""
        f = paths.run_dir(run_id) / "options.json"
        if not f.exists():
            raise SystemExit(f"no run `{run_id}` under {paths.RESULTS}")
        d = json.loads(f.read_text(encoding="utf-8"))
        fields = {k for k in Options.__dataclass_fields__}
        kw = {k: v for k, v in d.items() if k in fields}
        kw["laws"], kw["ontology"] = Path(d["laws"]), Path(d["ontology"])
        for k in ("definition_precedence", "model_prices"):
            if kw.get(k):
                kw[k] = Path(kw[k])
        kw["reading"] = Path(d.get("base_reading") or d["reading"])
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
        self.iteration = int(snap.get("iteration", 0))
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
            broken = sorted(k for k, d in self.base_nodes.items() if {c.get("rule") for c in d.get("compositions", [])} & dropped)
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

    def all_nodes(self) -> dict[str, dict]:
        """Accepted nodes the plan may compose: the base chain's, then this run's; a fenced version
        carries `fenced` (its reason and evidence)."""
        return self._annotated({**self.base_nodes, **self.accepted_nodes})

    def all_concepts(self) -> dict[str, dict]:
        """Accepted concepts: the base chain's, then this run's; a fenced version carries `fenced`
        (its reason and evidence), and no new record may claim it."""
        return self._annotated({**self.base_concepts, **self.accepted_concepts})

    def _annotated(self, records: dict[str, dict]) -> dict[str, dict]:
        out = dict(records)
        for ident, ev in self.fenced.items():
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

    def read_hints(self) -> str:
        return paths.USER_HINTS.read_text(encoding="utf-8") if paths.USER_HINTS.exists() else "(none)\n"


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
        if lf and Path(lf).exists():
            out.update({l.id: l for l in corpus.load_laws(Path(lf))})
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


_COMMIT_LOCK = __import__("threading").Lock()


def commit_state(run: Run, ledger, concept_ledger, node_ledger, prog: dict | None = None) -> None:
    """One commit: the snapshot first, replaced atomically, then its projections (the three
    ledgers and the accepted records). A process stopped between the two leaves a snapshot that
    `Run.restore_state` projects again; what the snapshot does not hold did not happen."""
    from dataclasses import asdict
    with _COMMIT_LOCK:
        snap = run.load_state() or {}
        snap.update({"schema": 1, "run_id": run.opts.run_id, "iteration": run.iteration,
                     "ledger": [asdict(e) for e in ledger.entries.values()],
                     "concept_ledger": [asdict(e) for e in concept_ledger.entries.values()],
                     "node_ledger": [asdict(e) for e in node_ledger.entries.values()],
                     "accepted_nodes": run.accepted_nodes, "accepted_concepts": run.accepted_concepts,
                     "deferred_nodes": run.deferred_nodes, "deferred_concepts": run.deferred_concepts,
                     "aggregate_failures": run.aggregate_failures, "fenced": run.fenced,
                     "fence_history": run.fence_history, "rechecked": run.rechecked, "pending_notices": run.pending_notices})
        snap.pop("defective_concepts", None)
        if prog is not None:
            snap["prog"] = prog
        jsonl.write_atomic(run.state_file, json.dumps(snap, ensure_ascii=False))
        ledger.save(); concept_ledger.save(); node_ledger.save(); run.save_accepted()
