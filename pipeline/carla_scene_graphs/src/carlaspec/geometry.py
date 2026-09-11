"""Geometric and map queries used by the ground-truth oracle.

Everything here reads the **CARLA server** — actor transforms, bounding boxes and
the OpenDRIVE map — and nothing here reads a scene graph. That separation is the
whole point: the oracle must be able to disagree with the abstraction the Lean
specifications are evaluated over, otherwise `monitor` compares the pipeline
against itself.

Two distance notions are recorded for every actor pair, and they are not
interchangeable:

* **centre distance** — plane-projected Euclidean distance between actor
  origins. This is what `carla_sgg.sgg_abstractor` bins into its proximity bands
  (`safety_hazard` <= 2 m, `near_coll` <= 4 m, ...), so it is what a Lean rule
  written with `Pred.withinMetres` actually tests.
* **bumper gap** — centre distance minus both half-lengths along the ego's
  forward axis, i.e. the clear space between the vehicles. This is what a statute
  means by "within four metres of the vehicle it is following".

For two ~4.7 m cars those differ by roughly 4.7 m, which is larger than the
threshold in the following-distance law. Recording both is what lets the report
say *why* a rule and the footage disagree instead of just that they do.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, asdict
from typing import Optional

import carla


def unit_forward(transform: carla.Transform) -> tuple[float, float]:
    """The transform's forward vector, plane-projected and normalised."""
    yaw = math.radians(transform.rotation.yaw)
    return (math.cos(yaw), math.sin(yaw))


def plane_distance(a: carla.Location, b: carla.Location) -> float:
    """Distance in the XY plane, matching `carla_sgg.utils.get_distance`, which
    projects onto the plane before taking the norm."""
    return math.hypot(a.x - b.x, a.y - b.y)


def half_length(actor: carla.Actor) -> float:
    """Half the actor's extent along its own forward axis."""
    try:
        return float(actor.bounding_box.extent.x)
    except (AttributeError, RuntimeError):
        return 0.0


@dataclass
class Relative:
    """Where `other` sits in the ego's own frame."""

    longitudinal: float   # +ahead of ego, -behind
    lateral: float        # +to the ego's right (CARLA is left-handed in yaw)
    centre_distance: float
    bumper_gap: float     # clear space; negative means the boxes overlap
    heading_dot: float    # +1 same heading, -1 head-on
    ahead: bool
    oncoming: bool        # headings differ by more than 90 degrees

    def as_dict(self) -> dict:
        return asdict(self)


def relative_to(ego: carla.Actor, other: carla.Actor) -> Relative:
    ego_tf, other_tf = ego.get_transform(), other.get_transform()
    fx, fy = unit_forward(ego_tf)
    dx = other_tf.location.x - ego_tf.location.x
    dy = other_tf.location.y - ego_tf.location.y

    longitudinal = dx * fx + dy * fy
    # Right-hand normal of (fx, fy) under CARLA's left-handed yaw convention.
    lateral = -dx * fy + dy * fx
    centre = math.hypot(dx, dy)

    ox, oy = unit_forward(other_tf)
    heading_dot = fx * ox + fy * oy

    gap = abs(longitudinal) - (half_length(ego) + half_length(other))

    return Relative(
        longitudinal=longitudinal,
        lateral=lateral,
        centre_distance=centre,
        bumper_gap=gap,
        heading_dot=heading_dot,
        ahead=longitudinal > 0.0,
        oncoming=heading_dot < 0.0,
    )


@dataclass
class LaneInfo:
    """The ego's position in the road network, from OpenDRIVE.

    `on_road` is False when the actor's location does not project onto any lane
    at all without snapping, which is the honest reading of "off the roadway".
    Every other field is then taken from the nearest projected waypoint and is
    advisory.
    """

    on_road: bool
    road_id: Optional[int]
    lane_id: Optional[int]
    section_id: Optional[int]
    is_junction: bool
    junction_id: Optional[int]
    has_driving_lane_to_right: bool
    has_driving_lane_to_left: bool
    wrong_way: bool
    lane_width: Optional[float]

    def as_dict(self) -> dict:
        return asdict(self)


def _same_direction_driving(wp: carla.Waypoint,
                            neighbour: Optional[carla.Waypoint]) -> bool:
    """A neighbouring lane counts only if it is a driving lane carrying traffic
    the same way. In OpenDRIVE, same-direction lanes share the sign of their id.
    """
    if neighbour is None:
        return False
    if neighbour.lane_type != carla.LaneType.Driving:
        return False
    return neighbour.lane_id * wp.lane_id > 0


def lane_info(carla_map: carla.Map, actor: carla.Actor) -> LaneInfo:
    location = actor.get_location()

    exact = carla_map.get_waypoint(location, project_to_road=False,
                                   lane_type=carla.LaneType.Driving)
    wp = exact or carla_map.get_waypoint(location, project_to_road=True,
                                         lane_type=carla.LaneType.Driving)
    if wp is None:
        return LaneInfo(False, None, None, None, False, None,
                        False, False, False, None)

    ax, ay = unit_forward(actor.get_transform())
    wx, wy = unit_forward(wp.transform)

    return LaneInfo(
        on_road=exact is not None,
        road_id=int(wp.road_id),
        lane_id=int(wp.lane_id),
        section_id=int(wp.section_id),
        is_junction=bool(wp.is_junction),
        junction_id=int(wp.junction_id) if wp.is_junction else None,
        has_driving_lane_to_right=_same_direction_driving(wp, wp.get_right_lane()),
        has_driving_lane_to_left=_same_direction_driving(wp, wp.get_left_lane()),
        wrong_way=(ax * wx + ay * wy) < 0.0,
        lane_width=float(wp.lane_width),
    )


def same_lane(a: LaneInfo, b: LaneInfo) -> bool:
    """Both actors occupy one lane of one road.

    Junction-internal lanes are excluded from the road/lane comparison because
    CARLA renumbers them per connecting road; two vehicles inside one junction
    are compared by junction id instead.
    """
    if a.is_junction and b.is_junction:
        return a.junction_id is not None and a.junction_id == b.junction_id
    if a.is_junction or b.is_junction:
        return False
    return (a.road_id is not None
            and a.road_id == b.road_id
            and a.lane_id == b.lane_id)


def opposing_lane(a: LaneInfo, b: LaneInfo) -> bool:
    """Same road, lane ids of opposite sign — the two carriageways."""
    if a.road_id is None or a.road_id != b.road_id:
        return False
    if a.lane_id is None or b.lane_id is None:
        return False
    return a.lane_id * b.lane_id < 0


def distance_to_landmarks(wp: carla.Waypoint, lookahead: float,
                          opendrive_type: str) -> Optional[float]:
    """Distance along the lane to the next landmark of an OpenDRIVE type.

    Type "206" is a stop sign and "1000001" is a traffic light in CARLA's
    OpenDRIVE export. Landmarks are the map's own sign records, so this answers
    "is a stop sign posted for the lane I am in" without needing to guess from
    an actor's trigger volume.
    """
    try:
        landmarks = wp.get_landmarks_of_type(lookahead, opendrive_type)
    except RuntimeError:
        return None
    if not landmarks:
        return None
    return min(float(lm.distance) for lm in landmarks)
