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
    session_retries: int = 2       # relaunches of a session that never ran (account limit, API error)
    retry_wait: float = 900.0      # seconds between those relaunches
    plan_batch: int = 8            # laws per plan session; a law is planned after the laws it names are accepted or in its batch
    workers: int = 1               # coding sessions run at once (concepts, then nodes, in dependency waves)
    plan_turns: int = 40           # turn cap for a plan or repair session (a coding session keeps `max_turns`)
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
        """This run's accepted nodes and concepts, and its base run's. A base node of a law this run
        lists is not taken: the law is planned again. A base node that composes one not taken stops
        the run, since its law is not planned here."""
        self.accepted_nodes = self._load_jsonl(self.accepted_file, "node_id")
        self.accepted_concepts = self._load_jsonl(self.accepted_concepts_file, "concept_id")
        if self.opts.base_run:
            base = paths.run_dir(self.opts.base_run)
            listed = {l.id for l in corpus.load_laws(self.opts.laws)} if Path(self.opts.laws).exists() else set()
            nodes = self._load_jsonl(base / "accepted_nodes.jsonl", "node_id")
            self.base_nodes = {k: d for k, d in nodes.items() if d["law_refs"][0] not in listed}
            dropped = set(nodes) - set(self.base_nodes)
            broken = sorted(k for k, d in self.base_nodes.items() if {c.get("rule") for c in d.get("compositions", [])} & dropped)
            if broken:
                raise SystemExit(f"base run `{self.opts.base_run}`: node(s) {broken} compose a node of a law this run plans again "
                                 f"({sorted(dropped)}); list their laws too")
            self.base_concepts = self._load_jsonl(base / "accepted_concepts.jsonl", "concept_id")

    def all_nodes(self) -> dict[str, dict]:
        """Accepted nodes the plan may compose: the base run's, then this run's."""
        return {**self.base_nodes, **self.accepted_nodes}

    def all_concepts(self) -> dict[str, dict]:
        """Accepted concepts the plan may use: the base run's, then this run's."""
        return {**self.base_concepts, **self.accepted_concepts}

    def save_accepted(self) -> None:
        jsonl.write_atomic(self.accepted_file, "".join(json.dumps(d, ensure_ascii=False) + "\n" for d in self.accepted_nodes.values()))
        jsonl.write_atomic(self.accepted_concepts_file, "".join(json.dumps(d, ensure_ascii=False) + "\n" for d in self.accepted_concepts.values()))

    def next_iteration(self) -> int:
        existing = [int(p.name.split("-")[1]) for p in self.dir.glob("iter-*") if p.is_dir()]
        self.iteration = (max(existing) + 1) if existing else 1
        self.iter.mkdir(parents=True, exist_ok=True)
        return self.iteration

    def read_notes(self) -> str:
        return self.auto_notes.read_text(encoding="utf-8") if self.auto_notes.exists() else "(first iteration: no feedback yet)\n"

    def read_hints(self) -> str:
        return paths.USER_HINTS.read_text(encoding="utf-8") if paths.USER_HINTS.exists() else "(none)\n"
