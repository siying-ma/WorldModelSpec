"""Code: one session per accepted node writes the rule and the witness; the harness gates it.

The session starts from two files the harness wrote (`skeleton.py`): every declaration the gate
compares, the parameters as terms, the four scenarios with their verdicts. It is shown the Core
surface, the run's reading (the values its witnesses must be built against), and the most recently
accepted node as a worked example. Core is readable, not writable; the harness is neither.
"""
from __future__ import annotations
import json
from pathlib import Path
from .. import gate, index_sync, lean, nodeid, paths, render, session, skeleton, surface
from ..blueprint import Node
from ..reading import Reading
from ..state import Run

PLACEHOLDERS = ("node", "files", "core_surface", "reading", "example", "skeletons", "gate", "rule_path", "witness_path", "node_id")
SESSION_FAILED = "SESSION_FAILED"     # the session never ran; not a verdict on the node


def node_dir(run: Run, node_id: str) -> Path:
    return run.iter / "code" / node_id


def rollback(node_id: str, baseline: dict[str, str]) -> None:
    """Remove the node's files unless they existed in the baseline (they never should)."""
    for rel in (nodeid.rule_path(node_id), nodeid.witness_path(node_id)):
        p = paths.LIBRARY / rel
        if rel not in baseline and p.exists():
            p.unlink()
    index_sync.write_index()


def gate_cli(run: Run, node_id: str) -> str:
    return f"python -m harness gate --run_id {run.opts.run_id} --node_id {node_id}"


def reading_table(node: Node, reading: Reading) -> str:
    """The node's parameters with the run's values (a witness is evaluated against these), and the aggregates."""
    out = ["| parameter | value | unit | convention |", "|---|---|---|---|"]
    for name in node.params():
        p = reading.params.get(name)
        if p is None:
            out.append(f"| `{name}` | (absent from the reading: the gate reports CHECK_FAIL until the operator adds it) | | |")
        else:
            out.append(f"| `{name}` | {p.get('value')} | {p.get('unit', '')} | {p.get('convention', '')} |")
    aggs = reading.data.get("aggregates", [])
    if aggs:
        out += ["", "Aggregates (which `ru.*` classes a word of the corpus covers):", ""]
        out += [f"- `{a['word']}`: {', '.join(a.get('classes', []))}" for a in aggs]
    out += ["", f"The catalogue is `{reading.path.relative_to(paths.REPO) if reading.path.is_relative_to(paths.REPO) else reading.path}` (read-only). "
            "Values enter a witness's geometry only: a `forbid` scene breaks the bound by a clear margin, a `permit` scene keeps it by one."]
    return "\n".join(out) + "\n"


def worked_example(run: Run) -> str:
    """The most recently accepted node's two files, as the pattern to follow; the skeletons alone when there is none."""
    for nid in reversed(list(run.accepted_nodes)):
        rp, wp = paths.LIBRARY / nodeid.rule_path(nid), paths.LIBRARY / nodeid.witness_path(nid)
        if rp.exists() and wp.exists():
            return (f"An accepted node of this library, `{nid}` — its header records its reading, its formulas use only "
                    f"claimed names, its witnesses are built scenes:\n\n```lean\n-- library/{nodeid.rule_path(nid)}\n"
                    + rp.read_text(encoding="utf-8") + f"\n```\n\n```lean\n-- library/{nodeid.witness_path(nid)}\n"
                    + wp.read_text(encoding="utf-8") + "\n```\n")
    return "(no node accepted yet in this library; the skeletons below are the pattern, the Core surface the vocabulary)\n"


def write_skeletons(node: Node) -> tuple[str, str]:
    rule_rel, wit_rel = nodeid.rule_path(node.id), nodeid.witness_path(node.id)
    r, w = skeleton.rule_skeleton(node), skeleton.witness_skeleton(node)
    for rel, text in ((rule_rel, r), (wit_rel, w)):
        p = paths.LIBRARY / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8")
    return r, w


