"""Feedback: AUTO_NOTES.md for the next plan, the run's TO_USER.md for the operator (gap decisions, parameter reviews, questions, laws closed) and its list of observable readings, and summary.json with the run's status."""
from __future__ import annotations
import json
import re
from pathlib import Path
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


def scope_report(run: Run, ledger: Ledger) -> dict | str:
    """The laws the run's active stage is limited to: "all", or `{laws: n, of: N, out_of_scope: {law:
    state}}` with n the laws of the ledger in its scope, N the ledger's laws, and each law out of it
    with its label state or else its ledger state."""
    from ..loop import label_scope
    scope = label_scope(run)
    if scope is None:
        return "all"
    states = getattr(run, "label_states", None) or {}
    return {"laws": sum(1 for law in ledger.entries if law in scope), "of": len(ledger.entries),
            "out_of_scope": {e.law: states.get(e.law, {}).get("state") or e.state for e in ledger.entries.values() if e.law not in scope}}


def scope_line(scope: dict) -> str:
    """The operator's line for a stage limited to a scope: what it covers, and what it leaves out."""
    out = ", ".join(f"`{law}` ({st})" for law, st in sorted(scope["out_of_scope"].items())) or "none"
    return (f"scope {scope['laws']}/{scope['of']}: this stage checks, repairs and accepts only the laws in its scope; "
            f"nothing it reports is complete for the run's other laws — out of scope: {out}")


def candidate_link_lines(run: Run) -> list[str]:
    """The operator's lines for the live gaps that may stand for a pending gap carried over from an
    earlier run without having been filed for it (`deferred_gaps.candidate_links`): a report, which
    links nothing. A view that cannot be read says so and stops nothing."""
    from ..store import deferred_gaps
    try:
        gl = GapLedger.for_run(paths.GAPS_DIR, run)
        pairs = deferred_gaps.candidate_links(gl.live_rows() + gl.archived_rows(), deferred_gaps.fixed(run.opts))
    except Exception as e:                           # a report never stops the run
        return [f"candidate links to carried-over gaps cannot be computed: {type(e).__name__}: {str(e)[:300]}"]
    return [f"gap {r['id']} ({r['kind']}, `{r['occurrence']}`) and the carried-over pending gap {deferred_gaps.identity(d)} "
            f"(`{d['occurrence']}`) are of one kind on the same law text, one span within the other: a candidate link for you to "
            "confirm or refuse; nothing is merged" for r, d in pairs]


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
    to_user = list(to_user) + candidate_link_lines(run)
    scope = scope_report(run, ledger)
    if scope != "all":
        to_user = list(to_user) + [scope_line(scope)]
    write_to_user(run, list(dict.fromkeys(l for l in to_user if l)))      # one line per decision, however often it was raised
    from .observable_view import write_current_view as write_observable_view
    write_observable_view(run)                                            # the operator's list of observable readings, rebuilt with the report
    summary = {"run": run.opts.run_id, "iteration": run.iteration, "status": "running", "stop_reason": "",
               "laws": ledger.counts(), "accepted_nodes": len(run.accepted_nodes), "accepted_concepts": len(run.accepted_concepts),
               "concepts": concept_ledger.counts() if concept_ledger is not None else {}, "gate_costs": costs,
               "gaps_total": len(gap_rows := GapLedger(paths.GAPS_DIR).rows),
               "gaps_created_by_this_run": sum(1 for g in gap_rows if str(g.get("proposed_in", "")).startswith(run.opts.run_id + "/"))}
    from . import behaviour_review                   # the review's standing, counted apart from the label acceptances
    if hasattr(run, "dir") and behaviour_review.required(run):
        summary["review"] = behaviour_review.counts(run, ledger)
    if scope != "all":
        summary["scope"] = scope
    (run.dir / "summary.json").write_text(json.dumps(summary, indent=1, ensure_ascii=False), encoding="utf-8")


