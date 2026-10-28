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
from .model.blueprint import Node, ConceptRecord
from .store.gaps import GapLedger
from .store.ledger import Ledger, ConceptLedger, NodeLedger
from .phases import plan as plan_phase, review as review_phase, validate as validate_phase, code as code_phase, integrate as integrate_phase, feedback as feedback_phase
from .phases import aggregate as aggregate_phase
from .model import definitions as definitions_mod
from .store.ledger import TERMINAL, JUDGE_STAGES
from .store import jsonl
from .store.budget import BudgetPaused
from .model.reading import Reading
from .store.state import Options, Run, commit_state
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


def param_notes_to_user(to_user: list[str], notes: list[tuple[str, str]]) -> None:
    """Each of the reviewer's words on a proposed parameter, placed right after that parameter's
    review line (and the notes already there), or at the end when the line is not in this list."""
    for name, text in notes:
        at = next((i for i, line in enumerate(to_user) if line.startswith(f"parameter `{name}` = ")), None)
        if at is None:
            to_user.append(f"parameter `{name}` (proposed, under review): {text}")
            continue
        while at + 1 < len(to_user) and to_user[at + 1].startswith("  - "):
            at += 1
        to_user.insert(at + 1, f"  - {text}")


def concept_deps(n: Node) -> set[str]:
    """The pipeline concepts a node claims, wherever the record claims them (`Node.claimed_concepts`)."""
    return n.claimed_concepts()


def concept_closure(ids: set[str], refs_of: dict[str, set[str]]) -> set[str]:
    """The concepts reached from `ids` through the concepts they call (as far as `refs_of` knows)."""
    out, frontier = set(ids), set(ids)
    while frontier:
        frontier = {r for c in frontier for r in refs_of.get(c, set())} - out
        out |= frontier
    return out


def reached_concepts(run: Run, ids: set[str]) -> set[str]:
    """The accepted concepts a task reaches: those it calls and, through them, those they call."""
    refs = {c: set(ConceptRecord(r).refs()) for c, r in run.all_concepts().items()}
    return concept_closure(set(ids), refs) & set(run.all_concepts())


def report_of(run: Run, task: Path, reached: set[str]):
    """A task's dependency-defect report, judged (`review_phase.dependency_report`). A report no one
    could decide is never the task's defect: a judge whose answer stayed invalid gives status
    `deferred`, a session or certificate program that did not run gives `unavailable`; either way the
    task waits, uncharged, with the reason."""
    try:
        return review_phase.dependency_report(run, task, reached)
    except review_phase.Deferred as e:
        return review_phase.DependencyReport("deferred", reasons=[f"{e.stage}: {e.why}"])
    except (session.SessionUnavailable, review_phase.HarnessFailure) as e:
        return review_phase.DependencyReport("unavailable", reasons=[str(e)])


def mark_defective(run: Run, opts: Options, dep, task: Path, to_user: list) -> None:
    """A concept version an adjudication found defective on a reported counterexample: marked, with
    its evidence, so no new record claims it (a later version is not marked); its accepted callers
    are listed for the operator with the subset-continuation command, nothing reopened."""
    run.fence(dep.concept, "concept", "dependency_defect", evidence=dep.line, task=str(task), iteration=run.iteration)
    refresh_inactive(run)
    refs = {c: set(ConceptRecord(r).refs()) for c, r in run.all_concepts().items()}
    callers = sorted(nid for nid, rec in run.all_nodes().items() if dep.concept in concept_closure(concept_deps(Node(rec)), refs))
    callers += sorted(c for c in run.all_concepts() if c != dep.concept and dep.concept in concept_closure(refs.get(c, set()), refs))
    if callers:
        laws = sorted({Node(run.all_nodes()[c]).law for c in callers if c in run.all_nodes()})
        to_user.append(f"concept `{dep.concept}` was found defective on a reported counterexample ({dep.line[:200]}); accepted callers "
                       f"{callers} were judged with it — to re-run their laws: python -m scripts.subset_laws <new run> {opts.laws} "
                       + " ".join(laws) + f" and launch with --base_run {opts.run_id}; the evidence is in {task}")


def fenced_provider_reasons(run: Run, n: Node, fenced_used: list[str]) -> list[str]:
    """Why a node fenced since it was planned goes back to the planner, uncharged: each record it uses
    that is fenced now, and what the planner may do."""
    return [f"`{n.id}` uses `{d}`, fenced since it was planned ({run.fenced[d].get('reason')}: "
            f"{str(run.fenced[d].get('evidence', ''))[:160]}) — supersede it with a successor of the same contract (the fence "
            "stands for the counterexample) or map the words around it" for d in fenced_used]


def context_notices(failing: list[str], closed: list[str]) -> list[str]:
    """The operator's notices of a context check: each record fenced, and each fenced for calling one."""
    return ([x + " — fenced: no new record may use it; re-plan its law on a subset continuation" for x in failing]
            + [f"`{i}` fenced: it calls or composes a fenced record" for i in closed])


def context_base(opts: Options, semantic: dict) -> dict:
    """What every record's dependency context is computed against besides its own inputs: Core, the
    ontology and the review configuration."""
    return {"core": semantic["core"], "ontology": semantic["ontology"],
            "review": [opts.reviewer_model, opts.review_effort, opts.judge_effort, opts.review_passes]}


def refresh_inactive(run: Run) -> None:
    """The operational library leaves out every fenced record (and everything that calls one): the
    selection every registry build reads, rewritten before the next build whenever the fences
    change."""
    index_sync.set_inactive(set(run.fenced), run.opts.run_id)


def subset_command(run: Run, opts: Options, node_ids: list[str]) -> str:
    """The subset continuation that re-plans the laws of these nodes: the run to start from is this
    one when it accepted records of its own, else its base run, whose listed laws are kept; the
    corpus is the base chain's first run's."""
    from .store.state import listed_laws
    laws = {Node(run.all_nodes()[i]).law for i in node_ids if i in run.all_nodes()}
    own = bool(run.accepted_nodes or run.accepted_concepts)
    base = opts.run_id if own or not opts.base_run else opts.base_run
    if base == opts.base_run:
        laws |= listed_laws(opts.laws)
    root = run.base_chain[0] if run.base_chain else None
    corpus = (jsonl.read_json(paths.run_dir(root) / "options.json", {}) or {}).get("laws") if root else None
    corpus = corpus or str(opts.laws)
    new = f"{opts.run_id}_fix"
    return (f"python -m scripts.subset_laws {new} {corpus} {' '.join(sorted(laws))} && python -m harness loop --run_id {new} "
            f"--laws {paths.run_dir(new) / 'laws' / 'laws.jsonl'} --base_run {base} ...")


def effective_laws(run: Run, by_id: dict) -> dict:
    """The posted laws of every node of the effective view: the base chain's corpora (where an
    inherited node's law is read from), then this run's."""
    from .store.state import chain_laws
    return {**chain_laws(run), **by_id}


def admission_preflight(run: Run, opts: Options, reading, base: dict, context_base: dict | None = None,
                        laws: dict | None = None) -> tuple[list[str], str]:
    """Before any session: every accepted record of the effective view is held to today's gates
    (`integrate.admission_recheck`), then, with `context_base`, its recorded obligations are checked
    on its dependency context as it is now (`integrate.recheck_contexts`, over `laws`), so a provider
    whose context fails is fenced before anything is coded on it. A record either check rejects is
    fenced with everything that calls it, and the operational library leaves them out; a record
    whose evaluation exceeded the gate's deadline stays as accepted, with a notice, and is checked
    again at the next launch. Returns
    (notes, the stop message): the run stops before any spend when an accepted node it keeps is
    fenced, or calls or composes a fenced record, with the subset continuation that re-plans those
    nodes' laws; when a check could not be made (a gate or program that did not run, a law in no
    corpus); a fenced concept alone stops nothing, since its successor comes through the planner of
    the laws that need it."""
    refresh_inactive(run)
    unjudged: list[str] = []
    try:
        failed = integrate_phase.admission_recheck(run, reading, base, unjudged)
    except integrate_phase.AdmissionUnavailable as e:
        return [], f"the admission recheck of the accepted records did not run: {e}; nothing was spent, rerun the loop"
    refresh_inactive(run)
    notes = [f"`{i}` fails today's gates ({v['verdict']}: {'; '.join(v['details'][:2])[:300]}): fenced" for i, v in failed.items()]
    notes += unjudged
    if context_base is not None:
        _ok, failing, unresolved = integrate_phase.recheck_contexts(run, reading, context_base, laws or {})
        closed = integrate_phase.fence_closure(run)
        refresh_inactive(run)
        notes += context_notices(failing, closed)
        if unresolved:
            return notes, ("the obligations of accepted records could not be checked before any spend — " + "; ".join(unresolved[:4])
                           + "; nothing was spent, rerun the loop once the cause is fixed")
    notes += [f"`{i}` fenced: {ev.get('evidence', '')[:200]}" for i, ev in run.fenced.items() if ev.get("reason") == "dependency" and i not in failed]
    kept = sorted(i for i in run.fenced if i in run.all_nodes())
    if not kept:
        return notes, ""
    lines = [f"`{i}`: {run.fenced[i].get('evidence', '')[:240]}" for i in kept]
    return notes, ("accepted node(s) this run keeps are fenced (they fail today's gates, or call or compose a record that does) — "
                   + "; ".join(lines) + f". Re-plan their laws in a subset continuation: {subset_command(run, opts, kept)}")


def propagate_concept_failures(concept_ledger: ConceptLedger) -> list[str]:
    """A concept waiting on a concept that failed fails too, with the reason; returns the ids failed."""
    out, grown = [], True
    while grown:
        grown = False
        for e in concept_ledger.entries.values():
            dead = [w for w in e.waiting if w in concept_ledger.entries and concept_ledger.entries[w].state == "failed"]
            if e.state == "planned" and dead:
                concept_ledger.fail(e.concept, [f"calls {dead}, which failed"])
                out.append(e.concept); grown = True
    return out


def sibling_records(run: Run, law: str, exclude: str, ledger: Ledger, node_ledger: NodeLedger, prog: dict) -> list[Node]:
    """Every other node the law's plan lists, each in its most recent valid record: this attempt's
    repair revision if it validated, else the last coded `node.json`, else the accepted node, else
    the plan's record (a held one included); whatever the sibling's state, failed included."""
    out = []
    ids = list(ledger.entries[law].nodes) if law in ledger.entries else []
    plan_dir = Path(prog["plan_dir"]) if prog.get("plan_dir") else None
    planned = {n.id: n for n in blueprint.load(plan_dir / "blueprint.jsonl")} if plan_dir and (plan_dir / "blueprint.jsonl").exists() else {}
    planned.update({Node(d).id: Node(d) for d in prog.get("carried", [])})
    for nid in ids:
        if nid == exclude:
            continue
        rec = None
        rdir = prog.get("node_repairs", {}).get(nid)
        rep = plan_phase.read_repair(Path(rdir), concept=False) if rdir else None
        if rep is not None and rep.accepted:
            rec = rep.records[0]
        e = node_ledger.entries.get(nid)
        if rec is None and e is not None and e.last_task and (Path(e.last_task) / "node.json").exists():
            rec = Node(json.loads((Path(e.last_task) / "node.json").read_text(encoding="utf-8")))
        if rec is None and nid in run.all_nodes():
            rec = Node(run.all_nodes()[nid])
        if rec is None:
            rec = planned.get(nid)
        if rec is not None:
            out.append(rec)
    return out


def aggregate_claimants(run: Run, node_ledger: NodeLedger, prog: dict) -> dict[str, list[str]]:
    """Every node that already depends on an admitted aggregate, including nodes in a plan that
    exists on a resumed iteration but has not yet been integrated."""
    nodes = {n.id: n for n in [Node(v) for v in run.all_nodes().values()] +
             [Node(d) for d in run.deferred_nodes]}
    for entry in node_ledger.entries.values():
        task = Path(entry.last_task) if entry.last_task else None
        if task is not None and (task / "node.json").exists():
            n = Node(json.loads((task / "node.json").read_text(encoding="utf-8")))
            nodes[n.id] = n
    plan_dir = Path(prog["plan_dir"]) if prog.get("plan_dir") else None
    if plan_dir is not None and (plan_dir / "blueprint.jsonl").exists():
        for n in blueprint.load(plan_dir / "blueprint.jsonl"):
            nodes[n.id] = n
    out: dict[str, set[str]] = {}
    for n in nodes.values():
        for ids in aggregate_phase.claimed_ids([n]).values():
            for aid in ids:
                out.setdefault(aid, set()).add(n.id)
    return {aid: sorted(ids) for aid, ids in out.items()}


