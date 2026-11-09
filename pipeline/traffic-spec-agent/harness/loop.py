"""The loop: plan → validate A → code (concepts first, then the rules that use them), each coded
concept reviewed against its contract, each node decided by its gate (and, with `label_repair`, its
law by the label check) → integrate → feedback, until nothing is plannable or an iteration accepts
nothing new."""
from __future__ import annotations
import json
import re
from dataclasses import asdict, replace
from pathlib import Path
import shutil
from .checks import aggregates, gate, validate_a
from .model import acquisition, blueprint, corpus, nodeid, ontology
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
from .store.paths import run_is_new
from .store.budget import BudgetPaused
from .model.reading import Reading
from .store.state import (Options, Run, RUN_VERSION, acceptance_by_law, acceptance_policy_refusal, chain_version_refusal, commit_state,
                          policy_defects, saved_version_refusal, snapshot_defects)
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
        for c in n.dependencies():
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


def dependency_causes(states: dict[str, str], repairable: set[str]) -> list[str]:
    """The unmet concepts (id ↦ ledger state) that return a node's law: failed, never proposed, or
    returned with no repair to come. A concept still pending (returned and repairable, under repair or
    waiting) causes no return and is not registered against the law: the law waits for it."""
    return sorted(cd for cd, s in states.items() if s in ("failed", "not proposed") or (s == "returned" and cd not in repairable))


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
    task waits, uncharged, with the reason, and keeps the concept it names and the execution stage
    it reached (`execution` stays `unknown` where none was recorded)."""
    try:
        return review_phase.dependency_report(run, task, reached)
    except review_phase.Deferred as e:
        return replace(getattr(e, "reached", None) or review_phase.DependencyReport(""), status="deferred", reasons=[f"{e.stage}: {e.why}"])
    except (session.SessionUnavailable, review_phase.HarnessFailure) as e:
        return replace(getattr(e, "reached", None) or review_phase.DependencyReport(""), status="unavailable", reasons=[str(e)])


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


#: The review settings a record's dependency context depends on: those the concept review and its
#: adjudication use.
CONTEXT_REVIEW_SETTINGS = ("reviewer_model", "review_effort", "judge_effort")


def context_base(opts: Options, semantic: dict) -> dict:
    """What every record's dependency context is computed against besides its own inputs: Core, the
    ontology and the settings of the concept review (`CONTEXT_REVIEW_SETTINGS`)."""
    return {"core": semantic["core"], "ontology": semantic["ontology"],
            "review": [getattr(opts, k) for k in CONTEXT_REVIEW_SETTINGS]}


def check_options(opts: Options) -> None:
    """Refuse, before anything is spent, a budget that is not a finite non-negative amount, and an
    aggregate verifier that shares the planner's vendor (unless allowed) or whose key is not set."""
    import math
    for k in ("session_budget_usd", "repair_budget_usd", "judge_budget_usd", "openai_budget_usd", "claude_budget_usd",
              "total_budget_usd", "aggregate_verifier_budget_usd"):
        x = getattr(opts, k, None)
        if x is not None and (isinstance(x, bool) or not isinstance(x, (int, float)) or not math.isfinite(float(x)) or float(x) < 0):
            raise SystemExit(f"--{k} must be a finite, non-negative amount in USD (given {x!r})")
    if opts.label_deferred and opts.label_stage:
        raise SystemExit("--label_deferred and --label_stage are the two stages of a split run: give one")
    if (opts.label_deferred or opts.label_stage) and not opts.label_repair:
        raise SystemExit("--label_deferred and --label_stage are stages of a run with --label_repair")
    if opts.label_deferred and opts.label_dataset:
        raise SystemExit("--label_deferred reads no training recording: do not give --label_dataset")
    if opts.label_repair and not opts.label_deferred and not opts.label_dataset:
        raise SystemExit("--label_repair needs the training recordings (--label_dataset)")
    if (opts.label_deferred or opts.label_stage) and (opts.base_run or opts.budget_peers):
        raise SystemExit("a split run (--label_deferred / --label_stage) hands its state between machines, and its handoff does not "
                         "carry a base_run chain or the runs of budget_peers: run it without them")
    if opts.aggregate_verifier_model:
        from .agents import openai_runner
        if session.vendor_of(opts.aggregate_verifier_model) == session.vendor_of(opts.model) and not opts.allow_same_vendor:
            raise SystemExit(f"the aggregate verifier ({opts.aggregate_verifier_model}) and the planner ({opts.model}) share a vendor; "
                             "it is a second vendor's model — pass --allow_same_vendor to override")
        if session.vendor_of(opts.aggregate_verifier_model) == "openai" and not openai_runner.available() and not opts.dry_run:
            raise SystemExit("the aggregate verifier is an OpenAI model and OPENAI_API_KEY is not set in the harness's environment")


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


def unavailable_roots(ledger: Ledger, waits: dict) -> dict[str, set[str]]:
    """The laws that cannot progress without the operator, each with the root laws it waits on: a law
    blocked or closed as failed is its own root; a law whose current waits (`waits`: law ↦ the laws it
    waits on — a waiting law's named laws, a planned law's held nodes' composed laws) are all such
    laws is one too, with their roots. The least such set, so a cycle of waits reaching no root is none."""
    roots = {l: {l} for l, e in ledger.entries.items() if e.state in ("blocked", "failed")}
    changed = True
    while changed:
        changed = False
        for law, w in waits.items():
            if law not in roots and w and all(x in roots for x in w):
                roots[law] = set().union(*(roots[x] for x in w)); changed = True
    return roots


def held_waits(carried: list[Node], ledger: Ledger, accepted: set[str], usable_for=None) -> dict[str, set[str]]:
    """For each planned law every one of whose held nodes waits on composed nodes not accepted: the
    laws of those nodes. A planned law with a held node that waits on no other law's node (a concept
    under repair, its own coding) is left out: it progresses by itself. `usable_for` (law ↦ the node
    ids a node of that law may compose, `Run.usable_nodes`) replaces `accepted` when given."""
    by_law: dict[str, list[Node]] = {}
    for n in carried:
        by_law.setdefault(n.law, []).append(n)
    out: dict[str, set[str]] = {}
    for law, ns in by_law.items():
        if law not in ledger.entries or ledger.entries[law].state != "planned":
            continue
        ok = usable_for(law) if usable_for is not None else accepted
        per = [{nodeid.law_of(c["rule"])[0] for c in n.dependencies() if isinstance(c.get("rule"), str) and c["rule"]
                and c["rule"] not in ok} - {law} for n in ns]
        if all(per):
            out[law] = set().union(*per)
    return out


def acceptance_waits(run: Run, held: list[Node], ledger: Ledger) -> dict[str, set[str]]:
    """Under `acceptance_by_law`: for each planned law, the other planned laws one of its held nodes
    composes a node of that is not usable by it (`Run.usable_nodes`): the law cannot be accepted
    before those laws are, since its acceptance needs every node it was planned with."""
    out: dict[str, set[str]] = {}
    planned = lambda l: l in ledger.entries and ledger.entries[l].state == "planned"
    for n in held:
        if not planned(n.law):
            continue
        ok = run.usable_nodes(n.law)
        for c in n.dependencies():
            r = c.get("rule")
            if isinstance(r, str) and r and r not in ok:
                law = nodeid.law_of(r)[0]
                if law != n.law and planned(law):
                    out.setdefault(n.law, set()).add(law)
    return out


def acceptance_cycles(waits: dict[str, set[str]]) -> list[list[str]]:
    """The cycles of the acceptance waits (strongly connected components of more than one law): each
    law's acceptance waits, through the others, on its own, so none of them can ever be accepted."""
    index: dict[str, int] = {}
    low: dict[str, int] = {}
    on: set[str] = set()
    stack: list[str] = []
    out: list[list[str]] = []

    def visit(v: str) -> None:
        index[v] = low[v] = len(index)
        stack.append(v); on.add(v)
        for w in sorted(waits.get(v, ())):
            if w not in index:
                visit(w); low[v] = min(low[v], low[w])
            elif w in on:
                low[v] = min(low[v], index[w])
        if low[v] == index[v]:
            comp = []
            while True:
                w = stack.pop(); on.discard(w); comp.append(w)
                if w == v:
                    break
            if len(comp) > 1:
                out.append(sorted(comp))
    for v in sorted(waits):
        if v not in index:
            visit(v)
    return out


def block_acceptance_cycles(run: Run, ledger: Ledger, held: list[Node]) -> list[list[str]]:
    """A cycle of acceptance waits never resolves: each of its laws is blocked on `decision:<law>`
    for the operator, the cycle named, no attempt counted and no session run for it. A cycle of text
    references alone is not one (only held nodes' compositions count). Returns the cycles."""
    cycles = acceptance_cycles(acceptance_waits(run, held, ledger))
    for comp in cycles:
        why = (f"acceptance cycle {comp}: a held node of each composes a node of the next, and a law is accepted only with every "
               "node it was planned with, so none can be accepted; held for you, no attempt counted")
        for law in comp:
            ledger.block(law, [f"decision:{law}"], [why])
        run.pending_notices.append(why + " (python -m harness reopen " + run.opts.run_id + " --laws " + ",".join(comp) + ")")
        print(f"[loop] {why}")
    return cycles


def unavailable_rules(nodes, ledger: Ledger, law_of_id, roots: dict[str, set[str]], accepted: set[str]) -> dict[str, set[str]]:
    """The composed rules of `nodes` (execution dependencies naming a rule), not in `accepted`, whose
    law cannot progress without the operator — blocked or failed now, or in `roots` — each with the
    root laws it waits on."""
    out: dict[str, set[str]] = {}
    for n in nodes:
        for c in n.dependencies():
            r = c.get("rule")
            if not isinstance(r, str) or not r or r in accepted:
                continue
            law = law_of_id(r)
            e = ledger.entries.get(law)
            if e is not None and e.state in ("blocked", "failed"):
                out[r] = {law}
            elif law in roots:
                out[r] = set(roots[law])
    return out


def hold_on_unavailable(ledger: Ledger, law: str, rules: dict[str, set[str]], reasons: list[str], who: str,
                        notes: list[str], to_user: list[str], run_id: str) -> None:
    """A node of `law` composes `rules`, whose laws wait for the operator (rule ↦ root laws): the
    law is not coded and no attempt is counted; its record, the composition and its map stand as
    planned. It is blocked on what its roots wait on — a blocked root's gaps or decision tokens, and
    `decision:<root>` for a root closed as failed, which reopening that law decides — and reopens with
    them."""
    roots = set().union(*rules.values())
    tokens: set[str] = set()
    for r in sorted(roots):
        e = ledger.entries[r]
        tokens |= set(e.gaps) if e.state == "blocked" and e.gaps else {f"decision:{r}"}
    why = (f"composes {sorted(rules)}, whose law(s) wait for the operator ({', '.join(f'`{r}` {ledger.entries[r].state}' for r in sorted(roots))}): "
           f"the composition stands, and this law waits on {sorted(tokens)}; no attempt counted")
    ledger.block(law, sorted(tokens), [why] + [r for r in reasons if r])
    e = ledger.entries[law]
    if e.state == "blocked":                           # a dependency wait: a split stage stops for the operator on it
        e.waits_on = sorted(set(e.waits_on) | roots)
    notes.append(f"`{who}`: {why}")
    for r in sorted(roots):
        if ledger.entries[r].state == "failed":
            to_user.append(f"`{law}` waits on `{r}`, closed as failed, which a node of it composes: reopening `{r}` reopens `{law}` "
                           f"(python -m harness reopen {run_id} --laws {r})")


