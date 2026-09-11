"""L1 — the jurisdiction-neutral fact track.

The one schema every downstream artifact is written against. It records *what
physically happened*, in SI units and OpenDRIVE identifiers, and says nothing
about any legal system. A jurisdiction's rules are expressed as `reading.py`
expressions over these names; adding a jurisdiction adds readings, never fields,
and never re-annotates a capture.

Why the schema is the load-bearing artifact
-------------------------------------------
Labelling per rule is O(rules x captures) and has to be redone for every new
statute book. Labelling the *world* once, densely, in a neutral vocabulary is
O(captures), and every jurisdiction is then a derivation over it. That is the
only shape in which "formalize all of BC MVA Part 3, and let a user swap in
another city's code" is affordable.

Provenance is part of the schema, not documentation
---------------------------------------------------
Every field carries where it came from, because the answer changes what a
disagreement means:

  SIM      privileged simulator state. Ground truth. The monitor cannot see it.
  SG       readable from the scene graph the monitor is evaluated over.
  DERIVED  computed here from other fields (finite differences, event onsets).
  ABSENT   the field is declared but this capture cannot supply it.

A rule whose antecedent needs a field the monitor's own view marks ABSENT is
vacuous by construction on that capture, and `metrics.vacuity` reports it as
untested rather than as compliant. Without per-field provenance that distinction
is unrecoverable, and a library of unmonitorable rules scores perfectly.
"""

from __future__ import annotations

import json
import math
from typing import Any, Dict, Iterator, List, Optional

SIM = "sim"
SG = "sg"
DERIVED = "derived"
ABSENT = "absent"

SCHEMA_VERSION = "1.0.0"

#: Every field the fact track may carry, with its unit and its meaning.
#: `extract_*.py` must fill exactly these; `reading.py` may reference exactly
#: these. Anything else is a schema change, which is a deliberate, versioned act
#: because it invalidates every capture already on disk.
FIELDS: Dict[str, str] = {
    # ---- ego kinematics
    "ego.speed_mps": "m/s, ground-plane",
    "ego.speed_kph": "km/h, ground-plane",
    "ego.accel_mps2": "m/s^2, signed along the heading",
    "ego.yaw_deg": "degrees, CARLA left-handed yaw",
    "ego.yaw_rate_dps": "degrees/s",
    "ego.x": "metres, map frame",
    "ego.y": "metres, map frame",
    # ---- ego control
    "ego.throttle": "0..1",
    "ego.brake": "0..1",
    "ego.steer": "-1..1",
    "ego.hand_brake": "bool",
    "ego.reverse": "bool",
    # ---- ego road position
    "ego.lane.on_road": "bool; the location projects onto a driving lane without snapping",
    "ego.lane.road_id": "OpenDRIVE road id",
    "ego.lane.lane_id": "OpenDRIVE lane id; sign encodes direction",
    "ego.lane.junction_id": "OpenDRIVE junction id, or null outside one",
    "ego.lane.is_junction": "bool",
    "ego.lane.wrong_way": "bool; heading opposes the lane's own",
    "ego.lane.lanes_to_right": "count of same-direction driving lanes to the right",
    "ego.lane.lanes_to_left": "count of same-direction driving lanes to the left",
    "ego.lane.width_m": "metres",
    "ego.lane.curvature": "1/m, signed; 0 on a straight",
    "ego.lane.type": "driving | sidewalk | shoulder | biking | parking | none",
    # ---- what is posted for the ego's own lane (OpenDRIVE landmarks)
    "ego.posted.speed_limit_kph": "km/h from the governing speed-limit landmark",
    "ego.posted.stop_ahead_m": "metres to the next stop landmark, or null",
    "ego.posted.yield_ahead_m": "metres to the next yield landmark, or null",
    "ego.posted.signal_ahead_m": "metres to the next signal landmark, or null",
    "ego.posted.crosswalk_ahead_m": "metres to the next crosswalk polygon, or null",
    "ego.posted.no_passing": "bool; a no-overtaking landmark governs this lane",
    "ego.posted.one_way": "bool",
    # ---- the lead vehicle, resolved once here rather than in every reading
    #
    # Physics belongs in the fact layer and thresholds belong in the reading
    # layer. "Two seconds of space" is a time, and a time gap is distance over
    # speed; putting that division in the expression language would mean giving
    # the language arithmetic, and an expression language with arithmetic stops
    # being reviewable at a glance -- which is the only property that makes the
    # reading layer worth having. Computing the headway here keeps every
    # reading a comparison against a named constant.
    "ego.lead.present": "bool; a vehicle ahead in the ego's own lane",
    "ego.lead.gap_m": "centre-to-centre distance to it",
    "ego.lead.bumper_gap_m": "body-to-body clear space; ABSENT in the scene-graph view",
    "ego.lead.headway_s": "seconds of travel at the ego's current speed to close the gap",
    "ego.lead.closing_mps": "+ closing, - opening; needs the lead's speed",
    "ego.lead.brake_light": "bool, the lead's brake lamp",

    # ---- the signal governing the ego's lane
    "signal.state": "Red | Yellow | Green | Off | null",
    "signal.distance_m": "metres to the stop line it protects",
    "signal.governs_ego_lane": "bool; from get_stop_waypoints, not the trigger volume",
    # ---- per-actor (list; reading expressions quantify over it)
    "actor.cls": "car|truck|van|bus|motorcycle|bicycle|pedestrian|other",
    "actor.is_emergency": "bool, from the blueprint's special type",
    "actor.emergency_lights_on": "bool, VehicleLightState Special1/Special2",
    "actor.lights.brake": "bool",
    "actor.lights.left_blinker": "bool",
    "actor.lights.right_blinker": "bool",
    "actor.speed_mps": "m/s; ABSENT in the scene-graph view (see extract_sg)",
    "actor.rel.longitudinal_m": "+ahead of ego",
    "actor.rel.lateral_m": "+to the ego's right",
    "actor.rel.centre_distance_m": "actor-origin to actor-origin, ground plane",
    "actor.rel.bumper_gap_m": "clear longitudinal space; negative means overlap",
    "actor.rel.lateral_gap_m": "clear lateral space, body to body",
    "actor.rel.heading_dot": "-1 head-on .. +1 same heading",
    "actor.rel.ahead": "bool",
    "actor.rel.oncoming": "bool",
    "actor.same_lane": "bool",
    "actor.opposing_lane": "bool",
    "actor.lane.is_junction": "bool",
    "actor.lane.junction_id": "OpenDRIVE junction id or null",
}


