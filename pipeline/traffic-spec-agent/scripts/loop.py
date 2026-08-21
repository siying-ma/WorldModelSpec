"""The autoformalization loop: plan → validate → code → integrate, repeated.

Each iteration is self-contained: it plans a small batch of rules, writes them,
and either lands them or reverts them. Nothing blocks the loop — every failure
becomes a typed note the next plan phase consumes, which is what lets a run go
unattended.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

from . import index_sync, plan_validate
from .phases import CodePhase, IntegratePhase, PlanPhase
from .state import (
    LoopContext,
    LoopOptions,
    append_log,
    init_state_dir,
    next_iter_num,
    read_stage,
)
from .task import SpecNodeResult

PHASE_ORDER = ("plan", "code", "integrate")


@dataclass
class IterationSummary:
    iter_num: int
    stage: str
    planned: int = 0
    accepted: int = 0
    integrated: list[str] = field(default_factory=list)
    reverted: list[str] = field(default_factory=list)
    plan_errors: list[str] = field(default_factory=list)
    verdicts: dict[str, str] = field(default_factory=dict)
    cost_usd: float = 0.0
    blocked: bool = False

    def to_dict(self) -> dict:
        return {
            "iter": self.iter_num,
            "stage": self.stage,
            "planned": self.planned,
            "accepted": self.accepted,
            "integrated": self.integrated,
            "reverted": self.reverted,
            "plan_errors": self.plan_errors,
            "verdicts": self.verdicts,
            "cost_usd": round(self.cost_usd, 4),
            "blocked": self.blocked,
        }


def skip_set(from_phase: Optional[str]) -> set[str]:
    if not from_phase:
        return set()
    norm = from_phase.strip().lower()
    if norm not in PHASE_ORDER:
        raise ValueError(f"--from must be one of {', '.join(PHASE_ORDER)}, got {from_phase!r}")
    return set(PHASE_ORDER[:PHASE_ORDER.index(norm)])


class Loop:
    def __init__(self, ctx: LoopContext) -> None:
        self.ctx = ctx
        self.summaries: list[IterationSummary] = []

    def run(self) -> list[IterationSummary]:
        ctx = self.ctx
        init_state_dir(ctx.state_dir)
        ctx.results_dir.mkdir(parents=True, exist_ok=True)

        for n in range(1, ctx.options.max_iterations + 1):
            ctx.iter_num = next_iter_num(ctx.state_dir)
            ctx.stage = read_stage(ctx.progress_file, ctx.options.force_stage)
            ctx.skip_now = skip_set(ctx.options.from_phase) if n == 1 else set()

            print(f"\n{'#' * 72}")
            print(f"# iteration {n}/{ctx.options.max_iterations} "
                  f"(iter dir {ctx.iter_num:03d}, stage {ctx.stage})")
            print(f"{'#' * 72}")

            if ctx.stage == "COMPLETE":
                print("[info] PROGRESS.md reports COMPLETE — stopping.")
                break

            summary = self._iterate()
            self.summaries.append(summary)
            self._write_summary()

            append_log(
                ctx.progress_file,
                f"iter {ctx.iter_num:03d}: planned {summary.planned}, "
                f"integrated {len(summary.integrated)}, reverted {len(summary.reverted)}"
                + (f", plan rejected ({len(summary.plan_errors)} objection(s))"
                   if summary.plan_errors else "")
            )

            if summary.blocked:
                print("[warn] iteration blocked; stopping so the state can be inspected.")
                break

        self._write_summary()
        self.print_summary()
        return self.summaries

    def _iterate(self) -> IterationSummary:
        ctx = self.ctx
        summary = IterationSummary(iter_num=ctx.iter_num, stage=ctx.stage)

        # ── 1. plan ─────────────────────────────────────────────────────
        plan_result = PlanPhase(ctx).run()
        if plan_result.completed:
            return summary

        # ── 2. validate (deterministic) ─────────────────────────────────
        print(f"\n[phase 2] Plan validation  (iter {ctx.iter_num:03d})")
        nodes, errors = plan_validate.validate(
            ctx.objectives_file, ctx.laws_file, ctx.library_root,
            max_nodes=ctx.options.max_nodes_per_iter,
        )
        summary.planned = len(nodes)
        if errors:
            summary.plan_errors = errors
            print(f"[error] plan rejected with {len(errors)} objection(s):")
            for e in errors:
                print(f"  - {e}")
            plan_validate.write_auto_notes(
                ctx.auto_notes_file,
                [("Plan rejected — fix these before proposing work again", errors)],
            )
            return summary
        print(f"[info] plan accepted: {len(nodes)} node(s)")
        for node in nodes:
            print(f"  - {node.node_id}  ({len(node.scenarios)} scenarios, "
                  f"{len(node.binders)} binders)")

        # ── 3. code ─────────────────────────────────────────────────────
        code_phase = CodePhase(ctx, nodes)
        code_result = code_phase.run()
        summary.accepted = sum(1 for r in code_phase.results if r.accepted)
        summary.verdicts = {r.node_id: r.verdict for r in code_phase.results}
        summary.cost_usd = sum(r.cost_usd for r in code_phase.results)

        # ── 4. integrate ────────────────────────────────────────────────
        integrate_phase = IntegratePhase(ctx, code_phase.tasks, code_phase.results)
        integrate_result = integrate_phase.run()
        summary.integrated = integrate_phase.integrated
        summary.reverted = integrate_phase.reverted
        summary.blocked = integrate_result.blocked
        summary.verdicts = {r.node_id: r.verdict for r in code_phase.results}

        # ── 5. feedback for the next plan phase ─────────────────────────
        notes = list(code_result.notes) + list(integrate_result.notes)
        sections: list[tuple[str, list[str]]] = []
        if notes:
            sections.append(("Outcomes from the previous iteration", notes))
        remaining = self._uncovered_laws()
        if remaining:
            sections.append(
                ("Laws with no rule yet",
                 [f"`{lid}`" for lid in remaining[:40]]
                 + ([f"... and {len(remaining) - 40} more"] if len(remaining) > 40 else []))
            )
        plan_validate.write_auto_notes(ctx.auto_notes_file, sections)
        return summary

    def _uncovered_laws(self) -> list[str]:
        """Law ids not referenced by any rule file in the library."""
        law_ids = plan_validate.load_law_ids(self.ctx.laws_file)
        if not law_ids:
            return []
        covered: set[str] = set()
        rules_dir = self.ctx.library_root / "TrafficSpec" / "Rules"
        if rules_dir.exists():
            for path in rules_dir.rglob("*.lean"):
                text = path.read_text(encoding="utf-8", errors="replace")
                for lid in law_ids:
                    if lid in text:
                        covered.add(lid)
        return sorted(law_ids - covered)

    # ── reporting ───────────────────────────────────────────────────────

    def _write_summary(self) -> None:
        ctx = self.ctx
        payload = {
            "run": ctx.results_dir.name,
            "library_root": str(ctx.library_root),
            "laws_file": str(ctx.laws_file),
            "generated_at": datetime.now().isoformat(),
            "model": ctx.options.model,
            "iterations": [s.to_dict() for s in self.summaries],
            "totals": {
                "planned": sum(s.planned for s in self.summaries),
                "accepted": sum(s.accepted for s in self.summaries),
                "integrated": sum(len(s.integrated) for s in self.summaries),
                "reverted": sum(len(s.reverted) for s in self.summaries),
                "cost_usd": round(sum(s.cost_usd for s in self.summaries), 4),
                "rules_in_library": index_sync.registered_count(ctx.library_root),
                "laws_total": len(plan_validate.load_law_ids(ctx.laws_file)),
                "laws_uncovered": len(self._uncovered_laws()),
            },
        }
        (ctx.results_dir / "summary.json").write_text(
            json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8"
        )

    def print_summary(self) -> None:
        W = 78
        print(f"\n{'=' * W}")
        print(f"{'AUTOFORMALIZATION SUMMARY':^{W}}")
        print(f"{'=' * W}")
        print(f"{'Iter':>4}  {'Planned':>7}  {'Accepted':>8}  {'Landed':>6}  "
              f"{'Reverted':>8}  {'Cost':>8}")
        print("-" * W)
        for s in self.summaries:
            print(f"{s.iter_num:>4}  {s.planned:>7}  {s.accepted:>8}  "
                  f"{len(s.integrated):>6}  {len(s.reverted):>8}  "
                  f"${s.cost_usd:>7.4f}")
        print("-" * W)
        total_cost = sum(s.cost_usd for s in self.summaries)
        rules = index_sync.registered_count(self.ctx.library_root)
        uncovered = self._uncovered_laws()
        laws_total = len(plan_validate.load_law_ids(self.ctx.laws_file))
        print(f"Rules in library: {rules}    "
              f"Laws covered: {laws_total - len(uncovered)}/{laws_total}    "
              f"Total cost: ${total_cost:.4f}")
        if uncovered:
            print(f"Uncovered law ids: {', '.join(uncovered[:12])}"
                  + (" ..." if len(uncovered) > 12 else ""))
        print(f"Summary written to {self.ctx.results_dir / 'summary.json'}")
        print("=" * W)


def build_context(
    repo_root: Path,
    laws_file: Path,
    run_id: str,
    options: LoopOptions,
    library_root: Optional[Path] = None,
) -> LoopContext:
    repo_root = repo_root.resolve()
    return LoopContext(
        repo_root=repo_root,
        library_root=(library_root or (repo_root / "library")).resolve(),
        laws_file=laws_file.resolve(),
        state_dir=(repo_root / "state" / run_id),
        results_dir=(repo_root / "results" / run_id),
        prompts_dir=(repo_root / "prompts"),
        options=options,
    )