def reference_records(run: Run, law_ids: list[str], by_id: dict[str, corpus.Law]) -> tuple[dict[str, set[str]], set[str]]:
    """For each law whose text names other laws: the named laws its latest records in this run only
    borrow words from (`definition` references) and compose no node of, and whether it has no
    record at all (its first plan). A named law only borrowed from is no provider of this one, so
    planning it again never waits on it; a law with no record has not yet said what its reference
    is. A law whose history cannot be read in full counts as having a record."""
    ids, borrowed, unrecorded = set(by_id), {}, set()
    for lid in law_ids:
        if lid not in by_id or not corpus.references(by_id[lid], ids):
            continue
        _k, entries, unread = plan_phase.law_history(run, by_id[lid])
        latest = [Node(e.versions[-1][1]) for e in entries if e.versions]
        if not latest and not unread:
            unrecorded.add(lid)
        sources = {s for n in latest for s in n.definition_sources()}
        composed = {nodeid.law_of(str(c.get("rule")))[0] for n in latest for c in n.dependencies()}
        if sources - composed:
            borrowed[lid] = sources - composed
    return borrowed, unrecorded


def plan_batches(plannable: list, ledger: Ledger, by_id: dict[str, corpus.Law], batch_size: int,
                 borrowed: dict[str, set[str]] | None = None, unrecorded: set[str] | None = None,
                 held: dict[str, set[str]] | None = None
                 ) -> tuple[list[list[corpus.Law]], dict[str, list[str]], dict[str, list[str]]]:
    """The plannable laws in plan sessions of at most `batch_size`, ordered so that a law comes
    after every law its text names: a named law that is accepted is composed by its node; one
    that is plannable now goes into the same or an earlier batch (a cycle of references shares a
    batch); one that is planned (held included) or blocked makes this law wait (returned as `waiting`),
    closed over the chain: a law naming a law that waits waits with it. A named law closed as
    failed does not stop this law: it is planned (returned in `named_unavailable`, for the notes).
    Depth-first order over the reference graph, so a chain of exceptions is planned root first. A
    named law the law's latest records only borrow words from (`borrowed`, from `reference_records`)
    is no reference here: neither a wait nor an order. A law with no record yet (`unrecorded`) does
    not wait on a named law that cannot progress without the operator (`unavailable_roots`: blocked,
    failed, or waiting only on such laws, `held` giving a planned law's waits): it is planned with that
    law's posted text and returned in `named_unavailable` with it. A plan that composes such a law's
    node is held on what that law waits on, uncharged (`hold_on_unavailable`)."""
    ids = set(by_id)
    plan_ids = {e.law for e in plannable}
    first = unrecorded or set()
    refs = {lid: corpus.references(by_id[lid], ids) - (borrowed or {}).get(lid, set()) for lid in plan_ids}
    named = {lid: [r for r in sorted(refs[lid]) if r in ledger.entries and ledger.entries[r].state != "accepted"] for lid in plan_ids}
    waiting: dict[str, list[str]] = {}
    for _ in range(len(plan_ids) + 2):                    # the unavailable set only grows: a few passes settle it
        roots = unavailable_roots(ledger, {**(held or {}), **waiting})
        passes = {lid: {r for r in named[lid] if ledger.entries[r].state == "failed" or (lid in first and r in roots)} for lid in plan_ids}
        now = {lid: pending for lid in plan_ids if (pending := [r for r in named[lid] if r not in plan_ids and r not in passes[lid]])}
        changed = True
        while changed:
            changed = False
            for lid in sorted(plan_ids - set(now)):
                chain = [r for r in named[lid] if r in plan_ids and r in now and r not in passes[lid]]
                if chain:
                    now[lid] = chain; changed = True
        if now == waiting:
            break
        waiting = now
    named_unavailable = {lid: sorted(passes[lid]) for lid in plan_ids if passes[lid] and lid not in waiting}
    ready: set[str] = plan_ids - set(waiting)
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
    return batches, waiting, named_unavailable


def gap_gate(run: Run, opts: Options) -> list[tuple[str, str]]:
    """Before a launch touches anything: a new run (no state yet) starts a round, which refuses while
    a gap of the last one is open and archives the resolved ones with the runs that proposed them;
    a training run, new or resumed, refuses a ledger row that names a held-out law. Returns the
    gaps archived."""
    gaps = GapLedger(paths.GAPS_DIR)
    moved = gaps.start_round(paths.RESULTS) if not run.state_file.exists() else []
    if moved:
        print(f"[loop] {len(moved)} resolved gap(s) archived with the runs that proposed them: "
              + ", ".join(f"{g} → results/{r}/gaps.jsonl" for g, r in moved))
    if opts.mode == "train":
        held = held_out_law_ids()
        named = [f"{r['id']}: {sorted(set(r.get('law_refs', [])) & held)}" for r in gaps.rows if set(r.get("law_refs", [])) & held]
        if named:
            raise SystemExit("[loop] the gap ledger names held-out laws, which a training run must not see: " + "; ".join(named[:6]))
    return moved


def held_out_law_ids() -> set[str]:
    """The ids of the held-out split's laws (its law file's ids only), empty without one."""
    f = paths.REPO / "laws" / "example" / "test" / "laws.jsonl"
    return {json.loads(line)["id"] for line in f.read_text(encoding="utf-8").splitlines() if line.strip()} if f.exists() else set()


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
            "notes": [], "to_user": [], "gaps_filed": [], "coder_narrowings": {}, "held_why": {}}


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


def _ready(items, key_deps, accepted: set[str]):
    """The items whose dependencies are all accepted, in the given order."""
    return [x for x in items if all(d in accepted for d in key_deps(x))]


def _item_task(code, report, review=None):
    """One item's whole pipeline, run in a worker: its coding session and gate (`code`), its coder's
    dependency-defect report (`report`) and, for a concept the gate passed that the report leaves
    standing, its review (`review`; a node has none: its gate decides it). Returns (verdict, report,
    review outcome, the exception that stopped it): a budget pause stops it at any step, and leaves no
    verdict when it stops the coding or the report; a review that could not run stops only the review
    (the coding phase reports its own outage as a verdict)."""
    try:
        v = code()
        dep = report()
    except BudgetPaused as e:
        return None, None, None, e
    if review is None or v.verdict != "OK" or dep.status in review_phase.NOT_JUDGED + ("upheld",):
        return v, dep, None, None
    try:
        return v, dep, review(v), None
    except (session.SessionUnavailable, BudgetPaused) as e:
        return v, dep, None, e


def _scheduled(fn):
    """`fn` counted as a task that may write the production tree (`candidate.SCHEDULING`): counted
    here, before it is submitted, so a pause never misses it, and released when it ends."""
    from .phases.candidate import SCHEDULING
    held = SCHEDULING.task()
    held.__enter__()

    def run():
        try:
            return fn()
        finally:
            held.__exit__(None, None, None)
    return run


def _rolling(pending: list, workers: int, ready_of, start, apply, halted, where, shared: list[str] = (), scheduled: bool = False) -> None:
    """A stage's items, each run as one task (`start(item)`, in this thread, returns what a worker
    runs), at most `workers` at once; each task's outcome is applied in this thread as soon as it ends
    (`apply(item, result)`), and then every item that has become ready is submitted, in the order
    `ready_of(running ids)` returns them. `pending` holds the items not yet submitted and loses each
    one as it is. `ready_of` decides what it can of them; it is not asked while a task runs once
    `halted()`, so what is left is decided after the running tasks have ended.

    A gate's scope check does not count the files of another task whose run overlaps its session:
    `where(item)` gives an item's task directory and its two library files, and before a task starts
    its directory records those of every running task, and `shared` (what the loop writes for
    another item while sessions run), and each running task's directory adds the new task's. With
    `scheduled`, each task is counted by the scheduling a candidate transaction pauses (`_scheduled`)."""
    from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
    workers = max(1, workers)
    running: dict = {}
    with ThreadPoolExecutor(max_workers=workers) as ex:
        while True:
            if not (running and halted()):
                for x in ready_of({y.id for y in running.values()})[:workers - len(running)]:
                    work, own = where(x)
                    for y in running.values():
                        code_phase.tolerate(where(y)[0], own)
                    code_phase.tolerate(work, [f for y in running.values() for f in where(y)[1]] + list(shared), fresh=True)
                    pending.remove(x)
                    running[ex.submit(_scheduled(start(x)) if scheduled else start(x))] = x
            if not running:
                return
            done, _ = wait(running, return_when=FIRST_COMPLETED)
            for fut in [f for f in running if f in done]:
                apply(running.pop(fut), fut.result())


def _loop_written() -> list[str]:
    """The files of the pipeline the node stage writes for one node while others' sessions run, as
    the repository digest keys them: the gap ledger, which a node's outcome may file a gap in."""
    root, gaps = paths.REPO.resolve(), GapLedger(paths.GAPS_DIR)
    return [f.resolve().relative_to(root).as_posix() for f in (gaps.proposals_file, gaps.counter) if f.resolve().is_relative_to(root)]


def enter_proposed(run: Run, opts: Options, n: Node) -> None:
    """A node's vetted parameter proposals and its declarations, entered into both readings as the
    proposed tier, marked with the run, the iteration and the node (idempotent)."""
    vetted = [pr for pr in n.get("param_proposals", []) if isinstance(pr, dict)]
    origin = f"{opts.run_id}/iter-{run.iteration:03d} {n.id}"
    decls = [d for d in n.get("assumptions", []) + n.get("intentions", []) if isinstance(d, dict) and d.get("id")]
    decls = list({d["id"]: {"id": d["id"], "meaning": d.get("meaning")} for d in decls}.values())
    for target in (run.reading_file, opts.reading):
        Reading.add_proposals(target, vetted, origin)
        Reading.add_declarations(target, decls, origin)


def unannounced(run: Run, origin, node_id: str) -> bool:
    """Whether a reading entry `proposed` by `origin` is this node's entry in this run whose notice is
    still due: entered in this iteration, or in an earlier one from which on the node had not started
    (no task directory of it holds its record) until this iteration."""
    m = re.fullmatch(re.escape(run.opts.run_id) + r"/iter-(\d+) " + re.escape(node_id), str(origin or ""))
    if m is None:
        return False
    return not any((paths.iter_dir(run.opts.run_id, k) / "code" / node_id / "node.json").exists() for k in range(int(m[1]), run.iteration))


def _lib_files(kind: str, ident: str) -> list[str]:
    """A node's or a concept's two files, relative to the library (the layout of a snapshot)."""
    if kind == "concept":
        return [nodeid.concept_path(ident), nodeid.concept_witness_path(ident)]
    return [nodeid.rule_path(ident), nodeid.witness_path(ident)]


def _files_of(kind: str, ident: str) -> list[str]:
    """The same files as the repository digest keys them."""
    return [gate.lib_rel(r) for r in _lib_files(kind, ident)]


def reviewed_reading(reading: Path) -> str:
    """The digest of a reading's operator-reviewed content, the semantic input a run fixes: the reading
    without the parameters and declarations still marked `proposed`, which are a run's own state."""
    import hashlib
    data = jsonl.read_json(reading, {}) or {}
    kept = {**data, "params": [p for p in data.get("params", []) if isinstance(p, dict) and not p.get("proposed")],
            "declarations": [d for d in data.get("declarations", []) if isinstance(d, dict) and not d.get("proposed")]}
    return hashlib.sha256(json.dumps(kept, sort_keys=True, ensure_ascii=False).encode()).hexdigest()[:24]


