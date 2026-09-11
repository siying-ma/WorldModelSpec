"""L1 from the scene graph — *the monitor's view*.

This extractor deliberately produces a fact track that is WEAKER than the
simulator's. It reads only `carla_sgg.sgg_abstractor.process_to_junction_rsv`
output, which is exactly what a specification is evaluated over, so the gap
between this track and `extract_sim`'s is a direct, per-field measurement of what
the abstraction destroys.

That gap is the point. A rule that disagrees with ground truth because the
abstraction cannot see the fact it needs is a *perception* finding, not a
specification finding, and the two are billed to different owners. Running both
extractors over the same capture is what separates them without argument.

Measured properties of real `carla_sgg` output this file encodes
----------------------------------------------------------------
Verified against the 33-capture SceneFlowLang corpus (44,455 frames), not
assumed from the generator source:

* **No non-ego actor ever carries a velocity.** `copy_carla_actor_state` is
  called for the ego node only. Every other vehicle's node has `carla_id`,
  `carla_type_id`, `light_*` and geometry, and nothing else. `actor.speed_mps`
  is therefore ABSENT in this view, permanently, for every capture.

* **On any capture derived from a CARLA recorder log the EGO has no velocity
  either.** The replayer teleports actors, so `carla_speed` is 0.0 on all 962
  frames of `HazardAtSideLaneTwoWays` while the vehicle is plainly doing 8 m/s.
  This extractor detects an identically-zero velocity series and falls back to
  differencing `vertex`, which recovers it (8.22 m/s against the ego log's
  8.0-8.4). The fallback is recorded in the provenance as DERIVED so no reader
  mistakes it for a measurement.

* **`ego -isIn-> Lane` is one-to-many.** The ego's footprint overlaps several
  lane segment nodes at once (five, in the frame this was checked on). "Same
  lane" is therefore a set intersection, never an equality, and a rule written
  as equality silently never fires.

* **Posted controls are present and typed.** Traffic lights reach lanes by
  `controlsTrafficOf` and carry `light_state`; OpenDRIVE landmarks reach lanes
  by `mayAffect` and carry `landmark_type` (206 stop, 274 speed limit, 1000001
  signal) with `landmark_value`. A posted speed limit is therefore monitorable,
  which decides whether "unless a sign tells you otherwise" is expressible.

* **`landmark_unit` reads 'mph' on CARLA's speed-limit landmarks** while the
  towns are authored in km/h. The unit field is not trustworthy; the reading
  layer pins the interpretation and `SPEED_LIMIT_UNIT` below records which was
  chosen, so the choice is visible rather than buried in an arithmetic.
"""

from __future__ import annotations

import glob
import json
import math
import os
import pickle
import re
from typing import Any, Dict, List, Optional, Tuple

from .facts import (ABSENT, DERIVED, SG, SIM, FactTrack, Frame,
                    finite_difference, finite_difference_speed, unwrap_degrees)

#: CARLA authors its towns in km/h and exports the landmark unit as 'mph'.
#: Treating the value as km/h is the reading this project takes; changing it
#: changes every speed verdict, so it is a named constant and not a literal.
SPEED_LIMIT_UNIT = "kph"

LANE_RE = re.compile(r"^Lane (\d+)_([+-])(\d+)$")
ROAD_RE = re.compile(r"^Road (\d+)$")
JUNCTION_RE = re.compile(r"^Junction (-?\d+)$")

LM_STOP = "206"
LM_SPEED_LIMIT = "274"
LM_SIGNAL = "1000001"
LM_YIELD = "205"

#: SGG base classes mapped onto the fact schema's actor vocabulary.
ACTOR_CLASSES = {
    "car": "car", "truck": "truck", "van": "van", "bus": "bus",
    "motorcycle": "motorcycle", "bicycle": "bicycle", "person": "pedestrian",
    "vehicle": "car",
}


def _name(node):
    return str(node)


def _attr(node):
    return getattr(node, "attr", {}) or {}


def _base(node):
    return getattr(node, "base_class", None)


def _vertex(node):
    v = _attr(node).get("vertex")
    if v is None:
        return None
    return (float(v[0]), float(v[1]))