def write_status(run: Run, ledger: Ledger, status: str, reason: str, stop: str = "") -> dict:
    """The run's terminal status in `summary.json`: `complete` when every law is terminal,
    `infrastructure_failure` when a session could not be launched, `paused_budget` when a limit on the
    run's spend admits no further request (resumed under the same run id once raised),
    `paused_defect` when one gate failure was repeated across laws in an iteration (resumed under the same
    run id once the operator has looked),
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
    again now, whether every law's generation is complete (`generation_report`). A run whose active
    stage is limited to a scope (`scope_report`) has `scope` with `n/N` and the laws out of it, and
    its reason begins `scope n/N`; its `complete` is the scope's (`complete_for: "scope"`), never the run's.
    A run under `review: required` adds `review`, its laws by review standing (`behaviour_review.counts`):
    strictly reviewed, under a review condition, permission laws generated and not reviewed, awaiting
    review, a finding to repair, held, and a test stand-in's acceptances apart. `awaiting_review` is a
    status of a stage with no work of its own while the review stage has work. `spend` is the run's
    spend with money and the Claude API equivalent apart (`spend_report`).
    This is the one point where a launch's status is said: `status` names what ended the launch (the
    launcher's exit status follows it), and `stops` lists every stop still active, that one included,
    each from its own record with its own clearing condition (`active_stops`); the operator's file
    `TO_USER.md` opens with the same list. Returns the summary."""
    f = run.dir / "summary.json"
    f.parent.mkdir(parents=True, exist_ok=True)
    summary = json.loads(f.read_text(encoding="utf-8")) if f.exists() else {"run": run.opts.run_id}
    summary.update({"status": status, "stop_reason": reason, "laws": ledger.counts(), "iteration": run.iteration,
                    "never_planned": sorted(e.law for e in ledger.entries.values() if e.state == "open" and not e.iteration),
                    "stop": stop, "stage": ((run.load_state() or {}).get("prog") or {}).get("stage") if hasattr(run, "load_state") else None,
                    "pending": pending_lists(run, ledger),
                    "generation": generation_report(run, ledger, status, stop)})
    summary["spend"] = spend_report(run.dir / "usage.jsonl")
    try:
        scope = scope_report(run, ledger)
    except Exception as e:                           # a stage record that cannot be read: no reading of the scope, never "all"
        scope = {"unreadable": f"{type(e).__name__}: {str(e)[:300]}"}
    if scope != "all":
        summary["scope"] = scope
        if "laws" in scope:
            if status == "complete":
                summary["complete_for"] = "scope"
            if not reason.startswith(f"scope {scope['laws']}/{scope['of']}"):
                summary["stop_reason"] = f"scope {scope['laws']}/{scope['of']}: " + reason + (
                    " — complete for the scope, not for the run" if status == "complete" else "")
    summary["stops"] = active_stops(run, status, reason)
    f.write_text(json.dumps(summary, indent=1, ensure_ascii=False), encoding="utf-8")
    write_stops_section(run, summary["stops"])
    return summary


