"""L2 — a *reading*: the quantified, reviewable form of one atomic obligation.

The problem this solves
-----------------------
A statute is prose. Two things must be produced from it, and they are usually
produced twice by accident:

  1. the specification under test (a Lean rule over the scene graph), and
  2. the ground truth the specification is scored against.

If both are written from the prose independently, they are two readings of the
same ambiguous sentence. When they agree you have learned nothing — the same
misreading twice is indistinguishable from a correct one. When they disagree you
cannot say which is wrong. This was observed directly in this project: the same
clause ("at least two seconds of space") was quantified as 20 m centre-to-centre
in the Lean rule and 4 m bumper-to-bumper in the label script, and neither is
wrong on its face.

A reading is the artifact that makes the quantification happen exactly once, in
a place both consumers cite. Human and legal review is spent here and only here:
it is O(obligations), it is done once per jurisdiction, and it is short enough to
audit line by line.

What a reading is NOT
--------------------
It is not the specification. It is written against the *fact schema* (privileged
physical state) and the specification is written against the *scene graph*
(what a monitor can actually perceive). They remain independent in the way that
matters — abstraction fidelity, grounding, adapter renames, perception loss —
while sharing the one thing that must not vary: what the clause is taken to mean.

Three-valued by construction
----------------------------
A missing fact is UNKNOWN, never False. A rule whose antecedent needs a field the
capture cannot supply is UNTESTABLE on that capture, which is reported, rather
than trivially compliant, which would be a silent lie. `facts.FactTrack.is_absent`
is the authority.

Expression language
-------------------
JSON, deliberately small enough to review without a manual.

  literals      42, 3.5, true, false, {"lit": "Red"}
  field paths   "ego.speed_kph", "signal.state", "actor.rel.bumper_gap_m"
  comparison    {"gt": [a, b]} ge lt le eq ne
  interval      {"between": [x, lo, hi]}
  logic         {"all": [..]} {"any": [..]} {"not": e}
  presence      {"notnull": path} {"isnull": path}
  actors        {"exists_actor": e} {"forall_actor": e}
                  inside e, "actor.*" binds to the candidate actor
  temporal      {"sustained": [seconds, e]}   e held continuously for >= seconds,
                                              true on the frame the window closes
                {"onset": e}                  e false on t-1 and true on t
                {"within": [seconds, e]}      e true at some frame in the next
                                              `seconds`, evaluated at t
                {"prev": e}                   e on the previous frame

`sustained` closes its window at the *end*, so the frame it first becomes true
is the first frame at which the obligation has actually been breached. That is
the instant a monitor should have alarmed, which is what `metrics.latency`
measures against.
"""

from __future__ import annotations

import json
from typing import Any, Dict, List, Optional, Tuple

TRUE = True
FALSE = False
UNKNOWN = None

_COMPARISONS = ("gt", "ge", "lt", "le", "eq", "ne")


class ReadingError(ValueError):
    pass


# --------------------------------------------------------------------------
# Kleene three-valued connectives
# --------------------------------------------------------------------------

def k_and(values):
    # type: (List[Optional[bool]]) -> Optional[bool]
    if any(v is FALSE for v in values):
        return FALSE
    if any(v is UNKNOWN for v in values):
        return UNKNOWN
    return TRUE


def k_or(values):
    # type: (List[Optional[bool]]) -> Optional[bool]
    if any(v is TRUE for v in values):
        return TRUE
    if any(v is UNKNOWN for v in values):
        return UNKNOWN
    return FALSE


def k_not(value):
    # type: (Optional[bool]) -> Optional[bool]
    return UNKNOWN if value is UNKNOWN else (not value)


# --------------------------------------------------------------------------
# The expression walker
# --------------------------------------------------------------------------

def referenced_paths(expr, out=None):
    # type: (Any, Optional[set]) -> set
    """Every fact path an expression reads.

    Used before evaluation to decide testability: if the capture marks any of
    these ABSENT, the obligation is UNTESTABLE here and no verdict is produced.
    """
    if out is None:
        out = set()
    if isinstance(expr, str):
        out.add(expr)
    elif isinstance(expr, dict):
        if "lit" in expr and len(expr) == 1:
            return out
        for key, value in expr.items():
            if key in ("sustained", "within"):
                referenced_paths(value[1], out)
            elif isinstance(value, list):
                for item in value:
                    referenced_paths(item, out)
            else:
                referenced_paths(value, out)
    return out


