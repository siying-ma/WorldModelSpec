"""The gap ledger: what the pipeline cannot express yet, who can fix it, and
whether the question is still open.

WHY THIS EXISTS. A plan agent that meets a clause it cannot fully formalize has
three moves, and before this file only two of them were recorded anywhere
machine-readable: formalize a weaker reading, or declare the clause unsupported.
Naming the missing capability — the third and usually correct move — went into
prose in `PLAN.md`, where the next iteration could not act on it and the
iteration after that re-derived it. One run named ten gaps across five
iterations, retired none, and spent its last three iterations reversing its own
earlier verdicts with weaker readings: cost rose while quality fell. A gap that
is written down but has no owner and no lifecycle is indistinguishable from a
gap nobody noticed.

TWO FIELDS DO THE WORK.

`owner` says **which layer must change** to retire the gap. It is a closed set,
and it is the same partition the perception ledger uses for where a datum stops
being available — so "what is missing" and "who can supply it" are answered in
the same vocabulary. The set includes `generator`, which is frozen byte-wise:
declaring that owner is therefore how the ledger says *this route is closed*,
and the resolution must re-route the gap to `capture` (a collector of our own,
running against the same simulation) or to `absent`.

`state` says **whether the question is open**. `retired` is the only state that
gives work back to the loop: a clause blocked on a retired gap becomes plannable
again, which is the mechanism that re-formalizes exactly the rules a capability
change affects and no others. `rejected` and `permanently_blocked` are the
opposite — a closed question, carrying the reason, which the next planning
session is shown so that it argues with the reason rather than re-deriving the
gap.

WHO WRITES WHAT. A planning session may only PROPOSE, into its own iteration
directory; it cannot grant itself work, choose an owner, or retire anything. The
harness allocates ids and merges proposals. Accepting, retiring and rejecting
are operator actions, made by editing this ledger — a gap is retired by the
change that retires it, and the ledger records that the change landed.

AND ONLY A PLANNING SESSION MAY FILE ONE. An operator who writes an entry by
hand has made the ledger into a maintained list rather than a record of what the
pipeline found, and the two drift the moment the library is re-formalized: the
hand-written version goes on asserting a gap no session would file again. Every
entry therefore carries `proposed_in`, the iteration that filed it, and
:func:`load` reports an entry without one. The operator's half is deciding
`state`, `owner` and `resolution` — never authoring the entry those apply to.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
from typing import Iterable, Optional

#: Which layer must change to retire a gap. Closed, and ordered by cost.
#:
#: The last two are not costs at all but verdicts. `generator` names the one
#: layer this project holds byte-wise frozen — `carla_sgg/` is upstream and the
#: whole provenance argument rests on it being unmodified — so a gap with that
#: owner is a dead end that must be re-routed rather than scheduled. `absent`
#: says the simulator does not have the datum in any form, which is the only
#: honest ground for recording a clause `unsupported`.
OWNERS: dict[str, str] = {
    "vocab": "a new `Pred.*` over keys the adapter already lifts. Cheapest: "
             "one addition to Core/Vocab.lean, no new information enters Lean.",
    "adapter": "a key the scene graph already carries and carla/adapter.py does "
               "not lift. Needs a schema entry and a portability class with it.",
    "manifest": "a capture-level setting already recorded beside the frames. "
                "Enters as a declared constant, never as a measurement.",
    "capture": "a datum the simulator has and the scene graph does not. Needs a "
               "collector of our own and a re-record; it cannot be recovered "
               "from captures already on disk.",
    "core": "the specification language itself — an operator, a Trace field, "
            "anything an `AtomicPred` cannot see. Core is frozen, so this owner "
            "is a request for an explicit unfreeze, not a scheduled change.",
    "generator": "would require editing carla_sgg/, which is frozen byte-wise. "
                 "CLOSED BY CONSTRUCTION: re-route to `capture` if our own "
                 "collector can supply it, or to `absent` if nothing can.",
    "absent": "the simulator does not have it in any form. The clause is "
              "`unsupported`, and that verdict is now citable and disputable.",
}

#: A gap's lifecycle. Only `retired` gives work back to the loop.
STATES: dict[str, str] = {
    "proposed": "a planning session named it. No decision has been made.",
    "accepted": "the operator agrees it is real. Clauses may keep depending on "
                "it; planning them is still refused until it retires.",
    "retired": "the change landed. Every clause blocked on it becomes plannable "
               "again, and that is the only automatic re-formalization trigger.",
    "rejected": "not a gap — the reading behind it was wrong. A closed question: "
                "`resolution` says why, and re-proposing it is refused.",
    "permanently_blocked": "real, and unreachable at this owner. A closed "
                           "question for the same reason, and the clauses it "
                           "blocks belong in `unsupported`.",
}

#: States in which a gap answers a question rather than asking one. A planning
#: session that re-proposes one of these is shown the resolution instead.
CLOSED_STATES = ("rejected", "permanently_blocked")

REQUIRED_FIELDS = ("id", "title", "owner", "state", "proposed_in")
ID_RE = re.compile(r"^G(\d+)$")

#: Where a ledger entry came from: `<run>/iter_NNN`, written by the harness when
#: it merges a planning session's proposals.
#:
#: ONLY A PLANNING SESSION MAY FILE AN ENTRY. An operator deciding what to do
#: about a gap is a different act from an operator inventing one, and the second
#: quietly turns the ledger into a to-do list somebody maintains — which is how
#: the same eleven gaps came to be transcribed by hand from a run's prose, at
#: which point they no longer described what the pipeline had found. Requiring a
#: filing origin in this shape makes the difference checkable: an entry nobody
#: proposed has nowhere to point.
PROPOSED_IN_RE = re.compile(r"^[A-Za-z0-9_.\-]+/iter_\d{3}$")

LEDGER_PATH = ("gaps", "ledger.jsonl")


@dataclass
class Gap:
    id: str
    title: str
    owner: str
    state: str
    statement: str = ""
    blocks: list[str] = field(default_factory=list)
    evidence: str = ""
    proposed_in: str = ""
    retired_at: Optional[str] = None
    retired_by: Optional[str] = None
    resolution: Optional[str] = None
    disputes: list[str] = field(default_factory=list)

    @property
    def is_closed(self) -> bool:
        return self.state in CLOSED_STATES

    @property
    def gives_work_back(self) -> bool:
        return self.state == "retired"

    def to_dict(self) -> dict:
        return {
            "id": self.id, "title": self.title, "owner": self.owner,
            "state": self.state, "statement": self.statement,
            "blocks": self.blocks, "evidence": self.evidence,
            "proposed_in": self.proposed_in, "retired_at": self.retired_at,
            "retired_by": self.retired_by, "resolution": self.resolution,
            "disputes": self.disputes,
        }


def ledger_path(repo_root: Path) -> Path:
    return repo_root.joinpath(*LEDGER_PATH)


def load(repo_root: Path) -> tuple[dict[str, Gap], list[str]]:
    """Read the ledger, returning ``(id -> Gap, problems)``.

    Problems are reported rather than raised: a malformed ledger must not stop a
    run, because the ledger is a backlog and the run is the work. They surface
    in the convergence report and in `run_spec doctor`.
    """
    path = ledger_path(repo_root)
    gaps: dict[str, Gap] = {}
    problems: list[str] = []
    if not path.exists():
        return gaps, problems
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("//"):
            continue
        try:
            d = json.loads(line)
        except json.JSONDecodeError as exc:
            problems.append(f"ledger line {lineno}: not valid JSON ({exc})")
            continue
        missing = [f for f in REQUIRED_FIELDS if not d.get(f)]
        if missing:
            problems.append(f"ledger line {lineno}: missing {', '.join(missing)}")
            continue
        gap = Gap(**{k: v for k, v in d.items() if k in Gap.__dataclass_fields__})
        if not ID_RE.match(gap.id):
            problems.append(f"ledger line {lineno}: id `{gap.id}` must be G<number>")
            continue
        if gap.id in gaps:
            problems.append(f"ledger line {lineno}: duplicate id `{gap.id}`")
            continue
        if not PROPOSED_IN_RE.match(gap.proposed_in or ""):
            problems.append(
                f"{gap.id}: `proposed_in` is {gap.proposed_in!r}, which is not "
                f"a planning session's filing (`<run>/iter_NNN`). Only a "
                f"planning session may file a gap; an operator decides `state`, "
                f"`owner` and `resolution` on entries it filed.")
        if gap.owner not in OWNERS:
            problems.append(f"{gap.id}: owner `{gap.owner}` is not one of "
                            f"{', '.join(OWNERS)}")
        if gap.state not in STATES:
            problems.append(f"{gap.id}: state `{gap.state}` is not one of "
                            f"{', '.join(STATES)}")
        # The invariants that make the two fields mean something.
        if gap.owner == "generator" and gap.state not in ("permanently_blocked",
                                                          "rejected"):
            problems.append(
                f"{gap.id}: owner `generator` is frozen byte-wise, so this gap "
                f"cannot be scheduled — set state `permanently_blocked` and "
                f"say in `resolution` whether it re-routes to `capture` or to "
                f"`absent`")
        if gap.state == "retired" and not (gap.retired_at and gap.retired_by):
            problems.append(f"{gap.id}: retired without `retired_at` and "
                            f"`retired_by`; a retirement nothing can be traced "
                            f"to cannot be trusted to have happened")
        if gap.is_closed and not gap.resolution:
            problems.append(f"{gap.id}: state `{gap.state}` closes the question, "
                            f"so `resolution` must say why — it is the text the "
                            f"next planning session is shown instead of the gap")
        gaps[gap.id] = gap
    return gaps, problems


def append(repo_root: Path, gaps: Iterable[Gap]) -> None:
    path = ledger_path(repo_root)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fd:
        for gap in gaps:
            fd.write(json.dumps(gap.to_dict(), ensure_ascii=False) + "\n")


def next_id(existing: dict[str, Gap]) -> str:
    used = [int(m.group(1)) for k in existing if (m := ID_RE.match(k))]
    return f"G{(max(used) + 1) if used else 1}"


def _normalise(title: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", title.lower()).strip()


def merge_proposals(repo_root: Path, proposals_file: Path,
                    origin: str) -> tuple[list[Gap], list[str], list[str]]:
    """Fold a planning session's proposals into the durable ledger.

    Returns ``(newly_recorded, refused, problems)``. A proposal is refused when
    it repeats a question the ledger has closed; the refusal carries that gap's
    `resolution`, and the loop feeds it back as harness notes. That feedback is
    the whole anti-relitigation mechanism: a closed question costs one line of
    feedback instead of a coding session spent on a weaker reading.

    Matching is by normalised title. It is deliberately crude — a near-duplicate
    with different wording lands as a second entry, which an operator merges,
    and that is the cheap failure. The expensive failure would be silently
    dropping a proposal as a duplicate of something it is not.
    """
    existing, problems = load(repo_root)
    if not proposals_file.exists():
        return [], [], problems
    by_title = {_normalise(g.title): g for g in existing.values()}
    recorded: list[Gap] = []
    refused: list[str] = []
    for lineno, line in enumerate(
            proposals_file.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("//"):
            continue
        try:
            d = json.loads(line)
        except json.JSONDecodeError as exc:
            problems.append(f"{proposals_file.name} line {lineno}: not JSON ({exc})")
            continue
        title = str(d.get("title") or "").strip()
        if not title:
            problems.append(f"{proposals_file.name} line {lineno}: no `title`")
            continue
        prior = by_title.get(_normalise(title))
        if prior is not None:
            if prior.is_closed:
                refused.append(
                    f"`{title}` repeats {prior.id}, a question this pipeline has "
                    f"closed ({prior.state}). Its resolution: {prior.resolution} "
                    f"— argue with that resolution if you disagree, by filing a "
                    f"dispute on {prior.id}; do not plan a weaker reading of the "
                    f"clause it blocks.")
            else:
                refused.append(f"`{title}` is already on the ledger as "
                               f"{prior.id} ({prior.state}); not recorded twice.")
            continue
        gap = Gap(
            id=next_id({**existing, **{g.id: g for g in recorded}}),
            title=title,
            owner=str(d.get("owner") or "vocab"),
            state="proposed",
            statement=str(d.get("statement") or ""),
            blocks=[str(x) for x in (d.get("blocks") or [])],
            evidence=str(d.get("evidence") or ""),
            proposed_in=origin,
        )
        if gap.owner not in OWNERS:
            problems.append(f"{proposals_file.name} line {lineno}: owner "
                            f"`{gap.owner}` is not one of {', '.join(OWNERS)}; "
                            f"recorded as `vocab` for an operator to correct")
            gap.owner = "vocab"
        recorded.append(gap)
        by_title[_normalise(title)] = gap
    if recorded:
        append(repo_root, recorded)
    return recorded, refused, problems


def render_for_agent(gaps: dict[str, Gap]) -> str:
    """The agent-facing ledger: what is open, what is closed, and what closed it."""
    if not gaps:
        return ("(the ledger is empty — no capability gap has been recorded yet)\n")
    open_states = [s for s in STATES if s not in CLOSED_STATES]
    lines: list[str] = []
    lines.append("**Owners** — which layer must change, and what that costs:")
    for owner, meaning in OWNERS.items():
        lines.append(f"- `{owner}` — {meaning}")
    lines.append("")
    lines.append("**States** — only `retired` gives work back:")
    for state, meaning in STATES.items():
        lines.append(f"- `{state}` — {meaning}")

    def block(title: str, chosen: list[Gap], extra: str = "") -> None:
        if not chosen:
            return
        lines.extend(["", f"**{title}**" + (f" {extra}" if extra else "")])
        for g in chosen:
            head = f"- `{g.id}` [{g.owner}] {g.title}"
            lines.append(head)
            if g.statement:
                lines.append(f"    {g.statement}")
            if g.blocks:
                lines.append(f"    blocks: {', '.join(g.blocks)}")
            if g.resolution:
                lines.append(f"    resolution: {g.resolution}")
            if g.retired_at:
                lines.append(f"    retired {g.retired_at} by {g.retired_by}")

    ordered = sorted(gaps.values(), key=lambda g: int(ID_RE.match(g.id).group(1)))
    block("Retired — the clauses these blocked are plannable again",
          [g for g in ordered if g.state == "retired"])
    block("Open", [g for g in ordered if g.state in open_states
                   and g.state != "retired"],
          "— a clause blocked on one of these is NOT plannable. Do not "
          "formalize a weaker reading of it; leave the row as it is.")
    block("Closed — settled questions", [g for g in ordered if g.is_closed],
          "— re-proposing one of these is refused. If you disagree, file a "
          "dispute; do not route around it.")
    return "\n".join(lines) + "\n"