def _yaw_from_forward(node):
    f = _attr(node).get("forward")
    if f is None:
        return None
    return math.degrees(math.atan2(float(f[1]), float(f[0])))


def _lane_ids(lane_name):
    # type: (str) -> Optional[Tuple[int, int]]
    m = LANE_RE.match(lane_name)
    if not m:
        return None
    road = int(m.group(1))
    lane = int(m.group(3)) * (1 if m.group(2) == "+" else -1)
    return road, lane


class _FrameView(object):
    """Indexes one pickled RSV graph so the extractor reads it once."""

    def __init__(self, graph):
        self.g = graph
        self.ego = None
        self.by_name = {}
        for node in graph.nodes:
            self.by_name[_name(node)] = node
            if _name(node) == "ego":
                self.ego = node
        self.out = {}
        self.inc = {}
        for u, v, data in graph.edges(data=True):
            self.out.setdefault(_name(u), []).append((data.get("label"), v))
            self.inc.setdefault(_name(v), []).append((data.get("label"), u))

    def targets(self, node, label):
        return [v for lbl, v in self.out.get(_name(node), []) if lbl == label]

    def sources(self, node, label):
        return [u for lbl, u in self.inc.get(_name(node), []) if lbl == label]

    def lanes_of(self, node):
        """Every lane node an entity `isIn`. One-to-many for the ego."""
        return [v for v in self.targets(node, "isIn")
                if LANE_RE.match(_name(v))]

    def road_of_lane(self, lane):
        for v in self.targets(lane, "isIn"):
            if ROAD_RE.match(_name(v)):
                return v
        return None

    def junction_of_road(self, road):
        if road is None:
            return None
        for v in self.targets(road, "isIn"):
            if JUNCTION_RE.match(_name(v)):
                return v
        return None


def _ego_lane_facts(view):
    # type: (_FrameView) -> dict
    lanes = view.lanes_of(view.ego) if view.ego is not None else []
    if not lanes:
        return {"on_road": False, "road_id": None, "lane_id": None,
                "junction_id": None, "is_junction": False,
                "lanes_to_right": None, "lanes_to_left": None,
                "width_m": None, "type": "none"}
    # The ego straddles several lane segments; the governing one is the lane it
    # shares with the largest number of its own segments, which is the lane its
    # centre is in. Ties break on the lowest |lane_id|, i.e. nearest the centre
    # line, matching how OpenDRIVE numbers outward.
    counts = {}
    for lane in lanes:
        ids = _lane_ids(_name(lane))
        if ids:
            counts[ids] = counts.get(ids, 0) + 1
    if not counts:
        return {"on_road": False, "road_id": None, "lane_id": None,
                "junction_id": None, "is_junction": False,
                "lanes_to_right": None, "lanes_to_left": None,
                "width_m": None, "type": "none"}
    (road_id, lane_id) = sorted(counts.items(),
                                key=lambda kv: (-kv[1], abs(kv[0][1])))[0][0]

    lane_node = None
    for lane in lanes:
        if _lane_ids(_name(lane)) == (road_id, lane_id):
            lane_node = lane
            break
    road = view.road_of_lane(lane_node) if lane_node is not None else None
    junction = view.junction_of_road(road)
    junction_id = None
    if junction is not None:
        m = JUNCTION_RE.match(_name(junction))
        if m and int(m.group(1)) != -1:
            junction_id = int(m.group(1))

    # `toRightOf` / `toLeftOf` hold between lane nodes of one road. Counting
    # same-direction neighbours gives the ego's position across the carriageway.
    right = left = 0
    if lane_node is not None:
        for other in view.sources(lane_node, "toRightOf"):
            ids = _lane_ids(_name(other))
            if ids and ids[1] * lane_id > 0:
                right += 1
        for other in view.sources(lane_node, "toLeftOf"):
            ids = _lane_ids(_name(other))
            if ids and ids[1] * lane_id > 0:
                left += 1
    return {"on_road": True, "road_id": road_id, "lane_id": lane_id,
            "junction_id": junction_id, "is_junction": junction_id is not None,
            "lanes_to_right": right, "lanes_to_left": left,
            "width_m": None, "type": "driving"}