def active_stops(run: Run, status: str = "", reason: str = "") -> list[dict]:
    """Every stop of the run active now, each `{id, kind, cause, clears}`, read from its own record:
    - `paused_defect`: a pause for one gate failure repeated across laws that no later launch answered
      (`shared_failures.unanswered`); a resume answers it, nothing else does;
    - `budget`: the limit this launch paused on (`status` `paused_budget`, its `reason`), else every
      limit the run's spend has reached; only raising the named limit lifts it;
    - `wrong_model`, `wrong_channel`, `bound_violated`, `response_missing`: a stop row of the run's
      usage file without its acknowledgement; every real send of the run is refused until the operator
      acknowledges that stop, and that acknowledgement clears it alone;
    - `unknown_execution`: a review call whose execution is not known; `reconcile` of its law settles
      the property call, a settlement row settles a request; never an acknowledgement;
    - `integrity`: this launch's damaged audit file (`status` `data_integrity_failure`), or the review's
      kept evidence lost or changed; only restoring it clears it.
    A record that cannot be read is itself listed as an `integrity` stop, never read as no stop."""
    from types import SimpleNamespace
    from ..store import budget, jsonl
    from ..store.shared_failures import PAUSES, unanswered
    from . import behaviour_review
    rid = run.opts.run_id
    out: list[dict] = []

    def unreadable(what: str, e: Exception) -> None:
        out.append({"id": f"integrity-{what}", "kind": "integrity", "cause": f"{what} cannot be read: {str(e)[:300]}",
                    "clears": f"restore {what} from the run's checkpoint (it is left as it is), then resume"})
    try:
        for n, row in unanswered(run.dir):
            out.append({"id": f"defect-{n}", "kind": "paused_defect",
                        "cause": (f"iteration {row.get('iteration')}: one gate failure repeated across laws: "
                                  + "; ".join(f"`{x}`" for x in row.get("signatures") or []))[:600] + f" (raw lines, nodes and spend in {PAUSES})",
                        "clears": "find its cause, then resume the run with the same command (these signatures never pause it again); "
                                  "no acknowledgement of another stop answers it"})
    except (OSError, jsonl.DataIntegrityError) as e:
        unreadable(PAUSES, e)
    try:
        rows = jsonl.read_strict(run.dir / "usage.jsonl")
        limits = [] if status == "paused_budget" else budget.spent_limits(run.dir / "usage.jsonl", run.opts)
    except (OSError, jsonl.DataIntegrityError) as e:
        rows, limits = [], []
        unreadable("usage.jsonl", e)
    if status == "paused_budget" or limits:
        out.append({"id": "budget", "kind": "budget", "cause": reason if status == "paused_budget" else "; ".join(limits),
                    "clears": "raise the limit its cause names, explicitly, then resume; no acknowledgement or resume alone raises one"})
    for x in budget.open_stops(rows):
        out.append({"id": x["stop"], "kind": x.get("reason"), "cause": (f"`{x['law']}`: " if x.get("law") else "") + str(x.get("why", ""))[:600],
                    "clears": f"python -m harness review_decide {rid} - acknowledge --stop {x['stop']} --record <record.json> "
                              "(confirms this stop only)"})
    states = getattr(run, "review_states", None) or {}
    if not states:
        try:
            states = (jsonl.read_json(run.dir / "state.json", None) or {}).get("review_states") or {}
        except (OSError, jsonl.DataIntegrityError, ValueError) as e:
            unreadable("state.json", e)
    for c in behaviour_review.unknown_calls(states, rows):
        out.append({"id": f"unknown-{c['law']}" if "law" in c else f"unknown-{c['request']}", "kind": "unknown_execution", "cause": c["text"],
                    "clears": f"python -m harness review_decide {rid} {c['law']} reconcile --record <record.json>" if "law" in c
                    else f"a settlement of request {c['request']} in usage.jsonl; it is never sent again"})
    if status == "data_integrity_failure":
        out.append({"id": "integrity", "kind": "integrity", "cause": reason,
                    "clears": "restore the named file from the run's checkpoint (it is left as it is), then resume"})
    if states:
        try:
            lost = behaviour_review.integrity_defects(SimpleNamespace(dir=run.dir, review_states=states))
        except (OSError, jsonl.DataIntegrityError) as e:
            lost = [f"the review's kept evidence cannot be read: {str(e)[:300]}"]
        if lost:
            out.append({"id": "integrity-evidence", "kind": "integrity", "cause": "; ".join(lost)[:900],
                        "clears": "restore the kept evidence (a real recovery); no acknowledgement passes it"})
    return out


#: The heading of the section that opens the operator's file with the run's active stops.
STOPS_HEAD = "## Active stops"


def one_line(text) -> str:
    return " ".join(str(text).split())


def write_stops_section(run: Run, stops: list[dict]) -> None:
    """Open the operator's file with the active stops (`active_stops`), replacing the list written
    before; with none, the section is removed. Every other section is kept as written."""
    path = run.dir / "TO_USER.md"
    old = path.read_text(encoding="utf-8") if path.exists() else ""
    rest = "".join(x for x in re.split(r"(?m)^(?=## )", old) if not x.startswith(STOPS_HEAD + "\n"))
    if not stops and rest == old:
        return
    head = (STOPS_HEAD + "\n\nEach stop is cleared only by its own condition; clearing one leaves the others standing.\n\n"
            + "".join(f"- `{x['id']}` ({x['kind']}): {one_line(x['cause'])} — cleared by: {one_line(x['clears'])}\n" for x in stops)
            + "\n") if stops else ""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(head + rest, encoding="utf-8")


