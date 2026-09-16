"""Task and result types for the autoformalization loop.

A `SpecNode` is one unit of planned work: one traffic-law clause (or one clause
of a decomposed clause) to be formalized as one rule file. A `SpecNodeTask`
wraps it with the runtime paths and model settings for a single Claude session.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

IDENT_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")


@dataclass
class ScenarioSpec:
    """One declared scenario, written by the plan agent from the law text.

    `role` says what job the scenario does, and the three are not
    interchangeable — see `plan_validate.SCENARIO_ROLES`. It defaults to empty
    here rather than being required, because this dataclass also reads
    `node_spec.json` files written before the field existed; requiring it is
    `plan_validate`'s business, and that runs on new plans only.
    """

    name: str
    expected: bool
    description: str = ""
    role: str = ""

    @staticmethod
    def from_dict(d: dict) -> "ScenarioSpec":
        return ScenarioSpec(
            name=str(d["name"]),
            expected=bool(d["expected"]),
            description=str(d.get("description", "")),
            role=str(d.get("role", "")),
        )

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "role": self.role,
            "expected": self.expected,
            "description": self.description,
        }


@dataclass
class SpecNode:
    """One planned rule, as emitted by the plan agent in objectives.jsonl."""

    node_id: str            # "<theme>/<slug>", e.g. "Following/R0001_following_distance"
    theme: str              # Lean-identifier-safe, e.g. "Following"
    slug: str               # Lean-identifier-safe, e.g. "R0001_following_distance"
    law_refs: list[str]     # ids into laws/<jurisdiction>/laws.jsonl
    description: str        # what this node must capture, in the planner's words
    binders: list[str]      # binder labels, e.g. ["v", "w"]
    scenarios: list[ScenarioSpec]
    notes: str = ""         # formalization guidance / decomposition rationale
    parent: Optional[str] = None   # node_id this was decomposed from

    @property
    def target_file(self) -> str:
        return f"TrafficSpec/Rules/{self.theme}/{self.slug}.lean"

    @property
    def module(self) -> str:
        return f"TrafficSpec.Rules.{self.theme}.{self.slug}"

    @property
    def namespace(self) -> str:
        return f"TrafficSpec.Rules.{self.theme}.{self.slug_namespace}"

    @property
    def witness_file(self) -> str:
        """Where this node's acceptance witnesses go.

        A separate file under a separate library root. The rule file is the
        specification and is what an application loads; the witnesses are
        evidence about it, produced once and read by the gate. Mirroring the
        rule's path keeps the pairing derivable rather than registered.
        """
        return f"TrafficSpecWitness/{self.theme}/{self.slug}.lean"

    @property
    def witness_module(self) -> str:
        return f"TrafficSpecWitness.{self.theme}.{self.slug}"

    @property
    def witness_namespace(self) -> str:
        return f"TrafficSpecWitness.{self.theme}.{self.slug_namespace}"

    @property
    def slug_namespace(self) -> str:
        """Namespace segment for the slug.

        A slug like `R0001_following_distance` names the file, but the Lean
        namespace uses just the leading identifier (`R0001`) so declarations
        read `Rules.Following.R0001.entry`. Slugs without an underscore use the
        whole slug.
        """
        return self.slug.split("_", 1)[0]

    @property
    def sanitized(self) -> str:
        """Filesystem-safe name for the per-node artifact directory."""
        return re.sub(r"[^A-Za-z0-9_]", "_", self.node_id)

    @staticmethod
    def from_dict(d: dict) -> "SpecNode":
        return SpecNode(
            node_id=str(d["node_id"]),
            theme=str(d["theme"]),
            slug=str(d["slug"]),
            law_refs=[str(x) for x in d.get("law_refs", [])],
            description=str(d.get("description", "")),
            binders=[str(x) for x in d.get("binders", [])],
            scenarios=[ScenarioSpec.from_dict(s) for s in d.get("scenarios", [])],
            notes=str(d.get("notes", "")),
            parent=(str(d["parent"]) if d.get("parent") else None),
        )

    def to_dict(self) -> dict:
        return {
            "node_id": self.node_id,
            "theme": self.theme,
            "slug": self.slug,
            "law_refs": self.law_refs,
            "description": self.description,
            "binders": self.binders,
            "scenarios": [s.to_dict() for s in self.scenarios],
            "notes": self.notes,
            "parent": self.parent,
            # Derived, included so the agent and the gate read identical values
            # rather than each re-deriving them.
            "target_file": self.target_file,
            "module": self.module,
            "namespace": self.namespace,
            "witness_file": self.witness_file,
            "witness_module": self.witness_module,
            "witness_namespace": self.witness_namespace,
        }


@dataclass
class SpecNodeTask:
    """Runtime handle for one coding session."""

    node: SpecNode
    library_root: Path
    task_dir: Path              # results/<run>/nodes/<sanitized>/
    prompts_dir: Path
    laws_file: Path

    max_turns: int = 60
    timeout_minutes: Optional[float] = 45
    model: Optional[str] = None
    effort: Optional[str] = None
    max_budget_usd: Optional[float] = None
    task_id: str = field(default="")

    def __post_init__(self) -> None:
        self.library_root = Path(self.library_root).resolve()
        self.task_dir = Path(self.task_dir).resolve()
        self.prompts_dir = Path(self.prompts_dir).resolve()
        self.laws_file = Path(self.laws_file).resolve()
        if not self.task_id:
            stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            self.task_id = f"spec_{self.node.sanitized}_{stamp}"

    # ── derived paths ──────────────────────────────────────────────────
    @property
    def target_path(self) -> Path:
        return self.library_root / self.node.target_file

    @property
    def witness_path(self) -> Path:
        return self.library_root / self.node.witness_file

    @property
    def node_spec_file(self) -> Path:
        return self.task_dir / "node_spec.json"

    @property
    def progress_file(self) -> Path:
        return self.task_dir / "progress.jsonl"

    @property
    def baseline_file(self) -> Path:
        return self.task_dir / "baseline.json"

    @property
    def snapshot_file(self) -> Path:
        """Pre-session content of the target file, for integrate-time rollback.

        Absent when the target file did not exist before this session, which is
        the signal to delete rather than restore on rollback.
        """
        return self.task_dir / "target_snapshot.lean"

    @property
    def witness_snapshot_file(self) -> Path:
        """Pre-session content of the witness file, on the same terms.

        A node is two files, so a rollback that restores only one leaves the
        library in a state no session produced: the rule gone and its witness
        still there, orphaned. That orphan is not inert — it enters the scope
        baseline of every node that runs after it, which is how a run once
        recovered from a scope defect by accident instead of failing cleanly.
        """
        return self.task_dir / "witness_snapshot.lean"

    @property
    def verdict_file(self) -> Path:
        return self.task_dir / "verdict.json"

    @property
    def report_file(self) -> Path:
        return self.task_dir / "node_report.json"

    @property
    def raw_stream_file(self) -> Path:
        return self.task_dir / "claude_raw.jsonl"

    @property
    def harness_file(self) -> Path:
        return self.task_dir / "harness.lean"

    @property
    def result_file(self) -> Path:
        return self.task_dir / "result.json"


@dataclass
class SpecNodeResult:
    """Outcome of one coding session plus its integration."""

    task_id: str
    node_id: str
    verdict: str                    # last verdict from check_spec.py
    accepted: bool                  # passed the gate AND integrated cleanly
    start_time: datetime
    end_time: datetime
    attempts: int = 0               # check_spec.py invocations
    scenarios_declared: int = 0
    scenarios_passed: int = 0
    blockers: list[str] = field(default_factory=list)
    suggest_decompose: list[str] = field(default_factory=list)
    missing_vocab: list[str] = field(default_factory=list)
    error_message: Optional[str] = None
    terminal_reason: Optional[str] = None
    cost_usd: float = 0.0
    input_tokens: int = 0
    output_tokens: int = 0
    cache_read_tokens: int = 0
    cache_creation_tokens: int = 0

    @property
    def duration_seconds(self) -> float:
        return (self.end_time - self.start_time).total_seconds()

    @property
    def total_input_tokens(self) -> int:
        return self.input_tokens + self.cache_read_tokens + self.cache_creation_tokens

    def to_dict(self) -> dict[str, Any]:
        return {
            "task_id": self.task_id,
            "node_id": self.node_id,
            "verdict": self.verdict,
            "accepted": self.accepted,
            "success": self.accepted,   # resume reads this key
            "attempts": self.attempts,
            "scenarios_declared": self.scenarios_declared,
            "scenarios_passed": self.scenarios_passed,
            "blockers": self.blockers,
            "suggest_decompose": self.suggest_decompose,
            "missing_vocab": self.missing_vocab,
            "duration_seconds": self.duration_seconds,
            "start_time": self.start_time.isoformat(),
            "end_time": self.end_time.isoformat(),
            "error_message": self.error_message,
            "terminal_reason": self.terminal_reason,
            "cost_usd": self.cost_usd,
            "input_tokens": self.input_tokens,
            "output_tokens": self.output_tokens,
            "cache_read_tokens": self.cache_read_tokens,
            "cache_creation_tokens": self.cache_creation_tokens,
            "total_input_tokens": self.total_input_tokens,
        }
