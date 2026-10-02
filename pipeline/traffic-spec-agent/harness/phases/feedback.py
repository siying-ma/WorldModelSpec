"""Feedback: AUTO_NOTES.md for the next plan, TO_USER.md for the operator, gap merge, summary."""
from __future__ import annotations
import json
from pathlib import Path
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
    failed = [e for e in ledger.entries.values() if e.state == "failed" and e.iteration == run.iteration]
    if failed:
        lines += ["", "## Laws closed as failed this iteration (reopen with `python -m harness reopen`)", ""]
        for e in failed:
            lines.append(f"- `{e.law}`: " + "; ".join(e.reasons[:6]))
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
        lines += ["", "## Nodes waiting for a node they compose (coded when it is accepted; no attempt counted)", ""]
        for d in deferred:
            waits = sorted({c.get("rule") for c in d.get("compositions", []) if c.get("rule") not in run.all_nodes()})
            lines.append(f"- `{d['node_id']}` waits on {', '.join(f'`{w}`' for w in waits) or '(nothing)'}")
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
    to_user_lines = [l for l in to_user if l]
    paths.TO_USER.write_text(("\n".join(f"- {l}" for l in to_user_lines) + "\n") if to_user_lines else "", encoding="utf-8")
    summary = {"run": run.opts.run_id, "iteration": run.iteration, "laws": ledger.counts(),
               "accepted_nodes": len(run.accepted_nodes), "accepted_concepts": len(run.accepted_concepts),
               "concepts": concept_ledger.counts() if concept_ledger is not None else {},
               "gaps_total": len(GapLedger(paths.GAP_LEDGER).rows)}
    (run.dir / "summary.json").write_text(json.dumps(summary, indent=1, ensure_ascii=False), encoding="utf-8")
