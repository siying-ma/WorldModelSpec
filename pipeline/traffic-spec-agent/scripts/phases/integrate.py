"""Integrate phase: land accepted nodes in the library, or roll them back.

Deterministic, no model. A node passed its own gate in isolation; integration
asks the different question of whether the library as a whole still builds and
whether every previously accepted rule still passes its scenarios. A node that
breaks either is reverted to its pre-session snapshot and reported to the planner.

Rollback is snapshot-based rather than git-based: the preprocessor saved the
target file's prior contents (or recorded its absence), which is all that is
needed because a coding session may only touch that one file.
"""

from __future__ import annotations

import json

from .. import index_sync
from ..lean_check import (
    LeanUnavailable,
    eval_harness,
    first_errors,
    lake_build,
    write_library_harness,
)
from ..preprocessor import rollback_node
from ..task import SpecNodeResult, SpecNodeTask
from .base import Phase, PhaseResult


class IntegratePhase(Phase):
    name = "Integrate"
    number = 4
    token = "integrate"

    def __init__(self, ctx, tasks: list[SpecNodeTask],
                 results: list[SpecNodeResult]) -> None:
        super().__init__(ctx)
        self.tasks = {t.node.node_id: t for t in tasks}
        self.results = results
        self.integrated: list[str] = []
        self.reverted: list[str] = []

    def run(self) -> PhaseResult:
        ctx = self.ctx
        if self.should_skip():
            print(f"[info] {self.name} skipped (--from)")
            return PhaseResult(skipped=True)

        self.header()
        notes: list[str] = []

        # Nodes that never passed their own gate leave nothing behind. The code
        # phase already rolls each rejection back as it happens, so this is a
        # safety net for a phase that died part-way; `rollback_node` is idempotent.
        for r in self.results:
            if not r.accepted:
                task = self.tasks.get(r.node_id)
                if task is not None:
                    rollback_node(task)

        candidates = [r for r in self.results if r.accepted]
        if not candidates:
            print("[info] No accepted nodes to integrate")
            return PhaseResult(notes=notes)

        if ctx.options.dry_run:
            print(f"[dry-run] would integrate {len(candidates)} node(s)")
            return PhaseResult(skipped=True)

        # Register everything first: an unregistered rule is invisible to the
        # library, so the registry has to be in place before the build.
        changed, problems = index_sync.sync(ctx.library_root)
        if problems:
            notes.extend(f"registry: {p}" for p in problems)
            print("[error] Registry sync refused:")
            for p in problems:
                print(f"  - {p}")
            for r in candidates:
                task = self.tasks.get(r.node_id)
                if task is not None:
                    rollback_node(task)
                    r.accepted = False
                    self.reverted.append(r.node_id)
            index_sync.sync(ctx.library_root)
            return PhaseResult(blocked=True, notes=notes)

        try:
            ok, output = self._verify()
        except LeanUnavailable as exc:
            print(f"[error] {exc}")
            return PhaseResult(blocked=True, notes=[f"toolchain: {exc}"])

        if ok:
            self.integrated = [r.node_id for r in candidates]
            print(f"[info] Integrated {len(self.integrated)} node(s); library is clean")
            ctx.write_meta(**{
                "integrate.integrated": self.integrated,
                "integrate.reverted": [],
            })
            return PhaseResult(notes=notes)

        # The library is broken. Find the culprit(s) by reverting one at a time,
        # newest first, rebuilding after each.
        print("[warn] Library verification failed after integration:")
        print(first_errors(output))
        notes.append("integration broke the library; bisecting")

        for r in reversed(candidates):
            task = self.tasks.get(r.node_id)
            if task is None:
                continue
            rollback_node(task)
            index_sync.sync(ctx.library_root)
            r.accepted = False
            self.reverted.append(r.node_id)
            notes.append(
                f"`{r.node_id}` was reverted: it passed its own gate but the library "
                f"did not build or an existing rule's scenarios regressed with it in "
                f"place. Re-plan it, or split it."
            )
            try:
                ok, output = self._verify()
            except LeanUnavailable as exc:
                return PhaseResult(blocked=True, notes=[f"toolchain: {exc}"])
            if ok:
                break

        self.integrated = [r.node_id for r in candidates if r.accepted]
        for r in self.results:
            task = self.tasks.get(r.node_id)
            if task is not None and task.result_file.exists():
                task.result_file.write_text(
                    json.dumps(r.to_dict(), indent=2, ensure_ascii=False),
                    encoding="utf-8",
                )

        if not ok:
            notes.append(
                "the library still does not verify after reverting every node from "
                "this iteration — inspect it by hand before the next run"
            )
        print(f"[info] Integrated {len(self.integrated)}, reverted {len(self.reverted)}")
        ctx.write_meta(**{
            "integrate.integrated": self.integrated,
            "integrate.reverted": self.reverted,
        })
        return PhaseResult(notes=notes, blocked=not ok)

    def _verify(self) -> tuple[bool, str]:
        """Whole-library build plus a re-run of every registered rule's scenarios."""
        ctx = self.ctx
        ok, output = lake_build(ctx.library_root)
        if not ok:
            return False, output

        harness = ctx.iter_dir / "library_harness.lean"
        write_library_harness(harness)
        ok, output = eval_harness(ctx.library_root, harness)
        if not ok:
            return False, output

        (ctx.iter_dir / "library_report.txt").write_text(output, encoding="utf-8")

        failures = [
            line for line in output.splitlines()
            if line.startswith("SCEN\t") and line.rstrip().split("\t")[-1] != "PASS"
        ]
        if failures:
            return False, "Scenario regressions:\n" + "\n".join(failures)
        return True, output
