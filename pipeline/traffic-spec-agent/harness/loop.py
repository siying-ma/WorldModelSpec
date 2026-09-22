"""The loop: plan → validate → code → integrate → feedback, until nothing is plannable or an
iteration accepts nothing new."""
from __future__ import annotations
import json
from dataclasses import asdict
from pathlib import Path
from . import blueprint, corpus, gate, paths
from .blueprint import Node
from .gaps import GapLedger
from .ledger import Ledger
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


def run_loop(opts: Options) -> dict:
    run = Run(opts)
    run.dir.mkdir(parents=True, exist_ok=True)
    (run.dir / "options.json").write_text(json.dumps({**asdict(opts), "laws": str(opts.laws), "ontology": str(opts.ontology), "reading": str(opts.reading)}, indent=1), encoding="utf-8")
    run.load_accepted()
    laws = corpus.load_laws(opts.laws)
    defs = corpus.load_definitions(opts.laws)
    by_id = {l.id: l for l in laws}
    reading = Reading(opts.reading)
    ledger = Ledger(run.ledger_file, [l.id for l in laws], opts.plan_attempts)
    gap_ledger = GapLedger(paths.GAP_LEDGER)
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
        plan_dir = plan_phase.run_plan(run, [by_id[e.law] for e in plannable], defs)
        nodes = blueprint.load(plan_dir / "blueprint.jsonl")
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
        # validate
        verdicts = validate_phase.run_validate(run, plan_dir, by_id)
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
        # code, in dependency order: a node is coded after every node it composes
        accepted_now: list[Node] = []
        baselines: dict[str, dict] = {}
        failed_ids: set[str] = set()
        for n in topological(to_code):
            deps = {c.get("rule") for c in n.compositions()}
            blocked_on = sorted(deps & failed_ids)
            if blocked_on:
                notes.append(f"`{n.id}`: not coded, composes {blocked_on} which did not pass")
                ledger.return_law(n.law, [f"composes {blocked_on}, not accepted this iteration"])
                failed_ids.add(n.id); continue
            v = code_phase.run_code(run, n, reading)
            baselines[n.id] = json.loads((code_phase.node_dir(run, n.id) / "baseline.json").read_text())
            notes.append(f"`{n.id}`: gate {v.verdict}" + (f" — {'; '.join(v.details[:4])}" if v.details else ""))
            if v.verdict == "OK":
                accepted_now.append(n)
            else:
                failed_ids.add(n.id)
                ledger.return_law(n.law, [f"gate {v.verdict}"] + v.details[:6])
        # integrate
        kept, reverted = integrate_phase.run_integrate(run, accepted_now, reading, baselines)
        for r in reverted:
            notes.append(f"reverted at integration: {r}")
            nid = r.split(":")[0]
            law = next((n.law for n in accepted_now if n.id == nid), None)
            if law:
                ledger.return_law(law, [r])
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
        feedback_phase.write_feedback(run, ledger, notes, to_user, gaps_filed)
        ledger.save()
        print(f"[loop] iteration {run.iteration}: accepted {len(kept)} node(s); laws {ledger.counts()}")
        if not kept and not gaps_filed and all(e.state != "returned" for e in ledger.entries.values()):
            print("[loop] no progress and nothing returned: stopping"); break
    ledger.save()
    return {"iterations": run.iteration, "laws": ledger.counts(), "accepted_nodes": len(run.accepted_nodes)}