class Frame(object):
    """One tick of the fact track."""

    __slots__ = ("index", "t", "ego", "signal", "actors")

    def __init__(self, index, t, ego, signal, actors):
        # type: (int, float, dict, Optional[dict], List[dict]) -> None
        self.index = index
        self.t = t
        self.ego = ego
        self.signal = signal
        self.actors = actors

    def get(self, path, default=None):
        # type: (str, Any) -> Any
        """Dotted lookup against this frame, e.g. `ego.lane.is_junction`.

        Returns `default` for a path that does not exist *or* whose value is
        None. Callers that must distinguish "absent" from "false" ask the
        FactTrack's provenance instead; at expression-evaluation time an absent
        value is a missing value, and `reading.py` propagates it as UNKNOWN
        rather than as False, so a rule cannot be silently satisfied by a gap.
        """
        parts = path.split(".")
        if parts[0] == "ego":
            node = self.ego
        elif parts[0] == "signal":
            node = self.signal
        else:
            return default
        for key in parts[1:]:
            if not isinstance(node, dict) or key not in node:
                return default
            node = node[key]
        return default if node is None else node

    def as_dict(self):
        # type: () -> dict
        return {"index": self.index, "t": self.t, "ego": self.ego,
                "signal": self.signal, "actors": self.actors}


