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
from ..model import nodeid, ontology
from ..store import paths
from ..agents import render, session
from ..model.blueprint import Node, ConceptRecord
from ..model.reading import Reading
from ..store.state import Run

PLACEHOLDERS = ("node", "files", "core_surface", "reading", "example", "skeletons", "gate", "rule_path", "witness_path", "node_id", "core_dir",
                "anchors", "aggregate_atom")
PLACEHOLDERS_CONCEPT = ("concept", "files", "core_surface", "example", "skeletons", "gate", "concept_path", "witness_path", "concept_id", "mode", "core_dir",
                        "anchors")
SESSION_FAILED = "SESSION_FAILED"     # the session never ran; not a verdict on the node


def _finished_verdict(d: Path) -> gate.Verdict | None:
    """The `OK` verdict a task directory already holds: a session the gate passed before the loop
    was interrupted. Its files stayed in the library (only a failing verdict rolls back), so the
    task is finished and a resume reviews it instead of coding it again."""
    f = d / "verdict.json"
    if not f.exists():
        return None
    try:
        v = json.loads(f.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    if v.get("verdict") != "OK":
        return None
    return gate.Verdict(v["verdict"], v.get("details", []), extras=v.get("extras", {}))


def node_dir(run: Run, node_id: str) -> Path:
    return run.iter / "code" / node_id


def _keep_before(work: Path, rels: tuple[str, ...]) -> None:
    """Copy the files a session is about to overwrite into the task directory, so a failure
    restores them rather than deleting them."""
    for rel in rels:
        p = paths.LIBRARY / rel
        if p.exists():
            dst = work / "before" / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(p.read_bytes())


def _restore(work: Path, baseline: dict[str, str], rels: tuple[str, ...]) -> None:
    """Every file back to its state before the session: restored from `before/` when it existed,
    removed when it did not. What the session left is kept under `final/`, for a repair session
    to read."""
    for rel in rels:
        p = paths.LIBRARY / rel
        if p.exists():
            dst = work / "final" / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(p.read_bytes())
    for rel in rels:
        p = paths.LIBRARY / rel
        kept = work / "before" / rel
        if gate.lib_rel(rel) in baseline and kept.exists():
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(kept.read_bytes())
        elif gate.lib_rel(rel) not in baseline and p.exists():
            p.unlink()
    with lean.library_lock(paths.LIBRARY):
        index_sync.write_index()


def _task_files(work: Path, registry: dict | None, concurrent: list[str] | None) -> None:
    """What a gate run from this task directory registers and tolerates: the accepted ids plus
    this task's, and the files of the sessions coding beside it."""
    if registry is not None:
        (work / "registry.json").write_text(json.dumps(registry), encoding="utf-8")
    if concurrent is not None:
        (work / "concurrent.json").write_text(json.dumps(sorted(concurrent)), encoding="utf-8")


def rollback(node_id: str, baseline: dict[str, str], work: Path) -> None:
    _restore(work, baseline, (nodeid.rule_path(node_id), nodeid.witness_path(node_id)))


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
    claimed = {c.split("=", 1)[1] for c in node.claimed_atoms() if c.startswith("ru.aggregate=")}
    aggs = [a for a in reading.data.get("aggregates", []) if a.get("id") in claimed]
    if aggs:
        out += ["", "Admitted aggregates the node claims (a witness's road user is a member when it carries an included class; "
                "one carrying only an unresolved class makes the atom unknown):", ""]
        out += [f"- `{a['id']}`: included {', '.join(a.get('included', [])) or '(none)'}; unresolved {', '.join(a.get('unresolved', [])) or '(none)'}" for a in aggs]
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


def run_code(run: Run, node: Node, reading: Reading, registry: dict | None = None, concurrent: list[str] | None = None) -> gate.Verdict:
    """One coding session for a node, then the harness's own gate call. `registry` names the ids
    the gate registers (the accepted ones and this node); `concurrent` the files of the sessions
    running beside this one, which its scope check does not count."""
    d = node_dir(run, node.id)
    d.mkdir(parents=True, exist_ok=True)
    done = _finished_verdict(d)
    if done is not None:                                     # a resume: the session ran, the gate passed, the files are in the library
        print(f"[code] {node.id}: reusing the OK verdict of the finished session")
        return done
    (d / "node.json").write_text(json.dumps(node.raw, ensure_ascii=False, indent=1), encoding="utf-8")
    _task_files(d, registry, concurrent)
    only_nodes = None if registry is None else sorted(set(registry.get("nodes", [])) | {node.id})
    only_concepts = None if registry is None else registry.get("concepts")
    baseline = gate.repo_digest()
    (d / "baseline.json").write_text(json.dumps(baseline), encoding="utf-8")
    (d / "gate_runs.txt").write_text("0", encoding="utf-8")
    rule_rel, wit_rel = nodeid.rule_path(node.id), nodeid.witness_path(node.id)
    _keep_before(d, (rule_rel, wit_rel))
    rule_text, wit_text = write_skeletons(node)
    if not run.opts.dry_run:
        with lean.library_lock(paths.LIBRARY):
            index_sync.write_index(only_nodes=only_nodes, only_concepts=only_concepts)
            ok, out = lean.lake_build(paths.LIBRARY, ["TrafficSpec.Index", nodeid.rule_module(node.id), nodeid.witness_module(node.id)])
        (d / "prewarm.log").write_text(out, encoding="utf-8")
        if not ok:
            print(f"[code] warning: the skeleton of {node.id} does not build; see prewarm.log")
    rule_abs, wit_abs = (paths.LIBRARY / rule_rel).resolve(), (paths.LIBRARY / wit_rel).resolve()
    files = (f"- rule: `{rule_abs}` — `namespace {nodeid.rule_namespace(node.id)}`, `def rule : Rule`\n"
             f"- witness: `{wit_abs}` — `namespace {nodeid.witness_namespace(node.id)}`, `def scenarios : List Scenario`\n"
             f"- imports: the rule file imports `TrafficSpec.Core.Language.Rule` only; the witness file imports `{nodeid.rule_module(node.id)}` and `TrafficSpec.Core.Evidence.Builders`\n"
             f"- both files exist already, written by the harness from the node (below); they build, and every declaration the gate compares is filled in — your work is the formulas and the scenes\n")
    skeletons = (f"```lean\n-- library/{rule_rel} (as written by the harness)\n{rule_text}\n```\n\n"
                 f"```lean\n-- library/{wit_rel} (as written by the harness)\n{wit_text}\n```\n")
    gate_text = (f"Run exactly this command, nothing more and nothing else:\n\n```\n{gate_cli(run, node.id)}\n```\n\nIt prints the verdict and its details. Verdicts, in the order the gate checks them: "
                 + ", ".join(gate.VERDICTS) + f". Budget: {run.opts.gate_budget} runs; the harness re-runs the gate itself after you stop, on the files as they are then.\n")
    prompt = render.render("code.md", {
        "node": json.dumps(node.raw, ensure_ascii=False, indent=1),
        "files": files, "core_surface": surface.core_surface(run.all_concepts(), claimed=node.claimed_atoms()), "reading": reading_table(node, reading),
        "example": worked_example(run), "skeletons": skeletons, "gate": gate_text,
        "rule_path": str(rule_abs), "witness_path": str(wit_abs), "node_id": node.id,
        "core_dir": str(paths.CORE.resolve()),
        "anchors": ontology.anchors_text(ontology.load(run.opts.ontology), lean=True),
        "aggregate_atom": ontology.AGGREGATE.replace(".", "_")})
    prompt += f"\n\n## Where to write\n\nWorking directory: `{d.resolve()}`. Write `task_result.md` there.\n"
    (d / "prompt.md").write_text(prompt, encoding="utf-8")
    if not run.opts.dry_run:
        try:
            session.run(prompt, cwd=d, out_dir=d, opts=run.opts, max_turns=run.opts.max_turns,
                        effort=run.opts.code_effort, label="session",
                        allow=session.code_allow([rule_abs, wit_abs], d, gate_cli(run, node.id)),
                        deny=session.deny_rules("code"), disallowed_tools=session.NO_SEARCH,
                        env=session.harness_env(run.opts.session_timeout))
        except session.SessionUnavailable as e:
            rollback(node.id, baseline, d)
            v = gate.Verdict(SESSION_FAILED, [str(e)])
            (d / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1), encoding="utf-8")
            return v
    # the harness's own gate call decides; the session's calls were advice to itself
    v = gate.run_gate(node, reading, baseline, d, budget_used=0, budget=run.opts.gate_budget + 1,
                      accepted_concepts=run.all_concepts())
    (d / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1), encoding="utf-8")
    if v.verdict != "OK":
        rollback(node.id, baseline, d)
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
    return gate.run_gate(node, Reading(Path(opts["reading"])), baseline, d, used, opts["gate_budget"],
                         accepted_concepts=_accepted_concepts_of(run_root, opts))


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


