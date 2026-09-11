"""L3 — derive ground-truth labels by evaluating readings over a fact track.

Nothing in this file is written by hand per capture. A label is a *function* of
(fact track, reading), so re-reading a clause relabels the whole corpus in
seconds and a corpus of any size costs no additional annotation.

Labels are intervals, not verdicts
----------------------------------
A violation happens over a span of time and begins at an instant. Both matter,
and a per-capture verdict throws away the part that matters most for a monitor:
*when* it should have alarmed. `metrics.py` scores a monitor by interval overlap
and by the delay between the true onset and the alarm, neither of which is
recoverable from a single word per capture.

The four verdicts
-----------------
  VIOLATED       the obligation applied and was breached; carries the intervals
  COMPLIANT      the obligation applied throughout some interval and held
  NOT_APPLICABLE the antecedent never became true. Not a formality: an
                 obligation whose situation never arose is untested by this
                 capture, and counting it as agreement lets a library of
                 vacuous rules score perfectly.
  UNTESTABLE     the capture cannot supply a fact the obligation reads. Distinct
                 from NOT_APPLICABLE, which is a claim about the world; this is
                 a claim about the recording. Conflating them is how a corpus
                 with a missing field reports full coverage.
"""

from __future__ import annotations

import json
from typing import Any, Dict, List, Optional, Tuple

from . import reading as reading_mod
from .reading import FALSE, TRUE, UNKNOWN, evaluate_track

VIOLATED = "violated"
COMPLIANT = "compliant"
NOT_APPLICABLE = "not_applicable"
UNTESTABLE = "untestable"


def intervals(track_values, want=TRUE):
    # type: (List[Optional[bool]], Optional[bool]) -> List[Tuple[int, int]]
    """Maximal [start, end] index runs where the three-valued track equals `want`.

    Ends are inclusive, because an interval of one frame is a real thing (an
    instantaneous breach) and a half-open convention makes it look empty.
    """
    out = []
    start = None
    for i, value in enumerate(track_values):
        if value is want:
            if start is None:
                start = i
        else:
            if start is not None:
                out.append((start, i - 1))
                start = None
    if start is not None:
        out.append((start, len(track_values) - 1))
    return out


class Label(object):
    """The derived ground truth for one obligation on one capture."""

    def __init__(self, reading_id, capture, verdict, applicable, violations,
                 fps, evidence=None, untestable_paths=None):
        self.reading_id = reading_id
        self.capture = capture
        self.verdict = verdict
        #: inclusive [start, end] frame ranges where the antecedent held
        self.applicable = applicable
        #: inclusive [start, end] frame ranges of breach; onset is violations[i][0]
        self.violations = violations
        self.fps = fps
        self.evidence = evidence or {}
        self.untestable_paths = untestable_paths or []

    @property
    def onsets(self):
        # type: () -> List[int]
        return [start for start, _ in self.violations]

    def as_dict(self):
        return {
            "reading": self.reading_id,
            "capture": self.capture,
            "verdict": self.verdict,
            "applicable_intervals": [list(iv) for iv in self.applicable],
            "violation_intervals": [list(iv) for iv in self.violations],
            "onsets": self.onsets,
            "fps": self.fps,
            "applicable_frames": sum(b - a + 1 for a, b in self.applicable),
            "violation_frames": sum(b - a + 1 for a, b in self.violations),
            "untestable_paths": self.untestable_paths,
            "evidence": self.evidence,
        }


def label_one(reading, track):
    # type: (Any, Any) -> Label
    """Derive one obligation's label on one capture."""
    absent = sorted(p for p in reading.paths() if track.is_absent(p))
    if absent:
        return Label(reading.id, track.capture, UNTESTABLE, [], [], track.fps,
                     evidence={"reason": "capture cannot supply these facts"},
                     untestable_paths=absent)

    applies = evaluate_track(reading.applies_when, track)
    applicable = intervals(applies, TRUE)
    if not applicable:
        unknown = intervals(applies, UNKNOWN)
        reason = ("the antecedent never held"
                  if not unknown else
                  "the antecedent never held; it was undetermined on %d frames"
                  % sum(b - a + 1 for a, b in unknown))
        return Label(reading.id, track.capture, NOT_APPLICABLE, [], [],
                     track.fps, evidence={"reason": reason})

    breach = evaluate_track(reading.violated_when, track)
    # A breach only counts while the obligation is in force. Evaluating
    # `violated_when` alone would convict a driver of a following-distance
    # breach recorded before it was following anything.
    gated = [reading_mod.k_and([applies[i], breach[i]])
             for i in range(len(breach))]
    violations = intervals(gated, TRUE)

    evidence = {
        "applicable_frames": sum(b - a + 1 for a, b in applicable),
        "violation_frames": sum(b - a + 1 for a, b in violations),
        "undetermined_frames": sum(b - a + 1
                                   for a, b in intervals(gated, UNKNOWN)),
        "borrowed_quantifications": [q.term
                                     for q in reading.borrowed_quantifications()],
    }
    verdict = VIOLATED if violations else COMPLIANT
    return Label(reading.id, track.capture, verdict, applicable, violations,
                 track.fps, evidence)


def label_capture(readings, track):
    # type: (List[Any], Any) -> Dict[str, Label]
    return dict((r.id, label_one(r, track)) for r in readings)


def write_labels(labels, path, meta=None):
    # type: (Dict[str, Label], str, Optional[dict]) -> None
    payload = {
        "derivation": (
            "computed by evalkit.evaluate from a fact track and a reading set; "
            "no per-capture human annotation is involved. Re-derive with "
            "`evalkit label` after any change to the readings."),
        "meta": meta or {},
        "labels": [labels[k].as_dict() for k in sorted(labels)],
    }
    with open(path, "w") as fd:
        json.dump(payload, fd, indent=2, sort_keys=True)
        fd.write("\n")
