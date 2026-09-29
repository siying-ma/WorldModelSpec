"""The loop: plan → validate → code (concepts first, then the rules that use them) → integrate →
feedback, until nothing is plannable or an iteration accepts nothing new."""
from __future__ import annotations
import json
from dataclasses import asdict
from pathlib import Path
import shutil
from . import aggregates, blueprint, corpus, gate, index_sync, nodeid, ontology, paths, session
from .blueprint import Node, ConceptRecord, concepts_of
from .gaps import GapLedger
from .ledger import Ledger, ConceptLedger
from .phases import plan as plan_phase, validate as validate_phase, code as code_phase, integrate as integrate_phase, feedback as feedback_phase
from .reading import Reading
from .state import Options, Run
from .mapping import MappingIndex


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


def check_library_isolation(run: Run) -> None:
    """The library holds exactly the nodes and concepts this run (or its base run) accepted: a node
    or concept on disk that no accepted record names would be registered and built into this
    run's library without ever passing through its plan; an accepted record whose files are gone
    cannot be composed or called. Either way the run does not start."""
    on_disk_nodes, on_disk_concepts = set(index_sync.node_ids()), set(index_sync.concept_ids())
    stray = sorted((on_disk_nodes - set(run.all_nodes())) | (on_disk_concepts - set(run.all_concepts())))
    missing = sorted((set(run.all_nodes()) - on_disk_nodes) | (set(run.all_concepts()) - on_disk_concepts))
    if stray:
        raise SystemExit(f"[loop] the library holds {len(stray)} node(s)/concept(s) this run did not accept: {stray[:6]}\n"
                         "        archive them first: python -m harness init --fresh --snapshot <the run they belong to>")
    if missing:
        raise SystemExit(f"[loop] accepted node(s)/concept(s) missing from the library: {missing[:6]}\n"
                         "        restore their files (results/<run>/library_snapshot/) or start a new run")