def reviewed_values(reading: Path) -> dict:
    """A reading's operator-reviewed values alone: its parameters and declarations not marked
    `proposed`. The aggregates a run admits into its own reading, and the proposals it enters, are
    the run's state, not these values."""
    data = jsonl.read_json(reading, {}) or {}
    return {k: [x for x in data.get(k, []) if isinstance(x, dict) and not x.get("proposed")] for k in ("params", "declarations")}


def semantic_inputs(opts: Options) -> dict:
    """The run version (`RUN_VERSION`) and the digests of what a run's plans and reviews were built
    against: the corpus (its laws and posted definitions), the definition precedence, the definition
    resolver that reads them (its table is rewritten at every launch), the ontology, Core, the
    prompts, the base reading's reviewed values (a proposal awaiting the operator's review is a run's
    own state, never a semantic input), the acquisition profile a run names with the parameter it
    resolves to, and a base run's accepted records. A resume against another value of any of them, or
    without one the run was started with, would mix two runs, and stops before any record is rewritten.
    The digests do not cover the whole harness: the run version is what refuses a run another version
    started."""
    import hashlib

    def digest(paths_: list[Path]) -> str:
        h = hashlib.sha256()
        for p in sorted(paths_):
            if p.is_file():
                h.update(str(p.relative_to(paths.REPO) if p.is_relative_to(paths.REPO) else p).encode()); h.update(p.read_bytes())
        return h.hexdigest()[:24]
    laws = Path(opts.laws)
    precedence = Path(opts.definition_precedence or definitions_mod.DEFAULT_PRECEDENCE)
    out = {"corpus": digest([laws, laws.with_name("definitions.jsonl")]),
           "definition_precedence": digest([precedence]),
           "resolver": digest([paths.REPO / "harness" / "model" / "definitions.py"]),
           "ontology": digest([Path(opts.ontology)]),
           "core": digest(list(paths.CORE.rglob("*.lean"))),
           "prompts": digest(list((paths.REPO / "prompts").glob("*.md"))),
           "base_reading": reviewed_reading(Path(opts.reading)), "run_version": RUN_VERSION}
    if getattr(opts, "acquisition_profile", None):        # a run that names no profile reads no `heading_since`
        out["acquisition"] = acquisition.standard_digest(opts.acquisition_profile)
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
    file is named and left as it is) and an exhausted budget (`paused_budget`: resumed under the same
    run id once the operator raises the limit, the paused iteration taking up what it left undecided,
    its gated candidates reviewed without being coded again). Either is raised after the iteration
    committed what it had decided. A fault of the validator itself
    (an exception inside a check) stops the run as `infrastructure_failure`, uncharged, its traceback
    kept in `validator_fault.txt`."""
    from .phases import label_check
    import contextlib
    try:
        with (label_check.deferred("--label_deferred") if opts.label_deferred else contextlib.nullcontext()):
            result = _run_loop(opts)
        label_check.freeze(paths.run_dir(opts.run_id))       # the library the run leaves, scored by `label_check`
        return result
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
        if isinstance(e, BudgetPaused):
            label_check.freeze(run.dir)
        print(f"[loop] status: {status} — {e}")
        return {"status": status, "stop_reason": str(e), "iterations": run.iteration, "laws": ledger.counts()}


def write_options(run: Run, opts: Options, semantic: dict, saved_roots: list[str]) -> None:
    """The run's saved options: its contract (the acceptance policy and the semantic inputs) and how
    this launch was given them."""
    precedence = Path(opts.definition_precedence or definitions_mod.DEFAULT_PRECEDENCE)
    jsonl.write_atomic(run.dir / "options.json", json.dumps({**asdict(opts), "laws": str(opts.laws), "ontology": str(opts.ontology),
                                                             "base_reading": str(opts.reading), "reading": str(run.reading_file),
                                                             "definition_precedence": str(precedence),
                                                             "model_prices": str(opts.model_prices) if opts.model_prices else None,
                                                             "definition_precedence_sha256": definitions_mod.precedence_digest(precedence),
                                                             "repo_roots": [r for r in saved_roots if r != str(paths.REPO)] + [str(paths.REPO)],
                                                             "semantic": semantic}, indent=1))


#: The files a run writes only once it has run past its initialisation (its first committed snapshot
#: writes the ledgers and the accepted records; an iteration, a status, a handoff and rulings follow).
PROGRESS_FILES = ("ledger.jsonl", "concept_ledger.jsonl", "node_ledger.jsonl", "accepted_nodes.jsonl", "accepted_concepts.jsonl",
                  "summary.json", "rulings.jsonl", "handoff")


def metadata_refusal(run: Run) -> str | None:
    """Why an existing run (`run_is_new` false) cannot be resumed on its metadata, or None. Its
    `options.json`, the contract every launch is checked against (the acceptance policy and the semantic
    inputs; a new run writes it first), must be readable and whole; its snapshot `state.json` must be
    readable and whole (`snapshot_defects`), and may be missing only while nothing past its initialisation was written (no
    `iter-*` directory and none of `PROGRESS_FILES`): a launch cut short before its first snapshot is
    taken up under the same contract. A run is never initialised again over what it left."""
    try:
        o = jsonl.read_json(run.dir / "options.json", None)
    except jsonl.DataIntegrityError as e:
        return f"its options.json cannot be read ({e})"
    if not isinstance(o, dict) or not isinstance(o.get("semantic"), dict):
        return ("its options.json, which holds its acceptance policy and semantic inputs, is "
                + ("missing" if o is None else "incomplete"))
    bad = policy_defects(o)
    if bad:
        return "its options.json holds no whole acceptance policy (" + "; ".join(bad) + ")"
    try:
        snap = jsonl.read_json(run.state_file, None)
    except jsonl.DataIntegrityError as e:
        return f"its snapshot state.json cannot be read ({e})"
    if snap is None:
        past = sorted(p.name for p in run.dir.iterdir() if p.name.startswith("iter-") or p.name in PROGRESS_FILES)
        if past:
            return f"its snapshot state.json is missing, while {past} show it ran past its initialisation"
    elif snapshot_defects(snap, run.opts.run_id):
        return "its snapshot state.json is not whole (" + "; ".join(snapshot_defects(snap, run.opts.run_id)[:6]) + ")"
    return None


def _run_loop(opts: Options) -> dict:
    from .store import owner
    run = Run(opts)
    new = run_is_new(run.dir)
    # another run version's run, or a base chain holding one, is refused on its raw saved version before anything is read whole
    refusal = (None if new else saved_version_refusal(run.dir)) or (chain_version_refusal(opts.base_run, opts.run_id)
                                                                      if opts.base_run else None)
    if refusal:
        raise SystemExit(f"[loop] run `{opts.run_id}` cannot be resumed or started: {refusal} — nothing of this run was rewritten")
    refusal = None if new else metadata_refusal(run)
    if refusal:
        raise SystemExit(f"[loop] run `{opts.run_id}` cannot be resumed: {refusal}; restore its checkpoint, or start a new run id "
                         "— nothing of this run was rewritten")
    run.dir.mkdir(parents=True, exist_ok=True)
    saved_first = None if new else jsonl.read_json(run.dir / "options.json", None)
    if saved_first is not None:                         # another policy is refused before anything is touched (the version was checked above)
        refusal = acceptance_policy_refusal(saved_first, opts)
        if refusal:
            raise SystemExit(f"[loop] run `{opts.run_id}` cannot be resumed: {refusal} — nothing of this run was rewritten")
    saved_roots = (saved_first or {}).get("repo_roots") or []
    paths.register_roots(saved_roots)                   # saved paths of a run that ran at another root read in this repository
    semantic = semantic_inputs(opts)
    if saved_first is not None:                         # every resume, snapshot or not, before any recovery, rewrite or session
        was = saved_first.get("semantic") or {}
        changed = sorted(k for k in set(was) | set(semantic) if was.get(k) != semantic.get(k))
        if changed:
            raise SystemExit(f"[loop] run `{opts.run_id}` was built against other inputs ({', '.join(changed)} changed); "
                             "start a new run id — nothing of this run was rewritten")
        # before its first snapshot the run's reading holds the reviewed values of the base reading it copied (pinned above)
        if not run.state_file.exists() and run.reading_file.exists() and reviewed_values(run.reading_file) != reviewed_values(Path(opts.reading)):
            raise SystemExit(f"[loop] run `{opts.run_id}` cannot be resumed: its reading {run.reading_file.name} holds reviewed values "
                             "other than those its saved semantic inputs fixed; restore its checkpoint, or start a new run id "
                             "— nothing of this run was rewritten")
    if new:                                              # a new run's contract is its first file
        write_options(run, opts, semantic, saved_roots)
    owner.acquire(opts.run_id, force=opts.force_takeover)
    from .tools import handoff                          # a run that crossed machines resumes only on its own baseline and artifacts
    handoff.check_on_launch(run)
    from .phases import candidate as candidate_phase           # a candidate's commit a stop cut short is completed first
    recovered = candidate_phase.recover(run)
    if recovered:
        print(f"[loop] {recovered}")
    run.pin_hints()                                      # the operator's hints as this run first read them
    training = None
    if opts.label_repair and opts.label_dataset and not opts.label_deferred:   # the training inputs, read from their content, before any state is rewritten
        from .phases import label_check
        training = label_check.training_context(run.dir, [l.id for l in corpus.load_laws(opts.laws)], Path(opts.label_dataset))
    gap_gate(run, opts)
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
    if opts.acquisition_profile:                            # a named standard resolves to a reviewed value before any session
        try:
            step = acquisition.step_parameter(opts.acquisition_profile)
        except acquisition.ProfileError as e:
            raise SystemExit(f"[loop] {e}") from None
        bad = acquisition.review_defects(step, json.loads(Path(opts.reading).read_text(encoding="utf-8")))
        if bad:
            raise SystemExit(f"[loop] acquisition profile `{opts.acquisition_profile}`: " + "; ".join(bad))
    write_options(run, opts, semantic, saved_roots)
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
    ledger = Ledger(run.ledger_file, [l.id for l in laws], opts.plan_attempts)
    concept_ledger = ConceptLedger(run.concept_ledger_file, opts.concept_attempts)
    node_ledger = NodeLedger(run.node_ledger_file, opts.node_attempts)
    run.law_entries = ledger.entries                     # the availability rule reads the live ledger
    gap_ledger = GapLedger.for_run(paths.GAPS_DIR, run)
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
        raise SystemExit("--reviewer_model is required: the concept review is run by a second vendor's model")
    if not opts.aggregate_verifier_model and not opts.dry_run:
        raise SystemExit("--aggregate_verifier_model is required: the aggregate verifier is configured on its own")
    uncapped = [k for k in ("session_budget_usd", "repair_budget_usd", "judge_budget_usd") if getattr(opts, k) is None]
    if (opts.claude_budget_usd is not None or opts.total_budget_usd is not None) and uncapped:
        raise SystemExit(f"--claude_budget_usd and --total_budget_usd need {', '.join('--' + k for k in uncapped)}: "
                         "a Claude session is reserved at its own cap")
    if opts.reviewer_model:
        if session.vendor_of(opts.reviewer_model) == session.vendor_of(opts.model) and not opts.allow_same_vendor:
            raise SystemExit(f"the reviewer ({opts.reviewer_model}) and the planner ({opts.model}) share a vendor; a reviewer is a second "
                             "vendor's model so a blind spot they share is not also the reviewer's — pass --allow_same_vendor to override")
        from .agents import openai_runner
        if session.vendor_of(opts.reviewer_model) == "openai" and not openai_runner.available():
            raise SystemExit("the reviewer is an OpenAI model and OPENAI_API_KEY is not set in the harness's environment")
    check_options(opts)
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
    released, _ = concept_ledger.release([law for law, _ in reopened], ledger.paused())   # as an operator's reopen
    for cid in released:
        print(f"[loop] concept `{cid}` released from its gate-cost hold with the laws reopened by a gap decision")
    status, stop_reason, stop = "", "", ""

    def settle(reason_if_open: str) -> tuple[str, str]:
        if all(e.state in TERMINAL for e in ledger.entries.values()):
            if (opts.label_deferred or opts.label_stage) and dependency_holds(ledger):
                return pause_reason(run, opts, ledger, concept_ledger, node_ledger, by_id)
            return "complete", "every law is accepted, blocked or failed"
        return "incomplete", reason_if_open
    while True:
        if resume_n is not None:
            run.iteration = resume_n; run.iter.mkdir(parents=True, exist_ok=True)
            prog = snap["prog"]; resume_n = None
        else:
            if acceptance_by_law(opts) and block_acceptance_cycles(run, ledger, [Node(d) for d in run.deferred_nodes]):
                persist()
            work = runnable_work(run, opts, ledger, concept_ledger, node_ledger, by_id)
            split_stage = opts.label_deferred or opts.label_stage
            # the bound counts iterations, not launches; a split stage with no work left says what it waits on instead
            if run.iteration >= opts.max_iterations and (any(work.values()) or not split_stage):
                if any(work.values()):
                    stop = "iteration_limit"
                    if work.get("labels"):
                        print(f"[loop] the iteration bound ({opts.max_iterations}) is reached with {len(work['labels'])} law(s) awaiting their "
                              f"label check or repair; launch again with --max_iterations {run.iteration + 1} or more")
                break
            if not any(work.values()):
                if split_stage:
                    status, stop_reason = pause_reason(run, opts, ledger, concept_ledger, node_ledger, by_id)
                    print(f"[loop] {stop_reason}")
                    break
                print("[loop] nothing plannable, nothing to repair, nothing held: every law is accepted, blocked or failed")
                status, stop_reason = settle("nothing plannable, to repair or held, yet a law is open"); break
            run.next_iteration()
            prog = new_progress(run)
            persist()
        ledger.attempt = run.iteration
        try:
            status, stop_reason = _iteration(run, opts, prog, persist, ledger, concept_ledger, node_ledger, gap_ledger,
                                             by_id, laws, defs, onto, reopened, training)
        except (jsonl.DataIntegrityError, BudgetPaused, validate_a.ValidatorFault):
            persist()
            raise
        reopened = []
        if status == "complete" and (opts.label_deferred or opts.label_stage) and dependency_holds(ledger):
            status, stop_reason = pause_reason(run, opts, ledger, concept_ledger, node_ledger, by_id)   # never `complete`
        if status:
            break
    if not status:
        status, stop_reason = settle(f"the iteration bound ({opts.max_iterations}) was reached")
        stop = stop if status != "complete" else ""
    persist()
    feedback_phase.write_status(run, ledger, status, stop_reason, stop=stop)
    print(f"[loop] status: {status} — {stop_reason}")
    return {"status": status, "stop_reason": stop_reason, "stop": stop, "iterations": run.iteration, "laws": ledger.counts(),
            "accepted_nodes": len(run.accepted_nodes), "accepted_concepts": len(run.accepted_concepts), "concepts": concept_ledger.counts()}


def _iteration(run: Run, opts: Options, prog: dict, persist, ledger: Ledger, concept_ledger: ConceptLedger, node_ledger: NodeLedger,
               gap_ledger: GapLedger, by_id: dict, laws: list, defs: list, onto, reopened: list, training=None) -> tuple[str, str]:
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
    if opts.label_stage:                               # a label stage plans and codes nothing new: it checks and repairs
        return label_iteration(run, opts, prog, persist, ledger, concept_ledger, gap_ledger, by_id, defs, onto, training)

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
            for law, entries in by_law.items():               # in the law's plan order, not the order its returns were applied in
                order = ledger.entries[law].nodes
                entries.sort(key=lambda e: order.index(e.node) if e.node in order else len(order))

            def repair_law(entries: list) -> None:
                """A law's nodes one after another, in its plan's order: each repair sees its siblings' most recent
                valid records, and once one outcome returns or blocks the law, its remaining repairs are not run."""
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
        held_now = held_waits(carried, ledger, set(run.all_nodes()), lambda law: set(run.usable_nodes(law)))
        batches, waiting, named_unavailable = plan_batches(plannable, ledger, by_id, opts.plan_batch,
                                                           *reference_records(run, [e.law for e in plannable], by_id), held_now)
        prog["unavailable"] = {law: sorted(r) for law, r in unavailable_roots(ledger, {**held_now, **waiting}).items()}
        for law, refs_ in named_unavailable.items():
            notes.append(f"`{law}` names {refs_}, whose law waits for the operator — planned with its posted text; a plan that "
                         "composes a node of it is held with that law, no attempt counted")
        for law, refs_ in waiting.items():
            notes.append(f"`{law}` names {refs_}, not yet accepted; not planned this iteration, no attempt counted")
        if not batches and not repaired and not carried and label_work(run, opts, ledger):
            notes.append("nothing to plan or code: this iteration checks and repairs laws on their labels")
            return label_iteration(run, opts, prog, persist, ledger, concept_ledger, gap_ledger, by_id, defs, onto, training)
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
        prog["plannable"] = [e.law for e in plannable]; prog["waiting"] = sorted(waiting)
        prog["cut_off_laws"] = cut_off_laws
        prog["stage"] = "planned"; persist()
    plan_dir = Path(prog["plan_dir"])
    unavailable = {law: set(r) for law, r in prog.get("unavailable", {}).items()}   # laws waiting for the operator, with their roots
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
        waiting = set(prog.get("waiting", []))
        for law, why in prog.get("id_defects", {}).items():
            if law in ledger.entries and ledger.entries[law].state not in TERMINAL:
                ledger.return_law(law, ["the plan's records could not be used: " + "; ".join(why[:6])], run.iteration)
                notes.append(f"`{law}`: returned — its plan records are malformed or their ids collide: " + "; ".join(why[:3]))
        for law in prog.get("plannable", []):
            if law in prog.get("id_defects", {}):
                continue
            e = ledger.entries.get(law)
            if e is not None and law not in planned_laws and law not in waiting and e.state in ("open", "returned"):
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
    # the calls between concepts: the accepted records', this iteration's, and those the ledger keeps for a
    # concept set aside with a held concept it calls
    graph: dict[str, set[str]] = {cid: set(ConceptRecord(r).refs()) for cid, r in run.all_concepts().items()}
    for cid, e in concept_ledger.entries.items():
        graph.setdefault(cid, set()).update(e.waiting)
    for c in to_code_concepts:
        graph[c.id] = set(c.refs()) | graph.get(c.id, set())

    def laws_reaching(cid: str, recorded: bool = True) -> list[str]:
        """The laws whose live nodes call `cid`, directly or through other concepts, and with
        `recorded`, the laws the ledger records as users of it or of a concept calling it."""
        callers = {c for c in graph if cid in concept_closure({c}, graph)} | {cid}
        laws = {n.law for n in ok_nodes if callers & concept_closure(concept_deps(n), graph)}
        if recorded:
            laws |= {nodeid.law_of(str(u))[0] for c in callers if c in concept_ledger.entries for u in concept_ledger.entries[c].used_by}
        return sorted(l for l in laws if l in ledger.entries)
    # a concept its gate holds for the operator is not coded again, nor is any concept that calls it, and
    # every law whose live nodes reach it is paused, at every iteration, resume or restart
    held_c = {cid for cid in concept_ledger.entries if concept_ledger.held(cid)}
    if held_c:
        stuck = {c.id for c in to_code_concepts if concept_closure({c.id}, graph) & held_c}
        to_code_concepts = [c for c in to_code_concepts if c.id not in stuck]
        for cid in sorted(held_c):
            _pause_users(ledger, concept_ledger, cid, laws_reaching(cid, recorded=False), f"concept `{cid}` is held for you by its gate "
                         f"({'; '.join(concept_ledger.entries[cid].reasons[:1]) or 'cost or panic'})", to_user, opts.run_id)
        if stuck:
            notes.append(f"concepts not coded, held for the operator or calling one that is: {sorted(stuck)}")
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
        carried_ids = {c.id for c in carried}

        def waits_of(law: str) -> tuple[dict[str, set[str]], list[str]]:
            """The law's composed rules whose law waits for the operator now, and its other defects."""
            vs = by_law_verdicts[law]
            unavail = unavailable_rules([v.node for v in vs if v.kind == "return"], ledger, law_of_id, unavailable, set(run.all_nodes()))
            return unavail, [r for v in vs for r in v.reasons if not ((m := validate_a.UNKNOWN_TARGET.match(r)) and m["rule"] in unavail)]

        def settle(law: str) -> None:
            """The returned law's outcome once no law of the batch can still close under it."""
            vs = by_law_verdicts[law]
            unavail, own = waits_of(law)
            if unavail:
                ledger.return_law(law, own + [f"composes {sorted(unavail)}, whose law waits for the operator: that composition stands, "
                                              "and the law waits for it once the defects above are fixed"], run.iteration)
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
        for law, vs in by_law_verdicts.items():
            if law in ledger.entries and any(v.kind == validate_a.FAIL for v in vs):
                ledger.fail(law, [r for v in vs for r in v.reasons])
                notes.append(f"`{law}`: closed as failed — " + "; ".join(r for v in vs for r in v.reasons[:2]))
        # the batch's returned laws are decided as a whole, in an order independent of the verdicts': the
        # dependency's own route first — a law whose only defects compose nodes of laws that wait for the
        # operator (blocked, failed, or waiting only on such laws, this batch's included) is held, uncharged,
        # with its composition and map, since the validator could not check such a target; a law is charged
        # only once no law of the batch it composes can still close (a hold, or a return spending the last
        # attempt), and a cycle of such laws is charged together
        rest = sorted(law for law, vs in by_law_verdicts.items() if law in ledger.entries
                      and not any(v.kind == validate_a.FAIL for v in vs) and any(v.kind == "return" for v in vs))
        while rest:
            held_now = [law for law in rest if (w := waits_of(law))[0] and not w[1]]
            for law in held_now:
                hold_on_unavailable(ledger, law, waits_of(law)[0], [], law, notes, to_user, opts.run_id)
            if held_now:
                rest = [law for law in rest if law not in held_now]
                continue
            open_laws = set(rest)
            final = [law for law in rest if not all((m := validate_a.UNKNOWN_TARGET.match(r)) and law_of_id(m["rule"]) in open_laws - {law}
                                                    for r in waits_of(law)[1])] or rest
            for law in final:
                settle(law)
            rest = [law for law in rest if law not in final]
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

    # --- concepts: each coded once every concept it calls is accepted; its coding, gate and review are
    # one task, `workers` at once, and its outcome is applied as soon as the task ends
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

    def concept_ready(running: set[str]) -> list[ConceptRecord]:
        """The concepts left to code whose calls are all accepted; with none and nothing running, each
        left waits for what it calls, or is closed when that failed."""
        remaining[:] = [c for c in remaining if c.id not in prog["concepts"]]
        if not remaining or sessions_down or budget_paused:
            return []
        accepted_c = set(run.all_concepts())
        ready = _ready(remaining, lambda c: sorted(c.refs() - set(onto.primitive_ids)), accepted_c)
        if not ready and not running:
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
            persist()
        return ready

    def start_concept(c: ConceptRecord):
        registry = {"nodes": sorted(run.all_nodes()), "concepts": sorted(run.all_concepts())}
        saved = code_phase.last_task(run, c.id) if c.id in concept_ledger.entries and concept_ledger.entries[c.id].cost_failures == 1 else None
        cdir = code_phase.concept_dir(run, c.id)
        return lambda: _item_task(lambda: code_phase.run_code_concept(run, c, reading, registry, saved=saved),
                                  lambda: report_of(run, cdir, reached_concepts(run, set(c.refs()))),
                                  lambda v: review_phase.review_concept(run, c, v.extras, cdir / "review"))

    def apply_concept(c: ConceptRecord, result) -> None:
        nonlocal sessions_down, budget_paused
        v, dep, out, e = result
        if v is None:                                   # paused before its review: undecided, taken up again on resume
            budget_paused = str(e); return
        cdir = code_phase.concept_dir(run, c.id)
        concept_baselines[c.id] = json.loads((cdir / "baseline.json").read_text())
        notes.append(f"concept `{c.id}`: gate {v.verdict}" + (f" — {'; '.join(v.details[:4])}" if v.details else ""))
        if dep.status in review_phase.NOT_JUDGED:  # its report could not be judged: the concept is held, uncharged
            if v.verdict == "OK":
                code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
            sessions_down = sessions_down or dep.status == "unavailable"
            deferred_concepts_now.append(c.raw); prog["concepts"][c.id] = "PAUSED"
            to_user.append(f"concept `{c.id}`: its coder's dependency-defect report could not be judged ({dep.status}: "
                           + "; ".join(dep.reasons)[:300] + "); its record is held — rerun the loop later")
            persist(); return
        if dep.status == "upheld":                    # a concept it calls is defective: it waits for that one's successor
            if v.verdict == "OK":
                code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
            mark_defective(run, opts, dep, cdir, to_user)
            concept_ledger.wait(c.id, [dep.concept], [f"its coder showed `{dep.concept}` computes what its contract excludes (upheld): {dep.line[:200]}"])
            prog["concepts"][c.id] = "WAITING"; deferred_concepts_now.append(c.raw)
            notes.append(f"concept `{c.id}`: waits — the concept it calls, `{dep.concept}`, was found defective")
            persist(); return
        if dep.status != "none":
            notes.append(f"concept `{c.id}`: its dependency-defect report was not admitted ({dep.status}): " + "; ".join(dep.reasons)[:300])
        if v.verdict in (code_phase.SESSION_FAILED, gate.INFRA):
            # an outage keeps the work: the record is held and coded again, nothing is charged
            sessions_down = True
            deferred_concepts_now.append(c.raw); prog["concepts"][c.id] = "PAUSED"
            to_user.append(f"the coding session or the toolchain for concept `{c.id}` did not run ({'; '.join(v.details[:1])}); rerun the loop later")
            persist(); return
        if v.verdict == gate.GATE_TIMEOUT:
            # the evaluation's cost or a Core panic judges nothing of the record: no coding attempt is counted
            kept = gate_evidence(cdir)
            panic = v.extras.get("panic", [])
            if concept_ledger.gate_cost(c.id, bool(panic)):
                why = (f"core_defect: the gate's evaluation of concept `{c.id}` panicked, reproduced in isolation: {panic[0]}" if panic else
                       f"gate_cost: the gate's evaluation of concept `{c.id}` ended on its cost "
                       f"{concept_ledger.entries[c.id].cost_failures} times at the same deadline")
                prog["concepts"][c.id] = v.verdict
                concept_ledger.entries[c.id].reasons = [why]
                _pause_users(ledger, concept_ledger, c.id, laws_reaching(c.id), f"{why}; evidence in {kept}", to_user, opts.run_id)
                _set_aside_callers(concept_ledger, prog, remaining, c.id, graph)
            else:
                deferred_concepts_now.append(c.raw); prog["concepts"][c.id] = "DEFERRED"
                notes.append(f"concept `{c.id}`: gate {v.verdict} on the evaluation's cost — next iteration its saved candidate "
                             f"is gated again (coded again if its context changed) at the same deadline, no attempt counted; evidence in {kept}")
            persist(); return
        if v.verdict == "SCOPE_VIOLATION":
            to_user.append(f"the coding session for concept `{c.id}` changed files outside its concept: {'; '.join(v.details[:2])} — "
                           f"the concept was rolled back; {cdir / 'baseline.json'} holds each library file's digest before the session: "
                           "restore only the files named to those digests before the next iteration, never by a restore of the whole tree")
        if v.verdict != "OK":
            concept_ledger.returned(c.id, [f"gate {v.verdict}"] + v.details[:6], last_task=str(cdir))
            prog["concepts"][c.id] = v.verdict; persist(); return
        if isinstance(e, BudgetPaused):
            # a pause keeps the work: the gated candidate stays, undecided, and the resumed
            # iteration reviews it again without coding it
            budget_paused = str(e); return
        if e is not None:
            code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
            deferred_concepts_now.append(c.raw); prog["concepts"][c.id] = "PAUSED"
            concept_ledger.planned(c.id, concept_ledger.entries[c.id].used_by if c.id in concept_ledger.entries else [], run.iteration)
            sessions_down = True
            to_user.append(f"the review session for concept `{c.id}` never ran ({e}); its record is held — rerun the loop later")
            persist(); return
        if out.status == "deferred":
            code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
            stage = out.defer_stage or "concept_adjudication"
            if stage == "certificate":            # the harness did not run: infrastructure, never counted
                sessions_down = True
                deferred_concepts_now.append(c.raw); prog["concepts"][c.id] = "PAUSED"
                to_user.append(f"the certificate program for concept `{c.id}` did not run ({'; '.join(out.reasons[:1])}); rerun the loop later")
                persist(); return
            prog["concepts"][c.id] = "DEFERRED"
            bound = 2 if stage in JUDGE_STAGES else opts.session_retries + 1
            if concept_ledger.defer_judge(c.id, stage, out.reasons, bound=bound):
                if stage in JUDGE_STAGES:
                    notes.append(f"concept `{c.id}`: closed, judge_protocol_failure — " + "; ".join(out.reasons[:2]))
                    to_user.append(f"concept `{c.id}` failed: its review was left without a valid judgment twice in a row "
                                   "(a diagnostic; the laws that use it are closed by the dependency route)")
                else:
                    _pause_users(ledger, concept_ledger, c.id, laws_reaching(c.id), f"the review of concept `{c.id}` stayed unusable {bound} times",
                                 to_user, opts.run_id)
                    _set_aside_callers(concept_ledger, prog, remaining, c.id, graph)
            else:
                deferred_concepts_now.append(c.raw)
                notes.append(f"concept `{c.id}`: review deferred ({stage}) — " + "; ".join(out.reasons[:2]) + "; coded again next iteration")
            persist(); return
        concept_ledger.clear_judge(c.id)
        review_notes = out.advisories
        if out.status == "returned":
            code_phase.rollback_concept(c.id, concept_baselines[c.id], cdir)
            concept_ledger.returned(c.id, ["review: " + "; ".join(out.reasons)], last_task=str(cdir))
            notes.append(f"concept `{c.id}`: review failed — " + "; ".join(out.reasons[:3]))
            prog["concepts"][c.id] = "REVIEW"; persist(); return
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
    _rolling(remaining, opts.workers, concept_ready, start_concept, apply_concept, lambda: sessions_down or bool(budget_paused),
             lambda c: (code_phase.concept_dir(run, c.id), _files_of("concept", c.id)), scheduled=opts.label_repair)
    if budget_paused:                                     # the iteration stays resumable: what is undecided is taken up again
        persist(); raise BudgetPaused(budget_paused)
    for c in remaining:                                   # left by an outage: held, coded next iteration
        if c.raw not in deferred_concepts_now:
            deferred_concepts_now.append(c.raw); prog["concepts"].setdefault(c.id, "PAUSED")
    propagate_concept_failures(concept_ledger)
    if prog["stage"] in ("validated",):
        prog["stage"] = "concepts"
    run.deferred_concepts = deferred_concepts_now
    persist()
    with lean.library_lock(paths.LIBRARY):
        index_sync.write_index()

    # --- nodes: carried ones first, then this plan's; each coded once every node it composes and every
    # concept it uses is accepted; its coding, gate and review are one task, `workers` at once, and its
    # outcome is applied as soon as the task ends
    accepted_now: list[Node] = []
    baselines: dict[str, dict] = {}
    failed_ids: set[str] = set()
    planned_now = {law for law, e in ledger.entries.items() if e.state == "planned"}
    live = lambda n: n.law in planned_now or prog["nodes"].get(n.id) == "OK"
    to_code = [n for n in carried if live(n)] + [n for n in to_code if n.id not in {c.id for c in carried} and live(n)]
    deferred_now: list[dict] = []
    held_why: dict[str, str] = prog.setdefault("held_why", {})   # a held node's id → the state it is held in, for the feedback

    def hold(n: Node, why: str) -> None:
        deferred_now.append(n.raw); held_why[n.id] = why
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

    def node_ready(running: set[str]) -> list[Node]:
        """The nodes left to code that can be coded now, after deciding those that cannot be coded
        in this iteration; a node waits while a node it composes is undecided (`running` or left)."""
        while True:
            closed = [n for n in remaining_nodes if n.law in ledger.entries and ledger.entries[n.law].state != "planned"]
            for n in closed:                                   # a sibling's return closed the law this iteration: nothing more of it is coded
                failed_ids.add(n.id); prog["nodes"][n.id] = "LAW_CLOSED"
                notes.append(f"`{n.id}`: not coded, its law is `{ledger.entries[n.law].state}` after a sibling was returned this iteration")
            remaining_nodes[:] = [n for n in remaining_nodes if n.id not in {c.id for c in closed}]
            if not remaining_nodes:
                persist(); return []
            if budget_paused:
                return []
            if sessions_down:
                for n in remaining_nodes:                         # the run stops: the node is held, its law keeps its plan
                    hold(n, "not coded: sessions were unavailable this iteration")
                    ledger.hold(n.law, run.iteration); prog["nodes"][n.id] = "PAUSED"
                    ledger.defer(n.law, ["not coded: sessions unavailable this iteration"])
                persist(); return []
            gated = acceptance_by_law(opts)
            ready: list[Node] = []
            for n in remaining_nodes:
                # what a node of this law may compose: the availability rule (`Run.usable_nodes`), and what this
                # iteration accepted of its own law (of any law when a node's acceptance is formal)
                accepted_n = set(run.usable_nodes(n.law)) | {m.id for m in accepted_now if not gated or m.law == n.law}
                deps = {c.get("rule") for c in n.dependencies()}
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
                    causes = dependency_causes(states, repairable)
                    if causes:
                        reasons = [f"uses concept `{cd}`, {s}" + (f": {'; '.join(concept_ledger.entries[cd].reasons[:3])}" if cd in concept_ledger.entries and concept_ledger.entries[cd].reasons else "") for cd, s in states.items()]
                        notes.append(f"`{n.id}`: not coded — " + "; ".join(reasons))
                        ledger.return_for_concepts(n.law, causes, reasons, run.iteration)
                    else:
                        notes.append(f"`{n.id}`: held — uses {unmet_concepts}, pending (under repair or waiting); no attempt counted")
                        hold(n, f"uses {unmet_concepts}, pending"); ledger.hold(n.law, run.iteration)
                    failed_ids.add(n.id); prog["nodes"][n.id] = "HELD"; continue
                unmet = sorted(d for d in deps if d not in accepted_n)
                # a composed node of another law that waits on its law's formal acceptance is not waited for in this
                # iteration: its law is accepted only after the label check, never while this stage runs
                pending_here = [d for d in unmet if (d in running or any(m.id == d for m in remaining_nodes)) and d not in failed_ids
                                and not (gated and law_of_id(d) != n.law)]
                if pending_here:
                    continue                                # submitted once its composed node is decided
                if unmet:
                    unavail = unavailable_rules([n], ledger, law_of_id, unavailable, accepted_n)
                    if unavail and not opts.label_deferred:
                        hold_on_unavailable(ledger, n.law, unavail, [], n.id, notes, to_user, opts.run_id)
                    else:
                        # a split generation stage keeps the law planned with its held node whatever its provider's
                        # state: no work while that provider is not accepted (`held_runnable`), so whether other
                        # laws run or not, the law waits the same way and keeps its plan for the provider's reopening
                        pending_law = sorted({law_of_id(d) for d in unmet if gated and law_of_id(d) != n.law and d in run.all_nodes()})
                        why = (f"composes {sorted(unavail)}, whose law(s) {sorted(set().union(*unavail.values()))} wait for the operator"
                               if unavail else f"composes {unmet}, whose law(s) {pending_law} are not formally accepted yet" if pending_law
                               else f"composes {unmet}, not accepted yet")
                        notes.append(f"`{n.id}`: not coded, {why}; kept for the next iteration, no attempt counted")
                        hold(n, why); ledger.hold(n.law, run.iteration)
                    failed_ids.add(n.id); prog["nodes"][n.id] = "HELD"; continue
                ready.append(n)
            remaining_nodes[:] = [n for n in remaining_nodes if n.id not in prog["nodes"]]
            persist()
            if any(ledger.entries[n.law].state != "planned" for n in ready):
                continue                                      # a law closed in this pass: its nodes are not coded (above)
            if not ready and not running:
                if remaining_nodes:                          # only nodes whose composed node failed this iteration are left
                    for n in remaining_nodes:
                        failed_ids.add(n.id); prog["nodes"][n.id] = "HELD"
                        hold(n, "a node it composes was returned this iteration"); ledger.hold(n.law, run.iteration)
                        notes.append(f"`{n.id}`: not coded, a node it composes was returned this iteration; kept for the next iteration")
                    persist()
            return ready

    # the proposed tier: before any node of the stage starts, the vetted proposals and declarations of
    # every node it may code enter both readings (in the stage's order; idempotent, so a resume repeats
    # it), and every task reads that one reading, which no other task's start changes
    for n in remaining_nodes:
        enter_proposed(run, opts, n)
    reading = Reading(run.reading_file)

    def start_node(n: Node):
        # the notices come from the reading's own record of what this node proposed, given once the node
        # starts, so a resume after a stop re-derives the ones the stop lost and repeats none
        names = {pr.get("name") for pr in n.get("param_proposals", []) if isinstance(pr, dict)}
        base = json.loads(Path(opts.reading).read_text(encoding="utf-8")) if names else {}
        for p in base.get("params", []):
            if p.get("name") in names and unannounced(run, p.get("proposed"), n.id):
                line = f"parameter `{p['name']}` = {p['value']} {p['unit']} proposed by `{n.id}` ({str(p.get('convention', ''))[:80]}); review it in {opts.reading}"
                if line not in to_user:
                    to_user.append(line)
                note = f"`{n.id}` proposed `{p['name']}` = {p['value']} {p['unit']}: {str(p.get('convention', ''))[:120]}"
                if note not in notes:
                    notes.append(note)
        registry = {"nodes": sorted(set(run.all_nodes()) | {m.id for m in accepted_now}), "concepts": sorted(run.all_concepts())}
        saved = code_phase.last_task(run, n.id) if ledger.entries[n.law].cost_failures.get(n.id) == 1 else None
        ndir = code_phase.node_dir(run, n.id)
        return lambda: _item_task(lambda: code_phase.run_code(run, n, reading, registry, saved=saved),
                                  lambda: report_of(run, ndir, reached_concepts(run, concept_deps(n))))

    def apply_node(n: Node, result) -> None:
        nonlocal sessions_down, budget_paused
        v, dep, _out, e = result
        if v is None:                                   # paused before its outcome: undecided, taken up again on resume
            budget_paused = str(e); return
        ndir = code_phase.node_dir(run, n.id)
        baselines[n.id] = json.loads((ndir / "baseline.json").read_text())
        notes.append(f"`{n.id}`: gate {v.verdict}" + (f" — {'; '.join(v.details[:4])}" if v.details else ""))
        if dep.status in review_phase.NOT_JUDGED:  # its report could not be judged: the node is held, its law keeps its budget
            if v.verdict == "OK":
                code_phase.rollback(n.id, baselines[n.id], ndir)
            sessions_down = sessions_down or dep.status == "unavailable"
            hold(n, f"its coder's dependency-defect report was not judged ({dep.status})")
            failed_ids.add(n.id); prog["nodes"][n.id] = "PAUSED"
            to_user.append(f"`{n.id}`: its coder's dependency-defect report could not be judged ({dep.status}: "
                           + "; ".join(dep.reasons)[:300] + "); the node is held — rerun the loop later")
            ledger.defer(n.law, [f"dependency-defect report not judged: {'; '.join(dep.reasons)[:200]}"]); persist(); return
        if dep.status == "upheld":                    # the defect is the concept's: the law returns once per concept version
            if v.verdict == "OK":
                code_phase.rollback(n.id, baselines[n.id], ndir)
            mark_defective(run, opts, dep, ndir, to_user)
            why = [f"`{n.id}`: its coder showed `{dep.concept}` computes what its contract excludes (upheld): {dep.line[:240]} — "
                   "supersede the concept or map the words around it"]
            failed_ids.add(n.id); prog["nodes"][n.id] = "DEPENDENCY"
            node_ledger.failed(n.id, n.law, why, str(ndir), run.iteration)
            ledger.return_for_concepts(n.law, [dep.concept], why, run.iteration)
            persist(); return
        if dep.status != "none":
            notes.append(f"`{n.id}`: its dependency-defect report was not admitted ({dep.status}): " + "; ".join(dep.reasons)[:300])
        if v.verdict in (code_phase.SESSION_FAILED, gate.INFRA):
            # an outage keeps the work: the node is held and coded again, its law keeps its plan and budget
            sessions_down = True
            hold(n, "its coding session or the toolchain did not run")
            failed_ids.add(n.id); prog["nodes"][n.id] = "PAUSED"
            to_user.append(f"the coding session or the toolchain for `{n.id}` did not run ({'; '.join(v.details[:1])}); the law keeps its attempt budget — rerun the loop later")
            ledger.defer(n.law, [f"session or toolchain did not run: {'; '.join(v.details[:1])}"]); persist(); return
        if v.verdict == gate.GATE_TIMEOUT:
            # the evaluation's cost or a Core panic judges nothing of the mapping: no attempt is counted
            failed_ids.add(n.id)
            kept = gate_evidence(ndir)
            panic = v.extras.get("panic", [])
            if ledger.gate_cost(n.law, n.id, bool(panic)):
                why = ([f"core_defect: the gate's evaluation of `{n.id}` panicked, reproduced in isolation: {panic[0]}"] if panic else
                       [f"gate_cost: the gate's evaluation of `{n.id}` ended on its cost {ledger.entries[n.law].cost_failures[n.id]} times "
                        "at the same deadline"]) + v.details[:2]
                prog["nodes"][n.id] = v.verdict
                ledger.block(n.law, [f"decision:{n.law}"], why)
                to_user.append(f"`{n.law}` held for you, no attempt counted: {why[0]}; evidence in {kept} "
                               f"(python -m harness reopen {opts.run_id} --laws {n.law})")
            else:
                hold(n, "its gate's evaluation ended on its cost; its saved candidate is gated again"); prog["nodes"][n.id] = "DEFERRED"
                ledger.defer(n.law, [f"gate_cost: {'; '.join(v.details[:1])}"])
                notes.append(f"`{n.id}`: gate {v.verdict} on the evaluation's cost — next iteration its saved candidate is gated "
                             f"again (coded again if its context changed) at the same deadline, no attempt counted; evidence in {kept}")
            persist(); return
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
            elif v.verdict != "SCOPE_VIOLATION" and node_ledger.budget_left(n.id):
                node_ledger.returned(n.id, n.law, reasons_g, str(ndir), run.iteration); ledger.hold(n.law, run.iteration)
                notes.append(f"`{n.id}`: gate {v.verdict} — sent to a node repair session; no attempt counted")
            else:                                     # a scope violation, or the node's codings are spent: the planner decides
                ledger.return_law(n.law, reasons_g, run.iteration)
            persist(); return
        added = list(v.extras.get("narrowings_added", []))
        if added:
            coder_narrowings[n.id] = added
        accepted_now.append(n); prog["nodes"][n.id] = "OK"; persist()
    _rolling(remaining_nodes, opts.workers, node_ready, start_node, apply_node, lambda: sessions_down or bool(budget_paused),
             lambda n: (code_phase.node_dir(run, n.id), _files_of("node", n.id)), shared=_loop_written(), scheduled=opts.label_repair)
    if budget_paused:                                     # the iteration stays resumable: what is undecided is taken up again
        persist(); raise BudgetPaused(budget_paused)
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
                    d for d in sorted((concept_deps(nodes_now[i]) | {c.get("rule") for c in nodes_now[i].dependencies()}) & set(run.fenced))]) or [why])
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
        for c in n.dependencies():
            line = f"`{n.law}` span {c.get('span')} composes accepted `{c.get('rule')}` (as: {c.get('as')})"
            notes.append(line); to_user.append(line + " — both rules can flag the same episode")
        for c in n.definition_references():            # borrowed words: the node's own elements carry them, for the operator to see
            line = f"`{n.law}` span {c.get('span')} borrows from `{c.get('source')}` the words “{' '.join(str(c.get('quote', '')).split())}”"
            notes.append(line); to_user.append(line + " — its elements carry them; the source's duties are not this rule's")
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
    accept_ready(run, opts, ledger, training, to_user)
    if opts.label_repair and not opts.label_deferred:     # each law awaiting its label repair, in a candidate transaction of its own
        from .phases import label_repair as label_repair_phase
        persist()
        label_repair_phase.run_repairs(run, ledger, training, by_id, defs, onto, gap_ledger, gaps_filed, to_user)
    # --- feedback
    feedback_phase.write_feedback(run, ledger, notes, to_user, gaps_filed, concept_ledger, run.deferred_nodes, coder_narrowings,
                                  held_why=prog.get("held_why"))
    prog["stage"] = "done"; persist()
    kept_concepts = [c for c in concepts_now if c in result.get("kept_concepts", concepts_now)]
    print(f"[loop] iteration {run.iteration}: accepted {len(kept)} node(s), {len(kept_concepts)} concept(s); laws {ledger.counts()}")
    if sessions_down:
        print("[loop] sessions or toolchain unavailable: stopping after this iteration")
        return "infrastructure_failure", "a session or the toolchain could not be launched"
    if not kept and not kept_concepts and not gaps_filed and not concept_ledger.repairable() and not run.deferred_nodes \
            and not run.deferred_concepts \
            and not node_ledger.repairable({e.law for e in ledger.entries.values() if e.state == "planned"}) \
            and not label_work(run, opts, ledger) \
            and all(e.state != "returned" for e in ledger.entries.values()):
        print("[loop] no progress and nothing returned: stopping")
        return ("complete" if all(e.state in TERMINAL for e in ledger.entries.values()) else "incomplete"), "no progress and nothing returned"
    return "", ""