class FactTrack(object):
    """A capture's whole fact track, plus the provenance of every field in it."""

    def __init__(self, capture, fps, frames, provenance, meta=None):
        # type: (str, int, List[Frame], Dict[str, str], Optional[dict]) -> None
        self.capture = capture
        self.fps = fps
        self.frames = frames
        #: field path -> SIM | SG | DERIVED | ABSENT for THIS capture
        self.provenance = provenance
        self.meta = meta or {}

    def __len__(self):
        return len(self.frames)

    def __iter__(self):
        # type: () -> Iterator[Frame]
        return iter(self.frames)

    def duration_s(self):
        # type: () -> float
        return len(self.frames) / float(self.fps)

    def is_absent(self, path):
        # type: (str) -> bool
        """Whether this capture can supply a field at all.

        `reading.py` consults this before evaluating, so a rule that depends on
        an absent field is reported UNTESTABLE on this capture instead of
        quietly evaluating to compliant.
        """
        return self.provenance.get(path, ABSENT) == ABSENT

    def frames_to_seconds(self, n):
        # type: (int) -> float
        return n / float(self.fps)

    def seconds_to_frames(self, s):
        # type: (float) -> int
        return max(1, int(round(s * self.fps)))

    # ------------------------------------------------------------------ io

    def write(self, path):
        # type: (str) -> None
        with open(path, "w") as fd:
            fd.write(json.dumps({
                "schema_version": SCHEMA_VERSION,
                "capture": self.capture,
                "fps": self.fps,
                "provenance": self.provenance,
                "meta": self.meta,
            }, sort_keys=True) + "\n")
            for frame in self.frames:
                fd.write(json.dumps(frame.as_dict(), sort_keys=True) + "\n")

    @classmethod
    def read(cls, path):
        # type: (str) -> FactTrack
        with open(path) as fd:
            header = json.loads(fd.readline())
            if header.get("schema_version") != SCHEMA_VERSION:
                raise ValueError(
                    "%s was written against fact schema %s, this is %s; "
                    "re-extract rather than reading it, because a field may have "
                    "changed meaning" % (path, header.get("schema_version"),
                                         SCHEMA_VERSION))
            frames = []
            for line in fd:
                if not line.strip():
                    continue
                row = json.loads(line)
                frames.append(Frame(row["index"], row["t"], row["ego"],
                                    row.get("signal"), row.get("actors", [])))
        return cls(header["capture"], header["fps"], frames,
                   header["provenance"], header.get("meta"))


# --------------------------------------------------------------------------
# Derivations shared by every extractor
# --------------------------------------------------------------------------

def finite_difference_speed(positions, fps, window=1):
    # type: (List[tuple], int, int) -> List[float]
    """Ground-plane speed from consecutive positions.

    This exists because of a measured property of CARLA recorder replay, not as
    a convenience. The replayer *teleports* actors, so every dynamic field the
    server reports during a replay is identically zero: on the 962-frame
    SceneFlowLang `HazardAtSideLaneTwoWays` capture, `carla_speed` is 0.0 on
    every frame while the ego is plainly moving at 8 m/s. Differencing the
    positions the scene graph does record recovers it to within the sampling
    error of the window.

    Every capture derived from a recorder log — which is how any Leaderboard or
    Bench2Drive route reaches a scene graph — has this property. An evaluation
    that reads `carla_speed` from such a capture silently measures a stationary
    vehicle, and every speed clause comes out compliant.
    """
    n = len(positions)
    out = [0.0] * n
    if n < 2:
        return out
    for i in range(n):
        lo = max(0, i - window)
        hi = min(n - 1, i + window)
        if hi == lo:
            continue
        dx = positions[hi][0] - positions[lo][0]
        dy = positions[hi][1] - positions[lo][1]
        dt = (hi - lo) / float(fps)
        out[i] = math.hypot(dx, dy) / dt
    return out


def finite_difference(series, fps, window=1):
    # type: (List[float], int, int) -> List[float]
    """Signed time derivative of a scalar series, same windowing as above."""
    n = len(series)
    out = [0.0] * n
    if n < 2:
        return out
    for i in range(n):
        lo = max(0, i - window)
        hi = min(n - 1, i + window)
        if hi == lo:
            continue
        out[i] = (series[hi] - series[lo]) / ((hi - lo) / float(fps))
    return out


def unwrap_degrees(series):
    # type: (List[float]) -> List[float]
    """Make a yaw series continuous so its derivative is a real yaw rate.

    A vehicle crossing the +/-180 boundary otherwise shows a 360 deg/frame yaw
    rate, which reads as a violent swerve to any comfort or control rule.
    """
    if not series:
        return []
    out = [series[0]]
    for value in series[1:]:
        delta = value - out[-1]
        while delta > 180.0:
            delta -= 360.0
        while delta < -180.0:
            delta += 360.0
        out.append(out[-1] + delta)
    return out
