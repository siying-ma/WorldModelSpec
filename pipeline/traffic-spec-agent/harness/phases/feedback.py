"""Feedback: AUTO_NOTES.md for the next plan, the run's TO_USER.md for the operator (gap decisions, parameter reviews, questions, laws closed), and summary.json with the run's status."""
from __future__ import annotations
import json
import re
from ..model import nodeid
from ..model.blueprint import Node, concepts_of
from ..store import paths
from ..store.gaps import GapLedger
from ..store.ledger import GATE_COST_BOUND, Ledger
from ..store.state import Run


def gate_costs(ledger: Ledger, concept_ledger=None) -> dict:
    """The gates that judged nothing of a mapping and counted no attempt: those that ended on the
    evaluation's cost, those whose evaluation panicked (a Core defect), and the nodes and concepts
    they hold for the operator."""
    concepts = list(concept_ledger.entries.values()) if concept_ledger is not None else []
    nodes = {n: c for e in ledger.entries.values() for n, c in e.cost_failures.items()}
    panics = sorted({n for e in ledger.entries.values() for n in e.core_panics})
    return {"cost_failures": sum(nodes.values()) + sum(e.cost_failures for e in concepts),
            "core_panics": len(panics) + sum(e.core_panics for e in concepts),
            "held_for_operator": sorted({n for n, c in nodes.items() if c >= GATE_COST_BOUND} | set(panics)
                                        | {e.concept for e in concepts if e.core_panics or e.cost_failures >= GATE_COST_BOUND})}


def write_feedback(run: Run, ledger: Ledger, notes: list[str], to_user: list[str], gaps_filed: list[dict],
                   concept_ledger=None, deferred: list[dict] | None = None,
                   coder_narrowings: dict[str, list[dict]] | None = None, held_why: dict[str, str] | None = None) -> None:
    """`deferred` are the nodes held for a later iteration; each is described by what it waits on
    (the composed nodes and concepts not accepted yet) or else by the state `held_why` records for it
    (a review deferred at a stage, an outage, a gate's cost)."""
    lines = [f"# Feedback from iteration {run.iteration}", ""]
    lines += notes or ["(nothing to report)"]
    lines += ["", "## Laws by state", ""]
    for state, count in sorted(ledger.counts().items()):
        lines.append(f"- {state}: {count}")
    returned = [e for e in ledger.entries.values() if e.state == "returned"]
    if returned:
        lines += ["", "## Returned laws and why", ""]
        for e in returned:
            done = [i for i in e.nodes if i in run.all_nodes()]
            lines.append(f"- `{e.law}` (attempt {e.attempts}): " + "; ".join(e.reasons[:6])
                         + (f" — accepted already and not to be re-planned: {', '.join(done)}" if done else ""))
    failed = [e for e in ledger.entries.values() if e.state == "failed" and e.outcome_iteration == run.iteration]   # its terminal transition
    if failed:
        lines += ["", "## Laws closed as failed this iteration (reopen with `python -m harness reopen`)", ""]
        for e in failed:
            lines.append(f"- `{e.law}`: " + "; ".join(e.reasons[:6]))
        to_user = list(to_user) + [f"`{e.law}` closed as failed: " + "; ".join(e.reasons[:3])[:400]
                                   + f" (python -m harness reopen {run.opts.run_id} --laws {e.law})" for e in failed]
    if concept_ledger is not None and concept_ledger.entries:
        lines += ["", "## Concepts by state", ""]
        for state, count in sorted(concept_ledger.counts().items()):
            lines.append(f"- {state}: {count}")
        returned_c = [e for e in concept_ledger.entries.values() if e.state in ("returned", "failed")]
        if returned_c:
            lines += ["", "## Returned concepts and why", ""]
            for e in returned_c:
                lines.append(f"- `{e.concept}` ({e.state}, attempt {e.attempts}; used by {', '.join(e.used_by) or 'no node'}): " + "; ".join(e.reasons[:6]))
    if deferred:
        lines += ["", "## Nodes held for a later iteration, and why (no attempt counted)", ""]
        for d in deferred:
            rules = {c.get("rule") for c in Node(d).dependencies()} - set(run.all_nodes())
            concepts = ({x for e in d.get("elements", []) for x in e.get("derived", [])}
                        | {x for o in d.get("operationalizations", []) for x in concepts_of(o)})
            waits = sorted(rules | {c for c in concepts if nodeid.is_concept_id(c) and c not in run.all_concepts()})
            why = (held_why or {}).get(d["node_id"])
            lines.append(f"- `{d['node_id']}` " + (f"waits on {', '.join(f'`{w}`' for w in waits)}" if waits else
                                                     f"held: {why}" if why else "waits on the run (paused or stopped before it was coded)"))
    if coder_narrowings:
        lines += ["", "## Readings the coding sessions narrowed (span, and what the formulas state more narrowly than its words)", ""]
        for nid, ns in coder_narrowings.items():
            for x in ns:
                lines.append(f"- `{nid}` {x.get('span')}: {x.get('why')}")
    if gaps_filed:
        lines += ["", "## Gaps filed this iteration", ""]
        for g in gaps_filed:
            lines.append(f"- {g['id']} ({g['kind']}) on `{g.get('span', '')[:80]}` — {', '.join(g.get('law_refs', []))}")
    run.auto_notes.write_text("\n".join(lines) + "\n", encoding="utf-8")
    costs = gate_costs(ledger, concept_ledger)
    if costs["cost_failures"] or costs["core_panics"]:
        to_user = list(to_user) + [f"gates that counted no attempt so far: {costs['cost_failures']} ended on the evaluation's cost, "
                                   f"{costs['core_panics']} panicked (a Core defect); held for you: "
                                   + (", ".join(f"`{i}`" for i in costs["held_for_operator"]) or "none")]
    write_to_user(run, list(dict.fromkeys(l for l in to_user if l)))      # one line per decision, however often it was raised
    summary = {"run": run.opts.run_id, "iteration": run.iteration, "status": "running", "stop_reason": "",
               "laws": ledger.counts(), "accepted_nodes": len(run.accepted_nodes), "accepted_concepts": len(run.accepted_concepts),
               "concepts": concept_ledger.counts() if concept_ledger is not None else {}, "gate_costs": costs,
               "gaps_total": len(gap_rows := GapLedger(paths.GAPS_DIR).rows),
               "gaps_created_by_this_run": sum(1 for g in gap_rows if str(g.get("proposed_in", "")).startswith(run.opts.run_id + "/"))}
    (run.dir / "summary.json").write_text(json.dumps(summary, indent=1, ensure_ascii=False), encoding="utf-8")