def rollback_concept(cid: str, baseline: dict[str, str], work: Path) -> None:
    _restore(work, baseline, (nodeid.concept_path(cid), nodeid.concept_witness_path(cid)))


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


def run_code_concept(run: Run, rec: ConceptRecord, reading: Reading, registry: dict | None = None, concurrent: list[str] | None = None) -> gate.Verdict:
    d = concept_dir(run, rec.id)
    d.mkdir(parents=True, exist_ok=True)
    done = _finished_verdict(d)
    if done is not None:
        print(f"[code] {rec.id}: reusing the OK verdict of the finished session")
        return done
    (d / "concept.json").write_text(json.dumps(rec.raw, ensure_ascii=False, indent=1), encoding="utf-8")
    _task_files(d, registry, concurrent)
    only_nodes = None if registry is None else registry.get("nodes")
    only_concepts = None if registry is None else sorted(set(registry.get("concepts", [])) | {rec.id})
    baseline = gate.repo_digest()
    (d / "baseline.json").write_text(json.dumps(baseline), encoding="utf-8")
    (d / "gate_runs.txt").write_text("0", encoding="utf-8")
    c_rel, w_rel = nodeid.concept_path(rec.id), nodeid.concept_witness_path(rec.id)
    _keep_before(d, (c_rel, w_rel))
    c_text, w_text = write_concept_skeletons(rec)
    if not run.opts.dry_run:
        with lean.library_lock(paths.LIBRARY):
            index_sync.write_index(only_nodes=only_nodes, only_concepts=only_concepts)
            ok, out = lean.lake_build(paths.LIBRARY, ["TrafficSpec.Index", nodeid.concept_module(rec.id), nodeid.concept_witness_module(rec.id)])
        (d / "prewarm.log").write_text(out, encoding="utf-8")
        if not ok:
            print(f"[code] warning: the skeleton of {rec.id} does not build; see prewarm.log")
    c_abs, w_abs = (paths.LIBRARY / c_rel).resolve(), (paths.LIBRARY / w_rel).resolve()
    files = (f"- concept: `{c_abs}` — `namespace {nodeid.concept_namespace(rec.id)}`, `def concept : Concept`\n"
             f"- witness: `{w_abs}` — `namespace {nodeid.concept_witness_namespace(rec.id)}`, `def instances : List Concept.Instance`, `def scenarios : List Scenario`\n"
             f"- imports: the concept file imports `TrafficSpec.Core.Language.Concept` only; the witness file imports `{nodeid.concept_module(rec.id)}` and `TrafficSpec.Core.Evidence.Builders`\n"
             f"- both files exist already, written by the harness from the record (below); they build, and every declaration the gate compares is filled in — your work is the body and the scenes\n")
    skeletons = (f"```lean\n-- library/{c_rel} (as written by the harness)\n{c_text}\n```\n\n"
                 f"```lean\n-- library/{w_rel} (as written by the harness)\n{w_text}\n```\n")
    gate_text = (f"Run exactly this command, nothing more and nothing else:\n\n```\n{gate_cli(run, rec.id)}\n```\n\nIt prints the verdict and its details. Verdicts, in the order the gate checks them: "
                 + ", ".join(gate.CONCEPT_VERDICTS) + f". Budget: {run.opts.gate_budget} runs; the harness re-runs the gate itself after you stop, on the files as they are then.\n")
    prompt = render.render("code_concept.md", {
        "concept": json.dumps(rec.raw, ensure_ascii=False, indent=1), "files": files,
        "core_surface": surface.core_surface(run.all_concepts(), claimed=rec.claimed_atoms() | rec.refs()), "example": concept_example(run), "skeletons": skeletons,
        "gate": gate_text, "concept_path": str(c_abs), "witness_path": str(w_abs), "concept_id": rec.id,
        "mode": run.opts.mode, "core_dir": str(paths.CORE.resolve()),
        "anchors": ontology.anchors_text(ontology.load(run.opts.ontology), lean=True)})
    prompt += f"\n\n## Where to write\n\nWorking directory: `{d.resolve()}`. Write `task_result.md` there.\n"
    (d / "prompt.md").write_text(prompt, encoding="utf-8")
    if not run.opts.dry_run:
        try:
            session.run(prompt, cwd=d, out_dir=d, opts=run.opts, max_turns=run.opts.max_turns,
                        effort=run.opts.code_effort, label="session",
                        allow=session.code_allow([c_abs, w_abs], d, gate_cli(run, rec.id)),
                        deny=session.deny_rules("code"), disallowed_tools=session.NO_SEARCH,
                        env=session.harness_env(run.opts.session_timeout))
        except session.SessionUnavailable as e:
            rollback_concept(rec.id, baseline, d)
            v = gate.Verdict(SESSION_FAILED, [str(e)])
            (d / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1), encoding="utf-8")
            return v
    v = gate.run_concept_gate(rec, reading, baseline, d, budget_used=0, budget=run.opts.gate_budget + 1,
                              mode=run.opts.mode, accepted=run.all_concepts())
    (d / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1), encoding="utf-8")
    if v.verdict != "OK":
        rollback_concept(rec.id, baseline, d)
    return v