def _resolve(operand, frame, actor):
    # type: (Any, Any, Optional[dict]) -> Any
    """A literal, or a dotted path against the frame or the bound actor."""
    if isinstance(operand, dict):
        if "lit" in operand:
            return operand["lit"]
        raise ReadingError("operand %r is not a literal or a path" % (operand,))
    if isinstance(operand, str):
        if operand.startswith("actor."):
            if actor is None:
                raise ReadingError(
                    "%s used outside exists_actor/forall_actor" % operand)
            node = actor
            for key in operand.split(".")[1:]:
                if not isinstance(node, dict) or key not in node:
                    return None
                node = node[key]
            return node
        return frame.get(operand)
    return operand


def _compare(op, left, right):
    # type: (str, Any, Any) -> Optional[bool]
    if left is None or right is None:
        return UNKNOWN
    try:
        if op == "gt":
            return left > right
        if op == "ge":
            return left >= right
        if op == "lt":
            return left < right
        if op == "le":
            return left <= right
        if op == "eq":
            return left == right
        if op == "ne":
            return left != right
    except TypeError:
        # Comparing a string state to a number is an authoring bug, not data
        # noise; surfacing it as UNKNOWN would hide it inside a passing report.
        raise ReadingError("cannot compare %r and %r with %s"
                           % (left, right, op))
    raise ReadingError("unknown comparison %s" % op)


def _eval_at(expr, track, t, actor=None):
    # type: (Any, Any, int, Optional[dict]) -> Optional[bool]
    """Evaluate one expression at frame `t`."""
    frame = track.frames[t]

    if isinstance(expr, bool):
        return expr
    if isinstance(expr, str):
        value = _resolve(expr, frame, actor)
        if value is None:
            return UNKNOWN
        return bool(value)
    if not isinstance(expr, dict):
        raise ReadingError("not an expression: %r" % (expr,))
    if len(expr) != 1:
        raise ReadingError("an expression node takes exactly one operator, "
                           "got %r" % sorted(expr))

    op, arg = list(expr.items())[0]

    if op in _COMPARISONS:
        left = _resolve(arg[0], frame, actor)
        right = _resolve(arg[1], frame, actor)
        return _compare(op, left, right)

    if op == "between":
        value = _resolve(arg[0], frame, actor)
        lo = _resolve(arg[1], frame, actor)
        hi = _resolve(arg[2], frame, actor)
        if value is None or lo is None or hi is None:
            return UNKNOWN
        return lo <= value <= hi

    if op == "all":
        return k_and([_eval_at(e, track, t, actor) for e in arg])
    if op == "any":
        return k_or([_eval_at(e, track, t, actor) for e in arg])
    if op == "not":
        return k_not(_eval_at(arg, track, t, actor))

    if op == "notnull":
        return _resolve(arg, frame, actor) is not None
    if op == "isnull":
        return _resolve(arg, frame, actor) is None

    if op == "exists_actor":
        return k_or([_eval_at(arg, track, t, a) for a in frame.actors])
    if op == "forall_actor":
        return k_and([_eval_at(arg, track, t, a) for a in frame.actors])

    if op == "prev":
        if t == 0:
            return UNKNOWN
        return _eval_at(arg, track, t - 1, actor)

    if op == "onset":
        here = _eval_at(arg, track, t, actor)
        if t == 0:
            return UNKNOWN if here is UNKNOWN else FALSE
        before = _eval_at(arg, track, t - 1, actor)
        return k_and([here, k_not(before)])

    if op == "ever_before":
        # True at t when the inner expression held at any frame up to and
        # including t. Needed for "entered the intersection without having
        # stopped", which is a claim about the whole approach rather than about
        # a window of fixed length -- and a fixed window would let a driver who
        # stopped slightly too early pass.
        for i in range(t + 1):
            if _eval_at(arg, track, i, actor) is TRUE:
                return TRUE
        return FALSE

    if op == "sustained":
        seconds, inner = arg[0], arg[1]
        need = track.seconds_to_frames(seconds)
        if t + 1 < need:
            # The window runs off the front of the trace. FALSE, not UNKNOWN:
            # the obligation demonstrably has not been breached for `seconds`
            # yet, because the trace has not been that long.
            return FALSE
        window = [_eval_at(inner, track, i, actor)
                  for i in range(t - need + 1, t + 1)]
        return k_and(window)

    if op == "within":
        seconds, inner = arg[0], arg[1]
        span = track.seconds_to_frames(seconds)
        hi = min(len(track.frames) - 1, t + span)
        window = [_eval_at(inner, track, i, actor) for i in range(t, hi + 1)]
        if hi < t + span and k_or(window) is FALSE:
            # The horizon runs off the end of the trace, so "it never happened"
            # is not established. Reporting FALSE here is how a capture that
            # simply ended early convicts a compliant driver.
            return UNKNOWN
        return k_or(window)

    raise ReadingError("unknown operator %r" % op)