def label_iteration(run: Run, opts: Options, prog: dict, persist, ledger: Ledger, concept_ledger: ConceptLedger, gap_ledger: GapLedger,
                    by_id: dict, defs: list, onto, training) -> tuple[str, str]:
    """An iteration with nothing to plan or code (a `label_stage` launch, or a launch whose only work is
    label work): the laws whose plans are gated are checked and routed (`accept_ready`), then each law
    awaiting its label repair is repaired, and the feedback written. Taken up again on resume: a law
    already routed is not checked again, and a repair resumes from its own record."""
    notes, to_user, gaps_filed = prog["notes"], prog["to_user"], prog["gaps_filed"]
    persist()
    accept_ready(run, opts, ledger, training, to_user)
    persist()
    if opts.label_repair and not opts.label_deferred:
        from .phases import label_repair as label_repair_phase
        label_repair_phase.run_repairs(run, ledger, training, by_id, defs, onto, gap_ledger, gaps_filed, to_user)
    feedback_phase.write_feedback(run, ledger, notes, to_user, gaps_filed, concept_ledger, run.deferred_nodes, prog["coder_narrowings"],
                                  held_why=prog.get("held_why"))
    prog["stage"] = "done"; persist()
    print(f"[loop] iteration {run.iteration}: label checks and repairs only; laws {ledger.counts()}")
    return "", ""