def _posted(view, ego_lane_nodes, ego_xy):
    # type: (_FrameView, list, Optional[tuple]) -> dict
    """Landmarks that `mayAffect` a lane the ego is in."""
    out = {"speed_limit_kph": None, "stop_ahead_m": None,
           "yield_ahead_m": None, "signal_ahead_m": None,
           "crosswalk_ahead_m": None, "no_passing": None, "one_way": None}
    lane_names = set(_name(l) for l in ego_lane_nodes)
    for node in view.g.nodes:
        attr = _attr(node)
        lm_type = attr.get("landmark_type")
        if lm_type is None:
            continue
        affected = set(_name(v) for v in view.targets(node, "mayAffect"))
        affected |= set(_name(v) for v in view.targets(node, "isIn"))
        if not (affected & lane_names):
            continue
        distance = None
        if ego_xy is not None:
            xy = _vertex(node)
            if xy is not None:
                distance = math.hypot(xy[0] - ego_xy[0], xy[1] - ego_xy[1])
        if lm_type == LM_SPEED_LIMIT:
            value = attr.get("landmark_value")
            if value is not None and value > 0:
                out["speed_limit_kph"] = float(value)
        elif lm_type == LM_STOP:
            if distance is not None and (out["stop_ahead_m"] is None
                                         or distance < out["stop_ahead_m"]):
                out["stop_ahead_m"] = distance
        elif lm_type == LM_YIELD:
            if distance is not None and (out["yield_ahead_m"] is None
                                         or distance < out["yield_ahead_m"]):
                out["yield_ahead_m"] = distance
        elif lm_type == LM_SIGNAL:
            if distance is not None and (out["signal_ahead_m"] is None
                                         or distance < out["signal_ahead_m"]):
                out["signal_ahead_m"] = distance
    return out


def _signal(view, ego_lane_nodes, ego_xy):
    lane_names = set(_name(l) for l in ego_lane_nodes)
    best = None
    for node in view.g.nodes:
        if _base(node) != "traffic_light":
            continue
        controls = set(_name(v) for v in view.targets(node, "controlsTrafficOf"))
        if not (controls & lane_names):
            continue
        distance = None
        xy = _vertex(node)
        if xy is not None and ego_xy is not None:
            distance = math.hypot(xy[0] - ego_xy[0], xy[1] - ego_xy[1])
        state = _attr(node).get("light_state")
        if best is None or (distance is not None
                            and (best["distance_m"] is None
                                 or distance < best["distance_m"])):
            best = {"state": str(state) if state is not None else None,
                    "distance_m": distance, "governs_ego_lane": True}
    return best


def _actors(view, ego_xy, ego_yaw_deg, ego_lane_nodes):
    if ego_xy is None or ego_yaw_deg is None:
        return []
    fx = math.cos(math.radians(ego_yaw_deg))
    fy = math.sin(math.radians(ego_yaw_deg))
    ego_lane_names = set(_name(l) for l in ego_lane_nodes)
    opposing = set()
    for lane in ego_lane_nodes:
        opposing |= set(_name(v) for v in view.targets(lane, "opposes"))

    rows = []
    for node in view.g.nodes:
        cls = ACTOR_CLASSES.get(_base(node))
        if cls is None or _name(node) == "ego":
            continue
        xy = _vertex(node)
        if xy is None:
            continue
        dx, dy = xy[0] - ego_xy[0], xy[1] - ego_xy[1]
        longitudinal = dx * fx + dy * fy
        lateral = -dx * fy + dy * fx
        centre = math.hypot(dx, dy)
        yaw = _yaw_from_forward(node)
        if yaw is None:
            heading_dot = None
        else:
            heading_dot = fx * math.cos(math.radians(yaw)) + fy * math.sin(
                math.radians(yaw))
        attr = _attr(node)
        lanes = view.lanes_of(node)
        lane_names = set(_name(l) for l in lanes)
        junction_id = None
        is_junction = False
        for lane in lanes:
            junction = view.junction_of_road(view.road_of_lane(lane))
            if junction is not None:
                m = JUNCTION_RE.match(_name(junction))
                if m and int(m.group(1)) != -1:
                    junction_id = int(m.group(1))
                    is_junction = True
                    break
        rows.append({
            "id": attr.get("carla_id"),
            "cls": cls,
            "is_emergency": attr.get("special_class") == "emergency",
            "emergency_lights_on": bool(attr.get("light_Special1")
                                        or attr.get("light_Special2")),
            "lights": {"brake": bool(attr.get("light_Brake")),
                       "left_blinker": bool(attr.get("light_LeftBlinker")),
                       "right_blinker": bool(attr.get("light_RightBlinker"))},
            "speed_mps": None,      # never present in the abstraction
            "rel": {"longitudinal_m": longitudinal, "lateral_m": lateral,
                    "centre_distance_m": centre,
                    "bumper_gap_m": None, "lateral_gap_m": None,
                    "heading_dot": heading_dot,
                    "ahead": longitudinal > 0.0,
                    "oncoming": None if heading_dot is None else heading_dot < 0.0},
            "same_lane": bool(lane_names & ego_lane_names),
            "opposing_lane": bool(lane_names & opposing),
            "lane": {"is_junction": is_junction, "junction_id": junction_id},
        })
    rows.sort(key=lambda r: r["rel"]["centre_distance_m"])
    return rows


