"""Code: one session per accepted node writes the rule and the witness; the harness gates it.

The session starts from two files the harness wrote (`skeleton.py`): every declaration the gate
compares, the parameters as terms, the four scenarios with their verdicts. It is shown the Core
surface, the run's reading (the values its witnesses must be built against), and the most recently
accepted node as a worked example. Core is readable, not writable; the harness is neither.
"""
from __future__ import annotations
import json
from pathlib import Path
from ..checks import gate
from ..lean import index_sync, lean, skeleton, surface
from ..model import nodeid
from ..store import paths
from ..agents import render, session
from ..model.blueprint import Node, ConceptRecord
from ..model.reading import Reading
from ..store.state import Run

PLACEHOLDERS = ("node", "files", "core_surface", "reading", "example", "skeletons", "gate", "rule_path", "witness_path", "node_id")
PLACEHOLDERS_CONCEPT = ("concept", "files", "core_surface", "example", "skeletons", "gate", "concept_path", "witness_path", "concept_id", "mode")
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
             f"- imports: the rule file imports `TrafficSpec.Core.Language.Rule` only; the witness file imports `{nodeid.rule_module(node.id)}` and `TrafficSpec.Core.Evidence.Builders`\n"
             f"- both files exist already, written by the harness from the node (below); they build, and every declaration the gate compares is filled in — your work is the formulas and the scenes\n")
    skeletons = (f"```lean\n-- library/{rule_rel} (as written by the harness)\n{rule_text}\n```\n\n"
                 f"```lean\n-- library/{wit_rel} (as written by the harness)\n{wit_text}\n```\n")
    gate_text = (f"Run from the repository root:\n\n```\n{gate_cli(run, node.id)}\n```\n\nIt prints the verdict and its details. Verdicts, in the order the gate checks them: "
                 + ", ".join(gate.VERDICTS) + f". Budget: {run.opts.gate_budget} runs; the harness re-runs the gate itself after you stop, on the files as they are then.\n")
    prompt = render.render("code.md", {
        "node": json.dumps(node.raw, ensure_ascii=False, indent=1),
        "files": files, "core_surface": surface.core_surface(run.all_concepts()), "reading": reading_table(node, reading),
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
    """The gate as the coding session calls it: counted against the budget, never authoritative.
    `node_id` is a node id or a concept id."""
    run_root = paths.run_dir(run_id)
    dirname = concept_dirname(node_id) if nodeid.is_concept_id(node_id) else node_id
    iters = sorted(p for p in run_root.glob("iter-*") if (p / "code" / dirname).exists())
    if not iters:
        return gate.Verdict("SCOPE_VIOLATION", [f"no task directory for {node_id} under {run_root}"])
    d = iters[-1] / "code" / dirname
    baseline = json.loads((d / "baseline.json").read_text(encoding="utf-8"))
    opts = json.loads((run_root / "options.json").read_text(encoding="utf-8"))
    used = int((d / "gate_runs.txt").read_text().strip() or 0)
    (d / "gate_runs.txt").write_text(str(used + 1), encoding="utf-8")
    if nodeid.is_concept_id(node_id):
        rec = ConceptRecord(json.loads((d / "concept.json").read_text(encoding="utf-8")))
        accepted = _accepted_concepts_of(run_root, opts)
        return gate.run_concept_gate(rec, Reading(Path(opts["reading"])), baseline, d, used, opts["gate_budget"],
                                     mode=opts.get("mode", "train"), accepted=accepted)
    node = Node(json.loads((d / "node.json").read_text(encoding="utf-8")))
    return gate.run_gate(node, Reading(Path(opts["reading"])), baseline, d, used, opts["gate_budget"])


def _accepted_concepts_of(run_root: Path, opts: dict) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for root in ([paths.run_dir(opts["base_run"])] if opts.get("base_run") else []) + [run_root]:
        f = root / "accepted_concepts.jsonl"
        if f.exists():
            for l in f.read_text(encoding="utf-8").splitlines():
                if l.strip():
                    d = json.loads(l); out[d["concept_id"]] = d
    return out


# ---------------------------------------------------------------------------------------------
# Concepts: one session per accepted concept record writes the concept and its witnesses.
# ---------------------------------------------------------------------------------------------
def concept_dirname(cid: str) -> str:
    return "concept__" + nodeid.concept_lean_name(cid)


def concept_dir(run: Run, cid: str) -> Path:
    return run.iter / "code" / concept_dirname(cid)


def rollback_concept(cid: str, baseline: dict[str, str]) -> None:
    for rel in (nodeid.concept_path(cid), nodeid.concept_witness_path(cid)):
        p = paths.LIBRARY / rel
        if rel not in baseline and p.exists():
            p.unlink()
    index_sync.write_index()


def concept_example(run: Run) -> str:
    """The most recently accepted concept's two files, as the pattern to follow."""
    for cid in reversed(list(run.all_concepts())):
        cp, wp = paths.LIBRARY / nodeid.concept_path(cid), paths.LIBRARY / nodeid.concept_witness_path(cid)
        if cp.exists() and wp.exists():
            return (f"An accepted concept of this library, `{cid}` — its body uses only claimed names over its formals, "
                    f"its witnesses instantiate the formals with figures of their own:\n\n```lean\n-- library/{nodeid.concept_path(cid)}\n"
                    + cp.read_text(encoding="utf-8") + f"\n```\n\n```lean\n-- library/{nodeid.concept_witness_path(cid)}\n"
                    + wp.read_text(encoding="utf-8") + "\n```\n")
    return "(no concept accepted yet in this library; the skeletons below are the pattern, the Core surface the vocabulary)\n"


def write_concept_skeletons(rec: ConceptRecord) -> tuple[str, str]:
    c_rel, w_rel = nodeid.concept_path(rec.id), nodeid.concept_witness_path(rec.id)
    c, w = skeleton.concept_skeleton(rec), skeleton.concept_witness_skeleton(rec)
    for rel, text in ((c_rel, c), (w_rel, w)):
        p = paths.LIBRARY / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8")
    return c, w


def run_code_concept(run: Run, rec: ConceptRecord, reading: Reading) -> gate.Verdict:
    d = concept_dir(run, rec.id)
    d.mkdir(parents=True, exist_ok=True)
    (d / "concept.json").write_text(json.dumps(rec.raw, ensure_ascii=False, indent=1), encoding="utf-8")
    index_sync.write_index()
    baseline = gate.library_digest(paths.LIBRARY)
    (d / "baseline.json").write_text(json.dumps(baseline), encoding="utf-8")
    (d / "gate_runs.txt").write_text("0", encoding="utf-8")
    c_rel, w_rel = nodeid.concept_path(rec.id), nodeid.concept_witness_path(rec.id)
    c_text, w_text = write_concept_skeletons(rec)
    index_sync.write_index()
    if not run.opts.dry_run:
        ok, out = lean.lake_build(paths.LIBRARY, ["TrafficSpec.Index", nodeid.concept_module(rec.id), nodeid.concept_witness_module(rec.id)])
        (d / "prewarm.log").write_text(out, encoding="utf-8")
        if not ok:
            print(f"[code] warning: the skeleton of {rec.id} does not build; see prewarm.log")
    files = (f"- concept: `library/{c_rel}` — `namespace {nodeid.concept_namespace(rec.id)}`, `def concept : Concept`\n"
             f"- witness: `library/{w_rel}` — `namespace {nodeid.concept_witness_namespace(rec.id)}`, `def instances : List Concept.Instance`, `def scenarios : List Scenario`\n"
             f"- imports: the concept file imports `TrafficSpec.Core.Language.Concept` only; the witness file imports `{nodeid.concept_module(rec.id)}` and `TrafficSpec.Core.Evidence.Builders`\n"
             f"- both files exist already, written by the harness from the record (below); they build, and every declaration the gate compares is filled in — your work is the body and the scenes\n")
    skeletons = (f"```lean\n-- library/{c_rel} (as written by the harness)\n{c_text}\n```\n\n"
                 f"```lean\n-- library/{w_rel} (as written by the harness)\n{w_text}\n```\n")
    gate_text = (f"Run from the repository root:\n\n```\n{gate_cli(run, rec.id)}\n```\n\nIt prints the verdict and its details. Verdicts, in the order the gate checks them: "
                 + ", ".join(gate.CONCEPT_VERDICTS) + f". Budget: {run.opts.gate_budget} runs; the harness re-runs the gate itself after you stop, on the files as they are then.\n")
    prompt = render.render("code_concept.md", {
        "concept": json.dumps(rec.raw, ensure_ascii=False, indent=1), "files": files,
        "core_surface": surface.core_surface(run.all_concepts()), "example": concept_example(run), "skeletons": skeletons,
        "gate": gate_text, "concept_path": f"library/{c_rel}", "witness_path": f"library/{w_rel}", "concept_id": rec.id,
        "mode": run.opts.mode})
    prompt += f"\n\n## Where to write\n\nWorking directory: the repository root. Write `task_result.md` in `{d.relative_to(paths.REPO)}`.\n"
    (d / "prompt.md").write_text(prompt, encoding="utf-8")
    if not run.opts.dry_run:
        try:
            session.run(prompt, cwd=paths.REPO, out_dir=d, opts=run.opts, max_turns=run.opts.max_turns,
                        effort=run.opts.code_effort, label="session")
        except session.SessionUnavailable as e:
            rollback_concept(rec.id, baseline)
            v = gate.Verdict(SESSION_FAILED, [str(e)])
            (d / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1), encoding="utf-8")
            return v
    v = gate.run_concept_gate(rec, reading, baseline, d, budget_used=0, budget=run.opts.gate_budget + 1,
                              mode=run.opts.mode, accepted=run.all_concepts())
    (d / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1), encoding="utf-8")
    if v.verdict != "OK":
        rollback_concept(rec.id, baseline)
    return v
