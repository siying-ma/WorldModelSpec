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
    concept_attempts: int = 3      # coding attempts per concept, the first plus its repairs
    node_attempts: int = 2         # coding attempts per node, the first plus one after a node repair session
    gate_budget: int = 6
    max_turns: int = 80
    session_timeout: float = 3600.0
    judge: bool = True
    dry_run: bool = False          # render prompts and run the deterministic phases, launch no session
    plan_effort: Optional[str] = "high"      # `claude --effort` for the plan session (low|medium|high|xhigh|max)
    code_effort: Optional[str] = "high"      # for each coding session
    judge_effort: Optional[str] = "medium"   # for the blind reader and the alignment judge
    session_budget_usd: Optional[float] = None   # `--max-budget-usd` per session; None = uncapped
    session_retries: int = 2       # relaunches of a session that never ran (account limit, API error)
    retry_wait: float = 900.0      # seconds between those relaunches
    plan_batch: int = 8            # laws per plan session; a law is planned after the laws it names are accepted or in its batch
    judge_samples: int = 1         # independent judge sessions per node review; every one must find the node aligned
    workers: int = 1               # coding sessions run at once (concepts, then nodes, in dependency waves)
    reader_model: Optional[str] = None   # the blind reader's model; None = the run's model
    plan_turns: int = 40           # turn cap for a plan or repair session (a coding session keeps `max_turns`)
    restart: bool = False          # discard an interrupted iteration instead of resuming it
    mode: str = "train"            # `train`: concepts may supersede; `test`: add-only over a base run
    base_run: Optional[str] = None # a run whose accepted nodes and concepts this run starts from, read-only


@dataclass
class Run:
    opts: Options
    iteration: int = 0
    accepted_nodes: dict[str, dict] = field(default_factory=dict)
    accepted_concepts: dict[str, dict] = field(default_factory=dict)
    base_nodes: dict[str, dict] = field(default_factory=dict)      # from `base_run`, read-only
    base_concepts: dict[str, dict] = field(default_factory=dict)

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
        kw["reading"] = Path(d.get("base_reading") or d["reading"])
        run = cls(Options(**kw))
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
    def deferred_file(self) -> Path:
        """Validated nodes waiting for a composed node to be accepted; coded in a later iteration without re-planning."""
        return self.dir / "deferred_nodes.jsonl"

    def load_deferred(self) -> list[dict]:
        if not self.deferred_file.exists():
            return []
        return [json.loads(l) for l in self.deferred_file.read_text(encoding="utf-8").splitlines() if l.strip()]

    def save_deferred(self, nodes: list[dict]) -> None:
        self.deferred_file.write_text("".join(json.dumps(d, ensure_ascii=False) + "\n" for d in nodes), encoding="utf-8")

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
        self.accepted_nodes = self._load_jsonl(self.accepted_file, "node_id")
        self.accepted_concepts = self._load_jsonl(self.accepted_concepts_file, "concept_id")
        if self.opts.base_run:
            base = paths.run_dir(self.opts.base_run)
            self.base_nodes = self._load_jsonl(base / "accepted_nodes.jsonl", "node_id")
            self.base_concepts = self._load_jsonl(base / "accepted_concepts.jsonl", "concept_id")

    def all_nodes(self) -> dict[str, dict]:
        """Accepted nodes the plan may compose: the base run's, then this run's."""
        return {**self.base_nodes, **self.accepted_nodes}

    def all_concepts(self) -> dict[str, dict]:
        """Accepted concepts the plan may use: the base run's, then this run's."""
        return {**self.base_concepts, **self.accepted_concepts}

    def save_accepted(self) -> None:
        self.accepted_file.write_text("".join(json.dumps(d, ensure_ascii=False) + "\n" for d in self.accepted_nodes.values()), encoding="utf-8")
        self.accepted_concepts_file.write_text("".join(json.dumps(d, ensure_ascii=False) + "\n" for d in self.accepted_concepts.values()), encoding="utf-8")

    def next_iteration(self) -> int:
        existing = [int(p.name.split("-")[1]) for p in self.dir.glob("iter-*") if p.is_dir()]
        self.iteration = (max(existing) + 1) if existing else 1
        self.iter.mkdir(parents=True, exist_ok=True)
        return self.iteration

    def read_notes(self) -> str:
        return self.auto_notes.read_text(encoding="utf-8") if self.auto_notes.exists() else "(first iteration: no feedback yet)\n"

    def read_hints(self) -> str:
        return paths.USER_HINTS.read_text(encoding="utf-8") if paths.USER_HINTS.exists() else "(none)\n"