def accept_ready(run: Run, opts: Options, ledger: Ledger, training, to_user: list[str]) -> None:
    """A law is accepted when every node it was planned with is accepted, whichever iteration coded
    it; with `label_repair`, once its label check on those nodes routes it there (`label_route`);
    with `label_deferred`, it is not accepted here: its generated nodes are kept and it is recorded
    `awaiting_labels` (`defer_labels`)."""
    if opts.label_repair:
        if opts.label_deferred:
            defer_labels(run, ledger, to_user)
        else:
            label_route(run, ledger, training, to_user)
        return
    for e in ledger.entries.values():
        if e.state == "planned" and e.nodes and all(i in run.all_nodes() for i in e.nodes):
            ledger.accept(e.law, e.nodes)


#: Where a law's label check routes it (`label_route`), by outcome.
LABEL_ROUTES = {"aligned": "accepted", "unverified": "accepted", "incomplete": "waiting", "failed": "failed",
                "mismatch": "awaiting_label_repair", "undecided": "awaiting_label_repair"}


def label_ready(run: Run, ledger: Ledger) -> dict[str, list[str]]:
    """The planned laws whose every node of the final plan is accepted, each with those nodes; a law
    already awaiting a label repair on the same nodes is not checked again (its repair checks it)."""
    out = {}
    for e in ledger.entries.values():
        st = run.label_states.get(e.law, {})
        if e.state == "planned" and e.nodes and all(i in run.all_nodes() for i in e.nodes) \
                and not (st.get("state") == "awaiting_label_repair" and st.get("nodes") == list(e.nodes)):
            out[e.law] = list(e.nodes)
    return out