def spend_report(usage_file: Path) -> dict:
    """The run's spend from its one usage file, money apart from the API equivalent, in USD: `cash`
    (the OpenAI calls at the operator's price table, and the Claude sessions billed to an API key),
    `claude_api_equivalent` (the cost the Claude CLI reports for sessions of an account login: no
    money spent per call), `claude_billing_not_recorded` (Claude rows that do not say how they were
    paid) and `unsettled_requests` (requests whose cost is not known, each counted above at its
    reservation, never as zero). Each request is counted once, as `budget.fold` counts it."""
    from ..store import budget, jsonl
    try:
        rows = jsonl.read_strict(usage_file)
    except jsonl.DataIntegrityError as e:
        return {"unreadable": str(e)[:300]}
    billing = {r["request"]: r["billing"] for r in rows if r.get("request") and r.get("billing")}
    groups: dict[str, list[dict]] = {}
    for r in rows:
        if r.get("state") in budget.GATE_STATES:
            continue
        if (r.get("vendor") or "openai") == "openai":
            key = "openai"
        else:
            key = {"api_key": "claude_api_key", "account": "claude_account"}.get(billing.get(r.get("request")) or r.get("billing"),
                                                                                 "claude_not_recorded")
        groups.setdefault(key, []).append(r)
    spent = {k: sum(budget.fold(v)[0].values()) for k, v in groups.items()}
    return {"cash": {"openai": round(spent.get("openai", 0.0), 4), "claude_api_key": round(spent.get("claude_api_key", 0.0), 4)},
            "claude_api_equivalent": round(spent.get("claude_account", 0.0), 4),
            "claude_billing_not_recorded": round(spent.get("claude_not_recorded", 0.0), 4),
            "unsettled_requests": len(budget.fold(rows)[1])}


def generation_report(run: Run, ledger: Ledger, status: str = "", stop: str = "") -> dict:
    """Whether the generation of the run's laws (every law of its ledger, from `--laws`) is complete,
    computed again from the run's state each time, an accepted law included: `complete` is true when
    every law is generated (its own nodes and those of every law it reaches usable for building,
    `loop.label_ready`'s conditions), false otherwise, and null, with `reason_if_null`, when it cannot
    be computed (a record or file that cannot be read). The laws are listed by what holds each one:
    a provider it waits on ([node, provider, code]), the planner, the operator (with its tokens),
    a failure, a revoked acceptance; a blocked law some of whose nodes are accepted is also listed as
    `partial`, with those nodes (partially generated, not complete); with the composition cycles a validator found, the providers
    whose laws wait for the operator, the gaps, and the launch's stop; and `scope`, "all" or `{laws: n,
    of: N}` for a stage limited to n of the run's N laws (`complete` stays the whole run's)."""
    if status in ("data_integrity_failure", "stale_aggregate"):   # the state it would be read from is not trusted: never an earlier `true`
        return {"complete": None, "reason_if_null": f"the run stopped on `{status}`: its state cannot be read as it stands"}
    try:
        from ..loop import own_generated, reached_laws, unready
        from ..store.state import Availability
        av = Availability(run, entries=ledger.entries)
        laws = {"generated": [], "generating": [], "waiting_provider": {}, "to_plan": {}, "blocked": {}, "partial": {}, "failed": [], "revoked": {}}
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
                kept = [n for n in e.nodes if n in run.all_nodes()]
                if kept:
                    laws["partial"][e.law] = kept
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
        scope = scope_report(run, ledger)
        return {"complete": complete, "reason_if_null": None, "laws": laws,
                "scope": scope if scope == "all" else {"laws": scope["laws"], "of": scope["of"]},
                "cycles": [r for e in ledger.entries.values() for r in e.reasons if r.startswith("composition cycle")],
                "provider_failures": provider_failures, "gaps": gaps,
                "stop": {"budget": status == "paused_budget", "iteration_limit": stop == "iteration_limit",
                         "infrastructure": status in ("infrastructure_failure", "data_integrity_failure")}}
    except Exception as e:                           # a state that cannot be read decides nothing: never an earlier `true`
        return {"complete": None, "reason_if_null": f"{type(e).__name__}: {str(e)[:300]}"}


