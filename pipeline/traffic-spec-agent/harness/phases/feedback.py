"""Feedback: AUTO_NOTES.md for the next plan, TO_USER.md for the operator, gap merge, summary."""
from __future__ import annotations
import json
from pathlib import Path
from .. import paths
from ..gaps import GapLedger
from ..ledger import Ledger
from ..state import Run


def write_feedback(run: Run, ledger: Ledger, notes: list[str], to_user: list[str], gaps_filed: list[dict],
                   concept_ledger=None) -> None:
    lines = [f"# Feedback from iteration {run.iteration}", ""]
    lines += notes or ["(nothing to report)"]
    lines += ["", "## Laws by state", ""]
    for state, count in sorted(ledger.counts().items()):
        lines.append(f"- {state}: {count}")
    returned = [e for e in ledger.entries.values() if e.state == "returned"]
    if returned:
        lines += ["", "## Returned laws and why", ""]
        for e in returned:
            lines.append(f"- `{e.law}` (attempt {e.attempts}): " + "; ".join(e.reasons[:6]))
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