def write_status(run: Run, ledger: Ledger, status: str, reason: str, stop: str = "") -> dict:
    """The run's terminal status in `summary.json`: `complete` when every law is terminal,
    `infrastructure_failure` when a session could not be launched, `paused_budget` when a limit on the
    run's spend admits no further request (resumed under the same run id once raised),
    `stale_aggregate` when an aggregate's inputs changed under nodes that claim it (a new run is
    needed), `protocol_failure` when the aggregate selection stayed defective twice, `data_integrity_failure` when an audit file cannot be read as written (named, and left as
    it is), `incomplete` when the iteration bound or a stop without progress left a law open.
    A split stage with no work of its own says why: `awaiting_labels` (the generation stage, while the
    label stage has work), `awaiting_generation` (the label stage, while the generation stage has
    work), `paused_budget` (also when the run's label repair budget no longer funds a law awaiting its
    repair), `awaiting_operator` (neither stage has work and a law is open). `awaiting_operator` also
    when a coding session changed files outside its own and they are not yet restored: no session
    starts until the operator restores them.
    `never_planned` names the laws still open that no plan was ever registered or returned for.
    `stop` is `iteration_limit` when the launch stopped at its iteration bound with work left (the one
    stop after which a launcher starts the next iteration), else empty; `stage` is the stage the last
    iteration reached; `pending` lists the laws by what each waits on; `generation` says, computed
    again now, whether every law's generation is complete (`generation_report`)."""
    f = run.dir / "summary.json"
    f.parent.mkdir(parents=True, exist_ok=True)
    summary = json.loads(f.read_text(encoding="utf-8")) if f.exists() else {"run": run.opts.run_id}
    summary.update({"status": status, "stop_reason": reason, "laws": ledger.counts(), "iteration": run.iteration,
                    "never_planned": sorted(e.law for e in ledger.entries.values() if e.state == "open" and not e.iteration),
                    "stop": stop, "stage": ((run.load_state() or {}).get("prog") or {}).get("stage") if hasattr(run, "load_state") else None,
                    "pending": pending_lists(run, ledger),
                    "generation": generation_report(run, ledger, status, stop)})
    f.write_text(json.dumps(summary, indent=1, ensure_ascii=False), encoding="utf-8")
    return summary