def evaluate_track(expr, track):
    # type: (Any, Any) -> List[Optional[bool]]
    """Evaluate an expression at every frame, returning a three-valued track."""
    return [_eval_at(expr, track, t) for t in range(len(track.frames))]


# --------------------------------------------------------------------------
# Readings
# --------------------------------------------------------------------------

PROVENANCE_KINDS = ("statute", "reading", "borrowed")


class Quantification(object):
    """One vague term, the number chosen for it, and who chose it.

    `statute`  the figure is in the statute text; cite it verbatim.
    `reading`  the statute is qualitative and this quantifies it. This is the
               claim a human reviewer is actually reviewing.
    `borrowed` the figure came from the implementation being tested. A label
               built on a borrowed number cannot falsify that number, only
               whether the rule fires on the right situation, and every report
               that uses it must say so.
    """

    def __init__(self, term, value, unit, kind, note=""):
        if kind not in PROVENANCE_KINDS:
            raise ReadingError("quantification kind %r must be one of %s"
                               % (kind, ", ".join(PROVENANCE_KINDS)))
        self.term = term
        self.value = value
        self.unit = unit
        self.kind = kind
        self.note = note

    def as_dict(self):
        return {"term": self.term, "value": self.value, "unit": self.unit,
                "kind": self.kind, "note": self.note}


class Reading(object):
    """One atomic obligation, quantified."""

    def __init__(self, id, jurisdiction, citation, text, applies_when,
                 violated_when, quantifications=None, scenarios=None,
                 tags=None, notes=""):
        self.id = id
        self.jurisdiction = jurisdiction
        self.citation = citation
        self.text = text
        self.applies_when = applies_when
        self.violated_when = violated_when
        self.quantifications = quantifications or []
        #: Bench2Drive / Leaderboard scenario names expected to exercise this.
        self.scenarios = scenarios or []
        self.tags = tags or []
        self.notes = notes

    @classmethod
    def from_dict(cls, row):
        # type: (dict) -> Reading
        missing = [k for k in ("id", "jurisdiction", "citation", "text",
                               "applies_when", "violated_when") if k not in row]
        if missing:
            raise ReadingError("reading %r is missing %s"
                               % (row.get("id", "?"), ", ".join(missing)))
        quants = [Quantification(**q) for q in row.get("quantifications", [])]
        return cls(row["id"], row["jurisdiction"], row["citation"], row["text"],
                   row["applies_when"], row["violated_when"], quants,
                   row.get("scenarios"), row.get("tags"), row.get("notes", ""))

    def as_dict(self):
        return {"id": self.id, "jurisdiction": self.jurisdiction,
                "citation": self.citation, "text": self.text,
                "applies_when": self.applies_when,
                "violated_when": self.violated_when,
                "quantifications": [q.as_dict() for q in self.quantifications],
                "scenarios": self.scenarios, "tags": self.tags,
                "notes": self.notes}

    def paths(self):
        # type: () -> set
        return (referenced_paths(self.applies_when)
                | referenced_paths(self.violated_when))

    def borrowed_quantifications(self):
        # type: () -> List[Quantification]
        return [q for q in self.quantifications if q.kind == "borrowed"]


def load_readings(path):
    # type: (str) -> List[Reading]
    readings = []
    seen = set()
    with open(path) as fd:
        for lineno, line in enumerate(fd, 1):
            line = line.strip()
            if not line or line.startswith("//"):
                continue
            try:
                row = json.loads(line)
            except ValueError as exc:
                raise ReadingError("%s:%d is not JSON: %s" % (path, lineno, exc))
            reading = Reading.from_dict(row)
            if reading.id in seen:
                raise ReadingError("%s:%d duplicates reading id %s"
                                   % (path, lineno, reading.id))
            seen.add(reading.id)
            readings.append(reading)
    return readings


def validate(readings, known_fields):
    # type: (List[Reading], Any) -> List[str]
    """Every path a reading uses must exist in the fact schema.

    A typo in a path would otherwise resolve to None, propagate as UNKNOWN, and
    silently render the obligation untestable everywhere — which looks exactly
    like a data limitation and is not one.
    """
    problems = []
    for reading in readings:
        for path in sorted(reading.paths()):
            if path not in known_fields:
                problems.append("%s references unknown fact path %r"
                                % (reading.id, path))
    return problems