def plan_batches(plannable: list, ledger: Ledger, by_id: dict[str, corpus.Law], batch_size: int
                 ) -> tuple[list[list[corpus.Law]], dict[str, list[str]], dict[str, list[str]]]:
    """The plannable laws in plan sessions of at most `batch_size`, ordered so that a law comes
    after every law its text names: a named law that is accepted is composed by its node; one
    that is plannable now goes into the same or an earlier batch (a cycle of references shares a
    batch); one that is planned, held or blocked makes this law wait (returned as `waiting`); one
    closed as failed closes this law too (returned as `failed`). Both close over the chain: a law
    naming a law that waits or fails waits or fails with it, and failure takes precedence over a
    wait on another branch. Depth-first order over the reference
    graph, so a chain of exceptions is planned root first."""
    ids = set(by_id)
    plan_ids = {e.law for e in plannable}
    refs = {lid: corpus.references(by_id[lid], ids) for lid in plan_ids}
    outside = {lid: [r for r in refs[lid] if r not in plan_ids and ledger.entries.get(r)] for lid in plan_ids}
    failed: dict[str, list[str]] = {lid: dead for lid in plan_ids
                                    if (dead := [r for r in outside[lid] if ledger.entries[r].state == "failed"])}
    # closed over the reference graph before any batch is formed, failure first and over every law: a
    # law naming a failed law fails, whatever else it waits for; then a law naming a law that waits waits
    changed = True
    while changed:
        changed = False
        for lid in sorted(plan_ids - set(failed)):
            dead = sorted(r for r in refs[lid] & plan_ids if r in failed)
            if dead:
                failed[lid] = dead; changed = True
    waiting: dict[str, list[str]] = {lid: pending for lid in plan_ids - set(failed)
                                     if (pending := [r for r in outside[lid] if ledger.entries[r].state not in ("accepted", "failed")])}
    changed = True
    while changed:
        changed = False
        for lid in sorted(plan_ids - set(failed) - set(waiting)):
            held = sorted(r for r in refs[lid] & plan_ids if r in waiting)
            if held:
                waiting[lid] = held; changed = True
    ready: set[str] = plan_ids - set(failed) - set(waiting)
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
# Checkpoints: what the current iteration has done so far lives in the run's state snapshot
# (`state.json`, see `commit_state`), committed after every step, so that a killed loop resumes
# where it was and an interrupted session is rolled back rather than refused.
# ---------------------------------------------------------------------------------------------
STAGES = ["start", "repaired", "planned", "validated", "concepts", "nodes", "integrated", "done", "abandoned"]


def new_progress(run: Run) -> dict:
    """An iteration's progress: its stage, the outcome of each item it decided, and the records it
    carries from the iteration before (held nodes and concepts), taken once when it starts."""
    return {"stage": "start", "repairs": {}, "node_repairs": {}, "plan_dir": None, "batch_laws": [], "aggregates_merged": False,
            "concepts": {}, "nodes": {}, "carried": list(run.deferred_nodes), "carried_concepts": list(run.deferred_concepts),
            "notes": [], "to_user": [], "gaps_filed": [], "coder_narrowings": {}}


def resumable_iteration(snap: dict | None) -> int | None:
    """The iteration the snapshot records short of `done`, or None."""
    if not snap or not snap.get("prog"):
        return None
    return int(snap["iteration"]) if snap["prog"].get("stage") not in ("done", "abandoned") else None


def recover_interrupted(run: Run, iteration: int) -> list[str]:
    """Roll back every coding task of the iteration that has no verdict: the session was killed
    with its files on disk. Returns the ids rolled back."""
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
    """Ids whose task directory in the unfinished iteration holds an `OK` verdict: their files are
    in the library by right, and the resume takes them to review instead of coding them again."""
    out: set[str] = set()
    n = resumable_iteration(run.load_state())
    if n is not None:
        for v in paths.iter_dir(run.opts.run_id, n).glob("code/*/verdict.json"):
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


def _owner_run(ident: str, first: str | None = None) -> str:
    """The run whose accepted records name a node or concept, `first` (the base run) tried before
    the others, else a dated strays folder."""
    import datetime
    for d in ([paths.run_dir(first)] if first else []) + sorted(paths.RESULTS.glob("*")):
        for name, key in (("accepted_nodes.jsonl", "node_id"), ("accepted_concepts.jsonl", "concept_id")):
            f = d / name
            if f.exists() and any(json.loads(l).get(key) == ident for l in f.read_text(encoding="utf-8").splitlines() if l.strip()):
                return d.name
    return "library_strays_" + datetime.datetime.now().strftime("%Y-%m-%d")


def check_library_isolation(run: Run) -> None:
    """The library holds exactly the nodes and concepts this run (or its base run) accepted. A node
    or concept on disk that no accepted record names would be registered and built into this
    run's library without ever passing through its plan: its files are moved into the snapshot
    of the run whose accepted records name it, the base run tried first (else, or where that
    snapshot already holds the file, a dated strays folder under `results/`). An
    accepted record whose files are gone cannot be composed or called: its files are restored from
    this run's snapshot, or from the candidates an integration kept. The run refuses to start only
    for a file that can be neither moved nor restored."""
    on_disk_nodes, on_disk_concepts = set(index_sync.node_ids()), set(index_sync.concept_ids())
    finished = finished_tasks(run)                           # gated `OK` in an unfinished iteration, not yet accepted: the resume reviews them
    stray = sorted(((on_disk_nodes - set(run.all_nodes())) | (on_disk_concepts - set(run.all_concepts()))) - finished)
    missing = sorted((set(run.all_nodes()) - on_disk_nodes) | (set(run.all_concepts()) - on_disk_concepts))
    moved, restored, lost = [], [], []
    for ident in stray:
        kind = "concept" if ident in on_disk_concepts else "node"
        dest = paths.RESULTS / _owner_run(ident, run.opts.base_run) / "library_snapshot"
        for rel in _lib_files(kind, ident):
            src = paths.LIBRARY / rel
            if src.exists() and (dest / rel).exists():                # an archived copy is never overwritten
                dest = paths.RESULTS / _owner_run("", None) / "library_snapshot"   # no record names "": the strays folder
            if src.exists():
                (dest / rel).parent.mkdir(parents=True, exist_ok=True); shutil.move(str(src), str(dest / rel)); moved.append(rel)
    # the copies an accepted record's files are restored from: the run's library snapshot, then the candidates an
    # integration kept, newest first (a run stopped while integration had removed a candidate it went on to decide)
    copies = [run.dir / "library_snapshot"] + sorted(run.dir.glob("iter-*/integrate/candidates"), reverse=True)
    for ident in missing:
        kind = "concept" if ident in run.all_concepts() else "node"
        holder = getattr(run, "provenance", {}).get(ident)          # an inherited record: the run that accepted it keeps its copy
        own = ([paths.run_dir(holder) / "library_snapshot"] + sorted(paths.run_dir(holder).glob("iter-*/integrate/candidates"), reverse=True)
               if holder else [])
        for rel in _lib_files(kind, ident):
            src = next((c / rel for c in own + copies if (c / rel).exists()), run.dir / "library_snapshot" / rel)
            if src.exists():
                (paths.LIBRARY / rel).parent.mkdir(parents=True, exist_ok=True); shutil.copy2(str(src), str(paths.LIBRARY / rel)); restored.append(rel)
            else:
                lost.append(rel)
    if moved or restored:
        index_sync.write_index()
        print(f"[loop] library isolation: moved {len(moved)} stray file(s) to their run's snapshot, restored {len(restored)} accepted file(s)")
    if lost:
        raise SystemExit(f"[loop] accepted file(s) missing from the library and from results/{run.opts.run_id}/library_snapshot/: {lost[:6]}\n"
                         "        no copy exists to restore; start a new run or reopen the law")


def plan_outputs_unreadable(d: Path) -> str | None:
    """The parse error of a plan directory's record files, or None when both read."""
    try:
        blueprint.load(d / "blueprint.jsonl"); blueprint.load_concepts(d / "blueprint.jsonl"); aggregates.load(d / "aggregates.jsonl")
    except ValueError as e:
        return str(e)
    return None


def quarantine_plan_outputs(d: Path) -> None:
    """A plan directory whose records cannot be read keeps them under `.unreadable` and holds
    empty record files, so the iteration goes on with nothing planned from it."""
    for name in ("blueprint.jsonl", "aggregates.jsonl"):
        f = d / name
        if f.exists():
            f.rename(f.with_suffix(f.suffix + ".unreadable"))
        f.write_text("", encoding="utf-8")


def _wave(items, key_deps, accepted: set[str]):
    """The items whose dependencies are all accepted, in the given order."""
    return [x for x in items if all(d in accepted for d in key_deps(x))]


def _lib_files(kind: str, ident: str) -> list[str]:
    """A node's or a concept's two files, relative to the library (the layout of a snapshot)."""
    if kind == "concept":
        return [nodeid.concept_path(ident), nodeid.concept_witness_path(ident)]
    return [nodeid.rule_path(ident), nodeid.witness_path(ident)]


def _files_of(kind: str, ident: str) -> list[str]:
    """The same files as the repository digest keys them."""
    return [gate.lib_rel(r) for r in _lib_files(kind, ident)]


def semantic_inputs(opts: Options) -> dict[str, str]:
    """The digests of what a run's plans and reviews were built against: the corpus (its laws and
    posted definitions), the definition precedence, the ontology, Core, the prompts, the base
    reading's reviewed values (a proposal awaiting the operator's review is a run's own state, never
    a semantic input), and a base run's accepted records. A resume against another value of any of
    them would mix two runs, and stops before any record is rewritten."""
    import hashlib

    def digest(paths_: list[Path]) -> str:
        h = hashlib.sha256()
        for p in sorted(paths_):
            if p.is_file():
                h.update(str(p.relative_to(paths.REPO) if p.is_relative_to(paths.REPO) else p).encode()); h.update(p.read_bytes())
        return h.hexdigest()[:24]
    laws = Path(opts.laws)
    precedence = Path(opts.definition_precedence or definitions_mod.DEFAULT_PRECEDENCE)
    def reviewed(reading: Path) -> str:                  # the operator's values; proposals awaiting review are runs' state
        data = jsonl.read_json(reading, {}) or {}
        kept = {**data, "params": [p for p in data.get("params", []) if isinstance(p, dict) and not p.get("proposed")],
                "declarations": [d for d in data.get("declarations", []) if isinstance(d, dict) and not d.get("proposed")]}
        return hashlib.sha256(json.dumps(kept, sort_keys=True, ensure_ascii=False).encode()).hexdigest()[:24]
    out = {"corpus": digest([laws, laws.with_name("definitions.jsonl")]),
           "definition_precedence": digest([precedence]),
           "ontology": digest([Path(opts.ontology)]),
           "core": digest(list(paths.CORE.rglob("*.lean"))),
           "prompts": digest(list((paths.REPO / "prompts").glob("*.md"))),
           "base_reading": reviewed(Path(opts.reading))}
    if opts.base_run:
        from .store.state import base_view
        import hashlib as _h
        view = base_view(opts.base_run, frozenset({opts.run_id}))
        rulings = digest([paths.run_dir(r) / "rulings.jsonl" for r in view["chain"]])
        out["base_run"] = _h.sha256(json.dumps({"view": {k: view[k] for k in ("nodes", "concepts", "fenced")}, "rulings": rulings,
                                                "reading": digest([paths.run_dir(opts.base_run) / "reading.json"])},
                                               sort_keys=True, ensure_ascii=False, default=str).encode()).hexdigest()[:24]
    return out


def run_loop(opts: Options) -> dict:
    """The loop, with its two run-level stops: a damaged audit file (`data_integrity_failure`: the
    file is named and left as it is) and an exhausted budget for the second vendor's calls
    (`paused_budget`: resumed under the same run id once the operator raises the limit). Either is
    raised after the iteration committed what it had validated. A fault of the validator itself
    (an exception inside a check) stops the run as `infrastructure_failure`, uncharged, its traceback
    kept in `validator_fault.txt`."""
    try:
        return _run_loop(opts)
    except (jsonl.DataIntegrityError, BudgetPaused, validate_a.ValidatorFault) as e:
        status = ("data_integrity_failure" if isinstance(e, jsonl.DataIntegrityError) else "paused_budget" if isinstance(e, BudgetPaused)
                  else "infrastructure_failure")
        run = Run(opts)
        if isinstance(e, validate_a.ValidatorFault):
            (run.dir / "validator_fault.txt").write_text(e.trace, encoding="utf-8")
        ledger = Ledger(run.ledger_file, [], opts.plan_attempts)
        snap = run.load_state() if not isinstance(e, jsonl.DataIntegrityError) else None
        run.iteration = int(snap["iteration"]) if snap else max([int(p.name.split("-")[1]) for p in run.dir.glob("iter-*") if p.is_dir()] or [0])
        feedback_phase.write_status(run, ledger, status, str(e))
        print(f"[loop] status: {status} — {e}")
        return {"status": status, "stop_reason": str(e), "iterations": run.iteration, "laws": ledger.counts()}