#: A vehicle further ahead than this is not "the vehicle in front" in the sense
#: any following-distance clause means. [reading]
LEAD_HORIZON_M = 60.0
#: Below this the ego is not following anything; a headway computed from a
#: near-zero speed is arbitrarily large and would read as compliant. [reading]
LEAD_MIN_SPEED_MPS = 1.0


def resolve_lead(actors, ego_speed_mps):
    # type: (List[dict], float) -> dict
    """The vehicle the ego is following, and the headway to it.

    Nearest same-lane, same-heading vehicle ahead. Pedestrians are excluded:
    every following-distance clause in the statute says "vehicle".

    `headway_s` is the gap divided by the ego's own speed, which is the quantity
    a two-second rule names. It is left null below `LEAD_MIN_SPEED_MPS` rather
    than reported as a huge number, because a stopped car is not keeping a large
    following distance -- it is not following -- and a null propagates as
    UNKNOWN through the reading rather than as compliance.
    """
    blank = {"present": False, "gap_m": None, "bumper_gap_m": None,
             "headway_s": None, "closing_mps": None, "brake_light": None}
    candidates = [a for a in actors
                  if a["same_lane"] and a["rel"]["ahead"]
                  and a["cls"] != "pedestrian"
                  and a["rel"]["heading_dot"] is not None
                  and a["rel"]["heading_dot"] > 0.0
                  and a["rel"]["centre_distance_m"] <= LEAD_HORIZON_M]
    if not candidates:
        return blank
    lead = min(candidates, key=lambda a: a["rel"]["longitudinal_m"])
    gap = lead["rel"]["centre_distance_m"]
    bumper = lead["rel"]["bumper_gap_m"]
    reference = bumper if bumper is not None else gap
    headway = (reference / ego_speed_mps
               if ego_speed_mps and ego_speed_mps >= LEAD_MIN_SPEED_MPS
               else None)
    closing = None
    if lead["speed_mps"] is not None and ego_speed_mps is not None:
        closing = ego_speed_mps - lead["speed_mps"]
    return {"present": True, "gap_m": gap, "bumper_gap_m": bumper,
            "headway_s": headway, "closing_mps": closing,
            "brake_light": lead["lights"]["brake"]}


