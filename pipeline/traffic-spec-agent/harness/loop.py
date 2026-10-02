"""The loop: plan → validate A → code (concepts first, then the rules that use them), each coded
node reviewed against its law → integrate → feedback, until nothing is plannable or an iteration
accepts nothing new."""
from __future__ import annotations
import json
from dataclasses import asdict
from pathlib import Path
import shutil
from .checks import aggregates, gate, validate_a
from .model import blueprint, corpus, nodeid, ontology
from .lean import index_sync, lean
from .store import paths
from .agents import session
from .model.blueprint import Node, ConceptRecord, concepts_of
from .store.gaps import GapLedger
from .store.ledger import Ledger, ConceptLedger, NodeLedger
from .phases import plan as plan_phase, validate as validate_phase, code as code_phase, integrate as integrate_phase, feedback as feedback_phase
from .model.reading import Reading
from .store.state import Options, Run
from .model.mapping import MappingIndex


def topological(nodes: list[Node]) -> list[Node]:
    """Nodes ordered so that every node follows the nodes it composes (ties keep plan order)."""
    by_id = {n.id: n for n in nodes}
    out: list[Node] = []
    state: dict[str, int] = {}

    def visit(n: Node) -> None:
        if state.get(n.id) == 2:
            return
        state[n.id] = 1
        for c in n.compositions():
            m = by_id.get(c.get("rule"))
            if m is not None and state.get(m.id) != 1:
                visit(m)
        state[n.id] = 2
        out.append(n)

    for n in nodes:
        visit(n)
    return out


def concept_order(concepts: list[ConceptRecord]) -> list[ConceptRecord]:
    """Concepts ordered so that every concept follows the concepts it references."""
    by_id = {c.id: c for c in concepts}
    out: list[ConceptRecord] = []
    state: dict[str, int] = {}

    def visit(c: ConceptRecord) -> None:
        if state.get(c.id) == 2:
            return
        state[c.id] = 1
        for r in sorted(c.refs()):
            m = by_id.get(r)
            if m is not None and state.get(m.id) != 1:
                visit(m)
        state[c.id] = 2
        out.append(c)

    for c in concepts:
        visit(c)
    return out


def concept_deps(n: Node) -> set[str]:
    """The pipeline concepts a node claims (elements and operationalizations)."""
    ids = {d for e in n.get("elements", []) for d in e.get("derived", [])}
    ids |= {x for o in n.get("operationalizations", []) for x in concepts_of(o)}
    return {i for i in ids if nodeid.is_concept_id(i)}


def plan_batches(plannable: list, ledger: Ledger, by_id: dict[str, corpus.Law], batch_size: int
                 ) -> tuple[list[list[corpus.Law]], dict[str, list[str]], dict[str, list[str]]]:
    """The plannable laws in plan sessions of at most `batch_size`, ordered so that a law comes
    after every law its text names: a named law that is accepted is composed by its node; one
    that is plannable now goes into the same or an earlier batch (a cycle of references shares a
    batch); one that is planned, held or blocked makes this law wait (returned as `waiting`); one
    closed as failed closes this law too (returned as `failed`). Depth-first order over the
    reference graph, so a chain of exceptions is planned root first."""
    ids = set(by_id)
    plan_ids = {e.law for e in plannable}
    refs = {lid: corpus.references(by_id[lid], ids) for lid in plan_ids}
    waiting: dict[str, list[str]] = {}
    failed: dict[str, list[str]] = {}
    ready: set[str] = set()
    for lid in plan_ids:
        outside = [r for r in refs[lid] if r not in plan_ids]
        dead = [r for r in outside if ledger.entries.get(r) and ledger.entries[r].state == "failed"]
        pending = [r for r in outside if ledger.entries.get(r) and ledger.entries[r].state not in ("accepted", "failed")]
        if dead:
            failed[lid] = dead
        elif pending:
            waiting[lid] = pending
        else:
            ready.add(lid)
    # strongly connected components of the reference graph among the ready laws, in an order that
    # puts every component after the components it references (Tarjan)
    index: dict[str, int] = {}
    low: dict[str, int] = {}
    on: set[str] = set()
    stack: list[str] = []
    comps: list[list[str]] = []
    counter = [0]

    def strong(v: str) -> None:
        index[v] = low[v] = counter[0]; counter[0] += 1
        stack.append(v); on.add(v)
        for w in sorted(refs[v] & ready):
            if w not in index:
                strong(w); low[v] = min(low[v], low[w])
            elif w in on:
                low[v] = min(low[v], index[w])
        if low[v] == index[v]:
            comp = []
            while True:
                w = stack.pop(); on.discard(w); comp.append(w)
                if w == v:
                    break
            comps.append(sorted(comp))

    for v in sorted(ready):
        if v not in index:
            strong(v)
    batches: list[list[corpus.Law]] = []
    current: list[corpus.Law] = []
    for comp in comps:                      # Tarjan emits a component after every component it references
        laws = [by_id[l] for l in comp]
        if current and len(current) + len(laws) > batch_size:
            batches.append(current); current = []
        current += laws
    if current:
        batches.append(current)
    return batches, waiting, failed


def doctor_ok() -> None:
    """The doctor runs before a loop: it runs no Lean and takes seconds, and a failure of a
    generated artifact would otherwise surface as a gate verdict charged to a law."""
    import sys
    sys.path.insert(0, str(paths.REPO))
    from scripts.diagnostics import doctor as doctor_mod
    if doctor_mod.run(paths.REPO, paths.LIBRARY, False):
        raise SystemExit("[loop] the doctor found a failure; fix it before a run")


# ---------------------------------------------------------------------------------------------
# Checkpoints: what an iteration has done so far, saved after every step, so that a killed loop
# resumes where it was and an interrupted session is rolled back rather than refused.
# ---------------------------------------------------------------------------------------------
STAGES = ["start", "repaired", "planned", "validated", "concepts", "nodes", "integrated", "done", "abandoned"]