def _run_loop(opts: Options) -> dict:
    from .store import owner
    run = Run(opts)
    run.dir.mkdir(parents=True, exist_ok=True)
    owner.acquire(opts.run_id, force=opts.force_takeover)
    semantic = semantic_inputs(opts)
    saved_opts = jsonl.read_json(run.dir / "options.json", None)
    if saved_opts is not None and run.state_file.exists():
        changed = sorted(k for k, v in semantic.items() if saved_opts.get("semantic", {}).get(k) != v)
        if changed:
            raise SystemExit(f"[loop] run `{opts.run_id}` was built against other inputs ({', '.join(changed)} changed); "
                             "start a new run id — nothing of this run was rewritten")
    from .lean import surface                              # the ontology the run names is the one the active Core carries
    core_ids, onto_ids = set(surface.core_atom_ids()), set(ontology.load(opts.ontology).atom_ids)
    if core_ids != onto_ids:
        raise SystemExit(f"[loop] the ontology {opts.ontology} and the active Core split disagree: {len(onto_ids - core_ids)} atom(s) only in "
                         f"the ontology, {len(core_ids - onto_ids)} only in Core — switch the split (python -m harness split --use ...) "
                         "or name the matching ontology")
    if not run.reading_file.exists():
        if json.loads(Path(opts.reading).read_text(encoding="utf-8")).get("aggregates"):
            raise SystemExit(f"{opts.reading} declares aggregates: aggregates are admitted per run by the aggregate gate, never declared")
        shutil.copy2(opts.reading, run.reading_file)      # the operator's base reading; the run admits its aggregates
    from .model.reading import reading_defects
    for f in (Path(opts.reading), run.reading_file):        # a reading is read whole, or nothing is evaluated on it
        bad = reading_defects(json.loads(f.read_text(encoding="utf-8")))
        if bad:
            raise SystemExit(f"[loop] the reading {f} cannot be read whole: " + "; ".join(bad[:6]))
    precedence = Path(opts.definition_precedence or definitions_mod.DEFAULT_PRECEDENCE)
    jsonl.write_atomic(run.dir / "options.json", json.dumps({**asdict(opts), "laws": str(opts.laws), "ontology": str(opts.ontology),
                                                             "base_reading": str(opts.reading), "reading": str(run.reading_file),
                                                             "definition_precedence": str(precedence),
                                                             "model_prices": str(opts.model_prices) if opts.model_prices else None,
                                                             "definition_precedence_sha256": definitions_mod.precedence_digest(precedence),
                                                             "semantic": semantic}, indent=1))
    doctor_ok()
    snap = run.restore_state()                            # projections completed from the snapshot before anything reads them
    run.load_accepted()
    if opts.base_run:
        run.inherit_declarations()                       # an inherited node's declared ids enter the readings before any session
    laws = corpus.load_laws(opts.laws)
    defs = corpus.load_definitions(opts.laws)
    by_id = {l.id: l for l in laws}
    onto = ontology.load(opts.ontology)
    # which posted definition applies to each law's words, once per run: the inherited nodes' laws included,
    # so an aggregate an inherited node claims is admitted against the same definitions as in its base run
    definitions_mod.write_table(run, list(effective_laws(run, by_id).values()), defs)
    ledger = Ledger(run.ledger_file, [l.id for l in laws], opts.plan_attempts, opts.repeat_limit)
    concept_ledger = ConceptLedger(run.concept_ledger_file, opts.concept_attempts)
    node_ledger = NodeLedger(run.node_ledger_file, opts.node_attempts)
    gap_ledger = GapLedger(paths.GAPS_DIR)
    prog: dict = (snap or {}).get("prog") or {}           # a launch that starts no iteration keeps the last one's record

    def persist() -> None:
        commit_state(run, ledger, concept_ledger, node_ledger, prog)

    # an interrupted iteration: its killed sessions are rolled back, and it is resumed or discarded
    resume_n = resumable_iteration(snap)
    if resume_n is not None:
        rolled = recover_interrupted(run, resume_n)
        if rolled:
            print(f"[loop] iteration {resume_n}: rolled back interrupted session(s) {rolled}")
        if opts.restart:
            prog = snap["prog"]; prog["stage"] = "abandoned"
            run.iteration = resume_n
            for e in ledger.entries.values():
                if e.state == "planned" and e.iteration == resume_n and not all(i in run.all_nodes() for i in e.nodes):
                    e.state = "open"
            persist()
            print(f"[loop] iteration {resume_n} discarded (--restart)"); resume_n = None
        else:
            print(f"[loop] iteration {resume_n} resumes at stage `{snap['prog']['stage']}`")
    check_library_isolation(run)
    if not opts.reviewer_model and not opts.dry_run:
        raise SystemExit("--reviewer_model is required: the behaviour review is a node's acceptance check")
    if opts.reviewer_model:
        if session.vendor_of(opts.reviewer_model) == session.vendor_of(opts.model) and not opts.allow_same_vendor:
            raise SystemExit(f"the reviewer ({opts.reviewer_model}) and the planner ({opts.model}) share a vendor; a reviewer is a second "
                             "vendor's model so a blind spot they share is not also the reviewer's — pass --allow_same_vendor to override")
        from .agents import openai_runner
        if session.vendor_of(opts.reviewer_model) == "openai" and not openai_runner.available():
            raise SystemExit("the reviewer is an OpenAI model and OPENAI_API_KEY is not set in the harness's environment")
    # the base chain's admitted aggregates are restored before any record is gated or checked on them
    c_notes, stale = aggregate_phase.check_admissions(run, effective_laws(run, by_id), defs, onto,
                                                      aggregate_claimants(run, node_ledger, prog))
    for x in c_notes:
        print(f"[loop] {x}")
    if stale:
        commit_state(run, ledger, concept_ledger, node_ledger)
        feedback_phase.write_status(run, ledger, "stale_aggregate", "; ".join(stale))
        print("[loop] stale aggregate(s) under existing nodes: " + "; ".join(stale))
        return {"status": "stale_aggregate", "stop_reason": "; ".join(stale), "iterations": run.iteration, "laws": ledger.counts()}
    pre_notes, stop = admission_preflight(run, opts, Reading(run.reading_file), {"core": semantic["core"], "ontology": semantic["ontology"]},
                                          context_base(opts, semantic), effective_laws(run, by_id))
    run.pending_notices += [x for x in pre_notes if x not in run.pending_notices]   # delivered by the next iteration
    commit_state(run, ledger, concept_ledger, node_ledger)          # the fences, with the saved progress left as it is
    for x in pre_notes:
        print(f"[loop] {x}")
    if stop:
        raise SystemExit(f"[loop] {stop}")
    reopened = ledger.reopen_for_gaps(gap_ledger.decided())
    status, stop_reason = "", ""

    def settle(reason_if_open: str) -> tuple[str, str]:
        if all(e.state in TERMINAL for e in ledger.entries.values()):
            return "complete", "every law is accepted, blocked or failed"
        return "incomplete", reason_if_open
    while True:
        if resume_n is not None:
            run.iteration = resume_n; run.iter.mkdir(parents=True, exist_ok=True)
            prog = snap["prog"]; resume_n = None
        else:
            if run.iteration >= opts.max_iterations:     # the bound counts iterations, not launches
                break
            plannable = ledger.plannable()
            held = [Node(d) for d in run.deferred_nodes]
            repairs = [e for e in concept_ledger.repairable() if any(e.concept in concept_deps(n) for n in held)]
            node_repairs = node_ledger.repairable({e.law for e in ledger.entries.values() if e.state == "planned"})
            if not plannable and not repairs and not node_repairs and not held and not run.deferred_concepts:
                print("[loop] nothing plannable, nothing to repair, nothing held: every law is accepted, blocked or failed")
                status, stop_reason = settle("nothing plannable, to repair or held, yet a law is open"); break
            run.next_iteration()
            prog = new_progress(run)
            persist()
        ledger.attempt = run.iteration
        try:
            status, stop_reason = _iteration(run, opts, prog, persist, ledger, concept_ledger, node_ledger, gap_ledger,
                                             by_id, laws, defs, onto, reopened)
        except (jsonl.DataIntegrityError, BudgetPaused, validate_a.ValidatorFault):
            persist()
            raise
        reopened = []
        if status:
            break
    if not status:
        status, stop_reason = settle(f"the iteration bound ({opts.max_iterations}) was reached")
    persist()
    feedback_phase.write_status(run, ledger, status, stop_reason)
    print(f"[loop] status: {status} — {stop_reason}")
    return {"status": status, "stop_reason": stop_reason, "iterations": run.iteration, "laws": ledger.counts(),
            "accepted_nodes": len(run.accepted_nodes), "accepted_concepts": len(run.accepted_concepts), "concepts": concept_ledger.counts()}


