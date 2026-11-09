"""Code: one session per accepted node writes the rule and the witness; the harness gates it.

The session starts from two files the harness wrote (`skeleton.py`): every declaration the gate
compares, the parameters as terms, the four scenarios with their verdicts. It is shown the Core
surface, the contracts of what its record claims and of what those read (the ones its reviewer is
shown), the run's reading (the values its witnesses must be built against), and the most recently
accepted node as a worked example. Core is readable, not writable; the harness is neither.
"""
from __future__ import annotations
import json
from pathlib import Path
from ..checks import gate
from ..lean import index_sync, lean, skeleton, surface
from ..model import acquisition, definitions as definitions_mod, nodeid, ontology
from ..store import jsonl, paths
from ..store.gaps import GapLedger
from ..agents import render, session
from ..model.blueprint import Node, ConceptRecord
from ..model.reading import Reading
from ..store.state import Run, base_view
from . import validate as validate_phase

PLACEHOLDERS = ("node", "files", "core_surface", "contracts", "reading", "example", "skeletons", "gate", "rule_path", "witness_path", "node_id",
                "core_dir", "anchors", "aggregate_atom")
PLACEHOLDERS_CONCEPT = ("concept", "files", "core_surface", "contracts", "example", "skeletons", "gate", "concept_path", "witness_path", "concept_id",
                        "mode", "core_dir", "anchors")
SESSION_FAILED = "SESSION_FAILED"     # the session never ran; not a verdict on the node


def _files_digest(rels: tuple[str, ...]) -> str | None:
    """The digest of a candidate's two files as they are in the library, or None when one is missing."""
    import hashlib
    h = hashlib.sha256()
    for rel in rels:
        p = paths.LIBRARY / rel
        if not p.exists():
            return None
        h.update(rel.encode()); h.update(p.read_bytes())
    return h.hexdigest()


def task_context(run: Run, kind: str, ident: str, raw: dict, reading: Reading) -> str | None:
    """The admission key a task's gate ran on: the candidate record's context (what it calls and
    composes, the reading values it reads, Core and the ontology) and the gate's implementation,
    computed from the candidate as given, before it is accepted. In a candidate transaction, Core and
    the ontology are the production digests it opened on (`base`), so the key does not depend on
    where the candidate lies."""
    from . import integrate as integrate_phase
    from ..loop import semantic_inputs
    try:
        base = getattr(run, "base", None) or {k: v for k, v in semantic_inputs(run.opts).items() if k in ("core", "ontology")}
        return integrate_phase.admission_key(run, kind, ident, reading, base,
                                             record=raw, catalogue={"nodes": run.all_nodes(), "concepts": run.all_concepts()})
    except (ValueError, KeyError, OSError):
        return None


