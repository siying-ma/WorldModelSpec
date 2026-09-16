"""The coverage table, read by the harness rather than by a person.

WHAT CHANGED AND WHY. The table used to carry four statuses, of which one —
`partial` — was never defined and could never be left. The prompt blesses
"formalize the decidable part and state the residue" as the normal outcome for
real law over an abstraction, which lands in `partial`; and the completion
condition required every clause to be `formalized` or `unsupported`. So the
usual correct outcome was also a state the run could not converge from. One run
finished with 19 of 21 clauses `partial`, a stage that stayed `formalize`, and
three iterations spent re-litigating its own earlier verdicts because nothing
told it there was nothing left to do.

The fix is to split `partial` by the only distinction that matters to a loop:
is there anything a further iteration could do about it?

    formalized_with_residue   no — the residue is named, directed, and not
                              retirable at the layer this pipeline can reach.
                              A terminal state, and the honest one for most
                              clauses.
    blocked_on_gap            not yet — a named gap must retire first. Terminal
                              WHILE that gap is open, plannable again the moment
                              it retires.

CONVERGENCE IS COMPUTED, NOT DECLARED. It used to be an instruction to the plan
agent ("set the stage when..."), and an agent declined it and planned five more
nodes. Now :func:`assess` derives it from the table and the gap ledger, and the
loop stops on that. The agent's `stage: COMPLETE` is still honoured as an early
stop, but it is no longer the only way a run ends.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from . import gaps as gaps_mod

#: One row per clause. The two middle states are what `partial` became.
STATUSES: dict[str, str] = {
    "pending": "no rule yet, and nothing blocking one. This iteration should "
               "plan it.",
    "formalized": "every obligation the clause states is expressed. No residue.",
    "formalized_with_residue": "a rule EXISTS and expresses less than the clause "
                               "says. The note must name the residue and which "
                               "way it errs — toward reporting violations the "
                               "law permits, or toward missing violations it "
                               "forbids. If a named gap would improve it, put "
                               "that id in the `gap` column: the row is still "
                               "terminal for now, and retiring the gap reopens "
                               "it.",
    "blocked_on_gap": "NO rule could be written at all — not a weaker one, not "
                      "a partial one — until a named gap retires. The `gap` "
                      "column must carry the id, and the `node(s)` column must "
                      "be empty, because a clause with a rule is not blocked.",
    "unsupported": "the simulator does not have what the clause needs, in any "
                   "form. The note must cite the gap whose owner is `absent`.",
}

#: Statuses from which no iteration can make progress on its own.
TERMINAL = ("formalized", "formalized_with_residue", "unsupported")

ROW_RE = re.compile(r"^\|\s*(?P<law>[A-Za-z0-9_.\-]+)\s*\|"
                    r"\s*(?P<status>[a-zA-Z_]+)\s*\|"
                    r"(?P<rest>.*)\|\s*$")

#: `[reopened <gap> <date>]`, written into a row's note by the harness when a
#: gap retires. Its presence is what keeps the reopening idempotent: the row is
#: flipped to `pending` once per retirement, not once per iteration.
REOPEN_RE = re.compile(r"\[reopened (?P<gap>G\d+) (?P<when>[0-9-]+)\]")

#: `reopen: <law id>` in USER_HINTS.md — the operator's lever for re-planning a
#: clause whose row is terminal. Deliberately explicit: a terminal row is
#: otherwise refused, which is what stops an unattended run from re-litigating
#: its own verdicts, and an operator must be able to overrule that.
HINT_REOPEN_RE = re.compile(r"^\s*[-*]?\s*reopen:\s*(?P<law>[A-Za-z0-9_.\-]+)",
                            re.M | re.I)


@dataclass
class Row:
    law: str
    status: str
    nodes: str = ""
    gap: str = ""
    note: str = ""
    lineno: int = 0

    @property
    def reopened_for(self) -> set[tuple[str, str]]:
        return {(m.group("gap"), m.group("when"))
                for m in REOPEN_RE.finditer(self.note)}


@dataclass
class Assessment:
    rows: list[Row] = field(default_factory=list)
    actionable: list[str] = field(default_factory=list)
    reopened: list[str] = field(default_factory=list)
    defects: list[str] = field(default_factory=list)
    missing: list[str] = field(default_factory=list)

    @property
    def converged(self) -> bool:
        return not self.actionable and not self.missing

    def counts(self) -> dict[str, int]:
        out = {s: 0 for s in STATUSES}
        for r in self.rows:
            out[r.status] = out.get(r.status, 0) + 1
        return out


def _split_cells(rest: str) -> tuple[str, str, str]:
    """The columns after `status`, tolerant of a table without a `gap` column.

    A three-cell tail is `node(s) | gap | note`; two is `node(s) | note`, which
    is the shape the previous template had, and reading it as the new one would
    put prose in the gap column and report every row as a defect.
    """
    cells = [c.strip() for c in rest.split("|")]
    while cells and not cells[-1]:
        cells.pop()
    if len(cells) >= 3:
        return cells[0], cells[1], " | ".join(cells[2:])
    if len(cells) == 2:
        nodes, tail = cells
        return (nodes, tail, "") if gaps_mod.ID_RE.match(tail) else (nodes, "", tail)
    return (cells[0] if cells else ""), "", ""


def parse(progress_file: Path) -> list[Row]:
    """Every coverage row, in file order. Unknown statuses are kept as they are.

    A row with a status this module does not know is not dropped: it is carried
    through so :func:`assess` can report it. Dropping it would make an
    unparseable table look like an empty one, and an empty table looks converged.
    """
    if not progress_file.exists():
        return []
    rows: list[Row] = []
    for lineno, line in enumerate(
            progress_file.read_text(encoding="utf-8").splitlines(), 1):
        m = ROW_RE.match(line.rstrip())
        if not m:
            continue
        law = m.group("law")
        if law.lower() in ("law id", "---", "--------"):
            continue
        if set(law) <= {"-"}:
            continue
        nodes, gap, note = _split_cells(m.group("rest"))
        rows.append(Row(law=law, status=m.group("status"), nodes=nodes,
                        gap=gap, note=note, lineno=lineno))
    return rows


def operator_reopens(hints_file: Path) -> set[str]:
    if not hints_file.exists():
        return set()
    text = hints_file.read_text(encoding="utf-8")
    return {m.group("law") for m in HINT_REOPEN_RE.finditer(text)}


def assess(progress_file: Path, repo_root: Path, law_ids: set[str],
           hints_file: Optional[Path] = None) -> Assessment:
    """What this run can still do, and whether it is done.

    `actionable` is the whole of what the next iteration may plan. It holds a
    clause when its row says `pending`, when a gap it is blocked on has retired,
    or when the operator has reopened it by hand. Everything else is terminal
    for this run — including `blocked_on_gap` on an open gap, which is the state
    the previous design had no way to express and therefore kept re-planning.
    """
    rows = parse(progress_file)
    ledger, ledger_problems = gaps_mod.load(repo_root)
    reopens = operator_reopens(hints_file) if hints_file else set()

    out = Assessment(rows=rows, defects=list(ledger_problems))
    listed = {r.law for r in rows}
    out.missing = sorted(law_ids - listed) if law_ids else []
    for row in rows:
        if law_ids and row.law not in law_ids:
            out.defects.append(f"{row.law}: not an id in the corpus")
        if row.status not in STATUSES:
            out.defects.append(
                f"{row.law}: status `{row.status}` is not one of "
                f"{', '.join(STATUSES)}. `partial` was split into "
                f"`formalized_with_residue` and `blocked_on_gap`.")
            continue
        if row.status == "pending":
            out.actionable.append(row.law)
            continue
        if row.status == "formalized_with_residue" and row.gap:
            # A residue with a named owner. Terminal now, plannable again when
            # the capability lands — the same trigger `blocked_on_gap` gets,
            # because the two differ in whether a rule exists today, not in
            # whether a gap would improve the clause.
            gap = ledger.get(row.gap)
            if gap is None:
                out.defects.append(
                    f"{row.law}: cites unknown gap `{row.gap}`")
            elif gap.gives_work_back:
                stamp = (gap.id, str(gap.retired_at))
                if stamp not in row.reopened_for:
                    out.actionable.append(row.law)
                    out.reopened.append(row.law)
            continue
        if row.status == "blocked_on_gap":
            if row.nodes.strip():
                out.defects.append(
                    f"{row.law}: `blocked_on_gap` but names node(s) "
                    f"`{row.nodes.strip()}`. A clause with a rule is not "
                    f"blocked — it is `formalized_with_residue`, with the gap "
                    f"id kept in the `gap` column so retiring it still reopens "
                    f"the row.")
            gap = ledger.get(row.gap) if row.gap else None
            if gap is None:
                out.defects.append(
                    f"{row.law}: `blocked_on_gap` names "
                    f"{'no gap' if not row.gap else f'unknown gap `{row.gap}`'}. "
                    f"A block nothing can retire is indistinguishable from a "
                    f"clause nobody looked at.")
                continue
            if gap.is_closed:
                out.defects.append(
                    f"{row.law}: blocked on {gap.id}, which is closed "
                    f"({gap.state}: {gap.resolution}). The row must move to a "
                    f"terminal status — `unsupported` if the resolution says "
                    f"the datum is absent.")
                continue
            if gap.gives_work_back:
                stamp = (gap.id, str(gap.retired_at))
                if stamp not in row.reopened_for:
                    out.actionable.append(row.law)
                    out.reopened.append(row.law)
            continue
        # Terminal statuses. The operator can still force one back.
        if row.law in reopens:
            out.actionable.append(row.law)
    return out


def reopen_rows(progress_file: Path, reopened: list[str],
                repo_root: Path) -> None:
    """Flip reopened rows to `pending` and stamp them, in place.

    Harness-owned, and deliberately so: the trigger for re-formalizing a rule
    after a capability lands must not be a judgement call made by the session
    that would then do the work. The stamp makes it happen once per retirement
    — without it the row would be reopened again on every iteration, which is
    the unbounded loop this design exists to prevent.
    """
    if not reopened or not progress_file.exists():
        return
    ledger, _ = gaps_mod.load(repo_root)
    lines = progress_file.read_text(encoding="utf-8").splitlines()
    wanted = set(reopened)
    for i, line in enumerate(lines):
        m = ROW_RE.match(line.rstrip())
        if not m or m.group("law") not in wanted:
            continue
        if m.group("status") != "blocked_on_gap":
            continue
        _, gap_id, _ = _split_cells(m.group("rest"))
        gap = ledger.get(gap_id)
        if gap is None or not gap.gives_work_back:
            continue
        cells = [c for c in line.split("|")]
        # cells[0] is the empty string before the leading pipe.
        for j, cell in enumerate(cells):
            if cell.strip() == "blocked_on_gap":
                cells[j] = " pending "
                break
        stamp = f" [reopened {gap.id} {gap.retired_at}]"
        cells[-2] = cells[-2].rstrip() + stamp + " "
        lines[i] = "|".join(cells)
    progress_file.write_text("\n".join(lines) + "\n", encoding="utf-8")


def render_for_agent(assessment: Assessment) -> str:
    """What the planning session may work on, and what it may not touch."""
    lines = ["**Statuses** — one row per clause:"]
    for status, meaning in STATUSES.items():
        lines.append(f"- `{status}` — {meaning}")
    counts = assessment.counts()
    lines += ["", "**This run's table right now**: "
              + ", ".join(f"{n} {s}" for s, n in counts.items() if n)
              + f" ({len(assessment.rows)} rows)."]
    if assessment.missing:
        lines.append("")
        lines.append("**Clauses with no row at all** — add one for each, and "
                     "plan the ones you can: "
                     + ", ".join(f"`{x}`" for x in assessment.missing[:40]))
    # `missing` is plannable and always was — the validator admits a clause with
    # no row, because a corpus the table has not caught up with must not stall a
    # run. Leaving it out of this list while listing it above produced a prompt
    # that said "plan the ones you can" and "nothing is plannable" in the same
    # breath, on every first iteration; one planning session reported the
    # contradiction and guessed which half to believe.
    plannable = list(assessment.actionable) + [
        m for m in assessment.missing if m not in assessment.actionable]
    if plannable:
        lines += ["", "**Plannable this iteration** — and nothing else is:"]
        for law in plannable:
            why = (" (reopened: a gap it was blocked on has retired)"
                   if law in assessment.reopened else
                   " (no row yet)" if law in assessment.missing else "")
            lines.append(f"- `{law}`{why}")
    else:
        lines += ["", "**Nothing is plannable.** Every clause is either "
                  "terminal or blocked on an open gap. Do not plan a node: set "
                  "`- stage: COMPLETE`, and if you believe a terminal row is "
                  "wrong, say so in the plan file and file a dispute on the gap "
                  "— the operator reads both."]
    if assessment.defects:
        lines += ["", "**Defects in the table or the ledger** — fix the rows "
                  "you own:"]
        for d in assessment.defects[:20]:
            lines.append(f"- {d}")
    return "\n".join(lines) + "\n"


def render_report(assessment: Assessment) -> str:
    """The operator's convergence report, printed at the end of a run."""
    counts = assessment.counts()
    width = max((len(s) for s in STATUSES), default=10)
    lines = ["Coverage:"]
    for status in STATUSES:
        lines.append(f"  {status:<{width}}  {counts.get(status, 0):>3}")
    unknown = sum(v for k, v in counts.items() if k not in STATUSES)
    if unknown:
        lines.append(f"  {'(unknown)':<{width}}  {unknown:>3}")
    if assessment.converged:
        lines.append("Converged: nothing is plannable without a capability "
                     "change. Retire a gap to give the loop work back.")
    else:
        lines.append(f"Not converged: {len(assessment.actionable)} clause(s) "
                     f"plannable — {', '.join(assessment.actionable[:8])}"
                     + (" ..." if len(assessment.actionable) > 8 else ""))
    if assessment.reopened:
        lines.append("Reopened by a retired gap: "
                     + ", ".join(assessment.reopened))
    for d in assessment.defects[:10]:
        lines.append(f"  defect: {d}")
    return "\n".join(lines)