def run_code(run: Run, node: Node, reading: Reading) -> gate.Verdict:
    d = node_dir(run, node.id)
    d.mkdir(parents=True, exist_ok=True)
    (d / "node.json").write_text(json.dumps(node.raw, ensure_ascii=False, indent=1), encoding="utf-8")
    index_sync.write_index()          # the registries carry every node accepted so far, siblings included
    baseline = gate.library_digest(paths.LIBRARY)
    (d / "baseline.json").write_text(json.dumps(baseline), encoding="utf-8")
    (d / "gate_runs.txt").write_text("0", encoding="utf-8")
    rule_rel, wit_rel = nodeid.rule_path(node.id), nodeid.witness_path(node.id)
    rule_text, wit_text = write_skeletons(node)
    index_sync.write_index()
    if not run.opts.dry_run:
        ok, out = lean.lake_build(paths.LIBRARY, ["TrafficSpec.Index", nodeid.rule_module(node.id), nodeid.witness_module(node.id)])
        (d / "prewarm.log").write_text(out, encoding="utf-8")
        if not ok:
            print(f"[code] warning: the skeleton of {node.id} does not build; see prewarm.log")
    files = (f"- rule: `library/{rule_rel}` — `namespace {nodeid.rule_namespace(node.id)}`, `def rule : Rule`\n"
             f"- witness: `library/{wit_rel}` — `namespace {nodeid.witness_namespace(node.id)}`, `def scenarios : List Scenario`\n"
             f"- imports: the rule file imports `TrafficSpec.Core.Rule` only; the witness file imports `{nodeid.rule_module(node.id)}` and `TrafficSpec.Core.Builders`\n"
             f"- both files exist already, written by the harness from the node (below); they build, and every declaration the gate compares is filled in — your work is the formulas and the scenes\n")
    skeletons = (f"```lean\n-- library/{rule_rel} (as written by the harness)\n{rule_text}\n```\n\n"
                 f"```lean\n-- library/{wit_rel} (as written by the harness)\n{wit_text}\n```\n")
    gate_text = (f"Run from the repository root:\n\n```\n{gate_cli(run, node.id)}\n```\n\nIt prints the verdict and its details. Verdicts, in the order the gate checks them: "
                 + ", ".join(gate.VERDICTS) + f". Budget: {run.opts.gate_budget} runs; the harness re-runs the gate itself after you stop, on the files as they are then.\n")
    prompt = render.render("code.md", {
        "node": json.dumps(node.raw, ensure_ascii=False, indent=1),
        "files": files, "core_surface": surface.core_surface(), "reading": reading_table(node, reading),
        "example": worked_example(run), "skeletons": skeletons, "gate": gate_text,
        "rule_path": f"library/{rule_rel}", "witness_path": f"library/{wit_rel}", "node_id": node.id})
    prompt += f"\n\n## Where to write\n\nWorking directory: the repository root. Write `task_result.md` in `{d.relative_to(paths.REPO)}`.\n"
    (d / "prompt.md").write_text(prompt, encoding="utf-8")
    if not run.opts.dry_run:
        try:
            session.run(prompt, cwd=paths.REPO, out_dir=d, opts=run.opts, max_turns=run.opts.max_turns,
                        effort=run.opts.code_effort, label="session")
        except session.SessionUnavailable as e:
            rollback(node.id, baseline)
            v = gate.Verdict(SESSION_FAILED, [str(e)])
            (d / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1), encoding="utf-8")
            return v
    # the harness's own gate call decides; the session's calls were advice to itself
    v = gate.run_gate(node, reading, baseline, d, budget_used=0, budget=run.opts.gate_budget + 1)
    (d / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1), encoding="utf-8")
    if v.verdict != "OK":
        rollback(node.id, baseline)
    elif v.extras.get("residues_added"):
        node.raw["residues"] = list(node.get("residues", [])) + [{"span": "code", "why": w} for w in v.extras["residues_added"]]
        (d / "node.json").write_text(json.dumps(node.raw, ensure_ascii=False, indent=1), encoding="utf-8")
    return v


def gate_from_cli(run_id: str, node_id: str) -> gate.Verdict:
    """The gate as the coding session calls it: counted against the budget, never authoritative."""
    run_root = paths.run_dir(run_id)
    iters = sorted(p for p in run_root.glob("iter-*") if (p / "code" / node_id).exists())
    if not iters:
        return gate.Verdict("SCOPE_VIOLATION", [f"no task directory for {node_id} under {run_root}"])
    d = iters[-1] / "code" / node_id
    node = Node(json.loads((d / "node.json").read_text(encoding="utf-8")))
    baseline = json.loads((d / "baseline.json").read_text(encoding="utf-8"))
    opts = json.loads((run_root / "options.json").read_text(encoding="utf-8"))
    used = int((d / "gate_runs.txt").read_text().strip() or 0)
    (d / "gate_runs.txt").write_text(str(used + 1), encoding="utf-8")
    return gate.run_gate(node, Reading(Path(opts["reading"])), baseline, d, used, opts["gate_budget"])