def _iteration(run: Run, opts: Options, prog: dict, persist, ledger: Ledger, concept_ledger: ConceptLedger, node_ledger: NodeLedger,
               gap_ledger: GapLedger, by_id: dict, laws: list, defs: list, onto, reopened: list) -> tuple[str, str]:
    """One iteration, from its committed progress on. Returns (status, stop reason) when the run
    stops after it, else ("", "")."""
    from concurrent.futures import ThreadPoolExecutor, as_completed
    import threading
    plannable = ledger.plannable()
    print(f"[loop] iteration {run.iteration}: {len(plannable)} plannable law(s), stage `{prog['stage']}`")
    notes, to_user, gaps_filed = prog["notes"], prog["to_user"], prog["gaps_filed"]
    coder_narrowings: dict[str, list[dict]] = prog["coder_narrowings"]

    def stage_at_least(s: str) -> bool:
        return STAGES.index(prog["stage"]) >= STAGES.index(s)

    def stop_infrastructure(what: str, ex) -> tuple[str, str]:
        print(f"[loop] {what} never ran ({ex}); iteration {run.iteration} stops here, its work kept for the resume")
        feedback_phase.write_feedback(run, ledger, notes + [f"iteration stopped: {what} never ran — {ex}"],
                                      ["sessions unavailable (account limit or API error); rerun the loop later"], [], concept_ledger)
        persist()
        return "infrastructure_failure", f"{what} could not be launched: {ex}"

    for law, why in reopened:
        notes.append(f"`{law}` reopened after the operator decided its gap(s): " + "; ".join(why))
    if run.pending_notices:                            # what the loop start found, before this iteration
        to_user += [x for x in run.pending_notices if x not in to_user]
        run.pending_notices = []
    carried = [Node(d) for d in prog["carried"] if d["node_id"] not in run.all_nodes()]

    # --- aggregates: reconcile admissions before any repair, plan, validation or coding work.
    # Planned nodes are claimants too: resuming after planning must not silently replace the
    # meaning under the plan that is about to be validated and coded.
    claimants = aggregate_claimants(run, node_ledger, prog)
    c_notes, stale = aggregate_phase.check_admissions(run, effective_laws(run, by_id), defs, onto, claimants)
    notes += c_notes
    if stale:
        print("[loop] stale aggregate(s) under existing nodes: " + "; ".join(stale))
        feedback_phase.write_feedback(run, ledger, notes + [f"run stopped: {x}" for x in stale],
                                      ["an aggregate's inputs changed after nodes claimed it: start a new run"], [], concept_ledger)
        persist()
        return "stale_aggregate", "; ".join(stale)
    if not prog.get("aggregates_prepared"):
        try:
            a_notes, a_user, a_hold, a_stop = aggregate_phase.prepare(run, laws, defs, onto, run.iter / "aggregates")
        except session.SessionUnavailable as ex:
            return stop_infrastructure("an aggregate session", ex)
        notes += a_notes; to_user += a_user
        prog["aggregate_hold"] = a_hold; prog["aggregates_prepared"] = True
        for law, why in a_hold.items():
            notes.append(f"`{law}`: not planned this iteration — {why}")
        persist()
        if a_stop:
            to_user.append(f"the aggregate selection stayed defective twice: {a_stop}")
            feedback_phase.write_feedback(run, ledger, notes, to_user, [], concept_ledger)
            return "protocol_failure", a_stop

    # --- repair: a concept the gate or the review returned is re-proposed from the coder's evidence,
    # before any law is planned; its users stay held and uncharged
    if not stage_at_least("repaired"):
        # repair sessions are independent and each writes only its own directory: they run together, and
        # each is committed as it finishes
        prog_lock = threading.Lock()

        def record(key: str, ident: str, rdir) -> None:
            with prog_lock:
                prog.setdefault(key, {})[ident] = str(rdir); persist()
        try:
            candidates = []
            for e in concept_ledger.repairable():
                if e.concept in prog["repairs"]:
                    continue                                # its repair session ran before an interruption
                rec_raw = None
                for cand in sorted(run.dir.glob("iter-*/code/concept__*/concept.json"), reverse=True):
                    d = json.loads(cand.read_text(encoding="utf-8"))
                    if d.get("concept_id") == e.concept:
                        rec_raw = d; break
                if rec_raw is not None:
                    candidates.append((e, ConceptRecord(rec_raw)))
            # a concept is repaired for the nodes that claim it now, directly or through the concepts they
            # call that wait on it; one nothing uses waits, returned, until a plan claims it again
            refs_of = {e.concept: set(rec.refs()) for e, rec in candidates}
            refs_of.update({ConceptRecord(d).id: set(ConceptRecord(d).refs()) for d in prog["carried_concepts"]})
            users_of = {e.concept: [n.raw for n in carried if e.concept in concept_closure(concept_deps(n), refs_of)] for e, _rec in candidates}
            jobs = []
            for e, rec in candidates:
                if not users_of[e.concept]:
                    notes.append(f"concept `{e.concept}`: not repaired, no node uses it")
                    continue
                jobs.append((e.concept, rec, e.reasons, Path(e.last_task), users_of[e.concept]))
            with ThreadPoolExecutor(max_workers=max(1, opts.workers)) as pool:
                futures = {pool.submit(plan_phase.run_repair, run, rec, reasons, last, defs, users): cid for cid, rec, reasons, last, users in jobs}
                for f in as_completed(futures):
                    record("repairs", futures[f], f.result())
        except session.SessionUnavailable as ex:
            return stop_infrastructure("a concept repair session", ex)
        try:
            planned_laws = {e.law for e in ledger.entries.values() if e.state == "planned"}
            by_law: dict[str, list] = {}
            # a law whose recorded repair returned or blocked it (before an interruption) runs no more repairs
            stopped = {node_ledger.entries[i].law for i, rd in prog["node_repairs"].items()
                       if i in node_ledger.entries and not plan_phase.read_repair(Path(rd), concept=False).accepted}
            for e in node_ledger.repairable(planned_laws):
                if e.node in prog["node_repairs"] or e.law in stopped:
                    continue
                if not (Path(e.last_task) / "node.json").exists():
                    node_ledger.failed(e.node, e.law, ["no record found in the last task directory"], e.last_task, run.iteration); continue
                by_law.setdefault(e.law, []).append(e)

            def repair_law(entries: list) -> None:
                """A law's nodes one after another: each repair sees its siblings' most recent valid records, and
                once one outcome returns or blocks the law, its remaining repairs are not run."""
                for e in entries:
                    nrec = Node(json.loads((Path(e.last_task) / "node.json").read_text(encoding="utf-8")))
                    siblings = sibling_records(run, e.law, e.node, ledger, node_ledger, prog)
                    rdir = plan_phase.run_node_repair(run, nrec, e.reasons, Path(e.last_task), by_id[e.law], defs, siblings, Reading(run.reading_file), onto)
                    record("node_repairs", e.node, rdir)
                    if not plan_phase.read_repair(Path(rdir), concept=False).accepted:
                        break                                 # this outcome returns or blocks the law
            with ThreadPoolExecutor(max_workers=max(1, opts.workers)) as pool:
                for f in as_completed([pool.submit(repair_law, entries) for entries in by_law.values()]):
                    f.result()
        except session.SessionUnavailable as ex:
            return stop_infrastructure("a node repair session", ex)
        prog["stage"] = "repaired"; persist()

    # the repairs' outcomes, applied once: a resume takes the records the first application kept
    if not prog.get("repairs_applied"):
        repaired_nodes, repaired = _apply_repairs(run, opts, prog, ledger, concept_ledger, node_ledger, gap_ledger, carried, notes, to_user, gaps_filed)
        prog["repair_results"] = {"nodes": [n.raw for n in repaired_nodes], "concepts": [c.raw for c in repaired]}
        prog["repairs_applied"] = True
        propagate_concept_failures(concept_ledger)
        persist()
    repaired_nodes = [Node(d) for d in prog["repair_results"]["nodes"]]
    repaired = [ConceptRecord(d) for d in prog["repair_results"]["concepts"]]
    carried = [n for n in carried if n.id not in {r.id for r in repaired_nodes}] + repaired_nodes
    # a concept held from the iteration before (a deferred review, a pause, a wait) is coded again, unrepaired
    for d in prog["carried_concepts"]:
        if d.get("concept_id") not in run.all_concepts() and d.get("concept_id") not in {r.id for r in repaired} \
                and concept_ledger.entries.get(d.get("concept_id")) is not None and concept_ledger.entries[d["concept_id"]].state != "failed":
            repaired.append(ConceptRecord(d))
            notes.append(f"concept `{d.get('concept_id')}`: coded again, it was held")
    # a law a repair above returned or blocked takes its held nodes with it: judged without their
    # siblings they would fail for the missing sibling, and those reasons would bury the law's own
    carried = [n for n in carried if n.law not in ledger.entries or ledger.entries[n.law].state == "planned"]

    # --- plan: one session per batch, root laws before the laws that name them; a law a repair above
    # returned is planned in this iteration
    if not stage_at_least("planned"):
        plannable = [e for e in ledger.plannable() if e.law not in prog.get("aggregate_hold", {})]
        batches, waiting, dead = plan_batches(plannable, ledger, by_id, opts.plan_batch)
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
                print("[loop] every plannable law waits for a law that cannot progress: stopping")
                return ("complete" if all(e.state in TERMINAL for e in ledger.entries.values()) else "incomplete",
                        "every plannable law waits for a law that cannot progress")
            return "", ""
        print(f"[loop] iteration {run.iteration}: {len(batches)} plan session(s) over {sum(len(b) for b in batches)} law(s)"
              + (f", {len(waiting)} waiting on a named law" if waiting else "") + (f", {len(repaired)} repaired concept(s)" if repaired else ""))
        try:
            def unreadable(d: Path, batch) -> bool:        # a planner's records that cannot be read return its laws; the run goes on
                bad = plan_outputs_unreadable(d)
                if bad is None:
                    return False
                quarantine_plan_outputs(d)
                for lw in batch:
                    ledger.return_law(lw.id, [f"the plan session's records could not be read: {bad}"], run.iteration)
                notes.append(f"plan records unreadable ({d.name}), {len(batch)} law(s) returned: {bad}")
                return True
            under_repair = [r.raw for r in repaired]           # the planner reuses these ids and proposes none of them again
            cut_off_laws: list[str] = []                        # laws of a plan session stopped at its cap: their missing nodes are not the law's
            if len(batches) == 1:
                plan_dir = plan_phase.run_plan(run, batches[0], defs, pending=under_repair)
                if session.cut_off_of(plan_dir):
                    cut_off_laws += [lw.id for lw in batches[0]]
                unreadable(plan_dir, batches[0])
                plan_phase.record_origins(plan_dir, [(plan_dir, [lw.id for lw in batches[0]])])
            else:
                dirs, pending = [], list(under_repair)
                for k, batch in enumerate(batches, 1):
                    d = plan_phase.run_plan(run, batch, defs, tag=f"batch-{k:02d}", pending=pending)
                    if session.cut_off_of(d):
                        cut_off_laws += [lw.id for lw in batch]
                    if unreadable(d, batch):
                        continue
                    dirs.append((d, [lw.id for lw in batch]))
                    pending += [n.raw for n in blueprint.load(d / "blueprint.jsonl")] + [c.raw for c in blueprint.load_concepts(d / "blueprint.jsonl")]
                plan_dir = plan_phase.merge_batches(run, [d for d, _laws in dirs])
                plan_phase.record_origins(plan_dir, dirs)
        except session.SessionUnavailable as e:
            return stop_infrastructure("a plan session", e)
        # an accepted node's id is not reserved here: a plan may re-emit the node unchanged, which the
        # validator admits (and the loop does not code again) and refuses when the record differs
        taken = {n.id: "a node held or repaired this iteration" for n in carried}
        id_defects, id_notes = plan_phase.settle_identity(plan_dir, taken)
        notes += id_notes
        prog["id_defects"] = id_defects
        prog["plan_dir"] = str(plan_dir); prog["batch_laws"] = [l.id for b in batches for l in b]
        prog["plannable"] = [e.law for e in plannable]; prog["waiting"] = sorted(waiting); prog["dead"] = sorted(dead)
        prog["cut_off_laws"] = cut_off_laws
        prog["stage"] = "planned"; persist()
    plan_dir = Path(prog["plan_dir"])
    # law-local aggregates the plans wrote are admitted by the same gate; a claim of an aggregate the
    # selection did not admit goes back to the selection role once (once per law)
    kept_claims: dict[str, str] = prog.get("kept_claims", {})
    if not prog.get("aggregates_merged"):
        try:
            local = []
            for r in aggregates.load(plan_dir / "aggregates.jsonl"):
                aid = str(r.get("aggregate_id", "")) if isinstance(r, dict) else ""
                law_id = aid.split(":", 1)[0]
                if not aggregates.law_local(aid) or law_id not in by_id:
                    notes.append(f"aggregate record `{aid}` rejected: a plan writes only law-local aggregates `<law id>:<span>::<term>`"); continue
                errs = aggregates.record_defects(r, onto, {law_id: " ".join(by_id[law_id].text.split())})
                if errs:
                    notes.append(f"aggregate `{aid}` rejected — " + "; ".join(errs[:4])); continue
                local.append(r)
            _entries, a_notes, a_user = aggregate_phase.admit(run, local, definitions_mod.load_table(run), defs, onto,
                                                              run.iter / "aggregates", laws=by_id)
            notes += a_notes; to_user += a_user
            claims = aggregate_phase.claimed_ids(blueprint.load(plan_dir / "blueprint.jsonl") + carried)
            c_notes, c_close = aggregate_phase.correct_claims(run, claims, defs, onto, ledger, run.iter / "aggregates")
            notes += c_notes
            for law, why in c_close.items():
                if law in ledger.entries and ledger.entries[law].state not in TERMINAL:
                    ledger.fail(law, [why]); notes.append(f"`{law}`: closed — {why}")
            admitted_now = Reading(run.reading_file).aggregate_ids()
            kept_claims = {law: f"the selection kept its representation of {sorted(i for i in ids if i not in admitted_now)}: map the words without the aggregate"
                           for law, ids in claims.items() if any(not aggregates.law_local(i) and i not in admitted_now for i in ids)}
        except session.SessionUnavailable as ex:
            return stop_infrastructure("an aggregate session", ex)
        prog["aggregates_merged"] = True; prog["kept_claims"] = kept_claims; persist()
    reading = Reading(run.reading_file)
    batch_laws = set(prog.get("batch_laws", []))
    nodes = []
    for n in blueprint.load(plan_dir / "blueprint.jsonl"):
        law = n.get("law_refs", ["?"])[0] if isinstance(n.get("law_refs"), list) and n.get("law_refs") else "?"
        if law in batch_laws and law in ledger.entries and ledger.entries[law].state not in TERMINAL:
            nodes.append(n)
        elif not prog.get("registered"):
            notes.append(f"`{n.id}`: a node of `{law}`, which this iteration's plan sessions were not given (or which is closed); not registered")
    if not prog.get("registered"):
        planned_laws: dict[str, list[str]] = {}
        for n in nodes:
            planned_laws.setdefault(n.law, []).append(n.id)
        for law, ids in planned_laws.items():
            if ledger.mark_planned(law, ids, run.iteration):
                node_ledger.drop_law(law)
                duties = [review_phase.duty_of(n, by_id[law]) for n in nodes if n.law == law]
                for r in review_phase.upheld_rows(run, {law}) + review_phase.upheld_rows(run, {law}, structural=True):
                    if not any(r.get("duty") == d["id"] or (r.get("law_digest") == d["law_digest"]
                                                            and review_phase.overlaps(r.get("duty_ranges") or [], d["ranges"])) for d in duties):
                        notes.append(f"`{law}`: no node of the plan holds the duty an obligation of iteration {r.get('iteration')} was "
                                     f"upheld on (`{r.get('subject')}`), so it is not replayed until one does")
        waiting, dead = set(prog.get("waiting", [])), set(prog.get("dead", []))
        for law, why in prog.get("id_defects", {}).items():
            if law in ledger.entries and ledger.entries[law].state not in TERMINAL:
                ledger.return_law(law, ["the plan's records could not be used: " + "; ".join(why[:6])], run.iteration)
                notes.append(f"`{law}`: returned — its plan records are malformed or their ids collide: " + "; ".join(why[:3]))
        for law in prog.get("plannable", []):
            if law in prog.get("id_defects", {}):
                continue
            e = ledger.entries.get(law)
            if e is not None and law not in planned_laws and law not in waiting and law not in dead and e.state in ("open", "returned"):
                if law in prog.get("cut_off_laws", []) and not ledger.record_outcomes(law, ["plan:cut_off"], limit=2):
                    ledger.return_uncharged(law, ["the plan session was stopped at its cap before it wrote a node for this law"])
                    notes.append(f"`{law}`: the plan session was cut off before its node; re-planned once, uncharged")
                    continue
                ledger.return_law(law, ["the plan session produced no node for this law"], run.iteration)
                notes.append(f"`{law}` was plannable and the plan produced no node for it; returned")
        prog["registered"] = True; persist()

    # --- validate A: concepts (the plan's and the repaired) and nodes; deterministic, re-run on resume,
    # its ledger writes skipped for what this iteration already decided
    verdicts, concept_verdicts = validate_phase.run_validate(run, plan_dir, by_id, reading, defs, extra_concepts=repaired, extra_nodes=carried,
                                                             extra_validate_nodes=carried)
    planned_ids = {n.id for n in nodes} | {c.id for c in carried}
    verdicts = [v for v in verdicts if v.node.id in planned_ids]
    to_code_concepts: list[ConceptRecord] = []
    failed_ids = {cid for cid, e in concept_ledger.entries.items() if e.state == "failed"}
    # the concepts this plan's nodes and the held nodes use, directly or through another concept's body:
    # read from records the validator accepted only (a held node by its current verdict), since a
    # returned record's fields may be malformed and it is used only through its law and its reasons
    judged = {v.node.id for v in verdicts}
    ok_nodes = [v.node for v in verdicts if v.kind == "accept"] + [c for c in carried if c.id not in judged]
    needed = {cd for n in ok_nodes for cd in concept_deps(n)}
    # the graph, the needed set and every queue come from accepted records only: a returned record's
    # id and references may be malformed, and one whose id is not a concept id goes back to its batch
    refs_of = {cv.concept.id: set(cv.concept.refs()) for cv in concept_verdicts if cv.kind == "accept"}
    needed = concept_closure(needed, refs_of)
    origin_reasons: dict[str, list[str]] = {}
    for cv in concept_verdicts:
        cid_raw = cv.concept.raw.get("concept_id")
        if cv.kind != "accept" and not (isinstance(cid_raw, str) and nodeid.is_concept_id(cid_raw)):
            o = plan_phase.origin_of(plan_dir, cv.concept.raw) or {}
            why = (f"a concept record of {o.get('batch', 'the plan')} (record {o.get('position', '?')}) was returned by the validator — "
                   + "; ".join(str(r) for r in cv.reasons[:4]))
            notes.append(why)
            for law in o.get("laws", []):
                origin_reasons.setdefault(law, []).append(why)
            continue
        decided = cv.concept.id in prog["concepts"] or cv.concept.id in run.all_concepts()
        if cv.concept.id in failed_ids:
            notes.append(f"concept `{cv.concept.id}` failed earlier in this run and is not coded again")
        elif cv.kind == "accept":
            # the users are the nodes of this plan and the held nodes that claim the concept, derived here;
            # a concept none of them uses (a repair's replacement the planner did not take up) is not coded
            users = {n.id for n in ok_nodes if cv.concept.id in concept_deps(n)}
            if cv.concept.id not in needed:
                notes.append(f"concept `{cv.concept.id}`: no node of this plan uses it; not coded")
                continue
            if not decided:
                concept_ledger.planned(cv.concept.id, sorted(users), run.iteration)
            to_code_concepts.append(cv.concept)
        elif not decided:
            concept_ledger.noted(cv.concept.id, cv.reasons)
            notes.append(f"concept `{cv.concept.id}` returned by the validator — " + "; ".join(cv.reasons[:4]))
    for v in verdicts:                                    # a plan that names a failed concept is a defect of the plan
        if v.kind != "accept":
            continue
        dead_c = sorted(cd for cd in concept_deps(v.node) if cd in failed_ids)
        if dead_c:
            v.kind = "return"
            v.reasons = v.reasons + [f"{v.node.id}: uses concept `{cd}`, which failed in this run "
                                     f"({'; '.join(concept_ledger.entries[cd].reasons[:2])[:300]}): propose a different notion "
                                     "under a new id, or withdraw the span as a gap" for cd in dead_c]
    by_law_verdicts: dict[str, list] = {}
    for v in verdicts:
        by_law_verdicts.setdefault(v.node.law, []).append(v)
    to_code: list[Node] = []
    law_of = {n.id: n.law for n in nodes}
    law_of.update({nid: Node(raw).law for nid, raw in run.all_nodes().items()})
    law_of.update({n.id: n.law for n in carried})

    def law_of_id(i: str) -> str:                       # a node of a law closed earlier is in none of the above
        return law_of.get(i) or nodeid.law_of(i)[0]
    if not stage_at_least("validated"):
        for law, vs in by_law_verdicts.items():
            if law not in ledger.entries:
                continue
            if any(v.kind == validate_a.FAIL for v in vs):
                ledger.fail(law, [r for v in vs for r in v.reasons])
                notes.append(f"`{law}`: closed as failed — " + "; ".join(r for v in vs for r in v.reasons[:2]))
            elif any(v.kind == "return" for v in vs):
                carried_ids = {c.id for c in carried}
                # the dependency's own route first: a held node composing a node of a failed law closes the law
                dead_comp = sorted({c.get("rule") for v in vs if v.node.id in carried_ids for c in v.node.compositions()
                                    if law_of_id(c.get("rule")) in ledger.entries and ledger.entries[law_of_id(c.get("rule"))].state == "failed"})
                if dead_comp:
                    ledger.fail(law, [f"composes {dead_comp}, whose law is closed as failed"])
                    notes.append(f"`{law}`: composes {dead_comp}, closed as failed — this law cannot be formalized")
                elif law in kept_claims:
                    # the plan claimed an aggregate the selection role, asked once, did not admit: no attempt is spent
                    ledger.return_uncharged(law, [kept_claims[law]] + [r for v in vs for r in v.reasons])
                    notes.append(f"`{law}`: {kept_claims[law]}; returned to the planner, no attempt counted")
                elif all(v.node.id in carried_ids for v in vs if v.kind == "return"):
                    # a node held from an earlier iteration no longer validates beside the current plan (a node it
                    # composes was re-planned): the planner sees it again, and the law is not charged for it
                    ledger.return_uncharged(law, [r for v in vs for r in v.reasons])
                    notes.append(f"`{law}`: a held node no longer validates beside the current plan; returned to the planner, no attempt counted")
                else:
                    ledger.return_law(law, [r for v in vs for r in v.reasons], run.iteration)
        for law, why in origin_reasons.items():            # a returned law also hears of its batch's returned concept records
            e = ledger.entries.get(law)
            if e is not None and e.state in ("returned", "failed") and e.outcome_iteration == run.iteration:
                e.reasons = e.reasons + [w for w in why if w not in e.reasons]
        prog["stage"] = "validated"; persist()
    # a node gated and reviewed `OK` this iteration stays a candidate whatever its law's state since: a
    # sibling's later return does not undo it, and a resume finds it in the progress, not in a planned law
    decided_ok = {nid for nid, o in prog["nodes"].items() if o == "OK"}
    for law, vs in by_law_verdicts.items():
        planned = law in ledger.entries and ledger.entries[law].state == "planned" and not any(v.kind != "accept" for v in vs)
        for v in vs:
            if v.node.id in run.all_nodes():
                if planned:
                    notes.append(f"`{v.node.id}`: re-emitted unchanged; already accepted, not coded again")
            elif planned or v.node.id in decided_ok:
                to_code.append(v.node)

    # --- concepts: coded in dependency waves (`workers` at once), each gated, then reviewed
    concepts_now: list[str] = [c for c, v in prog["concepts"].items() if v == "OK" and c in run.accepted_concepts]
    concept_baselines: dict[str, dict] = {}
    for c in concepts_now:
        bfile = code_phase.concept_dir(run, c) / "baseline.json"
        if bfile.exists():
            concept_baselines[c] = json.loads(bfile.read_text())
    deferred_concepts_now: list[dict] = [c.raw for c in to_code_concepts if prog["concepts"].get(c.id) in ("PAUSED", "DEFERRED", "WAITING")]
    sessions_down = False
    budget_paused = ""
    remaining = [c for c in concept_order(to_code_concepts) if c.id not in prog["concepts"]]
    while remaining and not sessions_down and not budget_paused:
        accepted_c = set(run.all_concepts())
        wave = _wave(remaining, lambda c: sorted(c.refs() - set(onto.primitive_ids)), accepted_c)
        if not wave:
            for c in remaining:
                unmet = sorted(r for r in c.refs() if r not in accepted_c and r not in onto.primitive_ids)
                dead_r = [r for r in unmet if r in concept_ledger.entries and concept_ledger.entries[r].state == "failed"]
                if dead_r:
                    concept_ledger.fail(c.id, [f"calls {dead_r}, which failed"])
                    notes.append(f"concept `{c.id}`: closed, it calls {dead_r}, which failed")
                    prog["concepts"][c.id] = "FAILED"
                else:
                    # the concepts it calls are still pending: it waits, uncharged, with its record kept
                    concept_ledger.wait(c.id, unmet, [f"waits for {unmet}, not yet accepted"])
                    deferred_concepts_now.append(c.raw)
                    notes.append(f"concept `{c.id}`: not coded yet, it waits for {unmet}")
                    prog["concepts"][c.id] = "WAITING"
            persist(); break
        wave = wave[:max(1, opts.workers)]
        registry = {"nodes": sorted(run.all_nodes()), "concepts": sorted(accepted_c)}
        wave_files = {c.id: _files_of("concept", c.id) for c in wave}
        with ThreadPoolExecutor(max_workers=max(1, opts.workers)) as ex:
            futures = {c.id: ex.submit(code_phase.run_code_concept, run, c, reading, registry,
                                       [f for o, fs in wave_files.items() if o != c.id for f in fs]) for c in wave}
            results = {cid: f.result() for cid, f in futures.items()}
        to_review_c: list[tuple] = []
        for c in wave:
            v = results[c.id]
            cdir = code_phase.concept_dir(run, c.id)
            concept_baselines[c.id] = json.loads((cdir / "baseline.json").read_text())
            notes.append(f"concept `{c.id}`: gate {v.verdict}" + (f" — {'; '.join(v.details[:4])}" if v.details else ""))
            dep = report_of(run, cdir, reached_concepts(run, set(c.refs())))
            if dep.status in ("deferred", "unavailable"):  # its report could not be judged: the concept is held, uncharged
                if v.verdict == "OK":
                    code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
                sessions_down = sessions_down or dep.status == "unavailable"
                deferred_concepts_now.append(c.raw); prog["concepts"][c.id] = "PAUSED"
                to_user.append(f"concept `{c.id}`: its coder's dependency-defect report could not be judged ({dep.status}: "
                               + "; ".join(dep.reasons)[:300] + "); its record is held — rerun the loop later")
                persist(); continue
            if dep.status == "upheld":                    # a concept it calls is defective: it waits for that one's successor
                if v.verdict == "OK":
                    code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
                mark_defective(run, opts, dep, cdir, to_user)
                concept_ledger.wait(c.id, [dep.concept], [f"its coder showed `{dep.concept}` computes what its contract excludes (upheld): {dep.line[:200]}"])
                prog["concepts"][c.id] = "WAITING"; deferred_concepts_now.append(c.raw)
                notes.append(f"concept `{c.id}`: waits — the concept it calls, `{dep.concept}`, was found defective")
                persist(); continue
            if dep.status != "none":
                notes.append(f"concept `{c.id}`: its dependency-defect report was not admitted ({dep.status}): " + "; ".join(dep.reasons)[:300])
            if v.extras.get("panic"):
                to_user.append(f"concept `{c.id}`: the gate's evaluation panicked, reproduced in isolation — a possible Core defect: {v.extras['panic'][0]}")
            if v.verdict in (code_phase.SESSION_FAILED, gate.INFRA):
                # an outage keeps the work: the record is held and coded again, nothing is charged
                sessions_down = True
                deferred_concepts_now.append(c.raw); prog["concepts"][c.id] = "PAUSED"
                to_user.append(f"the coding session or the toolchain for concept `{c.id}` did not run ({'; '.join(v.details[:1])}); rerun the loop later")
                persist(); continue
            if v.verdict == "SCOPE_VIOLATION":
                to_user.append(f"the coding session for concept `{c.id}` changed files outside its concept: {'; '.join(v.details[:2])} — "
                               f"the concept was rolled back; {cdir / 'baseline.json'} holds each library file's digest before the session: "
                               "restore only the files named to those digests before the next iteration, never by a restore of the whole tree")
            if v.verdict != "OK":
                concept_ledger.returned(c.id, [f"gate {v.verdict}"] + v.details[:6], last_task=str(cdir))
                prog["concepts"][c.id] = v.verdict; persist(); continue
            to_review_c.append((c, v, cdir))

        def review_one_concept(item):
            c, v, cdir = item
            try:
                return review_phase.review_concept(run, c, v.extras, cdir / "review"), None
            except (session.SessionUnavailable, BudgetPaused) as e:
                return None, e
        # the wave's concept reviews are independent: they run together, and their outcomes are applied
        # once all have finished, since a rollback rewrites files a running review reads
        with ThreadPoolExecutor(max_workers=max(1, opts.workers)) as ex:
            reviewed_c = list(ex.map(review_one_concept, to_review_c))
        for (c, v, cdir), (out, e) in zip(to_review_c, reviewed_c):
            if e is not None:
                code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
                deferred_concepts_now.append(c.raw); prog["concepts"][c.id] = "PAUSED"
                concept_ledger.planned(c.id, concept_ledger.entries[c.id].used_by if c.id in concept_ledger.entries else [], run.iteration)
                if isinstance(e, BudgetPaused):
                    budget_paused = str(e)
                else:
                    sessions_down = True
                    to_user.append(f"the review session for concept `{c.id}` never ran ({e}); its record is held — rerun the loop later")
                persist(); continue
            if out.status == "deferred":
                code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
                stage = out.defer_stage or "concept_adjudication"
                if stage == "certificate":            # the harness did not run: infrastructure, never counted
                    sessions_down = True
                    deferred_concepts_now.append(c.raw); prog["concepts"][c.id] = "PAUSED"
                    to_user.append(f"the certificate program for concept `{c.id}` did not run ({'; '.join(out.reasons[:1])}); rerun the loop later")
                    persist(); continue
                prog["concepts"][c.id] = "DEFERRED"
                bound = 2 if stage in JUDGE_STAGES else opts.session_retries + 1
                if concept_ledger.defer_judge(c.id, stage, out.reasons, bound=bound):
                    if stage in JUDGE_STAGES:
                        notes.append(f"concept `{c.id}`: closed, judge_protocol_failure — " + "; ".join(out.reasons[:2]))
                        to_user.append(f"concept `{c.id}` failed: its review was left without a valid judgment twice in a row "
                                       "(a diagnostic; the laws that use it are closed by the dependency route)")
                    else:
                        _pause_users(ledger, concept_ledger, c.id, f"the review of concept `{c.id}` stayed unusable {bound} times", to_user)
                else:
                    deferred_concepts_now.append(c.raw)
                    notes.append(f"concept `{c.id}`: review deferred ({stage}) — " + "; ".join(out.reasons[:2]) + "; coded again next iteration")
                persist(); continue
            concept_ledger.clear_judge(c.id)
            review_notes = out.advisories
            if out.status == "returned":
                code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
                concept_ledger.returned(c.id, ["review: " + "; ".join(out.reasons)], last_task=str(cdir))
                notes.append(f"concept `{c.id}`: review failed — " + "; ".join(out.reasons[:3]))
                prog["concepts"][c.id] = "REVIEW"; persist(); continue
            record = {**c.raw, "reads": v.extras.get("reads", []), "refs": v.extras.get("refs", sorted(c.refs())),
                      "canonical_body": v.extras.get("canonical_body"), "body_json": v.extras.get("body_json"),
                      "accepted_in": f"{opts.run_id}/iter-{run.iteration:03d}"}
            added = list(v.extras.get("narrowings_added", []))
            record["narrowings"] = list(c.raw.get("narrowings", [])) + added
            approx = [x for x in review_notes if x != "reviewer off"]   # what it computes as built, for every later plan
            if approx:
                record["approximations"] = approx
                notes.append(f"concept `{c.id}`: accepted; the review's notes are recorded on it — " + "; ".join(a[:200] for a in approx[:3]))
            if added:
                coder_narrowings[c.id] = added
            run.accepted_concepts[c.id] = record
            concepts_now.append(c.id)
            concept_ledger.accepted(c.id, last_task=str(cdir))
            prog["concepts"][c.id] = "OK"; persist()
            if c.get("supersedes"):
                users = [nid for nid, raw in run.all_nodes().items() if c.get("supersedes") in concept_deps(Node(raw))]
                notes.append(f"migration candidates for `{c.get('supersedes')}` → `{c.id}`: {users or 'none'}")
        remaining = [c for c in remaining if c.id not in {w.id for w in wave}]
    for c in remaining:                                   # left by an outage or a pause: held, coded next iteration
        if c.raw not in deferred_concepts_now:
            deferred_concepts_now.append(c.raw); prog["concepts"].setdefault(c.id, "PAUSED")
    propagate_concept_failures(concept_ledger)
    if prog["stage"] in ("validated",):
        prog["stage"] = "concepts"
    run.deferred_concepts = deferred_concepts_now
    persist()
    with lean.library_lock(paths.LIBRARY):
        index_sync.write_index()

    # --- nodes: carried ones first, then this plan's, coded in dependency waves; each gated, then reviewed
    accepted_now: list[Node] = []
    baselines: dict[str, dict] = {}
    failed_ids: set[str] = set()
    planned_now = {law for law, e in ledger.entries.items() if e.state == "planned"}
    live = lambda n: n.law in planned_now or prog["nodes"].get(n.id) == "OK"
    to_code = [n for n in carried if live(n)] + [n for n in to_code if n.id not in {c.id for c in carried} and live(n)]
    deferred_now: list[dict] = []
    for n in to_code:                                   # nodes already decided in this iteration (resume)
        v = prog["nodes"].get(n.id)
        if v == "OK":
            accepted_now.append(n)
            bfile = code_phase.node_dir(run, n.id) / "baseline.json"
            if bfile.exists():
                baselines[n.id] = json.loads(bfile.read_text())
        elif v in ("HELD", "PAUSED", "DEFERRED", "INTEGRATION_WAIT"):
            deferred_now.append(n.raw); failed_ids.add(n.id)
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
        if budget_paused or sessions_down:
            for n in remaining_nodes:                         # the run pauses or stops: the node is held, its law keeps its plan
                deferred_now.append(n.raw); ledger.hold(n.law, run.iteration); prog["nodes"][n.id] = "PAUSED"
                if sessions_down:
                    ledger.defer(n.law, ["not coded: sessions unavailable this iteration"])
            persist(); break
        accepted_n = set(run.all_nodes()) | {n.id for n in accepted_now}
        ready: list[Node] = []
        for n in remaining_nodes:
            deps = {c.get("rule") for c in n.compositions()}
            fenced_used = sorted((concept_deps(n) | deps) & set(run.fenced))
            if fenced_used:                              # fenced after it was planned: only a re-plan can give it a usable provider
                why = fenced_provider_reasons(run, n, fenced_used)
                ndir = code_phase.node_dir(run, n.id)
                if (ndir / "baseline.json").exists():     # coded before the fence (a resume): its files leave the library
                    code_phase.rollback(n.id, json.loads((ndir / "baseline.json").read_text(encoding="utf-8")), ndir)
                notes.append(f"`{n.id}`: not coded — " + "; ".join(why))
                ledger.return_uncharged(n.law, why)
                failed_ids.add(n.id); prog["nodes"][n.id] = "FENCED_PROVIDER"; continue
            unmet_concepts = sorted(cd for cd in concept_deps(n) if cd not in run.all_concepts())
            if unmet_concepts:
                states = {cd: (concept_ledger.entries[cd].state if cd in concept_ledger.entries else "not proposed") for cd in unmet_concepts}
                repairable = {cd for cd in unmet_concepts if cd in concept_ledger.entries and concept_ledger.entries[cd].state == "returned" and concept_ledger.entries[cd].last_task}
                if any(s in ("failed", "not proposed") for s in states.values()) or any(cd not in repairable and states[cd] == "returned" for cd in unmet_concepts):
                    reasons = [f"uses concept `{cd}`, {s}" + (f": {'; '.join(concept_ledger.entries[cd].reasons[:3])}" if cd in concept_ledger.entries and concept_ledger.entries[cd].reasons else "") for cd, s in states.items()]
                    notes.append(f"`{n.id}`: not coded — " + "; ".join(reasons))
                    ledger.return_for_concepts(n.law, sorted(states), reasons, run.iteration)
                else:
                    notes.append(f"`{n.id}`: held — uses {unmet_concepts}, pending (under repair or waiting); no attempt counted")
                    deferred_now.append(n.raw); ledger.hold(n.law, run.iteration)
                failed_ids.add(n.id); prog["nodes"][n.id] = "HELD"; continue
            unmet = sorted(d for d in deps if d not in accepted_n)
            pending_here = [d for d in unmet if any(m.id == d for m in remaining_nodes) and d not in failed_ids]
            if pending_here:
                continue                                # a later wave, once its composed node is decided
            if unmet:
                states = {d: ledger.entries[law_of_id(d)].state if law_of_id(d) in ledger.entries else "?" for d in unmet}
                dead_n = sorted(d for d, s in states.items() if s == "failed")
                blocked = sorted(d for d, s in states.items() if s == "blocked")
                if dead_n:
                    notes.append(f"`{n.id}`: composes {dead_n}, whose law is closed as failed — this law cannot be formalized")
                    ledger.fail(n.law, [f"composes {dead_n}, closed as failed"])
                elif blocked:
                    gaps = sorted({g for d in blocked for g in ledger.entries[law_of_id(d)].gaps})
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
            origin = f"{opts.run_id}/iter-{run.iteration:03d} {n.id}"
            decls = [d for d in n.get("assumptions", []) + n.get("intentions", []) if isinstance(d, dict) and d.get("id")]
            decls = list({d["id"]: {"id": d["id"], "meaning": d.get("meaning")} for d in decls}.values())
            for target in (run.reading_file, opts.reading):
                Reading.add_proposals(target, vetted, origin)
                Reading.add_declarations(target, decls, origin)
            # the notices come from the reading's own record of what this node proposed in this iteration,
            # so a resume after a stop re-derives the ones the stop lost and repeats none
            names = {pr.get("name") for pr in vetted}
            base = json.loads(Path(opts.reading).read_text(encoding="utf-8")) if vetted else {}
            for p in base.get("params", []):
                if p.get("proposed") == origin and p.get("name") in names:
                    line = f"parameter `{p['name']}` = {p['value']} {p['unit']} proposed by `{n.id}` ({str(p.get('convention', ''))[:80]}); review it in {opts.reading}"
                    if line not in to_user:
                        to_user.append(line)
                    note = f"`{n.id}` proposed `{p['name']}` = {p['value']} {p['unit']}: {str(p.get('convention', ''))[:120]}"
                    if note not in notes:
                        notes.append(note)
        reading = Reading(run.reading_file)
        registry = {"nodes": sorted(accepted_n), "concepts": sorted(run.all_concepts())}
        wave_files = {n.id: _files_of("node", n.id) for n in wave}
        with ThreadPoolExecutor(max_workers=max(1, opts.workers)) as ex:
            futures = {n.id: ex.submit(code_phase.run_code, run, n, reading, registry,
                                       [f for o, fs in wave_files.items() if o != n.id for f in fs]) for n in wave}
            results = {nid: f.result() for nid, f in futures.items()}
        to_review: list[tuple] = []
        for n in wave:
            v = results[n.id]
            ndir = code_phase.node_dir(run, n.id)
            baselines[n.id] = json.loads((ndir / "baseline.json").read_text())
            notes.append(f"`{n.id}`: gate {v.verdict}" + (f" — {'; '.join(v.details[:4])}" if v.details else ""))
            dep = report_of(run, ndir, reached_concepts(run, concept_deps(n)))
            if dep.status in ("deferred", "unavailable"):  # its report could not be judged: the node is held, its law keeps its budget
                if v.verdict == "OK":
                    code_phase.rollback(n.id, baselines[n.id], ndir)
                sessions_down = sessions_down or dep.status == "unavailable"
                deferred_now.append(n.raw); failed_ids.add(n.id); prog["nodes"][n.id] = "PAUSED"
                to_user.append(f"`{n.id}`: its coder's dependency-defect report could not be judged ({dep.status}: "
                               + "; ".join(dep.reasons)[:300] + "); the node is held — rerun the loop later")
                ledger.defer(n.law, [f"dependency-defect report not judged: {'; '.join(dep.reasons)[:200]}"]); persist(); continue
            if dep.status == "upheld":                    # the defect is the concept's: the law returns once per concept version
                if v.verdict == "OK":
                    code_phase.rollback(n.id, baselines[n.id], ndir)
                mark_defective(run, opts, dep, ndir, to_user)
                why = [f"`{n.id}`: its coder showed `{dep.concept}` computes what its contract excludes (upheld): {dep.line[:240]} — "
                       "supersede the concept or map the words around it"]
                failed_ids.add(n.id); prog["nodes"][n.id] = "DEPENDENCY"
                node_ledger.failed(n.id, n.law, why, str(ndir), run.iteration)
                ledger.return_for_concepts(n.law, [dep.concept], why, run.iteration)
                persist(); continue
            if dep.status != "none":
                notes.append(f"`{n.id}`: its dependency-defect report was not admitted ({dep.status}): " + "; ".join(dep.reasons)[:300])
            if v.extras.get("panic"):
                to_user.append(f"`{n.id}`: the gate's evaluation panicked, reproduced in isolation — a possible Core defect: {v.extras['panic'][0]}")
            if v.verdict in (code_phase.SESSION_FAILED, gate.INFRA):
                # an outage keeps the work: the node is held and coded again, its law keeps its plan and budget
                sessions_down = True
                deferred_now.append(n.raw); failed_ids.add(n.id); prog["nodes"][n.id] = "PAUSED"
                to_user.append(f"the coding session or the toolchain for `{n.id}` did not run ({'; '.join(v.details[:1])}); the law keeps its attempt budget — rerun the loop later")
                ledger.defer(n.law, [f"session or toolchain did not run: {'; '.join(v.details[:1])}"]); persist(); continue
            if v.verdict == "SCOPE_VIOLATION":
                to_user.append(f"the coding session for `{n.id}` changed files outside its node: {'; '.join(v.details[:2])} — "
                               f"the node was rolled back; {ndir / 'baseline.json'} holds each library file's digest before the session: "
                               "restore only the files named to those digests before the next iteration, never by a restore of the whole tree")
            if v.verdict != "OK":
                failed_ids.add(n.id); prog["nodes"][n.id] = v.verdict
                reasons_g = [f"gate {v.verdict}"] + v.details[:6]
                unexpressed = v.extras.get("unexpressed", []) if v.verdict == "UNEXPRESSED" else []
                # the two-confirmation rule for an unstatable span, keyed by the occurrence of its words in the law
                # (not its id, which a re-plan renumbers, nor its text, which may occur twice)
                offs = blueprint.span_offsets(n.get("segmentation", []), by_id[n.law].text)
                key_of = {u.get("span"): f"gate:UNEXPRESSED:{n.law}@{review_phase.law_digest(by_id[n.law].text)}:"
                                         + "-".join(str(x) for x in offs.get(str(u.get("span")), ("?", "?")))
                          for u in unexpressed}
                hit = ledger.record_outcomes(n.law, sorted(set(key_of.values())), limit=2) if unexpressed else []
                hit_keys = {h.rsplit(" ×", 1)[0] for h in hit}
                planned_gaps = {g.get("span"): g for g in n.gaps()}
                confirmed = {u.get("span") for u in unexpressed if u.get("span") in planned_gaps}
                hit_spans = {sp for sp, k in key_of.items() if k in hit_keys} | confirmed
                if hit_spans:                             # the coder said twice, or the planner and the coder agree, that the words cannot be stated
                    ids, routed = [], []
                    for u in unexpressed:
                        if u.get("span") not in hit_spans:
                            continue
                        kind = "atom" if u.get("kind") == "no_atom" else "operator"
                        span_text = n.spans().get(u.get("span"), {}).get("text", "")
                        pg = planned_gaps.get(u.get("span"), {})
                        gid, decided = _file_gap(gap_ledger, {"span": u.get("span"), "kind": pg.get("kind", kind),
                                                              "proposal": pg.get("proposal") or u.get("why", ""), "nearest": pg.get("nearest", []),
                                                              "span_text": span_text, "law_refs": [n.law], "node_id": n.id,
                                                              "occurrence": key_of[u.get("span")].split(":", 2)[2],
                                                              "linked_to": pg.get("linked_to"), "excluding_clause": pg.get("excluding_clause")},
                                                 opts.run_id, run.iteration, gaps_filed)
                        if decided:
                            routed.append(f"gap {gid} on span {u.get('span')} was {decided[0]} by the operator: {decided[1]}")
                        elif gid not in ids:
                            ids.append(gid)
                    node_ledger.failed(n.id, n.law, reasons_g + routed, str(ndir), run.iteration)
                    if ids:
                        ledger.block(n.law, ids, reasons_g)
                        why_filed = "the plan proposed the gap and the coding session confirmed it" if confirmed else "two coding sessions declared the span cannot be stated"
                        to_user.append(f"gap(s) {', '.join(ids)} filed for `{n.law}`: {why_filed}; "
                                       f"decide with `python -m harness gap decide <id> --state ... --decision ...`")
                        notes.append(f"`{n.id}`: gate UNEXPRESSED on {sorted(hit_spans)} ({why_filed}) — gap(s) {ids} filed, law blocked")
                    else:                                 # every span names a gap the operator already decided: back to the planner with the decision
                        ledger.return_law(n.law, reasons_g + routed, run.iteration)
                        notes.append(f"`{n.id}`: gate UNEXPRESSED on decided gap(s) — returned to the planner with the decision: " + "; ".join(routed)[:300])
                elif v.verdict not in ("SCOPE_VIOLATION", gate.GATE_TIMEOUT) and node_ledger.budget_left(n.id):
                    node_ledger.returned(n.id, n.law, reasons_g, str(ndir), run.iteration); ledger.hold(n.law, run.iteration)
                    notes.append(f"`{n.id}`: gate {v.verdict} — sent to a node repair session; no attempt counted")
                else:                                     # a repair cannot make the evaluation cheaper: the plan's mapping decides its shape
                    ledger.return_law(n.law, reasons_g, run.iteration)
                persist(); continue
            added = list(v.extras.get("narrowings_added", []))
            if added:
                coder_narrowings[n.id] = added
            to_review.append((n, v, ndir, added))

        def review_one(item):
            n, v, ndir, added = item
            try:
                return review_phase.review_behaviour(run, n, by_id[n.law], onto, reading, v.extras.get("rule_json"), added, ndir / "review"), None
            except (session.SessionUnavailable, BudgetPaused) as e:
                return None, e
        # the wave's reviews are independent and take no lock: they run together, and their outcomes are
        # applied only once all have finished, since a rollback rewrites files a running review reads
        with ThreadPoolExecutor(max_workers=max(1, opts.workers)) as ex:
            reviewed = list(ex.map(review_one, to_review))
        for (n, v, ndir, added), (out, e) in zip(to_review, reviewed):
            if e is not None:
                # an outage or a pause keeps the work: the node is held, its law keeps its plan and budget
                code_phase.rollback(n.id, baselines[n.id], ndir)
                deferred_now.append(n.raw); ledger.hold(n.law, run.iteration)
                failed_ids.add(n.id); prog["nodes"][n.id] = "PAUSED"
                if isinstance(e, BudgetPaused):
                    budget_paused = str(e)
                else:
                    sessions_down = True
                    to_user.append(f"the behaviour review for `{n.id}` never ran ({e}); the node is held, its law keeps its attempt budget — rerun the loop later")
                    ledger.defer(n.law, [f"behaviour review never ran: {e}"])
                persist(); continue
            param_notes_to_user(to_user, out.param_notes)
            for a in out.advisories:
                if a != "reviewer off":
                    notes.append(f"behaviour review of `{n.id}`, advisory: {a}")
                if a.startswith("obligation invalidated:"):
                    to_user.append(f"`{n.law}` ({n.id}), {a} — retire the ruling (`ruling: retired`) if the case was wrong; "
                                   "otherwise it is information only")
                if a.startswith("gap candidate:"):
                    to_user.append(f"`{n.law}` ({n.id}), {a} — file it in the gap ledger, or decide the rule may stand without it")
            to_user += [q for q in out.questions if q not in to_user]
            if out.status == "deferred":
                code_phase.rollback(n.id, baselines[n.id], ndir)
                failed_ids.add(n.id)
                stage = out.defer_stage or "review"
                if stage == "certificate":                # the harness did not run: infrastructure, never counted
                    sessions_down = True
                    deferred_now.append(n.raw); ledger.hold(n.law, run.iteration); prog["nodes"][n.id] = "PAUSED"
                    to_user.append(f"the certificate program for `{n.id}` did not run ({'; '.join(out.reasons[:1])}); rerun the loop later")
                    persist(); continue
                prog["nodes"][n.id] = "DEFERRED"
                bound = 2 if stage in JUDGE_STAGES else opts.session_retries + 1
                if node_ledger.defer_judge(n.id, n.law, stage, [f"review of `{n.id}` deferred: {r}" for r in out.reasons], bound=bound):
                    if stage in JUDGE_STAGES:
                        why = [f"judge_protocol_failure: the {stage} judge left the review of `{n.id}` without a valid answer twice in a row"] + out.reasons[:2]
                        node_ledger.failed(n.id, n.law, why, str(ndir), run.iteration); ledger.fail(n.law, why)
                        notes.append(f"`{n.law}`: closed, judge_protocol_failure ({stage}) — " + "; ".join(out.reasons[:2]))
                    else:
                        why = [f"the review of `{n.id}` stayed unusable {bound} times ({stage}): the operator decides"] + out.reasons[:2]
                        ledger.block(n.law, [f"decision:{n.law}"], why)
                        to_user.append(f"`{n.law}` paused: {why[0]} (python -m harness reopen {opts.run_id} --laws {n.law})")
                else:
                    deferred_now.append(n.raw); ledger.hold(n.law, run.iteration)
                    notes.append(f"`{n.id}`: review deferred ({stage}) — " + "; ".join(out.reasons[:2]) + "; coded again next iteration, no attempt counted")
                persist(); continue
            node_ledger.clear_judge(n.id)
            ledger.reset_outcomes(n.law, [f"behaviour:{k}" for k in out.satisfied])   # a satisfied case ends its streak
            ok_b, reasons_b, keys_b = out.status != "returned", out.reasons, out.keys
            if not ok_b:
                code_phase.rollback(n.id, baselines[n.id], ndir)
                failed_ids.add(n.id); prog["nodes"][n.id] = "BEHAVIOUR"
                notes.append(f"`{n.id}`: behaviour review returned it — " + "; ".join(reasons_b[:4]))
                keys = sorted(f"behaviour:{k}" for k in keys_b)          # the case's lineage: the same case across node ids and repairs
                repeated = ledger.record_outcomes(n.law, keys)
                reasons_full = [f"behaviour review of `{n.id}`: {r}" for r in reasons_b]
                if repeated:
                    why = [f"repeated outcome {', '.join(repeated)} across the law's plans and repairs: the operator decides"] + reasons_full
                    node_ledger.failed(n.id, n.law, why, str(ndir), run.iteration); ledger.block(n.law, [f"decision:{n.law}"], why)
                    to_user.append(f"`{n.law}` waits for a decision: {', '.join(repeated)} (python -m harness reopen {opts.run_id} --laws {n.law})")
                elif node_ledger.budget_left(n.id):
                    node_ledger.returned(n.id, n.law, reasons_full, str(ndir), run.iteration); ledger.hold(n.law, run.iteration)
                    notes.append(f"`{n.id}`: sent to a node repair session; no attempt counted")
                else:
                    ledger.return_law(n.law, reasons_full, run.iteration)
                persist(); continue
            accepted_now.append(n); prog["nodes"][n.id] = "OK"; persist()
        remaining_nodes = [n for n in remaining_nodes if n.id not in {w.id for w in wave}]
    run.deferred_nodes = deferred_now
    if not stage_at_least("nodes"):
        prog["stage"] = "nodes"
    persist()

    # --- the accepted candidates whose dependency context changed are checked again before integration
    if not prog.get("contexts_rechecked"):
        base = context_base(opts, semantic_inputs(opts))
        prog["context_base"] = base
        rechecked, failing, unresolved = integrate_phase.recheck_contexts(run, Reading(run.reading_file), base, effective_laws(run, by_id))
        closed = integrate_phase.fence_closure(run)
        refresh_inactive(run)
        notes += [f"dependency context changed and rechecked: `{i}`" for i in rechecked]
        to_user += context_notices(failing, closed)
        if unresolved:                                # a check that could not run decides nothing: nothing is integrated before it runs
            to_user += [x + " — not fenced and not recorded as checked; the iteration stops before integration and checks it again "
                        "at the resume" for x in unresolved if x not in to_user]
            feedback_phase.write_feedback(run, ledger, notes, to_user, [], concept_ledger)
            persist()
            return "infrastructure_failure", ("the obligations of accepted records could not be checked before integration — "
                                              + "; ".join(unresolved[:4]) + "; the coded candidates are kept, rerun the loop")
        prog["contexts_rechecked"] = True; persist()

    # --- integrate: one outcome, committed before it is applied, and applied once
    if prog.get("integration") is None:
        # a run stopped mid-integration: each candidate is put back as the gate passed it, from the integration's own copy
        cand = run.iter / "integrate" / "candidates"
        for n in accepted_now:
            for rel in (nodeid.rule_path(n.id), nodeid.witness_path(n.id)):
                if not (paths.LIBRARY / rel).exists() and (cand / rel).exists():
                    (paths.LIBRARY / rel).parent.mkdir(parents=True, exist_ok=True); shutil.copy2(cand / rel, paths.LIBRARY / rel)
        # a candidate whose files are not as the gate passed them is not integrated again
        missing = [n for n in accepted_now if code_phase._files_digest((nodeid.rule_path(n.id), nodeid.witness_path(n.id))) is None]
        accepted_now = [n for n in accepted_now if n not in missing]
        concept_refs = {c: set(ConceptRecord(run.accepted_concepts[c]).refs()) for c in concepts_now if c in run.accepted_concepts}
        # a candidate whose provider was fenced after it was coded waits, uncharged, for a usable successor
        held = integrate_phase.unavailable_candidates(run, accepted_now, concept_refs)
        result = integrate_phase.run_integrate(run, accepted_now, reading, baselines, concepts_now, concept_baselines, concept_refs,
                                               held=held)
        result["unavailable"] = held
        for n in missing:
            result["rejected"][n.id] = "its files left the library before integration (an interrupted integration); coded again"
        if result["status"] in ("infrastructure", "baseline_broken"):   # nothing was decided: a resume integrates again
            to_user.append(f"integration stopped ({result['status']}): " + "; ".join(result["problems"][:3]))
            persist()
            return result["status"] if result["status"] == "baseline_broken" else "infrastructure_failure", \
                f"integration {result['status']}: " + "; ".join(result["problems"][:2])
        prog["integration"] = result
        for i in result["rejected"]:
            if i in prog["nodes"]:
                prog["nodes"][i] = "INTEGRATION"
            if i in prog["concepts"]:
                prog["concepts"][i] = "INTEGRATION"
        for i in result["waiting"]:                       # held, not rejected: a resume puts them back on the held list
            if i in prog["nodes"]:
                prog["nodes"][i] = "INTEGRATION_WAIT"
            if i in prog["concepts"]:
                prog["concepts"][i] = "WAITING"
        persist()
    if not prog.get("integration_applied"):
        result = prog["integration"]
        # a fence committed after the result was (a stop between the two, a resume): nothing kept uses a fenced record
        late = integrate_phase.unavailable_candidates(
            run, [n for n in accepted_now if n.id in set(result["kept"])],
            {c: set(ConceptRecord(run.accepted_concepts[c]).refs()) for c in result.get("kept_concepts", []) if c in run.accepted_concepts})
        for i, why in late.items():
            result["kept"] = [k for k in result["kept"] if k != i]
            result["kept_concepts"] = [k for k in result.get("kept_concepts", []) if k != i]
            result["waiting"][i] = why
            result.setdefault("unavailable", {})[i] = why
            if i in prog["nodes"]:
                code_phase.rollback(i, baselines.get(i, {}), code_phase.node_dir(run, i)); prog["nodes"][i] = "INTEGRATION_WAIT"
            if i in prog["concepts"]:
                code_phase.rollback_concept(i, concept_baselines.get(i, {}), code_phase.concept_dir(run, i)); prog["concepts"][i] = "WAITING"
        nodes_now = {n.id: n for n in to_code}
        for i, why in result["rejected"].items():
            notes.append(f"rejected at integration: {i}: {why}")
            if i in nodes_now:
                ledger.return_law(nodes_now[i].law, [f"rejected at integration: {why}"], run.iteration)
            elif i in concept_ledger.entries:
                concept_ledger.returned(i, [f"rejected at integration: {why}"], last_task=str(code_phase.concept_dir(run, i)))
                run.accepted_concepts.pop(i, None)
        for i, why in result["waiting"].items():
            notes.append(f"held at integration: {i}: {why}")
            if i in nodes_now and i in result.get("unavailable", {}):   # a provider fenced after it was coded: the law is planned again
                ledger.return_uncharged(nodes_now[i].law, fenced_provider_reasons(run, nodes_now[i], [
                    d for d in sorted((concept_deps(nodes_now[i]) | {c.get("rule") for c in nodes_now[i].compositions()}) & set(run.fenced))]) or [why])
            elif i in nodes_now:
                run.deferred_nodes = [d for d in run.deferred_nodes if d.get("node_id") != i] + [nodes_now[i].raw]
                ledger.hold(nodes_now[i].law, run.iteration)
            elif i in run.accepted_concepts:
                run.deferred_concepts = [d for d in run.deferred_concepts if d.get("concept_id") != i] + [run.accepted_concepts.pop(i)]
                concept_ledger.planned(i, concept_ledger.entries[i].used_by if i in concept_ledger.entries else [], run.iteration)
        prog["integration_applied"] = True
        persist()
    result = prog["integration"]
    kept = set(result["kept"])
    index = MappingIndex(run.mapping_file)
    added = [n for n in accepted_now if n.id in kept and n.id not in run.accepted_nodes]
    for n in added:
        run.accepted_nodes[n.id] = {**n.raw, "narrowings": list(n.get("narrowings", [])) + coder_narrowings.get(n.id, [])}
    for n in added:
        if prog.get("context_base"):                   # what its verdicts were established on, once every node it composes is in
            run.accepted_nodes[n.id]["context"] = integrate_phase.context_version(run, "node", n.id, Reading(run.reading_file),
                                                                                     prog["context_base"], semantic=True)
        for cd in concept_deps(n):                     # an accepted concept lists the accepted nodes that call it, apart from its planned users
            callers = run.accepted_concepts[cd].setdefault("callers", []) if cd in run.accepted_concepts else None
            if callers is not None and n.id not in callers:
                callers.append(n.id)
        for g in n.gaps():                             # the plan doubted the vocabulary; the coder wrote the span with it
            to_user.append(f"`{n.law}` ({n.id}): the plan proposed a {g.get('kind')} gap on span {g.get('span')}, but the coding "
                           "session wrote the span with the mapped atoms and the rule was accepted; no gap is filed")
        for x in n.get("narrowings", []):              # each word read through conduct, for the operator to review
            if isinstance(x, dict) and x.get("kind") == "observable_reading":
                words = n.spans().get(x.get("span"), {}).get("text", "")
                to_user.append(f"`{n.law}` ({n.id}) reads \"{words}\" ({x.get('category')}) through conduct: {str(x.get('why', ''))[:240]}")
        for c in n.get("compositions", []):
            line = f"`{n.law}` span {c.get('span')} composes accepted `{c.get('rule')}` (as: {c.get('as')})"
            notes.append(line); to_user.append(line + " — both rules can flag the same episode")
        for e in n.get("elements", []):
            t = n.spans().get(e.get("span"), {}).get("text", "")
            index.record(t, set(e.get("atoms", [])) | set(e.get("derived", [])), n.id, n.spans().get(e.get("span"), {}).get("role"))
    index.save()
    if run.reconcile_fences():                         # a fence of a version this iteration replaced is history now
        refresh_inactive(run)
    # what this iteration's own gates accepted is known to pass them: the next loop start reuses that verdict
    sem = semantic_inputs(opts)
    integrate_phase.record_admitted(
        run, [("node", n.id) for n in added] + [("concept", c) for c in concepts_now
                                                if c in result.get("kept_concepts", concepts_now) and c in run.accepted_concepts],
        Reading(run.reading_file), {"core": sem["core"], "ontology": sem["ontology"]}, run.iteration)
    prog["stage"] = "integrated"; persist()
    # a law is accepted when every node it was planned with is accepted, whichever iteration coded it
    for e in ledger.entries.values():
        if e.state == "planned" and e.nodes and all(i in run.all_nodes() for i in e.nodes):
            ledger.accept(e.law, e.nodes)
    # --- feedback
    feedback_phase.write_feedback(run, ledger, notes, to_user, gaps_filed, concept_ledger, run.deferred_nodes, coder_narrowings)
    prog["stage"] = "done"; persist()
    kept_concepts = [c for c in concepts_now if c in result.get("kept_concepts", concepts_now)]
    print(f"[loop] iteration {run.iteration}: accepted {len(kept)} node(s), {len(kept_concepts)} concept(s); laws {ledger.counts()}")
    if budget_paused:
        print(f"[loop] the OpenAI budget is reached: pausing — {budget_paused}")
        return "paused_budget", budget_paused
    if sessions_down:
        print("[loop] sessions or toolchain unavailable: stopping after this iteration")
        return "infrastructure_failure", "a session or the toolchain could not be launched"
    if not kept and not kept_concepts and not gaps_filed and not concept_ledger.repairable() and not run.deferred_nodes \
            and not run.deferred_concepts \
            and not node_ledger.repairable({e.law for e in ledger.entries.values() if e.state == "planned"}) \
            and all(e.state != "returned" for e in ledger.entries.values()):
        print("[loop] no progress and nothing returned: stopping")
        return ("complete" if all(e.state in TERMINAL for e in ledger.entries.values()) else "incomplete"), "no progress and nothing returned"
    return "", ""