def defer_labels(run: Run, ledger: Ledger, to_user: list[str]) -> list[str]:
    """Under `label_deferred`: each law `label_ready` names keeps its plan and its generated nodes and
    is recorded as not accepted, its reason `awaiting_labels` (a wait for a label check, kept apart
    from any other acceptance condition); its earlier label record (its committed check, its repair
    counts and reports) is kept. No recording is read. Returns the laws newly recorded."""
    out = []
    for law, nodes in label_ready(run, ledger).items():
        old = run.label_states.get(law, {})
        if old.get("state") == "awaiting_labels" and old.get("nodes") == nodes:
            continue
        run.label_states[law] = {**old, "state": "awaiting_labels", "reason": "awaiting_labels", "nodes": nodes,
                                 "generated_in": run.iteration}
        out.append(law)
        to_user.append(f"`{law}`: every node of its plan passed the gate; not accepted — it awaits its label check (awaiting_labels)")
    return out


def label_work(run: Run, opts: Options, ledger: Ledger) -> list[str]:
    """The label work a launch with the training recordings can do now: each law to check (its plan's
    nodes all generated, not routed on those nodes, or routed `awaiting_labels`; a law left waiting on
    a fence is not checked again until its plan changes), and each law awaiting its label repair while
    the run's repair budget lasts (a law whose own repairs are spent is work too: it is held for the
    operator). None under `label_deferred` or without `label_repair`."""
    if not opts.label_repair or opts.label_deferred:
        return []
    from .phases import label_repair as label_repair_phase
    out = [law for law, nodes in label_ready(run, ledger).items()
           if not (run.label_states.get(law, {}).get("state") == "waiting" and run.label_states[law].get("nodes") == nodes)]
    budget_left = label_repair_phase.used(run) < opts.label_repair_budget
    for law in label_repair_phase.awaiting(run, ledger):
        spent = int(run.label_states[law].get("repairs", 0)) >= opts.label_repair_attempts
        if (budget_left or spent) and law not in out:
            out.append(law)
    return sorted(out)