def pending_lists(run: Run, ledger: Ledger) -> dict[str, list[str]]:
    """The laws not accepted, by what each waits on: a label check (`awaiting_labels`: generated,
    not checked), a label repair, generation (planned with nodes still to code or held), planning
    (open or returned), the operator (blocked) or nothing (failed). Under `review: required` a
    generated law waits first on its review (`awaiting_review`, or `review_repair` for a finding) and
    only then on its labels; the lists add the review's standing (`behaviour_review.counts`)."""
    from . import behaviour_review
    review = behaviour_review.required(run) if hasattr(run, "dir") else False
    rwork = behaviour_review.work(run, ledger) if review else {}
    waiting_review = set(rwork.get("review", [])) | set(rwork.get("exempt", []))
    out: dict[str, list[str]] = {k: [] for k in ("awaiting_labels", "awaiting_label_repair", "generating", "to_plan", "blocked", "failed")}
    if review:
        out.update(awaiting_review=[], review_repair=[])
    done = set(run.all_nodes()) if hasattr(run, "all_nodes") else set()
    for e in ledger.entries.values():
        st = (getattr(run, "label_states", None) or {}).get(e.law, {}).get("state")
        if e.state == "planned":
            if review and e.law in rwork.get("repair", []):          # a finding is repaired before its labels
                out["review_repair"].append(e.law)
            elif st == "awaiting_label_repair":
                out["awaiting_label_repair"].append(e.law)
            elif review and e.law in waiting_review:
                out["awaiting_review"].append(e.law)
            elif review and e.nodes and all(i in done for i in e.nodes) and not behaviour_review.ready(run, ledger, e.law):
                out["awaiting_review"].append(e.law)
            elif e.nodes and all(i in done for i in e.nodes):
                out["awaiting_labels"].append(e.law)
            else:
                out["generating"].append(e.law)
        elif e.state in ("open", "returned"):
            out["to_plan"].append(e.law)
        elif e.state in ("blocked", "failed"):
            out[e.state].append(e.law)
    return {k: sorted(v) for k, v in out.items()}


#: The line under an earlier iteration's heading in `TO_USER.md`: what it lists was observed then.
PAST = ("_Observed during iteration {k}: these items record what the run reported then, not its current state "
        "(the aggregate downgrades that hold now are in `{view}`)._")


def write_to_user(run: Run, lines: list[str]) -> None:
    """The operator's file keeps every iteration's items under the iteration's own heading, so an
    item raised once (a gap candidate, a composition) is still there when the run ends. Writing an
    iteration again replaces that iteration's section, so a second write never duplicates it. An
    earlier iteration's section is kept as written, under a line saying it was observed then, not
    the current state."""
    from .aggregate import VIEW_NAME
    path = run.dir / "TO_USER.md"
    head = f"## Iteration {run.iteration}"
    old = path.read_text(encoding="utf-8") if path.exists() else ""
    sections = [x for x in re.split(r"(?m)^(?=## Iteration \d+$)", old) if x.strip() and x.split("\n", 1)[0] != head]
    for i, x in enumerate(sections):
        m = re.match(r"## Iteration (\d+)\n", x)
        mark = PAST.format(k=int(m.group(1)), view=VIEW_NAME) if m and int(m.group(1)) < run.iteration else None
        if mark and mark not in x:
            sections[i] = x[:m.end()] + "\n" + mark + "\n" + x[m.end():]
    if lines:
        sections.append(head + "\n\n" + "\n".join(l if l.startswith("  - ") else f"- {l}" for l in lines) + "\n")   # a sub-item stays one
    path.write_text("\n".join(x.rstrip("\n") + "\n" for x in sections), encoding="utf-8")


#: How a planner's note for the operator is written in the operator's file: its identity (the
#: iteration, the source directory, its ordinal) and the digest of its source section lead the line.
NOTE = re.compile(r"^planner's note for the operator \(iteration (\d+), `([^`]+)`, note (\d+), section ([0-9a-f]+)")


def deliver_operator_notes(run: Run, to_user: list[str], notes: list[dict]) -> int:
    """Add each note a plan session wrote for the operator (`plan.operator_notes`) to the operator's
    lines, exactly once per identity: (this iteration, its source directory relative to the run, its
    ordinal in the source's section). Two sources with the same words are two notes; a note already
    in `to_user` with the same section digest is not added again, so a resume or a merged plan
    delivers nothing twice; a source whose section was rewritten since is delivered again with its
    new words, marked so. A note is a report: it blocks nothing, and grants no change or exemption.
    Returns how many were added."""
    last: dict[tuple[int, str, int], str] = {}
    for line in to_user:
        m = NOTE.match(line)
        if m:
            last[(int(m.group(1)), m.group(2), int(m.group(3)))] = m.group(4)
    added = 0
    for n in notes:
        src = Path(n["source"])
        try:
            src = src.resolve().relative_to(run.dir.resolve())
        except ValueError:
            pass
        ident = (run.iteration, src.as_posix(), int(n["ordinal"]))
        if last.get(ident) == n["section_digest"]:
            continue
        rewritten = "; source rewritten" if ident in last else ""
        to_user.append(f"planner's note for the operator (iteration {ident[0]}, `{ident[1]}`, note {ident[2]}, "
                       f"section {n['section_digest']}{rewritten}; a report, it decides nothing): {n['text']}")
        last[ident] = n["section_digest"]
        added += 1
    return added