def progress_file(run: Run, iteration: int | None = None) -> Path:
    return paths.iter_dir(run.opts.run_id, iteration or run.iteration) / "progress.json"


def load_progress(run: Run, iteration: int) -> dict:
    f = progress_file(run, iteration)
    if f.exists():
        return json.loads(f.read_text(encoding="utf-8"))
    return {"stage": "start", "repairs": {}, "plan_dir": None, "aggregates_merged": False, "concepts": {}, "nodes": {}, "kept": []}


def save_progress(run: Run, prog: dict) -> None:
    progress_file(run).write_text(json.dumps(prog, ensure_ascii=False, indent=1), encoding="utf-8")


def resumable_iteration(run: Run) -> int | None:
    """The latest iteration directory whose checkpoint is short of `done` (an older directory with
    no checkpoint counts as incomplete too), or None."""
    dirs = sorted((p for p in run.dir.glob("iter-*") if p.is_dir()), key=lambda p: int(p.name.split("-")[1]))
    if not dirs:
        return None
    n = int(dirs[-1].name.split("-")[1])
    return n if load_progress(run, n)["stage"] not in ("done", "abandoned") else None


def recover_interrupted(run: Run, iteration: int) -> list[str]:
    """Roll back every coding task of the iteration that has no verdict: the session was killed
    with its files on disk. Returns the ids rolled back."""
    from .phases import code as code_phase
    out = []
    code_dir = paths.iter_dir(run.opts.run_id, iteration) / "code"
    if not code_dir.exists():
        return out
    for d in sorted(code_dir.iterdir()):
        if not d.is_dir() or (d / "verdict.json").exists() or not (d / "baseline.json").exists():
            continue
        baseline = json.loads((d / "baseline.json").read_text(encoding="utf-8"))
        if (d / "concept.json").exists():
            cid = json.loads((d / "concept.json").read_text(encoding="utf-8"))["concept_id"]
            code_phase.rollback_concept(cid, baseline, d); out.append(cid)
        elif (d / "node.json").exists():
            nid = json.loads((d / "node.json").read_text(encoding="utf-8"))["node_id"]
            code_phase.rollback(nid, baseline, d); out.append(nid)
    return out


def finished_tasks(run: Run) -> set[str]:
    """Ids whose task directory in a not-yet-done iteration holds an `OK` verdict: their files are
    in the library by right, and the resume takes them to review instead of coding them again."""
    out: set[str] = set()
    for pf in run.dir.glob("iter-*/progress.json"):
        try:
            if json.loads(pf.read_text(encoding="utf-8")).get("stage") in ("done", "abandoned"):
                continue
        except json.JSONDecodeError:
            continue
        for v in pf.parent.glob("code/*/verdict.json"):
            try:
                if json.loads(v.read_text(encoding="utf-8")).get("verdict") != "OK":
                    continue
            except json.JSONDecodeError:
                continue
            name = v.parent.name
            if name.startswith("concept__"):
                out.add(_concept_id_of_dirname(name))
            else:
                out.add(name)
    return out


def _concept_id_of_dirname(dirname: str) -> str:
    """`concept__drv_motion_halt` → `drv.motion.halt`."""
    lean = dirname[len("concept__"):]
    fam, _, name = lean[len("drv_"):].partition("_")
    return f"drv.{fam}.{name}"


def check_library_isolation(run: Run) -> None:
    """The library holds exactly the nodes and concepts this run (or its base run) accepted: a node
    or concept on disk that no accepted record names would be registered and built into this
    run's library without ever passing through its plan; an accepted record whose files are gone
    cannot be composed or called. Either way the run does not start."""
    on_disk_nodes, on_disk_concepts = set(index_sync.node_ids()), set(index_sync.concept_ids())
    finished = finished_tasks(run)                           # gated `OK` in an unfinished iteration, not yet accepted: the resume reviews them
    stray = sorted(((on_disk_nodes - set(run.all_nodes())) | (on_disk_concepts - set(run.all_concepts()))) - finished)
    missing = sorted((set(run.all_nodes()) - on_disk_nodes) | (set(run.all_concepts()) - on_disk_concepts))
    if stray:
        raise SystemExit(f"[loop] the library holds {len(stray)} node(s)/concept(s) this run did not accept: {stray[:6]}\n"
                         "        archive them first: python -m harness init --fresh --snapshot <the run they belong to>")
    if missing:
        raise SystemExit(f"[loop] accepted node(s)/concept(s) missing from the library: {missing[:6]}\n"
                         "        restore their files (results/<run>/library_snapshot/) or start a new run")


def _wave(items, key_deps, accepted: set[str]):
    """The items whose dependencies are all accepted, in the given order."""
    return [x for x in items if all(d in accepted for d in key_deps(x))]


def _files_of(kind: str, ident: str) -> list[str]:
    if kind == "concept":
        return [gate.lib_rel(nodeid.concept_path(ident)), gate.lib_rel(nodeid.concept_witness_path(ident))]
    return [gate.lib_rel(nodeid.rule_path(ident)), gate.lib_rel(nodeid.witness_path(ident))]


