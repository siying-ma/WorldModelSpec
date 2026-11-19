"""One gate failure repeated across laws: a signal that the run should stop and the operator look.

A node's gate that ends `CHECK_FAIL` names each failed check on a detail line. A line is compared
across nodes with the node's own id replaced by `<node>`, so a check
that fails the same way in two nodes gives the same signature. Only a line that names the node
counts: a line that does not (a note on the gate's deadline, a check that states no rule) reads the
same for every node and says nothing of where the failure lies. When one signature occurs in the
`CHECK_FAIL` gates of at least `SHARED_FAILURE_LAWS` different laws in one iteration, the node stage
submits no further session and the run stops as `paused_defect` once the running sessions end.

The signal proves nothing about the cause: several nodes may have made the same mistake, or a shared
input (the run's reading, Core) may be wrong and no node able to change it. The gates are charged as
any gate is; the pause only stops spending until the operator has looked. Every pause is recorded
in `shared_failure_pauses.jsonl` of the run with its signatures, the laws and nodes, each node's raw
lines and task directory, and the run's spend by vendor at that point. A signature that has paused
the run once never pauses it again: the resume that follows is the operator's answer to it, and the
launch that resumes records that answer in the same file (a row `answered` with the number of pauses
it answers). A pause no later row answers is active: it is listed with the run's other stops until
then, and only a resume answers it; no acknowledgement of another stop does.
"""
from __future__ import annotations

import re
import time
from pathlib import Path

from . import jsonl
from .budget import fold

SHARED_FAILURE_LAWS = 3
PAUSES = "shared_failure_pauses.jsonl"


class DefectPaused(RuntimeError):
    """One gate failure was repeated across laws: the run pauses for the operator."""


def signature(node_id: str, line: str) -> str:
    """The line with the node's id replaced by `<node>`; another node's id, a sibling's included, is kept."""
    return re.sub(rf"(?<![\w-]){re.escape(node_id)}(?![\w-])", "<node>", " ".join(str(line).split()))


class SharedFailures:
    """The `CHECK_FAIL` signatures of one iteration's node gates, each with the laws and nodes it occurred
    in, kept in `seen` (a dict the iteration's progress persists, so a resume of the iteration keeps the
    count): signature ↦ law ↦ {node: [raw lines]}."""

    def __init__(self, run_dir: Path, seen: dict):
        self.file, self.seen = Path(run_dir) / PAUSES, seen
        self.paused_before = {s for row in jsonl.read_strict(self.file) for s in row.get("signatures", [])}

    def record(self, law: str, node_id: str, verdict: str, details: list[str]) -> None:
        """Adds a node's gate outcome."""
        if verdict != "CHECK_FAIL":
            return
        for line in details:
            sig = signature(node_id, line)
            if sig == " ".join(str(line).split()):
                continue
            lines = self.seen.setdefault(sig, {}).setdefault(law, {}).setdefault(node_id, [])
            if line not in lines:
                lines.append(line)

    def due(self) -> list[str]:
        """The signatures that reached the bound in this iteration and have never paused the run: read from
        `seen`, so a resume of the iteration finds a bound reached before the stop."""
        return sorted(s for s, laws in self.seen.items() if len(laws) >= SHARED_FAILURE_LAWS and s not in self.paused_before)

    def pause(self, signatures: list[str], iteration: int, task_dir) -> str:
        """Records the pause and returns its stop reason."""
        spent, _unresolved, _settled, _vendors = fold(jsonl.read_strict(self.file.parent / "usage.jsonl"))
        row = {"iteration": iteration, "signatures": signatures,
               "occurrences": {s: {law: {n: {"lines": lines, "task": str(task_dir(n))} for n, lines in nodes.items()}
                                   for law, nodes in self.seen[s].items()} for s in signatures},
               "spent_usd": {v: round(c, 4) for v, c in spent.items()}}
        jsonl.append_atomic(self.file, row)
        self.paused_before |= set(signatures)
        each = "; ".join(f"`{s}` in {len(self.seen[s])} laws ({', '.join(sorted(self.seen[s]))})" for s in signatures)
        return (f"one gate failure was repeated across laws in iteration {iteration}: {each}. No further session was "
                f"submitted; the gates were charged as usual. Raw lines, nodes and spend are in {self.file.name}. If the cause "
                "is a shared input the nodes cannot change (the reading, Core), fix it and check the resume contract before "
                "resuming: a changed semantic input needs a new run; `python -m harness reopen` restores the laws' budgets. "
                "If the nodes are wrong, resume with the same command; these signatures do not pause the run again")


def unanswered(run_dir: Path) -> list[tuple[int, dict]]:
    """The run's pauses no later launch answered: (ordinal among its pauses, from 1; the pause row)."""
    rows = jsonl.read_strict(Path(run_dir) / PAUSES)
    pauses = [r for r in rows if "signatures" in r]
    answered = max([int(r["answered"]) for r in rows if "answered" in r] or [0])
    return [(i, r) for i, r in enumerate(pauses, 1) if i > answered]


def answer(run_dir: Path) -> None:
    """A launch that resumes the run answers every pause recorded before it (one row, when any is open)."""
    f = Path(run_dir) / PAUSES
    if unanswered(run_dir):
        n = sum(1 for r in jsonl.read_strict(f) if "signatures" in r)
        jsonl.append_atomic(f, {"answered": n, "at": time.strftime("%Y-%m-%dT%H:%M:%S")})