#: What this view can and cannot supply. ABSENT entries are the abstraction's
#: measured losses, and every one of them makes some family of obligations
#: unmonitorable — which is a result, not a defect to paper over.
SG_PROVENANCE = {
    "ego.x": SG, "ego.y": SG, "ego.yaw_deg": SG,
    "ego.speed_mps": SG, "ego.speed_kph": SG,
    "ego.accel_mps2": DERIVED, "ego.yaw_rate_dps": DERIVED,
    "ego.throttle": SG, "ego.brake": SG, "ego.steer": SG,
    "ego.hand_brake": SG, "ego.reverse": SG,
    "ego.lane.on_road": SG, "ego.lane.road_id": SG, "ego.lane.lane_id": SG,
    "ego.lane.junction_id": SG, "ego.lane.is_junction": SG,
    "ego.lane.lanes_to_right": SG, "ego.lane.lanes_to_left": SG,
    # No lane heading is exposed, so "is the ego facing against the lane's own
    # direction" cannot be answered. Every wrong-way clause is unmonitorable
    # from this abstraction.
    "ego.lane.wrong_way": ABSENT,
    "ego.lane.width_m": ABSENT,
    "ego.lane.curvature": ABSENT,
    "ego.lane.type": SG,
    "ego.posted.speed_limit_kph": SG,
    "ego.posted.stop_ahead_m": SG,
    "ego.posted.yield_ahead_m": SG,
    "ego.posted.signal_ahead_m": SG,
    "ego.posted.crosswalk_ahead_m": ABSENT,
    "ego.posted.no_passing": ABSENT,
    "ego.posted.one_way": ABSENT,
    "signal.state": SG, "signal.distance_m": SG, "signal.governs_ego_lane": SG,
    "actor.cls": SG, "actor.is_emergency": SG,
    "actor.emergency_lights_on": SG,
    "actor.lights.brake": SG, "actor.lights.left_blinker": SG,
    "actor.lights.right_blinker": SG,
    # Measured: `copy_carla_actor_state` runs for the ego node only.
    "actor.speed_mps": ABSENT,
    "actor.rel.longitudinal_m": SG, "actor.rel.lateral_m": SG,
    "actor.rel.centre_distance_m": SG,
    # `threedbbox` is not carried onto RSV nodes, so no body-to-body clearance
    # is computable. Every "within N metres of the vehicle in front" clause is
    # measured centre-to-centre here and means something ~4.7 m looser.
    "actor.rel.bumper_gap_m": ABSENT,
    "actor.rel.lateral_gap_m": ABSENT,
    "actor.rel.heading_dot": SG, "actor.rel.ahead": SG,
    "actor.rel.oncoming": SG,
    "actor.same_lane": SG, "actor.opposing_lane": SG,
    "actor.lane.is_junction": SG, "actor.lane.junction_id": SG,
    "ego.lead.present": DERIVED, "ego.lead.gap_m": DERIVED,
    "ego.lead.headway_s": DERIVED, "ego.lead.brake_light": SG,
    # Both need something the abstraction does not carry: a body-to-body
    # clearance needs `threedbbox`, a closing speed needs the lead's velocity.
    "ego.lead.bumper_gap_m": ABSENT,
    "ego.lead.closing_mps": ABSENT,
}


#: A frame counts as "moving" when consecutive positions imply at least this
#: speed. Well above replay's settling noise and well below any real driving.
MOVING_MPS = 0.5
#: A reported speed below this counts as "the server says stationary".
STATIONARY_MPS = 0.1
#: Fraction of moving frames that must report stationary before the capture is
#: called a replay.
REPLAY_FRACTION = 0.95


def detect_replay(positions, reported_speed, fps):
    # type: (List[tuple], List[float], int) -> bool
    """Is this capture derived from a CARLA recorder log?

    A replay teleports actors, so the server reports no velocity while the
    positions plainly advance. The test is the *fraction* of moving frames that
    report stationary, not an exact-zero check: on the 962-frame
    `HazardAtSideLaneTwoWays` capture the last 8 frames carry settling noise of
    around 0.003 m/s, which an `all(speed == 0)` test reads as a live capture
    and then trusts 954 frames of zeros. Measured here: 882 of 882 moving frames
    report stationary, so the fraction is 1.000 and the threshold has wide
    margin either way.
    """
    if len(positions) < 2:
        return False
    moving = []
    for i in range(len(positions) - 1):
        ax, ay = positions[i]
        bx, by = positions[i + 1]
        if math.hypot(bx - ax, by - ay) * fps >= MOVING_MPS:
            moving.append(i)
    if not moving:
        return False
    stationary = sum(1 for i in moving
                     if abs(reported_speed[i]) < STATIONARY_MPS)
    return stationary / float(len(moving)) >= REPLAY_FRACTION