def _finished_verdict(d: Path, rels: tuple[str, ...], context: str | None = None) -> gate.Verdict | None:
    """The verdict a task directory already holds, when the loop was interrupted after the gate:
    the task is finished and a resume applies its outcome instead of coding it again. A failing
    verdict rolled its files back already. A verdict is reused only on the context its gate ran on
    (`context`, the task's admission key); `OK` only while both candidate files are in the library
    as the gate passed them. `SESSION_FAILED` (the session never ran) and `INFRA` (the toolchain or the
    run's own stop kept the gate from judging the candidate) decide nothing, and are not reused."""
    f = d / "verdict.json"
    if not f.exists():
        return None
    try:
        v = json.loads(f.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    if v.get("verdict") in (SESSION_FAILED, gate.INFRA):
        return None
    extras = v.get("extras", {})
    if extras.get("context") != context:
        return None
    if v.get("verdict") == "OK" and (not extras.get("candidate_digest") or extras.get("candidate_digest") != _files_digest(rels)):
        return None
    return gate.Verdict(v["verdict"], v.get("details", []), extras=extras)


def _save_verdict(d: Path, v: gate.Verdict, rels: tuple[str, ...], context: str | None = None) -> None:
    v.extras["context"] = context
    if v.verdict == "OK":
        v.extras["candidate_digest"] = _files_digest(rels)
    (d / "verdict.json").write_text(json.dumps(v.to_dict(), ensure_ascii=False, indent=1), encoding="utf-8")


def last_task(run: Run, ident: str) -> Path | None:
    """The record's most recent task directory of an earlier iteration that holds a verdict."""
    name = concept_dirname(ident) if nodeid.is_concept_id(ident) else ident
    done = [p.parent for p in run.dir.glob(f"iter-*/code/{name}/verdict.json") if int(p.parent.parent.parent.name[5:]) < run.iteration]
    return max(done, key=lambda p: p.parent.parent.name) if done else None


def _saved_candidate(saved: Path | None, rels: tuple[str, ...], context: str | None, verdict: str = gate.GATE_TIMEOUT) -> Path | None:
    """`saved` when it holds a candidate whose gate ended with `verdict` on this same context, with both
    files kept: gated again as it is, it needs no new coding session. `GATE_TIMEOUT`: the evaluation's
    cost (a deadline, or a resource failure reproduced in isolation; not a panic), in an earlier task;
    `INFRA`: a gate the toolchain or the run's stop kept from judging, in the task's own directory. Its context is the task's admission key (the
    record, what it calls and composes, the reading values it reads, Core, the ontology and the gate's
    implementation), so any change to those codes the record again."""
    if saved is None or context is None:
        return None
    try:
        v = json.loads((saved / "verdict.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    ok = (v.get("verdict") == verdict and not v.get("extras", {}).get("panic")
          and v.get("extras", {}).get("context") == context and all((saved / "final" / r).is_file() for r in rels))
    return saved if ok else None


def _gate_saved(d: Path, rels: tuple[str, ...], saved: Path, context: str | None, run_gate, rollback_) -> gate.Verdict:
    """Gate the saved candidate again, at the same deadline, without a session: its files enter the
    library as they were gated, and the verdict names the task they come from."""
    for rel in rels:
        p = paths.LIBRARY / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes((saved / "final" / rel).read_bytes())
    (d / "rerun_of.txt").write_text(str(saved), encoding="utf-8")
    print(f"[code] {d.name}: gating again the candidate saved in {saved}; no session")
    v = run_gate()
    v.extras["rerun_of"] = str(saved)
    _save_verdict(d, v, rels, context)
    if v.verdict != "OK":
        rollback_()
    return v


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


def _restore(work: Path, baseline: dict[str, str], rels: tuple[str, ...], keep_final: bool = True) -> None:
    """Every file back to its state before the session: restored from `before/` when it existed,
    removed when it did not. What a gated candidate left is kept under `final/`, for a repair session
    to read; `final/` is written once, from the candidate, so a second rollback never overwrites it.
    A session that never finished (`keep_final=False`) left no candidate: nothing is kept."""
    for rel in rels:
        p = paths.LIBRARY / rel
        dst = work / "final" / rel
        if keep_final and p.exists() and not dst.exists():
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


def _start(work: Path, rels: tuple[str, ...]) -> dict[str, str]:
    """The task's baseline. The first start keeps the files the session will overwrite and opens the
    attempt's gate budget; a later start (a resume of a task whose session did not finish) first puts
    the files back as they were before it, so nothing an earlier launch wrote is taken for the
    baseline, and the gate budget continues."""
    first = not (work / "baseline.json").exists()
    if not first:
        _restore(work, json.loads((work / "baseline.json").read_text(encoding="utf-8")), rels, keep_final=False)
    baseline = gate.repo_digest()
    (work / "baseline.json").write_text(json.dumps(baseline), encoding="utf-8")
    if first:
        (work / "gate_runs.txt").write_text("0", encoding="utf-8")
        _keep_before(work, rels)
    return baseline


def _cut_off_relaunch(work: Path, rels: tuple[str, ...], budget: int) -> str:
    """Before relaunching a coding session that was cut off: its files keep the candidate it left,
    and it may run the gate at least half its budget again (the runs it left, if more). Returns what
    the relaunch's prompt adds: that the files hold that candidate, the budget, and the verdict of
    the last gate run the cut-off launch made. The same text is kept as `relaunch_note.md`."""
    floor = -(-budget // 2)
    f = work / "gate_runs.txt"
    used = int(f.read_text().strip() or 0) if f.exists() else 0
    if used > budget - floor:
        f.write_text(str(budget - floor), encoding="utf-8")
    left = budget - min(used, budget - floor)
    last = work / "last_gate.json"
    try:
        v = json.loads(last.read_text(encoding="utf-8")) if last.exists() else None
    except json.JSONDecodeError:
        v = None
    verdict = ("its last gate run returned " + v["verdict"] + "".join(f"\n  - {x}" for x in v.get("details", [])[:8])
               if v else "it ran no gate")
    files = "".join(f"- `{(paths.LIBRARY / r).resolve()}`\n" for r in rels)
    note = ("\n\n## This is a relaunch after a cut-off\n\n"
            "The previous launch of this session was cut off before it finished. The two files no longer hold the skeletons "
            "shown above: they hold the candidate that launch left, which you continue from:\n" + files +
            f"\nThis task has used {used} gate run(s); this launch may run the gate {left} more time(s). "
            f"Before it was cut off, {verdict}\n(the files may have changed after that run).\n")
    (work / "relaunch_note.md").write_text(note, encoding="utf-8")
    return note


def _task_files(work: Path, registry: dict | None) -> None:
    """What a gate run from this task directory registers: the accepted ids plus this task's."""
    if registry is not None:
        (work / "registry.json").write_text(json.dumps(registry), encoding="utf-8")


def tolerate(work: Path, files: list[str], fresh: bool = False) -> None:
    """Files of the pipeline that a gate run from this task directory does not count as changed by
    its session (`concurrent.json`, keyed as the repository digest keys them): those of the other
    tasks running beside it, and those the loop writes for them. `fresh` replaces what an earlier
    launch left; otherwise `files` are added to the list, which the gate reads afresh at every run."""
    work.mkdir(parents=True, exist_ok=True)
    have = set() if fresh else gate.task_concurrent(work)
    jsonl.write_atomic(work / "concurrent.json", json.dumps(sorted(have | set(files))))


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


def contracts_block(run: Run, rec: Node | ConceptRecord) -> str:
    """The contracts a coding session writes by, from the run's ontology and catalogue through the
    one gloss path the reviewer and the judges are shown: for a node, its reviewer's own contracts
    (every id it claims, the atoms its claimed primitives and concepts read, its declared facts and
    its compositions); for a concept, every atom, primitive and concept its elements map to and the
    atoms those primitives and concepts read."""
    onto = ontology.load(run.opts.ontology)
    if isinstance(rec, Node):
        glosses = validate_phase.glosses_for(rec, onto, run)
    else:
        concepts = run.all_concepts()
        ids = validate_phase.claimed_closure(rec, onto) | rec.refs()
        for cid in rec.refs():
            ids |= set((concepts.get(cid) or {}).get("reads", []))
        glosses = validate_phase.glosses_of(sorted(ids), onto, run)
    return "### Contracts\n\n" + validate_phase.contracts_table(glosses)


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


def run_code(run: Run, node: Node, reading: Reading, registry: dict | None = None, saved: Path | None = None) -> gate.Verdict:
    """One coding session for a node, then the harness's own gate call. `registry` names the ids
    the gate registers (the accepted ones and this node); `saved` an earlier task whose candidate is
    gated again instead of a session when `_saved_candidate` admits it, and so is a candidate the task's
    own directory keeps from a gate that did not judge it (`INFRA`). The files its scope check does
    not count are the caller's to record (`tolerate`)."""
    d = node_dir(run, node.id)
    d.mkdir(parents=True, exist_ok=True)
    rels = (nodeid.rule_path(node.id), nodeid.witness_path(node.id))
    context = task_context(run, "node", node.id, node.raw, reading)
    done = _finished_verdict(d, rels, context)
    if done is not None:                                     # a resume: the session ran and the gate decided
        print(f"[code] {node.id}: reusing the {done.verdict} verdict of the finished session")
        return done
    (d / "node.json").write_text(json.dumps(node.raw, ensure_ascii=False, indent=1), encoding="utf-8")
    _task_files(d, registry)
    only_nodes = None if registry is None else sorted(set(registry.get("nodes", [])) | {node.id})
    only_concepts = None if registry is None else registry.get("concepts")
    baseline = _start(d, rels)
    again = _saved_candidate(saved, rels, context) or _saved_candidate(d, rels, context, gate.INFRA)
    if again is not None:
        return _gate_saved(d, rels, again, context, lambda: gate.run_gate(node, reading, baseline, d, budget_used=0, budget=run.opts.gate_budget + 1,
                                                                           accepted_concepts=run.all_concepts(),
                                                                           acquisition=run.opts.acquisition_profile),
                           lambda: rollback(node.id, baseline, d))
    rule_rel, wit_rel = rels
    rule_text, wit_text = write_skeletons(node)
    if not run.opts.dry_run:
        with lean.library_lock(paths.LIBRARY):
            index_sync.write_index(only_nodes=only_nodes, only_concepts=only_concepts)
            code, out = lean.lake_build(paths.LIBRARY, ["TrafficSpec.Index", nodeid.rule_module(node.id), nodeid.witness_module(node.id)])
        (d / "prewarm.log").write_text(out, encoding="utf-8")
        if code:
            print(f"[code] warning: the skeleton of {node.id} does not build; see prewarm.log")
    rule_abs, wit_abs = (paths.LIBRARY / rule_rel).resolve(), (paths.LIBRARY / wit_rel).resolve()
    files = (f"- rule: `{rule_abs}` — `namespace {nodeid.rule_namespace(node.id)}`, `def rule : Rule`\n"
             f"- witness: `{wit_abs}` — `namespace {nodeid.witness_namespace(node.id)}`, `def scenarios : List Scenario`\n"
             f"- imports: the rule file imports `TrafficSpec.Core.Language.Rule` only; the witness file imports `{nodeid.rule_module(node.id)}` and `TrafficSpec.Core.Evidence.Builders`\n"
             f"- both files exist already, written by the harness from the node (below); they build, and every declaration the gate compares is filled in — your work is the formulas and the scenes\n")
    skeletons = (f"```lean\n-- library/{rule_rel} (as written by the harness)\n{rule_text}\n```\n\n"
                 f"```lean\n-- library/{wit_rel} (as written by the harness)\n{wit_text}\n```\n")
    gate_text = (f"Run exactly this command, nothing more and nothing else:\n\n```\n{gate_cli(run, node.id)}\n```\n\nIt prints the verdict and its details. The verdicts on your files: "
                 + ", ".join(gate.VERDICTS) + f". `{gate.INFRA}` is not one: the toolchain or the run did not let the gate judge your files. Budget: {run.opts.gate_budget} runs; the harness re-runs the gate itself after you stop, on the files as they are then.\n")
    prompt = render.render("code.md", {
        "node": json.dumps(node.raw, ensure_ascii=False, indent=1) + "\n\n" + GapLedger.for_run(paths.GAPS_DIR, run).cited_block(node.raw)
                + definitions_mod.render_sources(definitions_mod.source_records(run, node.definition_sources()), definitions_mod.SOURCES_HEADING),
        "files": files, "core_surface": surface.core_surface(run.all_concepts(), claimed=node.claimed_atoms()), "contracts": contracts_block(run, node),
        "reading": reading_table(node, reading) + acquisition.standard_note(getattr(run.opts, "acquisition_profile", None)),
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
                        deny=session.deny_rules("code", run.opts.run_id), tools=session.CODE_TOOLS,
                        env=session.harness_env(run.opts.session_timeout),
                        relaunch=lambda: (_restore(d, baseline, rels, keep_final=False), write_skeletons(node)),
                        relaunch_cut_off=lambda: _cut_off_relaunch(d, rels, run.opts.gate_budget))
        except session.SessionUnavailable as e:
            _restore(d, baseline, rels, keep_final=False)
            v = gate.Verdict(SESSION_FAILED, [str(e)])
            _save_verdict(d, v, rels, context)
            return v
    # the harness's own gate call decides; the session's calls were advice to itself
    v = gate.run_gate(node, reading, baseline, d, budget_used=0, budget=run.opts.gate_budget + 1,
                      accepted_concepts=run.all_concepts(), acquisition=run.opts.acquisition_profile)
    _save_verdict(d, v, rels, context)
    if v.verdict != "OK":
        rollback(node.id, baseline, d)
    return v


def gate_from_cli(run_id: str, node_id: str) -> gate.Verdict:
    """The gate as the coding session calls it: counted against the budget, never authoritative, its
    verdict kept as `last_gate.json` for a relaunch after a cut-off. `node_id` is a node id or a
    concept id. A session coding in a candidate (its environment names the candidate's directory)
    gates in the candidate: its library, its scope and its task directories."""
    import os
    from .candidate import CANDIDATE_ENV, CANDIDATE_ITER
    area = os.environ.get(CANDIDATE_ENV)
    if not area:
        return _gate_from_cli(run_id, node_id, paths.run_dir(run_id))
    sc = json.loads((Path(area) / "scope.json").read_text(encoding="utf-8"))
    with paths.at_library(Path(sc["tree"]) / "library"), gate.candidate_scope(gate.CandidateScope(Path(sc["tree"]), frozenset(sc["write_set"]))):
        return _gate_from_cli(run_id, node_id, Path(area), CANDIDATE_ITER, Path(sc["reading"]), sc["concepts"])


def _gate_from_cli(run_id: str, node_id: str, root: Path, pattern: str = "iter-*", reading: Path | None = None,
                   concepts: dict | None = None) -> gate.Verdict:
    run_root = paths.run_dir(run_id)
    dirname = concept_dirname(node_id) if nodeid.is_concept_id(node_id) else node_id
    iters = sorted(p for p in root.glob(pattern) if (p / "code" / dirname).exists())
    if not iters:
        return gate.Verdict("SCOPE_VIOLATION", [f"no task directory for {node_id} under {run_root}"])
    d = iters[-1] / "code" / dirname
    baseline = json.loads((d / "baseline.json").read_text(encoding="utf-8"))
    opts = json.loads((run_root / "options.json").read_text(encoding="utf-8"))
    used = int((d / "gate_runs.txt").read_text().strip() or 0)
    (d / "gate_runs.txt").write_text(str(used + 1), encoding="utf-8")
    rd = Reading(reading or paths.local(opts["reading"]))
    catalogue = concepts if concepts is not None else cli_catalogue(run_id)
    if nodeid.is_concept_id(node_id):
        rec = ConceptRecord(json.loads((d / "concept.json").read_text(encoding="utf-8")))
        v = gate.run_concept_gate(rec, rd, baseline, d, used, opts["gate_budget"], mode=opts.get("mode", "train"),
                                  accepted={k: r for k, r in catalogue.items() if k != node_id} if concepts is not None else catalogue)
    else:
        node = Node(json.loads((d / "node.json").read_text(encoding="utf-8")))
        v = gate.run_gate(node, rd, baseline, d, used, opts["gate_budget"], accepted_concepts=catalogue,
                          acquisition=opts.get("acquisition_profile"))
    (d / "last_gate.json").write_text(json.dumps({"verdict": v.verdict, "details": v.details[:8]}, ensure_ascii=False), encoding="utf-8")
    return v


def cli_catalogue(run_id: str) -> dict[str, dict]:
    """The accepted concepts the run's own gate is given (`Run.all_concepts`): the run's committed
    snapshot and its base chain (`base_view`), each fenced version carrying `fenced`. Read without
    writing, so a coding session's gate never rewrites a record its owner commits."""
    view = base_view(run_id)
    return {k: {**v, "fenced": view["fenced"][k]} if k in view["fenced"] else v for k, v in view["concepts"].items()}


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


def run_code_concept(run: Run, rec: ConceptRecord, reading: Reading, registry: dict | None = None,
                     saved: Path | None = None) -> gate.Verdict:
    d = concept_dir(run, rec.id)
    d.mkdir(parents=True, exist_ok=True)
    rels = (nodeid.concept_path(rec.id), nodeid.concept_witness_path(rec.id))
    context = task_context(run, "concept", rec.id, rec.raw, reading)
    done = _finished_verdict(d, rels, context)
    if done is not None:
        print(f"[code] {rec.id}: reusing the {done.verdict} verdict of the finished session")
        return done
    (d / "concept.json").write_text(json.dumps(rec.raw, ensure_ascii=False, indent=1), encoding="utf-8")
    _task_files(d, registry)
    only_nodes = None if registry is None else registry.get("nodes")
    only_concepts = None if registry is None else sorted(set(registry.get("concepts", [])) | {rec.id})
    baseline = _start(d, rels)
    again = _saved_candidate(saved, rels, context) or _saved_candidate(d, rels, context, gate.INFRA)
    if again is not None:
        return _gate_saved(d, rels, again, context, lambda: gate.run_concept_gate(rec, reading, baseline, d, budget_used=0,
                                                                                   budget=run.opts.gate_budget + 1, mode=run.opts.mode,
                                                                                   accepted=run.all_concepts()),
                           lambda: rollback_concept(rec.id, baseline, d))
    c_rel, w_rel = rels
    c_text, w_text = write_concept_skeletons(rec)
    if not run.opts.dry_run:
        with lean.library_lock(paths.LIBRARY):
            index_sync.write_index(only_nodes=only_nodes, only_concepts=only_concepts)
            code, out = lean.lake_build(paths.LIBRARY, ["TrafficSpec.Index", nodeid.concept_module(rec.id), nodeid.concept_witness_module(rec.id)])
        (d / "prewarm.log").write_text(out, encoding="utf-8")
        if code:
            print(f"[code] warning: the skeleton of {rec.id} does not build; see prewarm.log")
    c_abs, w_abs = (paths.LIBRARY / c_rel).resolve(), (paths.LIBRARY / w_rel).resolve()
    files = (f"- concept: `{c_abs}` — `namespace {nodeid.concept_namespace(rec.id)}`, `def concept : Concept`\n"
             f"- witness: `{w_abs}` — `namespace {nodeid.concept_witness_namespace(rec.id)}`, `def instances : List Concept.Instance`, `def scenarios : List Scenario`\n"
             f"- imports: the concept file imports `TrafficSpec.Core.Language.Concept` only; the witness file imports `{nodeid.concept_module(rec.id)}` and `TrafficSpec.Core.Evidence.Builders`\n"
             f"- both files exist already, written by the harness from the record (below); they build, and every declaration the gate compares is filled in — your work is the body and the scenes\n")
    skeletons = (f"```lean\n-- library/{c_rel} (as written by the harness)\n{c_text}\n```\n\n"
                 f"```lean\n-- library/{w_rel} (as written by the harness)\n{w_text}\n```\n")
    gate_text = (f"Run exactly this command, nothing more and nothing else:\n\n```\n{gate_cli(run, rec.id)}\n```\n\nIt prints the verdict and its details. The verdicts on your files: "
                 + ", ".join(gate.CONCEPT_VERDICTS) + f". `{gate.INFRA}` is not one: the toolchain or the run did not let the gate judge your files. Budget: {run.opts.gate_budget} runs; the harness re-runs the gate itself after you stop, on the files as they are then.\n")
    prompt = render.render("code_concept.md", {
        "concept": json.dumps(rec.raw, ensure_ascii=False, indent=1), "files": files,
        "core_surface": surface.core_surface(run.all_concepts(), claimed=rec.claimed_atoms() | rec.refs()), "contracts": contracts_block(run, rec),
        "example": concept_example(run), "skeletons": skeletons,
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
                        deny=session.deny_rules("code", run.opts.run_id), tools=session.CODE_TOOLS,
                        env=session.harness_env(run.opts.session_timeout),
                        relaunch=lambda: (_restore(d, baseline, rels, keep_final=False), write_concept_skeletons(rec)),
                        relaunch_cut_off=lambda: _cut_off_relaunch(d, rels, run.opts.gate_budget))
        except session.SessionUnavailable as e:
            _restore(d, baseline, rels, keep_final=False)
            v = gate.Verdict(SESSION_FAILED, [str(e)])
            _save_verdict(d, v, rels, context)
            return v
    v = gate.run_concept_gate(rec, reading, baseline, d, budget_used=0, budget=run.opts.gate_budget + 1,
                              mode=run.opts.mode, accepted=run.all_concepts())
    _save_verdict(d, v, rels, context)
    if v.verdict != "OK":
        rollback_concept(rec.id, baseline, d)
    return v