def _file_gap(gap_ledger: GapLedger, proposal: dict, run_id: str, iteration: int, gaps_filed: list) -> tuple[str, tuple[str, str] | None]:
    """File a gap proposal; returns (id, the operator's decision if the gap matched is one already
    rejected or retired). A decided gap is never filed again as pending: its recurrence goes back
    with the decision. A new or undecided gap is listed once in `gaps_filed`."""
    gid = gap_ledger.add(proposal, run_id, iteration)
    decided = gap_ledger.decision(gid)
    if decided and decided[0] in ("rejected", "retired"):
        return gid, decided
    if not any(g["id"] == gid for g in gaps_filed):
        gaps_filed.append({"id": gid, "kind": proposal.get("kind"), "span": proposal.get("span_text") or proposal.get("span"),
                           "law_refs": proposal.get("law_refs", [])})
    return gid, None


def _pause_users(ledger: Ledger, concept_ledger: ConceptLedger, cid: str, why: str, to_user: list[str]) -> None:
    """A concept whose review stayed unusable within its operational budget: the laws that use it
    wait for the operator, uncharged."""
    e = concept_ledger.entries.get(cid)
    for law in sorted({nodeid.law_of(str(u))[0] for u in (e.used_by if e else [])}):
        if law in ledger.entries:
            ledger.block(law, [f"decision:{law}"], [why])
            to_user.append(f"`{law}` paused: {why} (python -m harness reopen <run> --laws {law})")