def pause_reason(run: Run, opts: Options, ledger: Ledger, concept_ledger: ConceptLedger, node_ledger: NodeLedger,
                 by_id: dict) -> tuple[str, str]:
    """Why a split stage with no work of its own stops, as (status, reason). It hands the run to the
    other stage only when that stage has work, judged by the function that stage judges its own work
    with (`runnable_work`, `label_work`): `awaiting_labels` from the generation stage, `awaiting_generation`
    from the label stage. Otherwise: `paused_budget` when a law awaits a label repair the run's repair
    budget no longer funds (its own repairs not spent); `complete` when every law is terminal;
    `awaiting_operator` when a law is open and nothing but an operator's decision can move it (a gap,
    a blocked or failed law it waits on, a cycle, a label check that cannot complete)."""
    from .phases import label_repair as label_repair_phase
    from .phases.feedback import pending_lists
    if opts.label_stage:
        other = runnable_work(run, replace(opts, label_stage=False, label_deferred=True), ledger, concept_ledger, node_ledger, by_id)
        other.pop("labels", None)
        if any(other.values()):
            return "awaiting_generation", ("the label stage has no label work left; generation has work: "
                                           + "; ".join(f"{k} {v}" for k, v in other.items() if v))
    else:
        labels = label_work(run, replace(opts, label_deferred=False), ledger)
        if labels:
            return "awaiting_labels", f"generation paused: nothing runnable is left without a label check; {len(labels)} law(s) await their labels: {labels}"
    unfunded = [law for law in label_repair_phase.awaiting(run, ledger)
                if int(run.label_states[law].get("repairs", 0)) < opts.label_repair_attempts]
    used = label_repair_phase.used(run)
    if unfunded and used >= opts.label_repair_budget:
        return "paused_budget", (f"the run-wide label repair count is spent: option --label_repair_budget, used {used} of its limit "
                                 f"{opts.label_repair_budget}; affected laws {unfunded} await a label repair it no longer funds "
                                 "(no dollar budget and no law's own --label_repair_attempts funds one): raise --label_repair_budget "
                                 "explicitly and resume")
    holds = dependency_holds(ledger)
    if all(e.state in TERMINAL for e in ledger.entries.values()) and not holds:
        return "complete", "every law is accepted, blocked or failed"
    open_laws = {e.law: run.label_states.get(e.law, {}).get("state") or e.state for e in ledger.entries.values()
                 if e.state not in TERMINAL or e.law in holds}
    waits = dependency_waits(run, ledger)
    return "awaiting_operator", (f"neither stage has work and laws are open, waiting on an operator decision: {open_laws}"
                                 + "".join(f"; `{law}` waits on {', '.join(f'`{d}` ({st})' for d, st in deps)}" for law, deps in waits.items())
                                 + f"; blocked {pending_lists(run, ledger)['blocked']}")


def dependency_waits(run: Run, ledger: Ledger) -> dict[str, list[tuple[str, str]]]:
    """The dependency waits of each open law, for the stop reason, each with its provider's current
    ledger state: the laws not accepted that its persisted records compose (its accepted, generated or
    held nodes), so a chain shows each link, and every law its active label repair waits on that is not accepted
    (`label_repair.wait_states`), including a dependency only the repair's uncommitted candidate
    declared. A report, not a scheduling decision: a provider listed `planned` may still be moved by
    either stage; only a blocked or failed one waits on the operator."""
    from .phases import label_repair as label_repair_phase
    records = {**run.all_nodes(), **{str(d.get("node_id")): d for d in run.deferred_nodes}}
    out: dict[str, list[tuple[str, str]]] = {}

    def add(law: str, dep: str, state: str) -> None:
        if (dep, state) not in out.get(law, []):
            out.setdefault(law, []).append((dep, state))
    for rec in records.values():
        n = Node(rec)
        e = ledger.entries.get(n.law)
        if e is None or e.state in TERMINAL:
            continue
        for c in n.dependencies():
            dep = nodeid.law_of(str(c.get("rule", "")))[0]
            d = ledger.entries.get(dep)
            if dep != n.law and d is not None and d.state != "accepted":
                add(n.law, dep, d.state)
    for e in ledger.entries.values():
        if e.state not in TERMINAL:
            for dep, state in label_repair_phase.wait_states(run, ledger, e.law).items():
                add(e.law, dep, state)
    for law, roots in dependency_holds(ledger).items():
        for dep in roots:
            add(law, dep, ledger.entries[dep].state if dep in ledger.entries else "unknown")
    return out


def dependency_holds(ledger: Ledger) -> dict[str, list[str]]:
    """The laws blocked only because a plan, a node repair or a held node of theirs composes a node of
    a law that waits for the operator (`hold_on_unavailable`), each with those laws: in a split run
    they wait on the operator's decision on their providers, so a stage never reports the run
    `complete` while one remains."""
    return {e.law: list(e.waits_on) for e in ledger.entries.values() if e.state == "blocked" and e.waits_on}


def runnable_work(run: Run, opts: Options, ledger: Ledger, concept_ledger: ConceptLedger, node_ledger: NodeLedger,
                  by_id: dict) -> dict[str, list[str]]:
    """The one judgment of whether a launch has work, at its start and between iterations: kind ↦ ids.
    - `label_stage`: the label work only (`label_work`): it plans and codes nothing new;
    - otherwise the plannable laws, the concept repairs a held node needs, the node repairs of planned
      laws, the held nodes and concepts, and the label work;
    - under `label_deferred` only what can run now: the plannable laws that wait on no law
      (`plan_batches`), and the held nodes that compose no node of another law their law may not use
      (`Run.usable_nodes`) while that law is not accepted (`held_runnable`): a node waiting on a
      pending law costs nothing and is not work, nor is one waiting on a blocked or failed law, which
      only the operator's decision can release."""
    work = {"labels": label_work(run, opts, ledger)}
    if opts.label_stage:
        return work
    held = [Node(d) for d in run.deferred_nodes]
    work["concept_repairs"] = sorted(e.concept for e in concept_ledger.repairable() if any(e.concept in concept_deps(n) for n in held))
    work["node_repairs"] = sorted(e.node for e in node_ledger.repairable({e.law for e in ledger.entries.values() if e.state == "planned"}))
    work["held_concepts"] = sorted(str(d.get("concept_id")) for d in run.deferred_concepts)
    plannable = ledger.plannable()
    if not opts.label_deferred:
        work["plannable"] = sorted(e.law for e in plannable)
        work["held"] = sorted(n.id for n in held)
        return work
    usable_for = lambda law: set(run.usable_nodes(law))
    batches, _waiting, _named = plan_batches(plannable, ledger, by_id, opts.plan_batch,
                                             *reference_records(run, [e.law for e in plannable], by_id),
                                             held_waits(held, ledger, set(), usable_for))
    work["plannable"] = sorted(l.id for b in batches for l in b)
    work["held"] = sorted(n.id for n in held if held_runnable(n, ledger, usable_for))
    return work