def generation_report(run: Run, ledger: Ledger, status: str = "", stop: str = "") -> dict:
    """Whether the generation of the run's laws (every law of its ledger, from `--laws`) is complete,
    computed again from the run's state each time, an accepted law included: `complete` is true when
    every law is generated (its own nodes and those of every law it reaches usable for building,
    `loop.label_ready`'s conditions), false otherwise, and null, with `reason_if_null`, when it cannot
    be computed (a record or file that cannot be read). The laws are listed by what holds each one:
    a provider it waits on ([node, provider, code]), the planner, the operator (with its tokens),
    a failure, a revoked acceptance; with the composition cycles a validator found, the providers
    whose laws wait for the operator, the gaps, and the launch's stop."""
    if status in ("data_integrity_failure", "stale_aggregate"):   # the state it would be read from is not trusted: never an earlier `true`
        return {"complete": None, "reason_if_null": f"the run stopped on `{status}`: its state cannot be read as it stands"}
    try:
        from ..loop import own_generated, reached_laws, unready
        from ..store.state import Availability
        av = Availability(run, entries=ledger.entries)
        laws = {"generated": [], "generating": [], "waiting_provider": {}, "to_plan": {}, "blocked": {}, "failed": [], "revoked": {}}
        provider_failures, gaps = {}, {}
        for e in ledger.entries.values():
            st = (getattr(run, "label_states", None) or {}).get(e.law, {})
            if st.get("revoked_reason"):
                laws["revoked"][e.law] = st["revoked_reason"].get("reason")
            g = [t for t in e.gaps if not t.startswith("decision:")]
            if g:
                gaps[e.law] = g
            if e.state in ("planned", "accepted") and own_generated(run, ledger, e.law, av) \
                    and all(own_generated(run, ledger, l, av) for l in reached_laws(run, ledger, e.law)):
                laws["generated"].append(e.law)
            elif e.state in ("open", "returned"):
                laws["to_plan"][e.law] = "; ".join(e.reasons[:2]) or e.state
            elif e.state == "blocked":
                laws["blocked"][e.law] = list(e.gaps)
                if e.waits_on:
                    provider_failures[e.law] = list(e.waits_on)
            elif e.state == "failed":
                laws["failed"].append(e.law)
            else:
                waits = [w for w in unready(run, ledger, e.law, av) if w[0] not in e.nodes or w[1] != w[0]]   # another record holds it
                if waits:
                    laws["waiting_provider"][e.law] = waits
                else:
                    laws["generating"].append(e.law)
        complete = len(laws["generated"]) == len(ledger.entries)
        return {"complete": complete, "reason_if_null": None, "laws": laws,
                "cycles": [r for e in ledger.entries.values() for r in e.reasons if r.startswith("composition cycle")],
                "provider_failures": provider_failures, "gaps": gaps,
                "stop": {"budget": status == "paused_budget", "iteration_limit": stop == "iteration_limit",
                         "infrastructure": status in ("infrastructure_failure", "data_integrity_failure")}}
    except Exception as e:                           # a state that cannot be read decides nothing: never an earlier `true`
        return {"complete": None, "reason_if_null": f"{type(e).__name__}: {str(e)[:300]}"}


def pending_lists(run: Run, ledger: Ledger) -> dict[str, list[str]]:
    """The laws not accepted, by what each waits on: a label check (`awaiting_labels`: generated,
    not checked), a label repair, generation (planned with nodes still to code or held), planning
    (open or returned), the operator (blocked) or nothing (failed)."""
    out: dict[str, list[str]] = {k: [] for k in ("awaiting_labels", "awaiting_label_repair", "generating", "to_plan", "blocked", "failed")}
    done = set(run.all_nodes()) if hasattr(run, "all_nodes") else set()
    for e in ledger.entries.values():
        st = (getattr(run, "label_states", None) or {}).get(e.law, {}).get("state")
        if e.state == "planned":
            if st == "awaiting_label_repair":
                out["awaiting_label_repair"].append(e.law)
            elif e.nodes and all(i in done for i in e.nodes):
                out["awaiting_labels"].append(e.law)
            else:
                out["generating"].append(e.law)
        elif e.state in ("open", "returned"):
            out["to_plan"].append(e.law)
        elif e.state in ("blocked", "failed"):
            out[e.state].append(e.law)
    return {k: sorted(v) for k, v in out.items()}


def write_to_user(run: Run, lines: list[str]) -> None:
    """The operator's file keeps every iteration's items under the iteration's own heading, so an
    item raised once (a gap candidate, a composition) is still there when the run ends. Writing an
    iteration again replaces that iteration's section, so a second write never duplicates it."""
    path = run.dir / "TO_USER.md"
    head = f"## Iteration {run.iteration}"
    old = path.read_text(encoding="utf-8") if path.exists() else ""
    sections = [x for x in re.split(r"(?m)^(?=## Iteration \d+$)", old) if x.strip() and x.split("\n", 1)[0] != head]
    if lines:
        sections.append(head + "\n\n" + "\n".join(l if l.startswith("  - ") else f"- {l}" for l in lines) + "\n")   # a sub-item stays one
    path.write_text("\n".join(x.rstrip("\n") + "\n" for x in sections), encoding="utf-8")