def _apply_repairs(run: Run, opts: Options, prog: dict, ledger: Ledger, concept_ledger: ConceptLedger, node_ledger: NodeLedger,
                   gap_ledger: GapLedger, carried: list[Node], notes: list, to_user: list, gaps_filed: list) -> tuple[list[Node], list[ConceptRecord]]:
    """Apply the repair sessions' outcomes to the ledgers: a node repair's revised record is coded
    again; a withdrawal of kind `atom` or `operator` files a gap and blocks the law; any other
    withdrawal, a missing record or a record that kept a defect returns the law to the planner. A
    concept repair's record is coded again; its withdrawal returns the laws that use it. Returns the
    revised node records and the concept records to code."""
    repaired_nodes: list[Node] = []
    repaired: list[ConceptRecord] = []
    laws_by_id = {l.id: l for l in corpus.load_laws(opts.laws)} if prog.get("node_repairs") else {}
    for nid, rdir in prog.get("node_repairs", {}).items():
        e = node_ledger.entries.get(nid)
        law_of_node = e.law if e else nodeid.law_of(nid)[0]
        rep = plan_phase.read_repair(Path(rdir), concept=False)
        if e is not None and e.state != "returned":
            if e.state == "repaired" and rep.accepted and nid not in run.all_nodes():
                repaired_nodes.append(rep.records[0])
            continue
        wd = rep.withdrawal
        planned_raw = json.loads((Path(e.last_task) / "node.json").read_text(encoding="utf-8")) if e and (Path(e.last_task) / "node.json").exists() else {}
        planned_spans = {s.get("id"): s for s in planned_raw.get("segmentation", [])}
        last_task = e.last_task if e else ""
        if rep.kind == "withdrawn" and wd.get("span") in planned_spans and wd.get("kind") in blueprint.GAP_KINDS:
            # the vocabulary cannot carry a span the law needs: a gap, decided by the operator, blocks the law
            law_obj = laws_by_id.get(law_of_node)
            at = blueprint.span_offsets(planned_raw.get("segmentation", []), law_obj.text).get(str(wd["span"])) if law_obj else None
            gid, decided = _file_gap(gap_ledger, {"span": wd["span"], "kind": wd["kind"], "proposal": wd.get("missing", ""), "nearest": wd.get("nearest", []),
                                                  "span_text": planned_spans[wd["span"]].get("text", ""), "law_refs": [law_of_node], "node_id": nid,
                                                  **({"occurrence": f"{law_of_node}@{review_phase.law_digest(law_obj.text)}:{at[0]}-{at[1]}"} if at else {}),
                                                  "linked_to": wd.get("linked_to"), "excluding_clause": wd.get("excluding_clause")},
                                     opts.run_id, run.iteration, gaps_filed)
            if decided:                                 # a recurrence of a decided gap: back to the planner with the operator's decision
                why = [f"node repair of `{nid}` withdrew span {wd['span']} as gap {gid}, which the operator {decided[0]}: {decided[1]}"]
                node_ledger.failed(nid, law_of_node, why, last_task, run.iteration)
                ledger.return_law(law_of_node, (list(e.reasons) if e else []) + why, run.iteration)
                notes.append(f"`{nid}`: " + why[0])
                continue
            to_user.append(f"gap {gid} filed for `{law_of_node}` by a node repair session; decide with `python -m harness gap decide {gid} ...`")
            node_ledger.failed(nid, law_of_node, [f"withdrawn: gap {gid}"], last_task, run.iteration)
            ledger.block(law_of_node, [gid], [f"node repair of `{nid}` withdrew span {wd['span']}: {wd.get('missing', '')}"])
            notes.append(f"`{nid}`: the repair session withdrew it — the vocabulary lacks {wd['kind']} `{wd.get('missing', '')}` for span {wd['span']}; gap {gid} filed, law blocked")
            continue
        refuted = list(e.reasons) if e else []          # why the node was sent to repair: the planner must see it, not only the repair's failure
        if rep.kind == "withdrawn" and wd.get("kind") == "concept":
            node = Node(planned_raw) if planned_raw else None
            dep = report_of(run, Path(rdir), reached_concepts(run, concept_deps(node)) if node else set())
            if dep.status in ("deferred", "unavailable"):  # the report could not be judged: the repair is not applied, nothing is charged
                to_user.append(f"node repair of `{nid}`: its dependency-defect report could not be judged ({dep.status}: "
                               + "; ".join(dep.reasons)[:300] + "); the node stays held for another repair — rerun the loop later")
                continue
            if dep.status == "upheld":
                mark_defective(run, opts, dep, Path(rdir), to_user)
                why = [f"node repair of `{nid}` showed `{dep.concept}` computes what its contract excludes (upheld): {dep.line[:240]}"]
                node_ledger.failed(nid, law_of_node, why, last_task, run.iteration)
                ledger.return_for_concepts(law_of_node, [dep.concept], refuted + why, run.iteration)
                notes.append(f"`{nid}`: " + why[0])
                continue
            why = [f"node repair of `{nid}`: its dependency-defect report was not admitted ({dep.status}) — " + "; ".join(dep.reasons)[:300]]
            node_ledger.failed(nid, law_of_node, why, last_task, run.iteration); ledger.return_law(law_of_node, refuted + why, run.iteration)
            notes.append(f"`{nid}`: " + why[0])
            continue
        if rep.kind in ("withdrawn", "missing"):
            why = [f"node repair of `{nid}`: the session " + ("withdrew the record" + (" as a plan defect (the text needs another cut)"
                                                                                       if wd.get("kind") == "plan" else "")
                                                               + (f" — {wd.get('missing')}" if wd.get("missing") else "")
                                                               if rep.kind == "withdrawn" else "wrote no record")]
            node_ledger.failed(nid, law_of_node, why, last_task, run.iteration); ledger.return_law(law_of_node, refuted + why, run.iteration)
            notes.append(f"`{nid}`: the repair session {'withdrew it' if rep.kind == 'withdrawn' else 'wrote no record'}; the law is returned to the planner")
        elif not rep.accepted:
            kept = rep.validation or [f"record.jsonl could not be read: {rep.message}"]
            why = [f"node repair of `{nid}` kept a defect: {l}" for l in kept[:4]]
            node_ledger.failed(nid, law_of_node, why, last_task, run.iteration); ledger.return_law(law_of_node, refuted + why, run.iteration)
            notes.append(f"`{nid}`: the repaired record kept a defect; the law is returned to the planner — " + "; ".join(kept[:2]))
        else:
            node_ledger.repaired(nid); repaired_nodes.append(rep.records[0])
            notes.append(f"`{nid}`: revised by a repair session; coded again this iteration")
    carried_now = [n for n in carried if n.id not in {r.id for r in repaired_nodes}] + repaired_nodes
    for cid, rdir in prog["repairs"].items():
        rep = plan_phase.read_repair(Path(rdir), concept=True)
        wd = rep.withdrawal if rep.kind == "withdrawn" else None
        if wd and wd.get("missing"):
            # a concept is the planner's decomposition of a law, not the law: when its repair withdraws it,
            # the laws that use it go back to the planner with the reason (and the replacements, if the
            # repair split it); a gap is filed for the operator to see, and blocks nothing
            why = str(wd["missing"])
            replacements = rep.records
            laws = sorted({n.law for n in carried_now if cid in concept_deps(n)})   # the laws whose nodes claim it now
            concept_ledger.fail(cid, [f"withdrawn by its repair session — {why}"])
            if replacements:
                new_ids = [r.id for r in replacements]
                repaired.extend(replacements)
                reason = f"concept `{cid}` was split by its repair session into {new_ids}: map its spans to them — {why[:300]}"
                notes.append(f"concept `{cid}`: split by its repair session into {new_ids}; {laws} return to the planner")
            else:
                gid, _decided = _file_gap(gap_ledger, {"span": cid, "kind": "concept", "proposal": why, "nearest": [], "span_text": f"concept {cid}",
                                                       "law_refs": laws, "node_id": cid}, opts.run_id, run.iteration, gaps_filed)
                reason = f"concept `{cid}` was withdrawn by its repair session: map the spans without it — {why[:300]}"
                notes.append(f"concept `{cid}`: withdrawn by its repair session; gap {gid} filed for the operator; {laws} return to the planner")
                to_user.append(f"gap {gid}: the repair session withdrew concept `{cid}` ({why[:200]}). Its laws {laws} return to the planner; "
                               "the gap blocks nothing and is for your review. A withdrawal states a session's view of the vocabulary, not a verdict it received")
            for law in laws:
                if law in ledger.entries:
                    ledger.return_for_concepts(law, [cid], [reason], run.iteration)
        elif rep.kind != "revised" or not rep.accepted:
            kept = (["the repair session wrote no record"] if rep.kind == "missing" else
                    ["the repair session withdrew it without a reason"] if rep.kind == "withdrawn" else
                    [f"the repaired record kept a defect: {l}" for l in (rep.validation or [f"record.jsonl could not be read: {rep.message}"])[:4]])
            concept_ledger.returned(cid, kept)
            notes.append(f"concept `{cid}`: " + "; ".join(kept[:2]))
        elif cid in run.all_concepts():
            pass
        else:
            repaired.append(rep.records[0])
            notes.append(f"concept `{cid}`: re-proposed by a repair session")
    return repaired_nodes, repaired