def held_runnable(n: Node, ledger: Ledger, usable_for) -> bool:
    """Whether a held node of a planned law can be coded now: none of its compositions names a node of
    another law that its law may not use (`usable_for`, `Run.usable_nodes`) while that other law is not
    accepted, whatever its state (planned: it waits for that law's generation or label check; blocked
    or failed: for the operator). Its own law's siblings, inherited nodes and the nodes of a law outside
    the ledger never make it wait here."""
    if n.law not in ledger.entries or ledger.entries[n.law].state != "planned":
        return False
    ok = usable_for(n.law)
    for c in n.dependencies():
        r = c.get("rule")
        if not isinstance(r, str) or not r or r in ok:
            continue
        dep = nodeid.law_of(r)[0]
        if dep != n.law and dep in ledger.entries and ledger.entries[dep].state != "accepted":
            return False
    return True


def label_state(run: Run, law: str, chk, nodes: list[str], where: Path, candidate: str) -> dict:
    """The routed state of a law's label check: its outcome, coverage, nodes and versions, the files
    of the check and its evidence (relative to the run), and the label repairs the law has used."""
    return {"state": LABEL_ROUTES[chk.outcome], "outcome": chk.outcome, "coverage": chk.coverage, "iteration": run.iteration,
            "nodes": list(nodes), "versions": chk.versions, "candidate": candidate,
            "check": str((where / "laws" / f"{law}.json").relative_to(run.dir)),
            "check_sha": label_check_sha(where / "laws" / f"{law}.json"),
            "evidence": str((where / "evidence" / f"{law}.md").relative_to(run.dir)),
            "repairs": run.label_states.get(law, {}).get("repairs", 0)}


def label_check_sha(f: Path) -> str | None:
    import hashlib
    return hashlib.sha256(f.read_bytes()).hexdigest() if f.is_file() else None


def route_law(run: Run, ledger: Ledger, law: str, chk, nodes: list[str], where: Path, candidate: str, to_user: list[str]) -> str:
    """Route one law by its label check (see `label_route`). Returns the state."""
    st = run.label_states[law] = label_state(run, law, chk, nodes, where, candidate)
    return route_entry(run, ledger, law, chk, nodes, st, to_user)


def route_entry(run: Run, ledger: Ledger, law: str, chk, nodes: list[str], st: dict, to_user: list[str]) -> str:
    """The ledger's part of routing a law by its routed label state `st`: a caller that commits the
    ledger with the state routes its own copy of the ledger before the commit."""
    cov = f"{chk.coverage['matched']}/{chk.coverage['eligible']} plain label(s) match"
    if st["state"] == "accepted":
        ledger.accept(law, list(nodes))
        to_user.append(f"`{law}`: label check {chk.outcome} ({cov}); accepted" + ("" if chk.outcome == "aligned" else ", not reported aligned"))
    elif st["state"] == "waiting":
        ledger.hold(law, run.iteration)
        to_user.append(f"`{law}`: label check incomplete ({'; '.join(chk.notes[:2])}); the law waits, no attempt counted")
    elif st["state"] == "failed":
        counts = {k: v for k, v in chk.summary["counts"].items() if v}
        ledger.block(law, [f"decision:{law}"], [f"label check failed on performance or infrastructure: {counts}"])
        to_user.append(f"`{law}`: label check failed ({counts}): a deadline, crash or unscorable report, not a semantic "
                       f"disagreement; held for you (python -m harness reopen {run.opts.run_id} --laws {law})")
    else:
        ledger.hold(law, run.iteration)
        to_user.append(f"`{law}`: label check mismatch ({cov}); awaiting its label repair, evidence in {st['evidence']}")
    return st["state"]


def label_route(run: Run, ledger: Ledger, training, to_user: list[str]) -> dict[str, str]:
    """Check every law `label_ready` names on a candidate library with no change, each law's whole plan
    together, and route each by its outcome; the check, its evidence and its judgment-call table are
    kept under the iteration (`label/`), the routed state in `run.label_states`:
    - aligned, unverified: the law is accepted (the outcome and the coverage are kept);
    - incomplete: an expected rule is not available (fenced); the law waits, no attempt counted;
    - failed: a deadline, a crash, an incomplete or unscorable report and no mismatch — a question of
      performance or infrastructure, not a semantic return: the law is held for the operator;
    - mismatch: the law awaits its label repair, with the evidence block rendered; nothing is re-planned.
    Nothing of a check reaches the planner's notes. Returns law → routed state."""
    from .phases import candidate as candidate_phase, label_check
    ready = label_ready(run, ledger)
    if not ready:
        return {}
    unavailable = {n: "fenced" for nodes in ready.values() for n in nodes if n in run.fenced}
    known_incomplete = {law: nodes for law, nodes in ready.items() if set(nodes) & set(unavailable)}
    checks, cid = {}, ""
    for law, nodes in known_incomplete.items():          # no monitor runs for a law that cannot be complete
        checks[law] = label_check.unrun_check(law, nodes, unavailable, training)
        label_check.write_check(checks[law], run.iter / "label")
    runnable = {law: nodes for law, nodes in ready.items() if law not in known_incomplete}
    if runnable:
        try:
            with candidate_phase.SCHEDULING.pause(timeout=600):
                txn = candidate_phase.Candidate.open(run, hooks=())
                try:
                    checks.update(label_check.check_in_candidate(txn, training, runnable, unavailable, run.iter / "label"))
                finally:
                    txn.close("the label check of the laws whose plan is gated")
                cid = txn.id
        except (RuntimeError, candidate_phase.NotDrained) as e:      # nothing judged: the laws stay planned and are checked again
            to_user.append(f"the label check of {sorted(runnable)} did not run ({str(e)[:300]}); the laws wait, no attempt counted")
            checks = {law: c for law, c in checks.items() if law in known_incomplete}
    routed = {}
    for law, chk in checks.items():
        routed[law] = route_law(run, ledger, law, chk, ready[law], run.iter / "label", cid, to_user)
    return routed


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


def gate_evidence(task: Path) -> str:
    """Where a gate's evidence stays in its task directory, for the operator."""
    return f"{task} (the candidate under final/, gate_harness.lean, reading.json, build.log, gate_harness.out, toolchain.jsonl)"


def _set_aside_callers(concept_ledger: ConceptLedger, prog: dict, remaining: list, cid: str, graph: dict[str, set[str]]) -> None:
    """The concepts left to code that call `cid`, directly or not, wait for the operator with it: not
    coded or carried, and each keeps in the ledger the held concept it waits on."""
    for a in remaining:
        if a.id != cid and cid in concept_closure({a.id}, graph):
            prog["concepts"][a.id] = "HELD_FOR_OPERATOR"
            concept_ledger.wait(a.id, [cid], [f"calls `{cid}`, held for the operator"])


def _pause_users(ledger: Ledger, concept_ledger: ConceptLedger, cid: str, laws: list[str], why: str, to_user: list[str],
                 run_id: str) -> list[str]:
    """A concept held for the operator (its review stayed unusable within its operational budget, or its
    gate's cost bound or a panic): `laws`, every law reaching it, each once, wait for the operator,
    uncharged, and are recorded on the concept as the laws its hold paused; a law already accepted,
    blocked or failed is neither paused nor recorded. One line names them all with the one command that
    reopens them together. Returns the laws newly paused."""
    new = [l for l in laws if ledger.entries[l].state not in ("blocked", "failed", "accepted")]
    for law in new:
        ledger.block(law, [f"decision:{law}"], [why])
    e = concept_ledger.entries.get(cid)
    if e is not None:
        e.held_laws = sorted(set(e.held_laws) | set(new))
    if new:
        to_user.append(f"{', '.join(f'`{l}`' for l in new)} paused: {why} (python -m harness reopen {run_id} --laws {','.join(new)})")
    return new


def _repair_waits(run: Run, ledger: Ledger, carried: list[Node], rep) -> dict[str, set[str]]:
    """When every defect the validator found in a repair's revised record is a composition of a node
    of a law that waits for the operator (blocked, failed, or held only on such laws): those rules,
    each with its roots; otherwise nothing."""
    accepted = set(run.all_nodes())
    roots = unavailable_roots(ledger, held_waits(carried, ledger, accepted))
    unavail = unavailable_rules(rep.records[:1], ledger, lambda r: nodeid.law_of(r)[0], roots, accepted)
    named = [m["rule"] if (m := validate_a.UNKNOWN_TARGET.match(r)) else None for r in rep.validation]
    return {r: unavail[r] for r in set(named)} if all(r in unavail for r in named) else {}


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
    composing: dict[str, tuple] = {}

    def kept_defect(nid: str, rep, law_of_node: str, last_task: str, refuted: list[str]) -> None:
        kept = rep.validation or [f"record.jsonl could not be read: {rep.message}"]
        why = [f"node repair of `{nid}` kept a defect: {l}" for l in kept[:4]]
        node_ledger.failed(nid, law_of_node, why, last_task, run.iteration); ledger.return_law(law_of_node, refuted + why, run.iteration)
        notes.append(f"`{nid}`: the repaired record kept a defect; the law is returned to the planner — " + "; ".join(kept[:2]))
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
            if dep.status in review_phase.NOT_JUDGED:  # the report could not be judged: the repair is not applied, nothing is charged
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
        elif not rep.accepted and rep.records and rep.validation and all(validate_a.UNKNOWN_TARGET.match(r) for r in rep.validation):
            composing[nid] = (rep, law_of_node, last_task, refuted)    # decided below, with the batch's other repairs
        elif not rep.accepted:
            kept_defect(nid, rep, law_of_node, last_task, refuted)
        else:
            node_ledger.repaired(nid); repaired_nodes.append(rep.records[0])
            notes.append(f"`{nid}`: revised by a repair session; coded again this iteration")
    # a revised record whose only defects compose nodes not accepted is decided once the repairs that can
    # close their laws are applied, in an order independent of the repairs': held, uncharged, when every
    # such node's law waits for the operator (blocked, failed, or waiting only on such laws, by a repair of
    # this pass included); charged as a kept defect once no repair left can close any of them, a cycle
    # of such repairs together
    pending = sorted(composing)
    while pending:
        held_now = {nid: unavail for nid in pending if (unavail := _repair_waits(run, ledger, carried, composing[nid][0]))}
        for nid, unavail in held_now.items():
            _rep, law_of_node, last_task, _refuted = composing[nid]
            node_ledger.failed(nid, law_of_node, [f"composes {sorted(unavail)}, whose law waits for the operator"], last_task, run.iteration)
            hold_on_unavailable(ledger, law_of_node, unavail, [], nid, notes, to_user, opts.run_id)
        if held_now:
            pending = [nid for nid in pending if nid not in held_now]
            continue
        open_laws = {composing[nid][1] for nid in pending}
        final = [nid for nid in pending if not all(nodeid.law_of(m["rule"])[0] in open_laws - {composing[nid][1]}
                                                   for r in composing[nid][0].validation if (m := validate_a.UNKNOWN_TARGET.match(r)))] or pending
        for nid in final:
            kept_defect(nid, *composing[nid])
        pending = [nid for nid in pending if nid not in final]
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
