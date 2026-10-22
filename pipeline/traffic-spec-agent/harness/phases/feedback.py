"""Feedback: AUTO_NOTES.md for the next plan, the run's TO_USER.md for the operator (gap decisions, parameter reviews, questions, laws closed), and summary.json with the run's status."""
from __future__ import annotations
import json
import re
from ..model import nodeid
from ..model.blueprint import concepts_of
from ..store import paths
from ..store.gaps import GapLedger
from ..store.ledger import Ledger
from ..store.state import Run


def write_feedback(run: Run, ledger: Ledger, notes: list[str], to_user: list[str], gaps_filed: list[dict],
                   concept_ledger=None, deferred: list[dict] | None = None,
                   coder_narrowings: dict[str, list[dict]] | None = None) -> None:
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
        lines += ["", "## Nodes held for a node or concept they use, or by a pause (coded when it is accepted or the run resumes; no attempt counted)", ""]
        for d in deferred:
            rules = {c.get("rule") for c in d.get("compositions", [])} - set(run.all_nodes())
            concepts = ({x for e in d.get("elements", []) for x in e.get("derived", [])}
                        | {x for o in d.get("operationalizations", []) for x in concepts_of(o)})
            waits = sorted(rules | {c for c in concepts if nodeid.is_concept_id(c) and c not in run.all_concepts()})
            lines.append(f"- `{d['node_id']}` waits on {', '.join(f'`{w}`' for w in waits) or 'the run (paused or stopped before it was coded)'}")
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
    write_to_user(run, list(dict.fromkeys(l for l in to_user if l)))      # one line per decision, however often it was raised
    summary = {"run": run.opts.run_id, "iteration": run.iteration, "status": "running", "stop_reason": "",
               "laws": ledger.counts(), "accepted_nodes": len(run.accepted_nodes), "accepted_concepts": len(run.accepted_concepts),
               "concepts": concept_ledger.counts() if concept_ledger is not None else {},
               "gaps_total": len(gap_rows := GapLedger(paths.GAPS_DIR).rows),
               "gaps_created_by_this_run": sum(1 for g in gap_rows if str(g.get("proposed_in", "")).startswith(run.opts.run_id + "/"))}
    (run.dir / "summary.json").write_text(json.dumps(summary, indent=1, ensure_ascii=False), encoding="utf-8")


def write_status(run: Run, ledger: Ledger, status: str, reason: str) -> dict:
    """The run's terminal status in `summary.json`: `complete` when every law is terminal,
    `infrastructure_failure` when a session could not be launched, `paused_budget` when the second
    vendor's budget admits no further call (resumed under the same run id once raised),
    `stale_aggregate` when an aggregate's inputs changed under nodes that claim it (a new run is
    needed), `protocol_failure` when the aggregate selection stayed defective twice, `data_integrity_failure` when an audit file cannot be read as written (named, and left as
    it is), `incomplete` when the iteration bound or a stop without progress left a law open."""
    f = run.dir / "summary.json"
    f.parent.mkdir(parents=True, exist_ok=True)
    summary = json.loads(f.read_text(encoding="utf-8")) if f.exists() else {"run": run.opts.run_id}
    summary.update({"status": status, "stop_reason": reason, "laws": ledger.counts(), "iteration": run.iteration})
    f.write_text(json.dumps(summary, indent=1, ensure_ascii=False), encoding="utf-8")
    return summary


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
