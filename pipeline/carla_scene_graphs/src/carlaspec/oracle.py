"""Per-tick ground truth, read from the CARLA server.

One record per captured frame, written to `oracle.jsonl` alongside the scene
graphs. `labeler.py` turns this into the per-law label file that
`traffic-spec-agent`'s `monitor` diffs its verdicts against.

**Why this exists.** The label file is the only check in the spec pipeline that
is independent of the agent that wrote the specification. A label asserted from
"the script set `ignore_lights_percentage=100`, therefore the ego ran a red
light" is not independent enough: it does not know whether the ego ever reached
a signalized junction, nor whether the signal was red rather than green when it
did. This module answers those questions from the simulator's own state —
`ego.get_traffic_light().get_state()`, `waypoint.is_junction`, actor transforms
and bounding boxes — none of which pass through `carla_sgg` or through Lean.

**What is deliberately NOT recorded here.** Anything derived from the scene
graph. If the abstraction drops a relation the oracle can see, that gap must
show up as a disagreement in the report, not be quietly reconciled here.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable, Optional

import carla

from .geometry import (
    LaneInfo,
    Relative,
    distance_to_landmarks,
    lane_info,
    opposing_lane,
    plane_distance,
    relative_to,
    same_lane,
)

# OpenDRIVE signal types, as exported by CARLA's maps.
OPENDRIVE_STOP_SIGN = "206"

# How far ahead to look for a posted stop sign governing the ego's lane.
STOP_SIGN_LOOKAHEAD_M = 40.0

# Blueprint ids CARLA gives emergency vehicles, matching
# `carla_sgg.actors.SPECIAL_TYPE_MAP` entries whose value is 'emergency'.
EMERGENCY_BLUEPRINTS = frozenset({
    "vehicle.dodge.charger_police",
    "vehicle.dodge.charger_police_2020",
    "vehicle.dodge_charger.police",
    "vehicle.carlamotors.firetruck",
    "vehicle.ford.ambulance",
})

# Base classes that `carla_sgg.sgg_abstractor.DEFAULT_PROXIMITY_RELATIONS` will
# actually emit a proximity edge for. A vehicle outside this set is invisible to
# every distance-based rule no matter how close it gets — the ambulance is a
# `van` and lands here, which is why the emergency scenarios use a police car.
PROXIMITY_VISIBLE_BASE_CLASSES = frozenset({
    "person", "bicycle", "car", "motorcycle", "bus", "truck",
})

# Copied from `carla_sgg.actors.BASE_TYPE_MAP` for the blueprints the scenarios
# spawn; anything unlisted falls back to "car", which is what the generator does
# for most four-wheeled blueprints.
_BASE_CLASS_OVERRIDES = {
    "vehicle.ford.ambulance": "van",
    "vehicle.mercedes.sprinter": "van",
    "vehicle.volkswagen.t2": "van",
    "vehicle.volkswagen.t2_2021": "van",
    "vehicle.carlamotors.firetruck": "truck",
    "vehicle.carlamotors.carlacola": "truck",
    "vehicle.tesla.cybertruck": "truck",
    "vehicle.mitsubishi.fusorosa": "bus",
    "vehicle.harley-davidson.low_rider": "motorcycle",
    "vehicle.kawasaki.ninja": "motorcycle",
    "vehicle.yamaha.yzf": "motorcycle",
    "vehicle.vespa.zx125": "motorcycle",
    "vehicle.bh.crossbike": "bicycle",
    "vehicle.diamondback.century": "bicycle",
    "vehicle.gazelle.omafiets": "bicycle",
}


def base_class_of(type_id: str) -> str:
    if type_id in _BASE_CLASS_OVERRIDES:
        return _BASE_CLASS_OVERRIDES[type_id]
    if type_id.startswith("walker."):
        return "person"
    return "car"


def _light_state_flags(actor: carla.Actor) -> dict:
    """Vehicle light booleans, the only dynamic evidence the abstraction keeps
    about a non-ego vehicle. CARLA leaves these off unless something sets them,
    which is why the runner enables `TrafficManager.update_vehicle_lights`."""
    try:
        state = actor.get_light_state()
    except (AttributeError, RuntimeError):
        return {}
    return {
        "brake": bool(state & carla.VehicleLightState.Brake),
        "left_blinker": bool(state & carla.VehicleLightState.LeftBlinker),
        "right_blinker": bool(state & carla.VehicleLightState.RightBlinker),
    }


class OracleRecorder:
    """Builds one ground-truth record per tick."""

    def __init__(self, world: carla.World, ego: carla.Actor,
                 fps: int, proximity_radius: float = 60.0):
        self.world = world
        self.ego = ego
        self.fps = fps
        self.carla_map = world.get_map()
        self.proximity_radius = proximity_radius
        self.records: list[dict] = []
        self._lights_by_lane = self._index_lights()

    def _index_lights(self) -> dict[tuple[int, int], carla.TrafficLight]:
        """Map each approach lane to the light that stops traffic in it.

        Built from `TrafficLight.get_stop_waypoints()`, the lane positions CARLA
        halts vehicles at. This is deliberately *not*
        `Vehicle.get_traffic_light()`: that returns a light only while the ego is
        inside its trigger volume, and the ego leaves that volume on the very
        frame it crosses into the junction. Asked at the moment that matters —
        "was the driver facing a red when it entered?" — the trigger-volume
        answer is None, and a red-light runner reads as compliant.

        A lane index has no such edge: the ego is still on the approach lane on
        the last frame before entry, so the governing light is unambiguous.
        """
        index: dict[tuple[int, int], carla.TrafficLight] = {}
        for light in self.world.get_actors().filter("traffic.traffic_light"):
            try:
                stops = light.get_stop_waypoints()
            except RuntimeError:
                continue
            for waypoint in stops:
                index[(int(waypoint.road_id), int(waypoint.lane_id))] = light
        return index

    # ------------------------------------------------------------------ ego

    def _ego_record(self, ego_lane: LaneInfo) -> dict:
        velocity = self.ego.get_velocity()
        control = self.ego.get_control()
        speed = velocity.length()
        return {
            "speed_mps": speed,
            "speed_kph": speed * 3.6,
            "throttle": float(control.throttle),
            "brake": float(control.brake),
            "steer": float(control.steer),
            "hand_brake": bool(control.hand_brake),
            "location": {
                "x": self.ego.get_transform().location.x,
                "y": self.ego.get_transform().location.y,
            },
            "lane": ego_lane.as_dict(),
        }

    # --------------------------------------------------------------- signal

    def _signal_record(self, ego_lane: LaneInfo) -> Optional[dict]:
        """The traffic light governing the ego's current lane.

        Both mechanisms are recorded. `state` comes from the lane index (see
        `_index_lights`) and is what the labeler judges on; `trigger_volume_id`
        is CARLA's own `Vehicle.get_traffic_light()`, kept for cross-reference
        because the two disagree exactly at the junction boundary, which is the
        frame the red-light clause turns on.
        """
        try:
            volume_light = self.ego.get_traffic_light()
        except RuntimeError:
            volume_light = None

        light = None
        if ego_lane.road_id is not None and ego_lane.lane_id is not None:
            light = self._lights_by_lane.get((ego_lane.road_id, ego_lane.lane_id))
        if light is None:
            light = volume_light
        if light is None:
            return None

        return {
            "id": int(light.id),
            "state": str(light.get_state()),
            "is_frozen": bool(light.is_frozen()),
            "distance_m": plane_distance(self.ego.get_location(),
                                         light.get_transform().location),
            "governs_lane": (ego_lane.road_id, ego_lane.lane_id) in self._lights_by_lane,
            "trigger_volume_id": int(volume_light.id) if volume_light else None,
            "at_light": bool(self.ego.is_at_traffic_light()),
        }

    # ------------------------------------------------------------ stop sign

    def _stop_sign_record(self, ego_lane: LaneInfo) -> Optional[dict]:
        """The stop sign posted for the ego's own lane, from the OpenDRIVE map.

        Read from the map's landmark records rather than from a `traffic.stop`
        actor's trigger volume: the landmark is attached to the lane, so it
        answers "is a stop posted for me" rather than "is a sign near me".
        """
        wp = self.carla_map.get_waypoint(self.ego.get_location(),
                                         project_to_road=True,
                                         lane_type=carla.LaneType.Driving)
        if wp is None:
            return None
        distance = distance_to_landmarks(wp, STOP_SIGN_LOOKAHEAD_M,
                                         OPENDRIVE_STOP_SIGN)
        if distance is None:
            return None
        return {"distance_m": distance, "in_junction": ego_lane.is_junction}

    # ----------------------------------------------------------- other cars

    def _actor_records(self, ego_lane: LaneInfo) -> list[dict]:
        rows: list[dict] = []
        ego_location = self.ego.get_location()
        for actor in self.world.get_actors():
            if actor.id == self.ego.id:
                continue
            if not (actor.type_id.startswith("vehicle.")
                    or actor.type_id.startswith("walker.")):
                continue
            if plane_distance(ego_location, actor.get_location()) > self.proximity_radius:
                continue

            rel: Relative = relative_to(self.ego, actor)
            other_lane = lane_info(self.carla_map, actor)
            base_class = base_class_of(actor.type_id)
            rows.append({
                "id": int(actor.id),
                "type_id": actor.type_id,
                "base_class": base_class,
                "is_emergency": actor.type_id in EMERGENCY_BLUEPRINTS,
                # Whether the abstraction can even express a distance to it.
                "proximity_edge_possible": base_class in PROXIMITY_VISIBLE_BASE_CLASSES,
                "speed_mps": actor.get_velocity().length(),
                "relative": rel.as_dict(),
                "lane": other_lane.as_dict(),
                "same_lane_as_ego": same_lane(ego_lane, other_lane),
                "opposing_lane_to_ego": opposing_lane(ego_lane, other_lane),
                "lights": _light_state_flags(actor),
            })
        rows.sort(key=lambda r: r["relative"]["centre_distance"])
        return rows

    # ------------------------------------------------------------------ api

    def tick(self, frame: int, sim_frame: int) -> dict:
        ego_lane = lane_info(self.carla_map, self.ego)
        record = {
            "frame": frame,
            "sim_frame": sim_frame,
            "t": frame / float(self.fps),
            "ego": self._ego_record(ego_lane),
            "signal": self._signal_record(ego_lane),
            "stop_sign": self._stop_sign_record(ego_lane),
            "actors": self._actor_records(ego_lane),
        }
        self.records.append(record)
        return record

    def write(self, path: Path) -> None:
        with open(path, "w", encoding="utf-8") as fd:
            for record in self.records:
                fd.write(json.dumps(record, ensure_ascii=False) + "\n")


def load_oracle(path: Path) -> list[dict]:
    with open(path, encoding="utf-8") as fd:
        return [json.loads(line) for line in fd if line.strip()]


def summarize(records: Iterable[dict]) -> dict:
    """A short human-readable digest, printed at the end of a capture."""
    records = list(records)
    if not records:
        return {}
    speeds = [r["ego"]["speed_kph"] for r in records]
    junction_frames = sum(1 for r in records if r["ego"]["lane"]["is_junction"])
    red_frames = sum(1 for r in records
                     if r["signal"] and r["signal"]["state"] == "Red")
    off_road = sum(1 for r in records if not r["ego"]["lane"]["on_road"])
    wrong_way = sum(1 for r in records if r["ego"]["lane"]["wrong_way"])
    return {
        "frames": len(records),
        "speed_kph_max": max(speeds),
        "speed_kph_mean": sum(speeds) / len(speeds),
        "frames_in_junction": junction_frames,
        "frames_facing_red": red_frames,
        "frames_off_road": off_road,
        "frames_wrong_way": wrong_way,
    }
