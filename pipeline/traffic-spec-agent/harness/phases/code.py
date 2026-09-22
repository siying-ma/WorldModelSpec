"""Code: one session per accepted node writes the rule and the witness; the harness gates it."""
from __future__ import annotations
import json
import shutil
from pathlib import Path
from .. import gate, index_sync, nodeid, paths, render, runner, surface
from ..blueprint import Node
from ..reading import Reading
from ..state import Run

PLACEHOLDERS = ("node", "files", "core_surface", "gate", "rule_path", "witness_path", "node_id")


def node_dir(run: Run, node_id: str) -> Path:
    return run.iter / "code" / node_id


def rollback(node_id: str, baseline: dict[str, str]) -> None:
    """Remove the node's files unless they existed in the baseline (they never should)."""
    for rel in (nodeid.rule_path(node_id), nodeid.witness_path(node_id)):
        p = paths.LIBRARY / rel
        if rel not in baseline and p.exists():
            p.unlink()


def gate_cli(run: Run, node_id: str) -> str:
    return f"python -m harness gate --run-id {run.opts.run_id} --node-id {node_id}"


def run_code(run: Run, node: Node, reading: Reading) -> gate.Verdict:
    d = node_dir(run, node.id)
    d.mkdir(parents=True, exist_ok=True)
    (d / "node.json").write_text(json.dumps(node.raw, ensure_ascii=False, indent=1), encoding="utf-8")
    index_sync.write_index()          # the registries carry every node accepted so far, siblings included
    baseline = gate.library_digest(paths.LIBRARY)
    (d / "baseline.json").write_text(json.dumps(baseline), encoding="utf-8")
    (d / "gate_runs.txt").write_text("0", encoding="utf-8")
    rule_rel, wit_rel = nodeid.rule_path(node.id), nodeid.witness_path(node.id)
    files = (f"- rule: `library/{rule_rel}` — `namespace {nodeid.rule_namespace(node.id)}`, declare `def rule : Rule`\n"
             f"- witness: `library/{wit_rel}` — `namespace {nodeid.witness_namespace(node.id)}`, declare `def scenarios : List Scenario`\n"
             f"- imports: the rule file imports `TrafficSpec.Core.Rule` only; the witness file imports `{nodeid.rule_module(node.id)}` and `TrafficSpec.Core.Builders`\n"
             f"- the witness's `reading` field is ignored by the gate (the run's reading is substituted); `manifest := Build.manifest` or `Build.manifest [\"<atom id>\", …]` for the blind witness\n")
    gate_text = (f"Run from the repository root:\n\n```\n{gate_cli(run, node.id)}\n```\n\nVerdicts, in the order the gate checks them: "
                 + ", ".join(gate.VERDICTS) + f". Budget: {run.opts.gate_budget} runs; the harness re-runs the gate after you stop.\n")
    prompt = render.render("code.md", {
        "node": json.dumps(node.raw, ensure_ascii=False, indent=1),
        "files": files, "core_surface": surface.core_surface(), "gate": gate_text,
        "rule_path": f"library/{rule_rel}", "witness_path": f"library/{wit_rel}", "node_id": node.id})
    prompt += f"\n\n## Where to write\n\nWorking directory: the repository root. Write `task_result.md` in `{d.relative_to(paths.REPO)}`.\n"
    (d / "prompt.md").write_text(prompt, encoding="utf-8")
    if not run.opts.dry_run:
        code, result, timed_out = runner.run_claude(prompt, cwd=paths.REPO, stream_path=d / "session.jsonl",
                                                    max_turns=run.opts.max_turns, model=run.opts.model,
                                                    timeout_seconds=run.opts.session_timeout)
        (d / "session_result.json").write_text(json.dumps({"code": code, "timed_out": timed_out, "result": result}, ensure_ascii=False, indent=1), encoding="utf-8")
    # the harness's own gate call decides; the session's calls were advice to itself
    v = gate.run_gate(node, reading, baseline, d, budget_used=0, budget=run.opts.gate_budget + 1)
    (d / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1), encoding="utf-8")
    if v.verdict != "OK":
        rollback(node.id, baseline)
    return v


def gate_from_cli(run_id: str, node_id: str) -> gate.Verdict:
    """The gate as the coding session calls it: counted against the budget, never authoritative."""
    from .. import state
    run_root = paths.run_dir(run_id)
    iters = sorted(p for p in run_root.glob("iter-*") if (p / "code" / node_id).exists())
    if not iters:
        return gate.Verdict("SCOPE_VIOLATION", [f"no task directory for {node_id} under {run_root}"])
    d = iters[-1] / "code" / node_id
    node = Node(json.loads((d / "node.json").read_text(encoding="utf-8")))
    baseline = json.loads((d / "baseline.json").read_text(encoding="utf-8"))
    opts = json.loads((run_root / "options.json").read_text(encoding="utf-8"))
    index_sync.write_index()
    used = int((d / "gate_runs.txt").read_text().strip() or 0)
    (d / "gate_runs.txt").write_text(str(used + 1), encoding="utf-8")
    v = gate.run_gate(node, Reading(Path(opts["reading"])), baseline, d, used, opts["gate_budget"])
    return v
