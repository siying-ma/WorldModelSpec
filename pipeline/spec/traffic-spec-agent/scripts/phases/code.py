"""Code phase: one Claude session per planned node.

Sessions run serially. Each writes exactly one rule file and must reach `OK`
from `tools/check_spec.py` — the gate is the only path to acceptance, so a
session that merely claims success does not produce an accepted node.

Serial rather than parallel because every session shares one library directory
and one `lake build`. Nodes have disjoint target files, so parallelism is
possible, but it needs a build lock to be correct and that is not worth the
complexity at this size.
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime
from pathlib import Path

from .. import runner
from ..preprocessor import (
    capture_baseline,
    library_manifest,
    prepare_tasks_for_resume,
    rollback_node,
    scope_diff,
)
from ..task import SpecNode, SpecNodeResult, SpecNodeTask
from .base import Phase, PhaseResult


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

TOOL_REL = "tools/check_spec.py"


def format_scenarios(node: SpecNode) -> str:
    rows = []
    for s in node.scenarios:
        kind = "must be SATISFIED" if s.expected else "must be VIOLATED"
        desc = f" — {s.description}" if s.description else ""
        rows.append(f"- `{s.name}` (`expected := {str(s.expected).lower()}`, {kind}){desc}")
    return "\n".join(rows)


def format_law_text(laws_file: Path, refs: list[str]) -> str:
    wanted = set(refs)
    blocks = []
    with open(laws_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                law = json.loads(line)
            except json.JSONDecodeError:
                continue
            if str(law.get("id")) in wanted:
                title = f" — {law['title']}" if law.get("title") else ""
                blocks.append(f"### `{law['id']}`{title}\n\n{law.get('text', '').strip()}\n")
    return "\n".join(blocks) if blocks else "(law text not found — check law_refs)\n"


def build_prompt(task: SpecNodeTask, repo_root: Path, schema_summary: str,
                 vocab_summary: str) -> str:
    template = (task.prompts_dir / "prompt_code.txt").read_text(encoding="utf-8")
    node = task.node
    return template.format(
        node_id=node.node_id,
        description=node.description,
        notes=node.notes or "(none)",
        law_text=format_law_text(task.laws_file, node.law_refs),
        law_refs=", ".join(node.law_refs),
        # Pre-rendered as Lean string literals so the agent cannot get the
        # quoting wrong in `entry.lawRefs`.
        law_refs_lean=", ".join(f'"{r}"' for r in node.law_refs),
        target_file=node.target_file,
        target_path=str(task.target_path),
        module=node.module,
        namespace=node.namespace,
        binders=", ".join(f"`{b}`" for b in node.binders),
        binder_count=len(node.binders),
        scenarios_block=format_scenarios(node),
        scenario_count=len(node.scenarios),
        library_root=str(task.library_root),
        task_dir=str(task.task_dir),
        node_spec_file=str(task.node_spec_file),
        node_report_file=str(task.report_file),
        check_spec_path=str(repo_root / TOOL_REL),
        vocab_file=str(task.library_root / "TrafficSpec" / "Core" / "Vocab.lean"),
        builders_file=str(task.library_root / "TrafficSpec" / "Core" / "Builders.lean"),
        example_file=str(task.library_root / "TrafficSpec" / "Rules" / "Following"
                         / "R0001_following_distance.lean"),
        vocab_summary=vocab_summary,
        schema_summary=schema_summary,
    )


def read_verdict(task: SpecNodeTask) -> dict:
    if not task.verdict_file.exists():
        return {"verdict": "NO_VERDICT", "attempts": 0}
    try:
        return json.loads(task.verdict_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"verdict": "NO_VERDICT", "attempts": 0}


def read_report(task: SpecNodeTask) -> dict:
    if not task.report_file.exists():
        return {}
    try:
        data = json.loads(task.report_file.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except json.JSONDecodeError:
        return {}


class CodePhase(Phase):
    name = "Coding agent(s)"
    number = 3
    token = "code"

    def __init__(self, ctx, nodes: list[SpecNode]) -> None:
        super().__init__(ctx)
        self.nodes = nodes
        self.results: list[SpecNodeResult] = []
        self.tasks: list[SpecNodeTask] = []

    def run(self) -> PhaseResult:
        ctx = self.ctx
        if self.should_skip():
            print(f"[info] {self.name} skipped (--from)")
            return PhaseResult(skipped=True)

        self.header()

        schema = json.loads(
            (ctx.repo_root / "carla" / "schema.json").read_text(encoding="utf-8")
        )
        from .plan import summarize_schema, summarize_vocab
        schema_summary = summarize_schema(schema)
        vocab_summary = summarize_vocab(ctx.library_root)

        all_tasks = [
            SpecNodeTask(
                node=node,
                library_root=ctx.library_root,
                task_dir=ctx.nodes_dir / node.sanitized,
                prompts_dir=ctx.prompts_dir,
                laws_file=ctx.laws_file,
                max_turns=ctx.options.max_turns,
                timeout_minutes=ctx.options.timeout_minutes,
                model=ctx.options.model,
                effort=ctx.options.effort,
                max_budget_usd=ctx.options.max_budget_usd,
            )
            for node in self.nodes
        ]
        to_run, already = prepare_tasks_for_resume(all_tasks)
        self.tasks = all_tasks

        for task, data in already:
            self.results.append(SpecNodeResult(
                task_id=data.get("task_id", task.task_id),
                node_id=task.node.node_id,
                verdict=data.get("verdict", "OK"),
                accepted=True,
                start_time=datetime.now(),
                end_time=datetime.now(),
                attempts=int(data.get("attempts", 0)),
            ))

        notes: list[str] = []
        for i, task in enumerate(to_run, 1):
            print(f"\n[{i}/{len(to_run)}] node {task.node.node_id}")
            result = self._run_one(task, schema_summary, vocab_summary)
            self.results.append(result)
            notes.extend(self._notes_for(result))

        accepted = sum(1 for r in self.results if r.accepted)
        print(f"\n[info] Code phase: {accepted}/{len(self.results)} node(s) passed the gate")
        return PhaseResult(notes=notes)

    def _run_one(self, task: SpecNodeTask, schema_summary: str,
                 vocab_summary: str) -> SpecNodeResult:
        ctx = self.ctx
        start = datetime.now()
        prompt = build_prompt(task, ctx.repo_root, schema_summary, vocab_summary)
        (task.task_dir / "prompt.txt").write_text(prompt, encoding="utf-8")

        if ctx.options.dry_run:
            print("[dry-run] node prompt written; not launching Claude")
            return SpecNodeResult(
                task_id=task.task_id, node_id=task.node.node_id, verdict="DRY_RUN",
                accepted=False, start_time=start, end_time=datetime.now(),
            )

        # Baseline the library as it is *now*, not as it was when the iteration was
        # prepared: earlier nodes in this phase have added their own rule files
        # since then. The harness keeps its own copy of the manifest so the
        # post-session scope re-check below cannot be influenced by the session.
        baseline = capture_baseline(task)
        baseline_sha = sha256_file(task.baseline_file)

        code, claude_result, timed_out = runner.run_claude(
            prompt,
            cwd=ctx.repo_root,
            stream_path=task.raw_stream_file,
            max_turns=task.max_turns,
            model=task.model,
            effort=task.effort,
            max_budget_usd=task.max_budget_usd,
            timeout_seconds=(task.timeout_minutes * 60 if task.timeout_minutes else None),
        )

        verdict_data = read_verdict(task)
        report = read_report(task)
        in_tok, out_tok, cr_tok, cc_tok = runner.extract_tokens(claude_result)

        error = None
        terminal = (claude_result or {}).get("terminal_reason")
        if timed_out:
            terminal, error = "timeout", "session killed after timeout"
        elif claude_result is None:
            error = f"claude exited {code} with no result line"

        verdict, accepted, audit = self._authorize(task, verdict_data, baseline,
                                                  baseline_sha)
        if audit:
            error = "; ".join(filter(None, [error, audit]))

        result = SpecNodeResult(
            task_id=task.task_id,
            node_id=task.node.node_id,
            verdict=verdict,
            accepted=accepted,
            start_time=start,
            end_time=datetime.now(),
            attempts=int(verdict_data.get("attempts", 0)),
            scenarios_declared=int(verdict_data.get("scenarios_declared", 0)),
            scenarios_passed=int(verdict_data.get("scenarios_passed", 0)),
            carla_groundings=int(verdict_data.get("carla_groundings", 0)),
            blockers=[str(x) for x in report.get("blockers", [])],
            suggest_decompose=[str(x) for x in report.get("suggest_decompose", [])],
            missing_vocab=[str(x) for x in report.get("missing_vocab", [])],
            error_message=error,
            terminal_reason=terminal,
            cost_usd=runner.extract_cost(claude_result),
            input_tokens=in_tok, output_tokens=out_tok,
            cache_read_tokens=cr_tok, cache_creation_tokens=cc_tok,
        )
        task.result_file.write_text(
            json.dumps(result.to_dict(), indent=2, ensure_ascii=False), encoding="utf-8"
        )
        print(f"[info] node {task.node.node_id}: verdict={result.verdict} "
              f"attempts={result.attempts} cost=${result.cost_usd:.4f}")

        # Undo a rejected node's edit now rather than at integrate. Left in place,
        # its file is part of the library that the *next* node in this phase is
        # baselined against and is reported to that node as an out-of-scope
        # change — a failure propagating into work that has not started yet.
        if not result.accepted:
            rollback_node(task)
        return result

    def _authorize(self, task: SpecNodeTask, verdict_data: dict,
                   baseline: dict, baseline_sha: str) -> tuple[str, bool, str]:
        """Decide acceptance here, not from what the session's gate call reported.

        The gate is still the sole authority on whether a rule is correct, but the
        *authority must be a gate call the harness controls*. A session can invoke
        `check_spec.py` with any `--library-root` and can rewrite the `baseline.json`
        it is compared against, and both were observed in run `test_eight_rules`:
        one node pointed the gate at a copy of the library with its siblings
        deleted, another regenerated the baseline from the current library and
        copied it over the real one. Both then reported `OK`.

        So three things are confirmed independently before a node is accepted:
        scope, measured against the manifest this phase captured and kept in
        memory; the library the gate actually looked at; and whether the build was
        skipped.
        """
        verdict = verdict_data.get("verdict", "NO_VERDICT")
        if verdict != "OK":
            return verdict, False, ""

        touched = scope_diff(baseline, library_manifest(task.library_root),
                             task.node.target_file)
        if touched:
            detail = "; ".join(touched)
            print(f"[warn] {task.node.node_id}: gate reported OK but the harness "
                  f"finds out-of-scope changes: {detail}")
            return "SCOPE_VIOLATION", False, f"harness scope re-check: {detail}"

        claimed_root = verdict_data.get("library_root")
        claimed_sha = verdict_data.get("baseline_sha")
        skipped_build = bool(verdict_data.get("skip_build"))
        problems = []
        if claimed_root is None and claimed_sha is None:
            # Gate predates provenance recording; scope was still re-checked above.
            return verdict, True, ""
        if claimed_root != str(task.library_root):
            problems.append(f"gate measured {claimed_root!r}, not the run's library "
                            f"{str(task.library_root)!r}")
        if claimed_sha != baseline_sha:
            problems.append("baseline.json was replaced between preparation and the "
                            "gate call")
        if skipped_build:
            problems.append("the accepting gate call used --skip-build, so the rule "
                            "was never compiled")
        if problems:
            detail = "; ".join(problems)
            print(f"[warn] {task.node.node_id}: rejecting an OK that was not "
                  f"gate-authorized — {detail}")
            return "GATE_BYPASS", False, detail
        return verdict, True, ""

    def _notes_for(self, r: SpecNodeResult) -> list[str]:
        """Turn one node's outcome into planner-facing feedback."""
        if r.accepted:
            if r.carla_groundings == 0:
                return [f"`{r.node_id}` was accepted but does not ground on the CARLA "
                        f"sample trace — confirm the entity types it quantifies over "
                        f"actually occur in captured data."]
            return []
        notes = [f"`{r.node_id}` was not accepted (verdict `{r.verdict}`, "
                 f"{r.attempts} gate call(s))."]
        if r.verdict == "GATE_BYPASS":
            notes.append(
                f"`{r.node_id}` reported `OK` from a gate call the harness could "
                f"not authorize ({r.error_message}). The specification itself may "
                f"be fine — re-plan the node unchanged and let it run again. Do not "
                f"treat this as a defect in the rule.")
        if r.verdict == "SCOPE_VIOLATION":
            notes.append(
                f"`{r.node_id}` touched a file outside its target. If the detail "
                f"names another node's rule file rather than Core/, that is a "
                f"harness fault and the node should simply be re-planned unchanged.")
        for b in r.blockers:
            notes.append(f"`{r.node_id}` blocker: {b}")
        for m in r.missing_vocab:
            notes.append(f"`{r.node_id}` needs a predicate that does not exist: {m}. "
                         f"Plan a Core/Vocab.lean extension before retrying this rule.")
        for s in r.suggest_decompose:
            notes.append(f"`{r.node_id}` suggests decomposition: {s}")
        if r.verdict == "SCENARIO_FAIL" and not r.blockers:
            notes.append(f"`{r.node_id}` could not satisfy its own acceptance tests — "
                         f"either the scenarios encode a reading the formula cannot "
                         f"express, or the clause needs splitting into cases.")
        if r.verdict == "CARLA_INCOMPATIBLE":
            notes.append(f"`{r.node_id}` requires scene-graph data CARLA does not "
                         f"produce. Mark the law `unsupported` in PROGRESS.md, naming "
                         f"the missing field, rather than re-planning it.")
        if r.error_message:
            notes.append(f"`{r.node_id}` session error: {r.error_message}")
        return notes