#: Frames to search either way when aligning an ego log to the scene graphs.
MAX_LOG_LAG_FRAMES = 25


def estimate_log_lag(sg_speeds, log_speeds, max_lag=MAX_LOG_LAG_FRAMES):
    # type: (List[float], List[float], int) -> Tuple[int, float, float]
    """Find the frame offset that aligns an ego log to the scene-graph frames.

    Returns `(lag, aligned_mean_abs_error, unaligned_mean_abs_error)`, where the
    log record for scene-graph frame `i` is `log[i + lag]`.

    **This is not a tuning knob, it is a correction for a real offset.** The
    leaderboard's agent log runs ahead of the CARLA recorder by a fixed number
    of ticks; `capture_sensor_data.py` names the constant `AGENT_TICK_DELAY = 10`
    and compensates by prepending ten zero records. Corpora that did not get
    that treatment are off by exactly that much, and pairing scene-graph frame
    `i` with log record `i` then evaluates every rule that mixes the two sources
    on data half a second apart.

    Measured on all three logged SceneFlowLang captures, independently:

        capture                         frames  lag0 err   best lag   err
        HazardAtSideLaneTwoWays           962    0.683      +10      0.039
        OppositeVehicleTakingPriority     464    1.173      +10      0.057
        VehicleTurningRoute_left          812    1.028      +10      0.045

    Three for three at +10, and the residual after alignment is 0.04-0.06 m/s,
    which is the discretisation of a one-frame finite difference. The offset is
    systematic, not a fit.
    """
    best = (0, float("inf"))
    unaligned = None
    for lag in range(-max_lag, max_lag + 1):
        errors = [abs(sg_speeds[i] - log_speeds[i + lag])
                  for i in range(len(sg_speeds))
                  if 0 <= i + lag < len(log_speeds)]
        if not errors:
            continue
        mean = sum(errors) / len(errors)
        if lag == 0:
            unaligned = mean
        if mean < best[1]:
            best = (lag, mean)
    return best[0], best[1], (unaligned if unaligned is not None else float("nan"))


def fuse_ego_log(track, ego_log_path, align=True):
    # type: (FactTrack, str, bool) -> FactTrack
    """Restore ego dynamics from a leaderboard agent log, correctly aligned.

    A replayed capture has no dynamics in the scene graph at all. The agent log
    is the only record of what the driver actually did, so a monitor evaluated
    on control inputs cannot be scored without it. Fusing it upgrades the
    provenance of the control fields from ABSENT to SIM and records the lag that
    was applied, so a later reader can tell an aligned track from a raw one.
    """
    with open(ego_log_path) as fd:
        records = json.load(fd).get("records", [])
    if not records:
        raise IOError("%s has no records" % ego_log_path)

    sg_speeds = [f.ego["speed_mps"] for f in track.frames]
    log_speeds = [r["state"]["velocity"]["value"] for r in records]
    lag, aligned_err, unaligned_err = (
        estimate_log_lag(sg_speeds, log_speeds) if align else (0, 0.0, 0.0))

    for i, frame in enumerate(track.frames):
        j = i + lag
        if not (0 <= j < len(records)):
            continue
        record = records[j]
        state, control = record["state"], record["control"]
        frame.ego["speed_mps"] = state["velocity"]["value"]
        frame.ego["speed_kph"] = state["velocity"]["value"] * 3.6
        frame.ego["accel_mps2"] = state.get("acceleration", {}).get("value")
        frame.ego["throttle"] = control.get("throttle")
        frame.ego["brake"] = control.get("brake")
        frame.ego["steer"] = control.get("steer")
        frame.ego["hand_brake"] = control.get("hand_brake")
        frame.ego["reverse"] = control.get("reverse")

    for key in ("ego.speed_mps", "ego.speed_kph", "ego.accel_mps2",
                "ego.throttle", "ego.brake", "ego.steer", "ego.hand_brake",
                "ego.reverse"):
        track.provenance[key] = SIM
    track.meta["ego_log"] = ego_log_path
    track.meta["ego_log_lag_frames"] = lag
    track.meta["ego_log_mean_abs_err_mps"] = round(aligned_err, 4)
    track.meta["ego_log_unaligned_err_mps"] = round(unaligned_err, 4)
    track.meta["speed_source"] = "ego_log(aligned %+d frames)" % lag
    return track