def run_loop(opts: Options) -> dict:
    run = Run(opts)
    run.dir.mkdir(parents=True, exist_ok=True)
    if not run.reading_file.exists():
        shutil.copy2(opts.reading, run.reading_file)      # the operator's base reading; the run adds derived aggregates
    (run.dir / "options.json").write_text(json.dumps({**asdict(opts), "laws": str(opts.laws), "ontology": str(opts.ontology),
                                                      "base_reading": str(opts.reading), "reading": str(run.reading_file)}, indent=1), encoding="utf-8")
    run.load_accepted()
    check_library_isolation(run)
    laws = corpus.load_laws(opts.laws)
    defs = corpus.load_definitions(opts.laws)
    by_id = {l.id: l for l in laws}
    onto = ontology.load(opts.ontology)
    reading = Reading(run.reading_file)
    ledger = Ledger(run.ledger_file, [l.id for l in laws], opts.plan_attempts)
    concept_ledger = ConceptLedger(run.concept_ledger_file, opts.plan_attempts)
    gap_ledger = GapLedger(paths.GAP_LEDGER)
    retired_now = gap_ledger.retire_values(Reading(opts.reading).has)
    if retired_now:
        gap_ledger.save(); print(f"[loop] value gaps retired by the reading: {', '.join(retired_now)}")
    reopened = ledger.reopen_for_gaps(gap_ledger.retired())
    for it in range(opts.max_iterations):
        plannable = ledger.plannable()
        if not plannable:
            print("[loop] nothing plannable: every law is accepted, blocked or failed"); break
        run.next_iteration()
        print(f"[loop] iteration {run.iteration}: {len(plannable)} plannable law(s)")
        notes, to_user, gaps_filed = [], [], []
        if reopened:
            notes.append(f"reopened after gap retirement: {', '.join(reopened)}"); reopened = []
        # plan
        try:
            plan_dir = plan_phase.run_plan(run, [by_id[e.law] for e in plannable], defs)
        except session.SessionUnavailable as e:
            print(f"[loop] the plan session never ran ({e}); iteration {run.iteration} abandoned, ledger unchanged")
            feedback_phase.write_feedback(run, ledger, [f"iteration abandoned: the plan session never ran — {e}"],
                                          ["sessions unavailable (account limit or API error); rerun the loop later"], [])
            ledger.save(); break
        # aggregates the planner derived from the definitions: validated, merged into the run's reading
        agg_ok, agg_errs = aggregates.validate(aggregates.load(plan_dir / "aggregates.jsonl"), defs, onto, Reading(opts.reading))
        if agg_ok:
            derived = aggregates.merge(run.reading_file, agg_ok, opts.run_id, run.iteration)
            reading = Reading(run.reading_file)
            to_user.append("aggregates derived from the definitions this iteration, for review in results/"
                           f"{opts.run_id}/reading.json: " + ", ".join(f"`{r['word']}` ← {r['definition']}" for r in agg_ok))
            notes.append("aggregates accepted: " + ", ".join(f"`{r['word']}` ({len(r['classes'])} members)" for r in agg_ok))
        for e in agg_errs:
            notes.append(f"aggregate rejected — {e}")
        nodes = blueprint.load(plan_dir / "blueprint.jsonl")
        plan_concepts = blueprint.load_concepts(plan_dir / "blueprint.jsonl")
        planned_laws = {}
        for n in nodes:
            planned_laws.setdefault(n.get("law_refs", ["?"])[0], []).append(n.id)
        for law, ids in planned_laws.items():
            if law in ledger.entries:
                ledger.mark_planned(law, ids, run.iteration)
        for e in plannable:
            if e.law not in planned_laws:
                notes.append(f"`{e.law}` was plannable and the plan produced no node for it")
                ledger.entries[e.law].state = "open"
        # validate: concepts and nodes
        verdicts, concept_verdicts = validate_phase.run_validate(run, plan_dir, by_id, reading, defs)
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
            if any(v.kind == "block" for v in vs):
                ids = []
                for v in vs:
                    for g in v.gaps:
                        span_text = v.node.spans().get(g.get("span"), {}).get("text", "")
                        gid = gap_ledger.add({**g, "span_text": span_text, "law_refs": [law], "node_id": v.node.id}, opts.run_id, run.iteration)
                        ids.append(gid); gaps_filed.append({**g, "id": gid, "span": span_text, "law_refs": [law]})
                ledger.block(law, ids, [r for v in vs for r in v.reasons])
                to_user.append(f"gap(s) {', '.join(ids)} filed for `{law}` await a decision in gaps/ledger.jsonl")
            elif any(v.kind == "judge" for v in vs):
                ledger.judge_failed(law, [r for v in vs for r in v.reasons])
            elif any(v.kind == "return" for v in vs):
                ledger.return_law(law, [r for v in vs for r in v.reasons])
            else:
                to_code += [v.node for v in vs]
        gap_ledger.save()
        # code the concepts first, in reference order; each is gated, then reviewed (blind read + judge)
        concepts_now: list[str] = []
        concept_baselines: dict[str, dict] = {}
        failed_concepts: set[str] = set()
        sessions_down = False
        for c in concept_order(to_code_concepts):
            if sessions_down:
                continue
            unmet = sorted(r for r in c.refs() if r not in run.all_concepts() and (r in failed_concepts or r not in {x.id for x in to_code_concepts}))
            if unmet:
                concept_ledger.returned(c.id, [f"references {unmet}, not accepted"]); failed_concepts.add(c.id)
                notes.append(f"concept `{c.id}`: not coded, references {unmet} which is not accepted"); continue
            v = code_phase.run_code_concept(run, c, reading)
            concept_baselines[c.id] = json.loads((code_phase.concept_dir(run, c.id) / "baseline.json").read_text())
            notes.append(f"concept `{c.id}`: gate {v.verdict}" + (f" — {'; '.join(v.details[:4])}" if v.details else ""))
            if v.verdict == code_phase.SESSION_FAILED:
                sessions_down = True
                to_user.append(f"the coding session for concept `{c.id}` never ran ({'; '.join(v.details[:1])}); rerun the loop later")
                continue
            if v.verdict != "OK":
                concept_ledger.returned(c.id, [f"gate {v.verdict}"] + v.details[:6]); failed_concepts.add(c.id); continue
            ok, reasons, judge = validate_phase.review_concept(run, c, v.extras, code_phase.concept_dir(run, c.id) / "review", nodes, defs)
            if not ok:
                code_phase.rollback_concept(c.id, concept_baselines[c.id])
                concept_ledger.returned(c.id, ["review: " + "; ".join(reasons)]); failed_concepts.add(c.id)
                notes.append(f"concept `{c.id}`: review failed — " + "; ".join(reasons[:3])); continue
            record = {**c.raw, "reads": v.extras.get("reads", []), "refs": v.extras.get("refs", sorted(c.refs())),
                      "canonical_body": v.extras.get("canonical_body"), "body_json": v.extras.get("body_json"),
                      "accepted_in": f"{opts.run_id}/iter-{run.iteration:03d}"}
            if v.extras.get("residues_added"):
                record["residues"] = list(c.get("residues", [])) + [{"span": "code", "why": w} for w in v.extras["residues_added"]]
            run.accepted_concepts[c.id] = record
            concepts_now.append(c.id)
            concept_ledger.accepted(c.id)
            if c.get("supersedes"):
                to_user.append(f"concept `{c.id}` supersedes `{c.get('supersedes')}`; rules using the old one are listed for migration in AUTO_NOTES.md")
                users = [nid for nid, raw in run.all_nodes().items() if c.get("supersedes") in concept_deps(Node(raw))]
                notes.append(f"migration candidates for `{c.get('supersedes')}` → `{c.id}`: {users or 'none'}")
        run.save_accepted()
        index_sync.write_index()
        # code the nodes, in dependency order: a node is coded after every node it composes and every concept it uses
        accepted_now: list[Node] = []
        baselines: dict[str, dict] = {}
        failed_ids: set[str] = set()
        # nodes deferred in an earlier iteration (their composed nodes were not accepted yet) are coded now, not re-planned
        carried = [Node(d) for d in run.load_deferred() if d["node_id"] not in {x.id for x in to_code} and d["node_id"] not in run.accepted_nodes]
        to_code = to_code + carried
        deferred_now: list[dict] = []
        law_of = {n.id: n.law for n in nodes}
        law_of.update({nid: Node(raw).law for nid, raw in run.accepted_nodes.items()})
        law_of.update({n.id: n.law for n in carried})
        codable = {n.id for n in to_code}
        for n in topological(to_code):
            if sessions_down:
                ledger.defer(n.law, ["not coded: sessions unavailable this iteration"]); continue
            # every composed node must be accepted already or coded (and passed) before this one
            deps = {c.get("rule") for c in n.compositions()}
            unmet = sorted(d for d in deps if d not in run.all_nodes() and (d not in codable or d in failed_ids))
            unmet_concepts = sorted(cd for cd in concept_deps(n) if cd not in run.all_concepts())
            if unmet_concepts:
                if any(concept_ledger.entries.get(cd) and concept_ledger.entries[cd].state == "failed" for cd in unmet_concepts):
                    notes.append(f"`{n.id}`: uses {unmet_concepts}, a concept closed as failed — the law returns to the plan")
                    ledger.return_law(n.law, [f"uses concept(s) {unmet_concepts}, closed as failed"])
                else:
                    notes.append(f"`{n.id}`: not coded, uses {unmet_concepts} which is not accepted yet; kept for the next iteration, no attempt counted")
                    deferred_now.append(n.raw)
                    ledger.mark_planned(n.law, [x.id for x in to_code if x.law == n.law], run.iteration)
                failed_ids.add(n.id); continue
            if unmet:
                dead = sorted(d for d in unmet if ledger.entries.get(law_of.get(d, ""), None) and ledger.entries[law_of[d]].state == "failed")
                if dead:
                    notes.append(f"`{n.id}`: composes {dead}, whose law is closed as failed — this law cannot be formalized")
                    ledger.fail(n.law, [f"composes {dead}, closed as failed"])
                else:
                    notes.append(f"`{n.id}`: not coded, composes {unmet} which is not accepted yet; kept for the next iteration, no attempt counted")
                    deferred_now.append(n.raw)
                    ledger.mark_planned(n.law, [x.id for x in to_code if x.law == n.law], run.iteration)
                failed_ids.add(n.id); continue
            v = code_phase.run_code(run, n, reading)
            baselines[n.id] = json.loads((code_phase.node_dir(run, n.id) / "baseline.json").read_text())
            notes.append(f"`{n.id}`: gate {v.verdict}" + (f" — {'; '.join(v.details[:4])}" if v.details else ""))
            if v.verdict == "OK":
                accepted_now.append(n)
            elif v.verdict == code_phase.SESSION_FAILED:
                sessions_down = True
                to_user.append(f"the coding session for `{n.id}` never ran ({'; '.join(v.details[:1])}); the law keeps its attempt budget — rerun the loop later")
                ledger.defer(n.law, [f"session never ran: {'; '.join(v.details[:1])}"])
            else:
                failed_ids.add(n.id)
                ledger.return_law(n.law, [f"gate {v.verdict}"] + v.details[:6])
        run.save_deferred(deferred_now)
        # integrate
        kept, reverted = integrate_phase.run_integrate(run, accepted_now, reading, baselines, concepts_now, concept_baselines)
        for r in reverted:
            notes.append(f"reverted at integration: {r}")
            nid = r.split(":")[0]
            law = next((n.law for n in accepted_now if n.id == nid), None)
            if law:
                ledger.return_law(law, [r])
            elif nid in concept_ledger.entries:
                concept_ledger.returned(nid, [r])
        index = MappingIndex(run.mapping_file)
        for n in accepted_now:
            if n.id in kept:
                run.accepted_nodes[n.id] = n.raw
                for e in n.get("elements", []):
                    t = n.spans().get(e.get("span"), {}).get("text", "")
                    index.record(t, set(e.get("atoms", [])) | set(e.get("derived", [])), n.id)
        index.save(); run.save_accepted()
        for law, ids in planned_laws.items():
            if law in ledger.entries and ids and all(i in run.accepted_nodes for i in ids):
                ledger.accept(law, ids)
        # feedback
        missing_params = sorted({p for n in nodes for p in Node(n.raw).params() if not reading.has(p)})
        if missing_params:
            to_user.append(f"parameters the reading lacks: {', '.join(missing_params)} (readings/)")
        feedback_phase.write_feedback(run, ledger, notes, to_user, gaps_filed, concept_ledger)
        ledger.save(); concept_ledger.save()
        print(f"[loop] iteration {run.iteration}: accepted {len(kept)} node(s), {len(concepts_now)} concept(s); laws {ledger.counts()}")
        if sessions_down:
            print("[loop] sessions unavailable: stopping after this iteration"); break
        if not kept and not concepts_now and not gaps_filed and all(e.state != "returned" for e in ledger.entries.values()):
            print("[loop] no progress and nothing returned: stopping"); break
    ledger.save(); concept_ledger.save()
    return {"iterations": run.iteration, "laws": ledger.counts(), "accepted_nodes": len(run.accepted_nodes),
            "accepted_concepts": len(run.accepted_concepts), "concepts": concept_ledger.counts()}