def run_loop(opts: Options) -> dict:
    from concurrent.futures import ThreadPoolExecutor
    run = Run(opts)
    run.dir.mkdir(parents=True, exist_ok=True)
    if not run.reading_file.exists():
        shutil.copy2(opts.reading, run.reading_file)      # the operator's base reading; the run adds derived aggregates
    (run.dir / "options.json").write_text(json.dumps({**asdict(opts), "laws": str(opts.laws), "ontology": str(opts.ontology),
                                                      "base_reading": str(opts.reading), "reading": str(run.reading_file)}, indent=1), encoding="utf-8")
    doctor_ok()
    run.load_accepted()
    laws = corpus.load_laws(opts.laws)
    defs = corpus.load_definitions(opts.laws)
    by_id = {l.id: l for l in laws}
    onto = ontology.load(opts.ontology)
    reading = Reading(run.reading_file)
    ledger = Ledger(run.ledger_file, [l.id for l in laws], opts.plan_attempts)
    concept_ledger = ConceptLedger(run.concept_ledger_file, opts.concept_attempts)
    node_ledger = NodeLedger(run.node_ledger_file, opts.node_attempts)
    gap_ledger = GapLedger(paths.GAP_LEDGER)
    # an interrupted iteration: its killed sessions are rolled back, and it is resumed or discarded
    resume_n = resumable_iteration(run)
    if resume_n is not None:
        rolled = recover_interrupted(run, resume_n)
        if rolled:
            print(f"[loop] iteration {resume_n}: rolled back interrupted session(s) {rolled}")
        if opts.restart:
            prog = load_progress(run, resume_n); prog["stage"] = "abandoned"
            run.iteration = resume_n; save_progress(run, prog)
            for e in ledger.entries.values():
                if e.state == "planned" and e.iteration == resume_n and not all(i in run.all_nodes() for i in e.nodes):
                    e.state = "open"
            ledger.save()
            print(f"[loop] iteration {resume_n} discarded (--restart)"); resume_n = None
        else:
            print(f"[loop] iteration {resume_n} resumes at stage `{load_progress(run, resume_n)['stage']}`")
    check_library_isolation(run)
    reopened = ledger.reopen_for_gaps(gap_ledger.decided())
    for it in range(opts.max_iterations):
        if resume_n is not None:
            run.iteration = resume_n; run.iter.mkdir(parents=True, exist_ok=True)
            prog = load_progress(run, resume_n); resume_n = None
        else:
            plannable = ledger.plannable()
            repairs = concept_ledger.repairable()
            carried_any = bool(run.load_deferred())
            if not plannable and not repairs and not carried_any:
                print("[loop] nothing plannable, nothing to repair, nothing held: every law is accepted, blocked or failed"); break
            run.next_iteration()
            prog = load_progress(run, run.iteration)
        plannable = ledger.plannable()
        print(f"[loop] iteration {run.iteration}: {len(plannable)} plannable law(s), stage `{prog['stage']}`")
        notes, to_user, gaps_filed = [], [], []
        coder_narrowings: dict[str, list[dict]] = {}

        def persist() -> None:
            ledger.save(); concept_ledger.save(); node_ledger.save(); run.save_accepted(); save_progress(run, prog)

        def stage_at_least(s: str) -> bool:
            return STAGES.index(prog["stage"]) >= STAGES.index(s)

        for law, why in reopened:
            notes.append(f"`{law}` reopened after the operator decided its gap(s): " + "; ".join(why))
        reopened = []
        carried = [Node(d) for d in run.load_deferred() if d["node_id"] not in run.all_nodes()]

        # --- repair: a concept the gate or the review returned is re-proposed from the coder's evidence,
        # before any law is planned; its users stay held and uncharged
        repaired: list[ConceptRecord] = []
        if not stage_at_least("repaired"):
            try:
                for e in concept_ledger.repairable():
                    rec_raw = None
                    for cand in sorted(run.dir.glob("iter-*/code/concept__*/concept.json"), reverse=True):
                        d = json.loads(cand.read_text(encoding="utf-8"))
                        if d.get("concept_id") == e.concept:
                            rec_raw = d; break
                    if rec_raw is None:
                        continue
                    users = [n.raw for n in carried if e.concept in concept_deps(n)]
                    rdir = plan_phase.run_repair(run, ConceptRecord(rec_raw), e.reasons, Path(e.last_task), defs, users)
                    prog["repairs"][e.concept] = str(rdir)
                    save_progress(run, prog)
            except session.SessionUnavailable as ex:
                print(f"[loop] a repair session never ran ({ex}); iteration {run.iteration} abandoned, ledger unchanged")
                feedback_phase.write_feedback(run, ledger, notes + [f"iteration abandoned: a repair session never ran — {ex}"],
                                              ["sessions unavailable (account limit or API error); rerun the loop later"], [], concept_ledger)
                persist(); break
            try:
                planned_laws = {e.law for e in ledger.entries.values() if e.state == "planned"}
                for e in node_ledger.repairable(planned_laws):
                    if e.node in prog.get("node_repairs", {}):
                        continue
                    f = Path(e.last_task) / "node.json"
                    if not f.exists():
                        node_ledger.failed(e.node, ["no record found in the last task directory"]); continue
                    nrec = Node(json.loads(f.read_text(encoding="utf-8")))
                    siblings = [Node(v) for v in run.all_nodes().values() if Node(v).law == e.law] + \
                               [Node(d) for d in run.load_deferred() if Node(d).law == e.law and d.get("node_id") != e.node]
                    for o in node_ledger.entries.values():      # the law's other nodes under repair: their revised record if one exists, else their last planned one
                        if o.law != e.law or o.node == e.node or o.node in {s.id for s in siblings}:
                            continue
                        rec_o = plan_phase.load_node_repair(Path(prog["node_repairs"][o.node])) if o.node in prog.get("node_repairs", {}) else None
                        fo = Path(o.last_task) / "node.json"
                        if rec_o is None and fo.exists():
                            rec_o = Node(json.loads(fo.read_text(encoding="utf-8")))
                        if rec_o is not None:
                            siblings.append(rec_o)
                    rdir = plan_phase.run_node_repair(run, nrec, e.reasons, Path(e.last_task), by_id[e.law], defs, siblings, reading, onto)
                    prog.setdefault("node_repairs", {})[e.node] = str(rdir)
                    save_progress(run, prog)
            except session.SessionUnavailable as ex:
                print(f"[loop] a node repair session never ran ({ex}); iteration {run.iteration} abandoned, ledger unchanged")
                feedback_phase.write_feedback(run, ledger, notes + [f"iteration abandoned: a node repair session never ran — {ex}"],
                                              ["sessions unavailable (account limit or API error); rerun the loop later"], [], concept_ledger)
                persist(); break
            prog["stage"] = "repaired"; save_progress(run, prog)
        repaired_nodes: list[Node] = []
        for nid, rdir in prog.get("node_repairs", {}).items():
            e = node_ledger.entries.get(nid)
            law_of_node = e.law if e else nodeid.law_of(nid)[0]
            if e is not None and e.state != "returned":
                if e.state == "repaired":
                    rec_n = plan_phase.load_node_repair(Path(rdir))
                    if rec_n is not None and nid not in run.all_nodes():
                        repaired_nodes.append(rec_n)
                continue
            rec_n = plan_phase.load_node_repair(Path(rdir))
            vtxt = (Path(rdir) / "validation.txt").read_text(encoding="utf-8").strip() if (Path(rdir) / "validation.txt").exists() else ""
            wd = plan_phase.load_node_withdrawal(Path(rdir))
            planned_raw = json.loads((Path(e.last_task) / "node.json").read_text(encoding="utf-8")) if e and (Path(e.last_task) / "node.json").exists() else {}
            planned_spans = {s.get("id"): s for s in planned_raw.get("segmentation", [])}
            if rec_n is None and wd and wd.get("span") in planned_spans and wd.get("kind") in blueprint.GAP_KINDS:
                # the vocabulary cannot carry a span the law needs: a gap, decided by the operator, blocks the law
                gid = gap_ledger.add({"span": wd["span"], "kind": wd["kind"], "proposal": wd.get("missing", ""), "nearest": wd.get("nearest", []),
                                      "span_text": planned_spans[wd["span"]].get("text", ""), "law_refs": [law_of_node], "node_id": nid}, opts.run_id, run.iteration)
                gap_ledger.save()
                gaps_filed.append({"id": gid, "kind": wd["kind"], "span": planned_spans[wd["span"]].get("text", ""), "law_refs": [law_of_node]})
                node_ledger.failed(nid, [f"withdrawn: gap {gid}"])
                ledger.block(law_of_node, [gid], [f"node repair of `{nid}` withdrew span {wd['span']}: {wd.get('missing', '')}"])
                notes.append(f"`{nid}`: the repair session withdrew it — the vocabulary lacks {wd['kind']} `{wd.get('missing', '')}` for span {wd['span']}; gap {gid} filed, law blocked")
                to_user.append(f"gap {gid} filed for `{law_of_node}` by a node repair session awaits a decision in gaps/ledger.jsonl")
                continue
            if rec_n is None:
                why = [f"node repair of `{nid}`: the session withdrew the record or wrote none" + (f" — {wd.get('missing')}" if wd else "")]
                node_ledger.failed(nid, why); ledger.return_law(law_of_node, why + (e.reasons if e else []), run.iteration)
                notes.append(f"`{nid}`: the repair session withdrew it or wrote no record; the law is returned to the planner")
            elif vtxt and vtxt != "accept":
                why = [f"node repair of `{nid}` kept a defect: {l}" for l in vtxt.splitlines()[:4]]
                node_ledger.failed(nid, why); ledger.return_law(law_of_node, why, run.iteration)
                notes.append(f"`{nid}`: the repaired record kept a defect; the law is returned to the planner — " + "; ".join(vtxt.splitlines()[:2]))
            else:
                node_ledger.repaired(nid); repaired_nodes.append(rec_n)
                notes.append(f"`{nid}`: revised by a repair session; coded again this iteration")
        carried = [n for n in carried if n.id not in {r.id for r in repaired_nodes}] + repaired_nodes
        for cid, rdir in prog["repairs"].items():
            rec = plan_phase.load_repair(Path(rdir))
            if rec is None:
                concept_ledger.returned(cid, ["repair session withdrew the record or wrote none"])
                notes.append(f"concept `{cid}`: the repair session withdrew it or wrote no record")
            elif cid in run.all_concepts():
                pass                                            # accepted earlier in this iteration; a resume does not re-validate it
            else:
                repaired.append(rec)
                notes.append(f"concept `{cid}`: re-proposed by a repair session")

        # --- plan: one session per batch, root laws before the laws that name them
        batches, waiting, dead = plan_batches(plannable, ledger, by_id, opts.plan_batch)
        if not stage_at_least("planned"):
            for law, refs_ in dead.items():
                ledger.fail(law, [f"names {refs_}, closed as failed"])
                notes.append(f"`{law}` names {refs_}, whose law is closed as failed — closed as failed too")
            for law, refs_ in waiting.items():
                notes.append(f"`{law}` names {refs_}, not yet accepted; not planned this iteration, no attempt counted")
            if not batches and not repaired and not carried:
                notes.append("every plannable law waits for a law it names")
                feedback_phase.write_feedback(run, ledger, notes, to_user, [], concept_ledger)
                prog["stage"] = "done"; persist()
                if not any(e.state in ("returned", "open") and e.law not in waiting for e in ledger.entries.values()):
                    print("[loop] every plannable law waits for a law that cannot progress: stopping"); break
                continue
            print(f"[loop] iteration {run.iteration}: {len(batches)} plan session(s) over {sum(len(b) for b in batches)} law(s)"
                  + (f", {len(waiting)} waiting on a named law" if waiting else "") + (f", {len(repaired)} repaired concept(s)" if repaired else ""))
            try:
                if len(batches) == 1:
                    plan_dir = plan_phase.run_plan(run, batches[0], defs)
                else:
                    dirs, pending = [], []
                    for k, batch in enumerate(batches, 1):
                        d = plan_phase.run_plan(run, batch, defs, tag=f"batch-{k:02d}", pending=pending)
                        dirs.append(d)
                        pending += [n.raw for n in blueprint.load(d / "blueprint.jsonl")] + [c.raw for c in blueprint.load_concepts(d / "blueprint.jsonl")]
                    plan_dir = plan_phase.merge_batches(run, dirs)
            except session.SessionUnavailable as e:
                print(f"[loop] a plan session never ran ({e}); iteration {run.iteration} abandoned, ledger unchanged")
                feedback_phase.write_feedback(run, ledger, notes + [f"iteration abandoned: a plan session never ran — {e}"],
                                              ["sessions unavailable (account limit or API error); rerun the loop later"], [], concept_ledger)
                persist(); break
            prog["plan_dir"] = str(plan_dir); prog["stage"] = "planned"; save_progress(run, prog)
        plan_dir = Path(prog["plan_dir"])
        # aggregates the planner derived from the definitions: validated, merged into the run's reading (once)
        if not prog.get("aggregates_merged"):
            agg_ok, agg_errs = aggregates.validate(aggregates.load(plan_dir / "aggregates.jsonl"), defs, onto, Reading(opts.reading))
            if agg_ok:
                aggregates.merge(run.reading_file, agg_ok, opts.run_id, run.iteration)
                to_user.append("aggregates derived from the definitions this iteration, for review in results/"
                               f"{opts.run_id}/reading.json: " + ", ".join(f"`{r['word']}` ← {r['definition']}" for r in agg_ok))
                notes.append("aggregates accepted: " + ", ".join(f"`{r['word']}` ({len(r['classes'])} members)" for r in agg_ok))
            for e in agg_errs:
                notes.append(f"aggregate rejected — {e}")
            prog["aggregates_merged"] = True; save_progress(run, prog)
        reading = Reading(run.reading_file)
        nodes = blueprint.load(plan_dir / "blueprint.jsonl")
        planned_laws: dict[str, list[str]] = {}
        for n in nodes:
            planned_laws.setdefault(n.get("law_refs", ["?"])[0], []).append(n.id)
        for law, ids in planned_laws.items():
            if law in ledger.entries:
                ledger.mark_planned(law, ids, run.iteration); node_ledger.drop_law(law)
        for e in plannable:
            if e.law not in planned_laws and e.law not in waiting and e.law not in dead and e.state in ("open", "returned"):
                notes.append(f"`{e.law}` was plannable and the plan produced no node for it")

        # --- validate A: concepts (the plan's and the repaired) and nodes; deterministic, re-run on resume
        verdicts, concept_verdicts = validate_phase.run_validate(run, plan_dir, by_id, reading, defs, extra_concepts=repaired, extra_nodes=carried,
                                                                 extra_validate_nodes=carried)
        to_code_concepts: list[ConceptRecord] = []
        for cv in concept_verdicts:
            if cv.kind == "accept":
                concept_ledger.planned(cv.concept.id, cv.concept.used_by(), run.iteration)
                to_code_concepts.append(cv.concept)
            else:
                concept_ledger.returned(cv.concept.id, cv.reasons)
                notes.append(f"concept `{cv.concept.id}` returned by the validator — " + "; ".join(cv.reasons[:4]))
        by_law_verdicts: dict[str, list] = {}
        for v in verdicts:
            by_law_verdicts.setdefault(v.node.law, []).append(v)
        to_code: list[Node] = []
        for law, vs in by_law_verdicts.items():
            if law not in ledger.entries:
                continue
            if any(v.kind == validate_a.FAIL for v in vs):
                ledger.fail(law, [r for v in vs for r in v.reasons])
                notes.append(f"`{law}`: closed as failed — " + "; ".join(r for v in vs for r in v.reasons[:2]))
            elif any(v.kind == "block" for v in vs):
                ids = []
                for v in vs:
                    for g in v.gaps:
                        span_text = v.node.spans().get(g.get("span"), {}).get("text", "")
                        gid = gap_ledger.add({**g, "span_text": span_text, "law_refs": [law], "node_id": v.node.id}, opts.run_id, run.iteration)
                        if gid not in ids:
                            ids.append(gid); gaps_filed.append({**g, "id": gid, "span": span_text, "law_refs": [law]})
                ledger.block(law, ids, [r for v in vs for r in v.reasons])
                to_user.append(f"gap(s) {', '.join(ids)} filed for `{law}` await a decision in gaps/ledger.jsonl")
            elif any(v.kind == "return" for v in vs):
                ledger.return_law(law, [r for v in vs for r in v.reasons], run.iteration)
            else:
                for v in vs:
                    if v.node.id in run.all_nodes():
                        notes.append(f"`{v.node.id}`: re-emitted unchanged; already accepted, not coded again")
                    else:
                        to_code.append(v.node)
        gap_ledger.save()
        prog["stage"] = "validated" if not stage_at_least("validated") else prog["stage"]; persist()

        # --- concepts: coded in dependency waves (`workers` at once), each gated, then reviewed
        concepts_now: list[str] = [c for c, v in prog["concepts"].items() if v == "OK" and c in run.accepted_concepts]
        concept_baselines: dict[str, dict] = {}
        for c in concepts_now:
            bfile = code_phase.concept_dir(run, c) / "baseline.json"
            if bfile.exists():
                concept_baselines[c] = json.loads(bfile.read_text())
        failed_concepts: set[str] = set()
        sessions_down = False
        remaining = [c for c in concept_order(to_code_concepts) if c.id not in prog["concepts"]]
        for c in to_code_concepts:
            if c.id in prog["concepts"] and prog["concepts"][c.id] != "OK":
                failed_concepts.add(c.id)
        while remaining and not sessions_down:
            accepted_c = set(run.all_concepts())
            wave = _wave(remaining, lambda c: sorted(c.refs() - set(onto.primitive_ids)), accepted_c)
            if not wave:
                for c in remaining:
                    unmet = sorted(r for r in c.refs() if r not in accepted_c and r not in onto.primitive_ids)
                    concept_ledger.returned(c.id, [f"references {unmet}, not accepted"]); failed_concepts.add(c.id)
                    notes.append(f"concept `{c.id}`: not coded, references {unmet} which is not accepted")
                    prog["concepts"][c.id] = "UNMET"
                persist(); break
            wave = wave[:max(1, opts.workers)] if opts.workers > 1 else wave[:1]
            registry = {"nodes": sorted(run.all_nodes()), "concepts": sorted(accepted_c)}
            wave_files = {c.id: _files_of("concept", c.id) for c in wave}
            with ThreadPoolExecutor(max_workers=max(1, opts.workers)) as ex:
                futures = {c.id: ex.submit(code_phase.run_code_concept, run, c, reading, registry,
                                           [f for o, fs in wave_files.items() if o != c.id for f in fs]) for c in wave}
                results = {cid: f.result() for cid, f in futures.items()}
            for c in wave:
                v = results[c.id]
                cdir = code_phase.concept_dir(run, c.id)
                concept_baselines[c.id] = json.loads((cdir / "baseline.json").read_text())
                notes.append(f"concept `{c.id}`: gate {v.verdict}" + (f" — {'; '.join(v.details[:4])}" if v.details else ""))
                if v.verdict in (code_phase.SESSION_FAILED, gate.INFRA):
                    sessions_down = True
                    to_user.append(f"the coding session or the toolchain for concept `{c.id}` did not run ({'; '.join(v.details[:1])}); rerun the loop later")
                    continue
                if v.verdict == "SCOPE_VIOLATION":
                    to_user.append(f"the coding session for concept `{c.id}` changed files outside its concept: {'; '.join(v.details[:2])} — "
                                   "the concept was rolled back; inspect and restore those files (git) before the next iteration")
                if v.verdict != "OK":
                    concept_ledger.returned(c.id, [f"gate {v.verdict}"] + v.details[:6], last_task=str(cdir)); failed_concepts.add(c.id)
                    prog["concepts"][c.id] = v.verdict; persist(); continue
                try:
                    ok, reasons, _judge = validate_phase.review_concept(run, c, v.extras, cdir / "review", nodes + carried, defs)
                except session.SessionUnavailable as e:
                    code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
                    sessions_down = True
                    to_user.append(f"the review session for concept `{c.id}` never ran ({e}); rerun the loop later")
                    continue
                if not ok:
                    code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
                    concept_ledger.returned(c.id, ["review: " + "; ".join(reasons)], last_task=str(cdir)); failed_concepts.add(c.id)
                    notes.append(f"concept `{c.id}`: review failed — " + "; ".join(reasons[:3]))
                    prog["concepts"][c.id] = "REVIEW"; persist(); continue
                record = {**c.raw, "reads": v.extras.get("reads", []), "refs": v.extras.get("refs", sorted(c.refs())),
                          "canonical_body": v.extras.get("canonical_body"), "body_json": v.extras.get("body_json"),
                          "accepted_in": f"{opts.run_id}/iter-{run.iteration:03d}"}
                record["narrowings"] = list(v.extras.get("narrowings_added", []))
                if record["narrowings"]:
                    coder_narrowings[c.id] = record["narrowings"]
                run.accepted_concepts[c.id] = record
                concepts_now.append(c.id)
                concept_ledger.accepted(c.id)
                prog["concepts"][c.id] = "OK"; persist()
                if c.get("supersedes"):
                    to_user.append(f"concept `{c.id}` supersedes `{c.get('supersedes')}`; rules using the old one are listed for migration in AUTO_NOTES.md")
                    users = [nid for nid, raw in run.all_nodes().items() if c.get("supersedes") in concept_deps(Node(raw))]
                    notes.append(f"migration candidates for `{c.get('supersedes')}` → `{c.id}`: {users or 'none'}")
            remaining = [c for c in remaining if c.id not in {w.id for w in wave}]
        if prog["stage"] in ("validated",):
            prog["stage"] = "concepts"
        persist()
        with lean.library_lock(paths.LIBRARY):
            index_sync.write_index()

        # --- nodes: carried ones first, then this plan's, coded in dependency waves; each gated, then reviewed
        accepted_now: list[Node] = []
        baselines: dict[str, dict] = {}
        failed_ids: set[str] = set()
        planned_now = {law for law, e in ledger.entries.items() if e.state == "planned"}
        to_code = [n for n in carried if n.law in planned_now] + [n for n in to_code if n.id not in {c.id for c in carried} and n.law in planned_now]
        deferred_now: list[dict] = []
        law_of = {n.id: n.law for n in nodes}
        law_of.update({nid: Node(raw).law for nid, raw in run.all_nodes().items()})
        law_of.update({n.id: n.law for n in carried})
        for n in to_code:                                   # nodes already decided in this iteration (resume)
            v = prog["nodes"].get(n.id)
            if v == "OK":
                accepted_now.append(n)
                bfile = code_phase.node_dir(run, n.id) / "baseline.json"
                if bfile.exists():
                    baselines[n.id] = json.loads(bfile.read_text())
            elif v is not None:
                failed_ids.add(n.id)
        remaining_nodes = [n for n in topological(to_code) if n.id not in prog["nodes"]]
        while remaining_nodes:
            closed = [n for n in remaining_nodes if n.law in ledger.entries and ledger.entries[n.law].state != "planned"]
            for n in closed:                                   # a sibling's return closed the law this iteration: nothing more of it is coded
                failed_ids.add(n.id); prog["nodes"][n.id] = "LAW_CLOSED"
                notes.append(f"`{n.id}`: not coded, its law is `{ledger.entries[n.law].state}` after a sibling was returned this iteration")
            remaining_nodes = [n for n in remaining_nodes if n.id not in {c.id for c in closed}]
            if not remaining_nodes:
                persist(); break
            if sessions_down:
                for n in remaining_nodes:
                    ledger.defer(n.law, ["not coded: sessions unavailable this iteration"])
                persist(); break
            accepted_n = set(run.all_nodes()) | {n.id for n in accepted_now}
            ready: list[Node] = []
            for n in remaining_nodes:
                deps = {c.get("rule") for c in n.compositions()}
                unmet_concepts = sorted(cd for cd in concept_deps(n) if cd not in run.all_concepts())
                if unmet_concepts:
                    states = {cd: (concept_ledger.entries[cd].state if cd in concept_ledger.entries else "not proposed") for cd in unmet_concepts}
                    repairable = {cd for cd in unmet_concepts if cd in concept_ledger.entries and concept_ledger.entries[cd].state == "returned" and concept_ledger.entries[cd].last_task}
                    if any(s in ("failed", "not proposed") for s in states.values()) or any(cd not in repairable and states[cd] == "returned" for cd in unmet_concepts):
                        reasons = [f"uses concept `{cd}`, {s}" + (f": {'; '.join(concept_ledger.entries[cd].reasons[:3])}" if cd in concept_ledger.entries and concept_ledger.entries[cd].reasons else "") for cd, s in states.items()]
                        notes.append(f"`{n.id}`: not coded — " + "; ".join(reasons))
                        ledger.return_for_concepts(n.law, sorted(states), reasons, run.iteration)
                    else:
                        notes.append(f"`{n.id}`: held — uses {unmet_concepts}, returned for repair; no attempt counted")
                        deferred_now.append(n.raw); ledger.hold(n.law, run.iteration)
                    failed_ids.add(n.id); prog["nodes"][n.id] = "HELD"; continue
                unmet = sorted(d for d in deps if d not in accepted_n)
                pending_here = [d for d in unmet if any(m.id == d for m in remaining_nodes) and d not in failed_ids]
                if pending_here:
                    continue                                # a later wave, once its composed node is decided
                if unmet:
                    states = {d: ledger.entries[law_of[d]].state if law_of.get(d) in ledger.entries else "?" for d in unmet}
                    dead = sorted(d for d, s in states.items() if s == "failed")
                    blocked = sorted(d for d, s in states.items() if s == "blocked")
                    if dead:
                        notes.append(f"`{n.id}`: composes {dead}, whose law is closed as failed — this law cannot be formalized")
                        ledger.fail(n.law, [f"composes {dead}, closed as failed"])
                    elif blocked:
                        gaps = sorted({g for d in blocked for g in ledger.entries[law_of[d]].gaps})
                        notes.append(f"`{n.id}`: composes {blocked}, whose law is blocked on {gaps} — this law waits on the same gap(s)")
                        ledger.block(n.law, gaps, [f"composes {blocked}, blocked on {gaps}"])
                    else:
                        notes.append(f"`{n.id}`: not coded, composes {unmet} which is not accepted yet; kept for the next iteration, no attempt counted")
                        deferred_now.append(n.raw); ledger.hold(n.law, run.iteration)
                    failed_ids.add(n.id); prog["nodes"][n.id] = "HELD"; continue
                ready.append(n)
            remaining_nodes = [n for n in remaining_nodes if n.id not in prog["nodes"]]
            persist()
            if not ready:
                if remaining_nodes:                          # only nodes whose composed node failed this iteration are left
                    for n in remaining_nodes:
                        failed_ids.add(n.id); prog["nodes"][n.id] = "HELD"
                        deferred_now.append(n.raw); ledger.hold(n.law, run.iteration)
                        notes.append(f"`{n.id}`: not coded, a node it composes was returned this iteration; kept for the next iteration")
                    persist()
                break
            wave = ready[:max(1, opts.workers)]
            for n in wave:                                   # the proposed tier: the node's vetted proposals enter both readings before its gate runs (idempotent, so a resume repeats it)
                vetted = [pr for pr in n.get("param_proposals", []) if isinstance(pr, dict)]
                for target in (run.reading_file, opts.reading):
                    for p in Reading.add_proposals(target, vetted, f"{opts.run_id}/iter-{run.iteration:03d} {n.id}"):
                        if target == opts.reading:
                            to_user.append(f"parameter `{p['name']}` = {p['value']} {p['unit']} proposed by `{n.id}` ({p['convention'][:80]}); review it in {opts.reading}")
                            notes.append(f"`{n.id}` proposed `{p['name']}` = {p['value']} {p['unit']}: {p['convention'][:120]}")
            reading = Reading(run.reading_file)
            registry = {"nodes": sorted(accepted_n), "concepts": sorted(run.all_concepts())}
            wave_files = {n.id: _files_of("node", n.id) for n in wave}
            with ThreadPoolExecutor(max_workers=max(1, opts.workers)) as ex:
                futures = {n.id: ex.submit(code_phase.run_code, run, n, reading, registry,
                                           [f for o, fs in wave_files.items() if o != n.id for f in fs]) for n in wave}
                results = {nid: f.result() for nid, f in futures.items()}
            for n in wave:
                v = results[n.id]
                ndir = code_phase.node_dir(run, n.id)
                baselines[n.id] = json.loads((ndir / "baseline.json").read_text())
                notes.append(f"`{n.id}`: gate {v.verdict}" + (f" — {'; '.join(v.details[:4])}" if v.details else ""))
                if v.verdict in (code_phase.SESSION_FAILED, gate.INFRA):
                    sessions_down = True
                    to_user.append(f"the coding session or the toolchain for `{n.id}` did not run ({'; '.join(v.details[:1])}); the law keeps its attempt budget — rerun the loop later")
                    ledger.defer(n.law, [f"session or toolchain did not run: {'; '.join(v.details[:1])}"]); continue
                if v.verdict == "SCOPE_VIOLATION":
                    to_user.append(f"the coding session for `{n.id}` changed files outside its node: {'; '.join(v.details[:2])} — "
                                   "the node was rolled back; inspect and restore those files (git) before the next iteration")
                if v.verdict != "OK":
                    failed_ids.add(n.id); prog["nodes"][n.id] = v.verdict
                    reasons_g = [f"gate {v.verdict}"] + v.details[:6]
                    if v.verdict != "SCOPE_VIOLATION" and node_ledger.budget_left(n.id):
                        node_ledger.returned(n.id, n.law, reasons_g, str(ndir), run.iteration); ledger.hold(n.law, run.iteration)
                        notes.append(f"`{n.id}`: gate {v.verdict} — sent to a node repair session; no attempt counted")
                    else:
                        ledger.return_law(n.law, reasons_g, run.iteration)
                    persist(); continue
                added = list(v.extras.get("narrowings_added", []))
                if added:
                    coder_narrowings[n.id] = added
                if opts.judge:
                    try:
                        aligned, reasons, _judge = validate_phase.review_node(run, n, by_id[n.law], onto, reading, v.extras.get("rule_json"),
                                                                              added, ndir / "review")
                    except session.SessionUnavailable as e:
                        code_phase.rollback(n.id, baselines[n.id], ndir)
                        sessions_down = True
                        to_user.append(f"the review session for `{n.id}` never ran ({e}); the law keeps its attempt budget — rerun the loop later")
                        ledger.defer(n.law, [f"review session never ran: {e}"]); continue
                    if not aligned:
                        code_phase.rollback(n.id, baselines[n.id], ndir)
                        failed_ids.add(n.id); prog["nodes"][n.id] = "REVIEW"
                        notes.append(f"`{n.id}`: review failed — " + "; ".join(reasons[:6]))
                        if node_ledger.budget_left(n.id):
                            node_ledger.returned(n.id, n.law, [f"review of `{n.id}`: {r}" for r in reasons], str(ndir), run.iteration)
                            ledger.hold(n.law, run.iteration)
                            notes.append(f"`{n.id}`: sent to a node repair session; no attempt counted")
                        else:
                            ledger.judge_failed(n.law, [f"review of `{n.id}`: {r}" for r in reasons], run.iteration)
                        persist(); continue
                    notes.append(f"`{n.id}`: review aligned")
                accepted_now.append(n); prog["nodes"][n.id] = "OK"; persist()
            remaining_nodes = [n for n in remaining_nodes if n.id not in {w.id for w in wave}]
        run.save_deferred(deferred_now + [d for d in run.load_deferred() if d["node_id"] in prog["nodes"] and prog["nodes"][d["node_id"]] == "HELD" and d["node_id"] not in {x["node_id"] for x in deferred_now}]
                          if sessions_down else deferred_now)
        prog["stage"] = "nodes"; persist()

        # --- integrate
        kept, reverted = integrate_phase.run_integrate(run, accepted_now, reading, baselines, concepts_now, concept_baselines)
        for r in reverted:
            notes.append(f"reverted at integration: {r}")
            nid = r.split(":")[0]
            law = next((n.law for n in accepted_now if n.id == nid), None)
            if law:
                ledger.return_law(law, [r], run.iteration)
            elif nid in concept_ledger.entries:
                concept_ledger.returned(nid, [r])
        index = MappingIndex(run.mapping_file)
        for n in accepted_now:
            if n.id in kept:
                run.accepted_nodes[n.id] = {**n.raw, "narrowings": list(n.get("narrowings", [])) + coder_narrowings.get(n.id, [])}
                for e in n.get("elements", []):
                    t = n.spans().get(e.get("span"), {}).get("text", "")
                    index.record(t, set(e.get("atoms", [])) | set(e.get("derived", [])), n.id)
        index.save()
        prog["kept"] = kept; prog["stage"] = "integrated"; persist()
        # a law is accepted when every node it was planned with is accepted, whichever iteration coded it
        for e in ledger.entries.values():
            if e.state == "planned" and e.nodes and all(i in run.all_nodes() for i in e.nodes):
                ledger.accept(e.law, e.nodes)
        # --- feedback
        missing_params = sorted({p for n in nodes for p in Node(n.raw).params() if not reading.has(p)})
        if missing_params:
            to_user.append(f"parameters the reading lacks: {', '.join(missing_params)} (readings/)")
        for d in deferred_now:
            deps = sorted(({c.get("rule") for c in Node(d).compositions()} - set(run.all_nodes())) | {cd for cd in concept_deps(Node(d)) if cd not in run.all_concepts()})
            to_user.append(f"`{d['node_id']}` waits for {deps} to be accepted; its law stays planned, no attempt counted")
        feedback_phase.write_feedback(run, ledger, notes, to_user, gaps_filed, concept_ledger, deferred_now, coder_narrowings)
        prog["stage"] = "done"; persist()
        print(f"[loop] iteration {run.iteration}: accepted {len(kept)} node(s), {len(concepts_now)} concept(s); laws {ledger.counts()}")
        if sessions_down:
            print("[loop] sessions or toolchain unavailable: stopping after this iteration"); break
        if not kept and not concepts_now and not gaps_filed and not concept_ledger.repairable() and not deferred_now \
                and all(e.state != "returned" for e in ledger.entries.values()):
            print("[loop] no progress and nothing returned: stopping"); break
    ledger.save(); concept_ledger.save(); node_ledger.save()
    return {"iterations": run.iteration, "laws": ledger.counts(), "accepted_nodes": len(run.accepted_nodes),
            "accepted_concepts": len(run.accepted_concepts), "concepts": concept_ledger.counts()}