def extract(rsv_dir, capture=None, fps=20, limit=None):
    # type: (str, Optional[str], int, Optional[int]) -> FactTrack
    """Build a fact track from a directory of `process_to_junction_rsv` pickles."""
    paths = glob.glob(os.path.join(rsv_dir, "*.pkl"))
    if not paths:
        raise IOError("no .pkl frames in %s" % rsv_dir)
    paths.sort(key=lambda p: int(os.path.splitext(os.path.basename(p))[0]))
    if limit:
        paths = paths[:limit]

    views = []
    for path in paths:
        with open(path, "rb") as fd:
            views.append(_FrameView(pickle.load(fd)))

    positions = []
    yaws = []
    reported_speed = []
    for view in views:
        if view.ego is None:
            positions.append(positions[-1] if positions else (0.0, 0.0))
            yaws.append(yaws[-1] if yaws else 0.0)
            reported_speed.append(0.0)
            continue
        positions.append(_vertex(view.ego) or (0.0, 0.0))
        yaws.append(_yaw_from_forward(view.ego) or 0.0)
        reported_speed.append(float(_attr(view.ego).get("carla_speed") or 0.0))

    provenance = dict(SG_PROVENANCE)
    replayed = detect_replay(positions, reported_speed, fps)
    if replayed:
        speeds = finite_difference_speed(positions, fps, window=2)
        provenance["ego.speed_mps"] = DERIVED
        provenance["ego.speed_kph"] = DERIVED
        # CONTROL SURVIVES REPLAY, dynamics do not. Measured: on the replayed
        # `HazardAtSideLaneTwoWays` capture `carla_throttle` takes 0.8 and
        # `carla_brake` 0.3/0.097/0.071 across frames while `carla_speed`,
        # `carla_vel_*` and `carla_acc_*` are identically zero. CARLA's replayer
        # restores each actor's VehicleControl but teleports its transform
        # instead of integrating physics, so `get_velocity()` has nothing to
        # report and `get_control()` does. Marking control ABSENT here would
        # discard a channel that is present and correct.
        provenance["ego.accel_mps2"] = DERIVED
    else:
        speeds = reported_speed

    accels = finite_difference(speeds, fps, window=2)
    yaw_rates = finite_difference(unwrap_degrees(yaws), fps, window=2)

    frames = []
    for i, view in enumerate(views):
        lane_nodes = view.lanes_of(view.ego) if view.ego is not None else []
        attr = _attr(view.ego) if view.ego is not None else {}
        ego = {
            "x": positions[i][0], "y": positions[i][1], "yaw_deg": yaws[i],
            "speed_mps": speeds[i], "speed_kph": speeds[i] * 3.6,
            "accel_mps2": accels[i], "yaw_rate_dps": yaw_rates[i],
            "throttle": attr.get("carla_throttle"),
            "brake": attr.get("carla_brake"),
            "steer": attr.get("carla_steer"),
            "hand_brake": attr.get("carla_hand_brake"),
            "reverse": attr.get("carla_reverse"),
            "lane": _ego_lane_facts(view),
            "posted": _posted(view, lane_nodes, positions[i]),
        }
        actors = _actors(view, positions[i], yaws[i], lane_nodes)
        ego["lead"] = resolve_lead(actors, speeds[i])
        ego["lane"]["wrong_way"] = None
        ego["lane"]["curvature"] = None
        frames.append(Frame(
            index=i, t=i / float(fps), ego=ego,
            signal=_signal(view, lane_nodes, positions[i]),
            actors=actors))

    return FactTrack(
        capture=capture or os.path.basename(os.path.dirname(rsv_dir.rstrip("/"))),
        fps=fps, frames=frames, provenance=provenance,
        meta={"view": "scene_graph", "rsv_dir": rsv_dir,
              "replay_detected": replayed,
              "speed_source": "finite_difference(vertex)" if replayed
                              else "carla_speed",
              "speed_limit_unit_assumed": SPEED_LIMIT_UNIT})
