#!/usr/bin/env python3
"""Convert CARLA RSV scene-graph frames into a Lean `Trace`.

    python3 carla/adapter.py --rsv-dir <dir of .pkl> --ego-log <ego_logs.json> \
        --output library/TrafficSpecEval/Captured.lean --module-name Captured

Reads the RoadScene2Vec-style abstraction produced by
`carla_sgg.sgg_abstractor.process_to_junction_rsv` (see
https://github.com/less-lab-uva/carla_scene_graphs) and emits a Lean module
defining `TrafficSpecEval.<module_name>Trace`.

**Where the output goes.** `library/TrafficSpecEval/`, which is its own Lean
library root (`library/lakefile.lean`) and is NOT under `TrafficSpec/`. The
formalization agents read `TrafficSpec/` for Core and the builders; a capture
inside that tree is evidence they can reach, and a capture is what a rule is
tested against rather than what it is written from. `run_spec loop` refuses to
start while a module carrying this file's banner sits under `TrafficSpec/`.

**Which abstraction.** It must be `process_to_junction_rsv`. That is the only one
whose node naming (`Lane <road>_<±lane>`, `Road <n>`, `Junction <n>`,
`Off Road`), `special_class` attribute and entity → lane → road → junction `isIn`
chain match this library. `process_to_rsv` names lanes `Ego Lane`,
`Left 1 of Ego Lane`, `Opposing Lane 0` and `Root Road`, every one of which
`classify` would bucket as `other`, silently making every lane-based predicate
false on the whole capture.

The label, type and attribute mappings below are the compatibility contract and
must stay in sync with `carla/schema.json`. Notes on upstream:

* The generator's code emits the proximity label `safety_hazard`, while its own
  documentation calls it `safe_hazard`. Both spellings are accepted here; an
  adapter that accepts only the documented one silently drops every
  closest-band edge.
* `travelsTo` is part of the RSV abstraction and is required by
  `Pred.approachingJunction`. `process_to_junction_rsv` spells the same relation
  `travels_to` and lane changes `can_lane_change_to`, so both spellings map.
* `controlsTrafficOf` (traffic light / stop sign → each lane it governs) and
  `mayAffect` (OpenDRIVE landmark → each lane it applies to) are the only
  sound sign-to-lane associations the generator produces, and are the reason
  signal and stop-sign laws are formalizable at all. There is never a proximity
  edge to a sign.
* Actor nodes carry the whole base-graph attribute dict, so a traffic light's
  `light_state`, every vehicle's per-light booleans and a landmark's posted value
  arrive with the graph. Anything this adapter does not lift is reported at the
  end of a run under "attributes present but not lifted" — a silent drop here is
  what makes a plan agent believe CARLA cannot express a law.

**Entity identity.** A Lean `EntityId` is assigned per PHYSICAL entity, not per
RSV node name. `process_to_junction_rsv` names every actor `{base_class}_{n}`
with `n` a per-frame counter over whichever actors are in the frame
(`sgg_abstractor.py:234-235`), so `car_0` in one frame and `car_0` in the next
are the same vehicle only while no car ahead of it in iteration order enters or
leaves the render box. Keying by name therefore spliced different vehicles into
one binding, and a temporal formula evaluated over that binding compared one
car's frame with another's. `entity_key` below resolves the identity from what
the generator does write: `carla_id` (every non-ego actor and every
traffic-light node, `sgg.py:607/623/681`), `entity_id` (the ego's own actor id
via `__add_actor_to_graph`, `sgg.py:837`; negative for map scenery, `:462`),
`landmark_id` (`:717`), and for anything static that carries none of these, its
world position — which for a static node is a stable identity. Structure nodes
are keyed by name, which IS their identity (`Lane 9_-1`, `Road 9`).

Booleans are emitted only when true: an absent boolean attribute reads as false
in `Pred.attrTrue`, which is the right default for a light that is off, and
emitting eight false lights per vehicle per frame would dwarf the trace.

Unpickling requires no CARLA installation: the graph nodes are rebound to a
local placeholder class, as the reference Lean project's adapter does.
"""

from __future__ import annotations

import argparse
import json
import pickle
import re
from pathlib import Path
from typing import Any, Optional

# ── RSV relation label → Lean RelLabel constructor ───────────────────────
REL_LABELS: dict[str, str] = {
    # semantic
    "isIn": "isIn",
    "opposes": "opposes",
    "travelsTo": "travelsTo",
    "travels_to": "travelsTo",
    "laneChange": "laneChange",
    "can_lane_change_to": "laneChange",
    # traffic control
    "controlsTrafficOf": "controls",
    "mayAffect": "mayAffect",
    # distance bands (closest first); both upstream spellings of the closest band
    "safety_hazard": "safetyHazard",
    "safe_hazard": "safetyHazard",
    "near_coll": "nearCollision",
    "super_near": "superNear",
    "very_near": "veryNear",
    "near": "near",
    "visible": "visible",
    # angular
    "toLeftOf": "toLeftOf",
    "toRightOf": "toRightOf",
    "inDFrontOf": "inDFrontOf",
    "inSFrontOf": "inSFrontOf",
    "atDRearOf": "atDRearOf",
    "atSRearOf": "atSRearOf",
}

# ── SGG base class → Lean EntityType constructor ─────────────────────────
# Keys are exactly what `actors.py::get_base_type` returns. Matched exactly,
# because a substring match on `vehicle` would swallow every `vehicle.*`
# blueprint id and collapse cars, trucks and vans into the generic type.
BASE_TYPES: dict[str, str] = {
    "car": "car",
    "truck": "truck",
    "van": "van",
    "bus": "bus",
    "motorcycle": "motorcycle",
    "vehicle": "vehicle",
    "bicycle": "bicycle",
    "person": "pedestrian",
    "traffic_light": "trafficLight",
    "stop_sign": "stopSign",
    "speed_limit": "speedLimitSign",
}

# Fallback substring probes, for captures whose nodes carry no base class.
NAME_PROBES: tuple[tuple[str, str], ...] = (
    ("walker", "pedestrian"),
    ("pedestrian", "pedestrian"),
    ("motorcycle", "motorcycle"),
    ("bicycle", "bicycle"),
    ("traffic_light", "trafficLight"),
    ("stop_sign", "stopSign"),
    ("speed_limit", "speedLimitSign"),
    ("truck", "truck"),
    ("bus", "bus"),
    ("van", "van"),
    ("car", "car"),
)

# Lean types that are `carla.Vehicle`s, and therefore carry light states.
VEHICLE_TYPES = frozenset(
    {"car", "truck", "van", "bus", "motorcycle", "vehicle", "bicycle"}
)

# Dynamics channels the ego log supplies, in the order the Lean builder expects.
EGO_CHANNELS = ("speed", "accel", "throttle", "brake", "steer")

# Lean attribute key → base-graph attribute key, for the per-light booleans
# `sgg.py` unpacks from `actor.get_light_state()` for every `carla.Vehicle`.
VEHICLE_LIGHTS: dict[str, str] = {
    "light_brake": "light_Brake",
    "light_left_blinker": "light_LeftBlinker",
    "light_right_blinker": "light_RightBlinker",
    "light_high_beam": "light_HighBeam",
    "light_low_beam": "light_LowBeam",
    "light_position": "light_Position",
    "light_fog": "light_Fog",
    "light_reverse": "light_Reverse",
}

# Landmark fields carrying regulatory meaning, in `mkLandmark` argument order
# after the name: type, value, unit, sub_type, country, text.
LANDMARK_FIELDS = ("landmark_type", "landmark_value", "landmark_unit",
                   "landmark_sub_type", "landmark_country", "landmark_text")

# ── Keys lifted because the generator emits them, not because a law asked ────
#
# What follows was previously reported to the agent as `available_not_exposed`,
# on reasons that did not survive being written down: "no statute in the corpus
# refers to gear selection" is a fact about one law corpus, and this library is
# meant to take any law. The criterion is now the only one that generalises —
# is the key on the node, can Lean read it decidably, and what does it cost —
# and the cost is measured, not guessed.
#
# Bytes added to the
# generated trace (baseline 614,946 bytes in 10 chunks, ~61 KB per chunk against
# Lean's ~500 KB per-definition codegen limit):
#
#   vertex 130,250   forward 125,490   ego vectors 82,650   carla_id 25,620
#   light_Interior/Special1/Special2 26,040   landmark_lane_validities 21,200
#   gear + manual_gear_shift 15,120        -> ~426 KB, ~43 KB per chunk
#
# Position as three decimal strings. `Core/Decimal.lean` reads them into integer
# milli-units, so a squared separation is exact integer arithmetic and needs no
# square root: this is what makes actor-to-actor distance recoverable even
# though `process_to_junction_rsv` drops the metric edge attribute.
GEOMETRY_VECTORS: dict[str, tuple[str, str, str]] = {
    "vertex": ("pos_x", "pos_y", "pos_z"),
    "forward": ("fwd_x", "fwd_y", "fwd_z"),
}

# Ego vector channels. `carla_ang_vel_z` was already lifted as the yaw rate;
# leaving its siblings out was an inconsistency, not a decision.
# Keyed Lean-name -> base-graph key, the same direction as `VEHICLE_LIGHTS`.
# Written the other way round it reads plausibly, emits nothing, and — because
# CONSUMED_ATTRS then swallows the raw keys — stops the unlifted-key report from
# showing the omission. Keep every mapping in this file pointing the same way.
#: Emitted in place of a numeric ego channel the capture cannot supply.
#:
#: NOT a fabricated zero, and not an arbitrary marker. `Core/Decimal.lean`
#: accepts only `[+-]? digit+ ( '.' digit+ )?`; `parseMilli` returns `none` for
#: anything else, and `leMilli` / `ltMilli` / `geMilli` / `gtMilli` /
#: `absLeMilli` each document that an unparseable value compares **false**. That
#: is exactly the semantics of an absent attribute — `Pred.attrMilli*` returns
#: `false` on `getAttr = none` — so a channel carrying this reads as NO EVIDENCE
#: in both directions, which is what "we did not measure it" means.
#:
#: The alternative that was in place is worse than it looks. A fabricated `0.0`
#: is not neutral: it makes `speedLe`, and therefore `Pred.stopped`, TRUE. 12 of
#: the 24 rule files read `stopped`, and on a replay-derived capture every one
#: of them saw an ego that never moved. `Speed/urban_default_limit` is
#: `□ (situation ⟹ ¬ₛ .bounded n (¬ₛ speedLeKph ego 50))`, which with speed 0
#: reports COMPLIANT on a capture where the ego did 90 km/h.
#:
#: `mkEgo` cannot omit a channel — it writes all nine pairs into `attrs`
#: unconditionally — so absence is expressed through the value rather than
#: through the key. No Core change is needed, because Core already specifies
#: this behaviour on every comparison it defines.
UNMEASURED = "unmeasured"

#: The `EGO_VECTOR_CHANNELS` entries that a CARLA recorder replay destroys.
#: The replayer teleports actors instead of integrating physics, so
#: `get_velocity()` / `get_acceleration()` / `get_angular_velocity()` have
#: nothing to report while `get_control()` still does. These keys are suppressed
#: entirely (`scalar_attrs` already skips a key it is not given) rather than
#: lifted as zeros; `gear` and `manual_gear_shift` are NOT here, because they
#: come from `copy_carla_control` and survive replay intact.
EGO_REPLAY_INVALID_VECTORS: frozenset = frozenset({
    "vel_x", "vel_y", "vel_z", "acc_x", "acc_y", "acc_z",
    "roll_rate", "pitch_rate",
})

EGO_VECTOR_CHANNELS: dict[str, str] = {
    "vel_x": "carla_vel_x", "vel_y": "carla_vel_y", "vel_z": "carla_vel_z",
    "acc_x": "carla_acc_x", "acc_y": "carla_acc_y", "acc_z": "carla_acc_z",
    "roll_rate": "carla_ang_vel_x", "pitch_rate": "carla_ang_vel_y",
    "gear": "carla_gear", "manual_gear_shift": "carla_manual_gear_shift",
}

# The remaining per-light booleans. `light_Special1` / `light_Special2` are
# CARLA's emergency beacons, which is the one dynamic signal that distinguishes
# a responding emergency vehicle from an idle one.
EXTRA_VEHICLE_LIGHTS: dict[str, str] = {
    "light_interior": "light_Interior",
    "light_special_1": "light_Special1",
    "light_special_2": "light_Special2",
}

# The CARLA actor id, lifted as an attribute so a rule can read it, and used by
# `entity_key` as the cross-frame identity a Lean `EntityId` is assigned to.
IDENTITY_ATTRS: dict[str, str] = {"carla_id": "carla_id"}

# Which lanes a landmark is valid for — the governance the `mayAffect` edge
# only approximates — plus the three landmark fields that are governance or
# identity rather than sign shape. `landmark_orientation` is decoded from the
# `carla.LandmarkOrientation` enum by `landmark_orientation_name` below; the
# other two are lifted as written.
LANDMARK_EXTRA: dict[str, str] = {
    "landmark_lane_validities": "landmark_lane_validities",
    "landmark_id": "landmark_id",
    "landmark_is_dynamic": "landmark_is_dynamic",
}

#: `landmark.orientation` (sgg.py:710) is written as the raw
#: `carla.LandmarkOrientation` enum, which the unpickler rebinds to
#: `OpaqueValue` carrying the enum's integer in `args[0]`. The names, in the
#: order `carla.LandmarkOrientation.names` lists them: Positive = the sign
#: faces vehicles travelling WITH the road's reference direction, i.e. the
#: lanes with NEGATIVE OpenDRIVE ids; Negative = faces the POSITIVE lanes;
#: Both = both directions (CARLA PythonAPI reference, carla.LandmarkOrientation).
#: This is the field that says which direction of travel a sign governs, and
#: with `lane_id` — lifted on every lane node — it narrows `mayAffect` to the
#: carriageway the sign actually faces.
LANDMARK_ORIENTATION_KEY = "landmark_orientation"
LANDMARK_ORIENTATION_NAMES = ("Positive", "Negative", "Both")

#: Map scenery: the parked vehicles baked into the level, which sgg.py Step 4
#: (:412-466) ingests through `world.get_environment_objects(CityObjectLabel.*)`
#: and names by the enum string (`sem_class = f'{bb_type}'`, :456). They reach
#: `__add_to_graph` with `entity_id=-static_id` (:462) and never pass through
#: the actor loop, so they carry no `carla_id`. In Lean they are otherwise
#: indistinguishable from moving traffic — same `EntityType`, same proximity
#: edges — so the two marks the generator does leave are lifted as one boolean.
#: The enum strings are the members of `carla.CityObjectLabel` the generator
#: lists at :415-426, including the single `Vehicles` label older CARLA used.
SCENERY_ATTR = "map_scenery"
SCENERY_SEM_CLASSES = frozenset(
    {"Car", "Bus", "Truck", "Bicycle", "Motorcycle", "Vehicles"})

#: Body half-extents, derived in the adapter from `threedbbox` — the eight
#: world-frame corners `parse3dbb` writes (sgg.py:837, :798) — projected onto
#: the node's own `forward` / `right` / `up` axes. Three numbers replace
#: twenty-four, and they are what a clearance needs: every separation the
#: library computes from `pos_*` is centre-to-centre, and the distance between
#: two bodies' SURFACES differs from it by about the sum of their half-extents
#: along the line between them. Metres, like `pos_*`.
EXTENT_ATTRS = ("half_length", "half_width", "half_height")
EXTENT_SOURCE_KEYS = ("threedbbox", "vertex", "forward", "right", "up")

# Base-graph attribute keys this adapter consumes. Everything else on an actor
# node is reported as unlifted, so the gap is visible instead of silent.
# `entity_id`, `threedbbox`, `right` and `up` are consumed without being
# emitted under their own names: the first becomes `map_scenery` and the
# identity key, the other three become the half-extents.
CONSUMED_ATTRS = frozenset(
    {"sem_class", "special_class", "light_state",
     "carla_speed", "carla_throttle", "carla_brake", "carla_steer",
     "carla_ang_vel_z", "carla_hand_brake", "carla_reverse",
     "carla_affected_by_traffic_light", "entity_id",
     LANDMARK_ORIENTATION_KEY}
    | set(VEHICLE_LIGHTS.values())
    | set(LANDMARK_FIELDS)
    | set(GEOMETRY_VECTORS)
    | set(EGO_VECTOR_CHANNELS.values())
    | set(EXTRA_VEHICLE_LIGHTS.values())
    | set(IDENTITY_ATTRS.values())
    | set(LANDMARK_EXTRA)
    | set(EXTENT_SOURCE_KEYS)
)


class SGNode:
    """Stand-in for the generator's `Node`, so pickles load without CARLA."""

    def __init__(self, name: str = "", base_class: Optional[str] = None,
                 attr: Optional[dict] = None) -> None:
        self.name = name
        self.base_class = base_class
        self.attr = attr or {}

    def __repr__(self) -> str:
        return str(self.name)


class OpaqueValue:
    """Stand-in for a third-party object held in an attribute we never read.

    A frame pickle carries `carla.libcarla` enums, shapely geometry
    (`vertex_point`, `waypoint_bbox_polygon`) and matplotlib colours, none of
    which this adapter looks at. Rebinding them to an inert placeholder is what
    lets a capture be read on a machine with no CARLA, no shapely and no
    matplotlib — the alternative is making the whole simulator stack a
    dependency of reading its output.
    """

    def __new__(cls, *args: Any, **_kw: Any) -> "OpaqueValue":
        obj = super().__new__(cls)
        obj.args = args
        return obj

    def __setstate__(self, state: Any) -> None:
        # Geometry classes restore from a WKB blob or a tuple rather than a
        # __dict__, which pickle rejects for a plain object. Swallow whatever
        # shape it is; nothing here is ever read back.
        self.state = state

    def __repr__(self) -> str:
        return "<opaque>"


# Kept as an alias: the class was called this before it covered more than CARLA.
CarlaValue = OpaqueValue

# Modules whose objects are never read. `numpy` is deliberately NOT here: the
# actor `vertex` / `forward` vectors are numpy arrays, and stubbing them would
# quietly discard the geometry listed under `available_not_exposed` in
# carla/schema.json, which is the next thing anyone will want to lift.
OPAQUE_MODULES = ("carla", "shapely", "matplotlib")


class SGUnpickler(pickle.Unpickler):
    def persistent_load(self, pid: Any) -> Any:
        if pid == "please_ignore_me":
            return None
        return super().persistent_load(pid)

    def find_class(self, module: str, name: str) -> Any:
        if name == "Node":
            return SGNode
        if module.startswith(OPAQUE_MODULES):
            return OpaqueValue
        try:
            return super().find_class(module, name)
        except ModuleNotFoundError as exc:
            raise ModuleNotFoundError(
                f"reading this capture needs the module '{exc.name}', which is "
                f"not installed. If it only appears in attributes this adapter "
                f"does not read, add it to OPAQUE_MODULES; if the data itself "
                f"lives in it, install it."
            ) from exc


def natural_key(name: str) -> list:
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r"(\d+)", str(name))]


def lean_str(s: str) -> str:
    return str(s).replace("\\", "\\\\").replace('"', '\\"')


def classify(name: str, base_class: Optional[str], sem_class: Optional[str]) -> str:
    """Map a node to a Lean `EntityType` constructor.

    Structural nodes are identified by name, because `process_to_junction_rsv`
    builds them as bare `Node`s named `Lane …`, `Road …`, `Junction …` and
    `Off Road` with no base class at all. Actors are identified by their base
    class — matched exactly, since `get_base_type` returns a fixed vocabulary —
    and only then by name probes, for captures that lost the base class.
    """
    lowered = str(name).lower()
    text = f"{name} {base_class or ''} {sem_class or ''}".lower()

    if lowered.startswith("lane") or sem_class == "Driving":
        return "lane"
    if lowered.startswith("road"):
        return "road"
    if lowered.startswith("junction") and "boundary" not in lowered:
        return "junction"
    if "off road" in lowered or "offroad" in text:
        return "offRoad"
    if lowered == "ego":
        return "car"   # ego's blueprint is not in the abstraction; car is the default

    if base_class:
        exact = BASE_TYPES.get(str(base_class))
        if exact:
            return exact
        if str(base_class).startswith("landmark"):
            return "landmark"
        if "junction_boundary" in str(base_class):
            return "junctionBoundary"

    if lowered.startswith("landmark"):
        return "landmark"
    if "junction_boundary" in text:
        return "junctionBoundary"

    for token, lean_type in NAME_PROBES:
        if token in text:
            return lean_type
    return "other"


# What the Lean library assumes about how a capture was recorded, keyed by the
# manifest field that records it. `runner.py::_generator_manifest` writes twelve
# such fields; every one of them is a caller-supplied default of the generator or
# the simulator, not a property of the scene-graph format, so every one of them
# can differ in a capture this pipeline did not produce.
#
# The split below is the whole point. A parameter is SEMANTIC when changing it
# leaves the trace well-formed but changes what a rule's constants mean — those
# must refuse, because the resulting error is silent and runs in the
# missed-violation direction. A parameter is VISIBILITY-ONLY when changing it
# alters which entities and edges appear at all — those must warn, because a rule
# can still be evaluated soundly on a thinner scene, it just grounds less often,
# and refusing would reject legitimate captures.
ASSUMED_CAPTURE_HZ = 20
ASSUMED_PROXIMITY_THRESHOLDS = [["safety_hazard", 2], ["near_coll", 4],
                                ["super_near", 7], ["very_near", 10],
                                ["near", 16], ["visible", 25]]
# carla_sgg.sgg_abstractor.DEFAULT_DIRECTIONAL_THRESHOLDS, reduced to the split
# the vocabulary actually depends on: `Pred.oncoming`/`inFrontOf`/`behind` are
# sound only if front/rear divide at 180 degrees and the D/S (direct/side) split
# falls at 45 degrees off-axis.
ASSUMED_DIRECTIONAL_DEGREES = {
    "inDFrontOf": [[45, 90], [90, 135]], "inSFrontOf": [[0, 45], [135, 180]],
    "atDRearOf": [[225, 270], [270, 315]], "atSRearOf": [[180, 225], [315, 360]],
}
# The base classes a proximity or angular edge can be drawn for. Rules binding a
# road user by proximity ground only over these; a capture whose table omits one
# makes those rules vacuous on it rather than wrong.
ASSUMED_PROXIMITY_CLASSES = {"person", "bicycle", "car", "motorcycle", "bus",
                             "truck"}
ASSUMED_ABSTRACTION = "process_to_junction_rsv"
# Visibility-only defaults, for the warning text. Value -> what a rule loses.
VISIBILITY_DEFAULTS = {
    "render_dist": (50.0, "entities beyond this radius are absent, so a rule "
                          "quantified over them grounds less often"),
    "segment_length": (1.0, "lane sampling granularity; affects which lane and "
                            "road nodes exist"),
    "check_occlusion": (False, "with occlusion culling on, a hidden actor is "
                               "dropped entirely and rules about it go vacuous"),
    "parse_junction_boundaries": (False, "changes which frames carry junction "
                                         "entities, so `Pred.inJunction` "
                                         "grounds differently"),
}


class CapturePreconditionError(ValueError):
    """The capture was recorded with settings the library does not assume."""


class RecordingPolicy:
    """How the capture was recorded, and therefore which channels are evidence.

    Separate from the `generator` settings block because it is a property of the
    RUN, not of the abstraction: the same generator configuration produces
    trustworthy dynamics live and none at all under replay.

    `ego_log_frame_offset` exists because the scene-graph frame index and the
    ego-log record index can have different origins and neither file records
    its own. In `carla_sgg`'s `capture_sensor_data.py` they do: `replay_file()`
    starts the replay, then ten `world.tick()` calls warm the five sensors up
    before `start_frame` is taken, so `rsv/i.pkl` is replay tick *i*+10 while
    `add_agent_delay` has already re-based `ego_logs.json` to tick 0. Measured
    on all three logged SceneFlowLang captures by matching positions, which both
    files record independently: mean error 3.45 m at offset 0, 0.039 m at +10.
    """

    def __init__(self, capture_mode="unknown", dynamics_valid=True,
                 ego_log_frame_offset=0, provenance="default"):
        self.capture_mode = capture_mode
        self.dynamics_valid = dynamics_valid
        self.ego_log_frame_offset = int(ego_log_frame_offset)
        self.provenance = provenance

    def as_dict(self) -> dict:
        return {"capture_mode": self.capture_mode,
                "dynamics_valid": self.dynamics_valid,
                "ego_log_frame_offset": self.ego_log_frame_offset,
                "_provenance": self.provenance}

    def __repr__(self):
        return ("RecordingPolicy(mode=%s, dynamics_valid=%s, ego_log_offset=%+d)"
                % (self.capture_mode, self.dynamics_valid,
                   self.ego_log_frame_offset))


#: Frames sampled when deciding whether a capture is replay-derived. The
#: signature is overwhelming when present — 882 of 882 moving frames report a
#: stationary vehicle on `HazardAtSideLaneTwoWays` — so a sample settles it
#: without unpickling the whole capture a second time.
REPLAY_PROBE_FRAMES = 40
#: Consecutive positions implying at least this speed count the frame as moving.
REPLAY_MOVING_MPS = 0.5
#: A reported speed below this counts as "the server says stationary".
REPLAY_STATIONARY_MPS = 0.1
#: Fraction of moving frames that must report stationary to call it a replay.
REPLAY_FRACTION = 0.95


def detect_replay_zeroing(files: list, capture_hz: Optional[int]) -> Optional[bool]:
    """Does this capture carry dynamics, judged from the frames themselves?

    Returns True when the ego demonstrably moves while the graph reports it
    stationary, False when the graph's speed tracks the motion, and None when
    the question cannot be answered (the ego never moves, or the rate is
    unknown).

    This is a detection, not a declaration, and it is used only to choose the
    SAFE direction when nobody declared: suppressing a channel that might have
    been valid costs a rule its evidence, while emitting a zero that is not a
    measurement inverts the rule's verdict. A manifest overrides it either way.
    """
    if not files or not capture_hz:
        return None
    dt = 1.0 / float(capture_hz)
    step = max(1, len(files) // REPLAY_PROBE_FRAMES)
    picked = list(range(0, len(files) - 1, step))[:REPLAY_PROBE_FRAMES]

    moving = stationary_reported = 0
    for i in picked:
        try:
            with files[i].open("rb") as fh:
                a = SGUnpickler(fh).load()
            with files[i + 1].open("rb") as fh:
                b = SGUnpickler(fh).load()
        except Exception:                                   # noqa: BLE001
            continue
        ego_a = _ego_node(a)
        ego_b = _ego_node(b)
        if ego_a is None or ego_b is None:
            continue
        pa, pb = _node_xy(ego_a), _node_xy(ego_b)
        if pa is None or pb is None:
            continue
        implied = ((pa[0] - pb[0]) ** 2 + (pa[1] - pb[1]) ** 2) ** 0.5 / dt
        if implied < REPLAY_MOVING_MPS:
            continue
        moving += 1
        reported = (getattr(ego_a, "attr", {}) or {}).get("carla_speed")
        if reported is None or abs(float(reported)) < REPLAY_STATIONARY_MPS:
            stationary_reported += 1
    if moving == 0:
        return None
    return (stationary_reported / float(moving)) >= REPLAY_FRACTION


def _ego_node(graph):
    for node in graph.nodes:
        if str(getattr(node, "name", node)) == "ego":
            return node
    return None


def _node_xy(node):
    vertex = (getattr(node, "attr", {}) or {}).get("vertex")
    if vertex is None:
        return None
    return (float(vertex[0]), float(vertex[1]))


def resolve_recording_policy(rsv_dir: Path, files: list, settings: dict,
                             manifest_path: Optional[Path],
                             declared_recording: Optional[dict]) -> RecordingPolicy:
    """Declaration first, manifest second, detection last."""
    if declared_recording:
        return RecordingPolicy(
            capture_mode=declared_recording.get("capture_mode", "unknown"),
            dynamics_valid=declared_recording.get("dynamics_valid", True),
            ego_log_frame_offset=declared_recording.get("ego_log_frame_offset", 0),
            provenance="declared by the caller; nothing verifies it")

    manifest = manifest_path or (rsv_dir.parent / "simulation.json")
    if manifest.exists():
        try:
            block = json.loads(manifest.read_text(encoding="utf-8")).get("recording")
        except ValueError:
            block = None
        if block:
            return RecordingPolicy(
                capture_mode=block.get("capture_mode", "unknown"),
                dynamics_valid=block.get("dynamics_valid", True),
                ego_log_frame_offset=block.get("ego_log_frame_offset", 0),
                provenance=f"read from {manifest}")

    replayed = detect_replay_zeroing(files, settings.get("capture_hz"))
    if replayed is True:
        print("[warn] this capture is replay-derived: the ego's position "
              "advances while the graph reports it stationary. Speed, "
              "acceleration and yaw rate are NOT measurements here and are "
              "emitted as `%s`, which every Core comparison reads as false. "
              "Declare `recording.ego_log_frame_offset` in the manifest if an "
              "ego log is also being used." % UNMEASURED)
        return RecordingPolicy("replay", dynamics_valid=False,
                               provenance="detected from the frames: motion "
                                          "without reported velocity")
    if replayed is False:
        return RecordingPolicy("live", dynamics_valid=True,
                               provenance="detected from the frames: reported "
                                          "velocity tracks the motion")
    return RecordingPolicy(provenance="undetermined: the ego never moves in "
                                      "this capture, so nothing distinguishes "
                                      "a replay from a stationary run")


def check_capture_preconditions(
        rsv_dir: Path,
        manifest_path: Optional[Path] = None,
        declared: Optional[dict] = None) -> dict:
    """Fail closed when the capture's settings contradict frozen Core.

    **The settings must be supplied; they are never assumed.** This used to warn
    and continue on a missing manifest, and every capture that took that branch
    converted with all five preconditions *assumed rather than checked* — which
    is indistinguishable, in the output, from a capture that was verified. There
    are two ways to supply them, and one of them must be taken:

      1. a manifest — `--manifest FILE`, or a `simulation.json` beside the frame
         directory, in the shape `carlaspec/runner.py::_generator_manifest`
         writes;
      2. a declaration — `--declare-capture-hz N --declare-generator-defaults`,
         by which the CALLER asserts the rate and that the generator ran with
         its default thresholds, tables and abstraction.

    Route 2 is not a weaker route 1: it records an assertion someone made and
    can be held to, where the old default recorded nothing at all. Returns the
    settings block that was checked, so the caller can put it in the output.
    """
    manifest = manifest_path or (rsv_dir.parent / "simulation.json")
    if manifest_path is not None and not manifest.exists():
        raise CapturePreconditionError(f"--manifest {manifest} does not exist")

    if not manifest.exists():
        if not declared:
            raise CapturePreconditionError(
                f"no capture settings for {rsv_dir}.\n"
                f"  Every duration, metre bound and angular relation in the "
                f"library is interpreted against them, so they are required "
                f"rather than assumed. Supply either:\n"
                f"    --manifest FILE                 (a simulation.json)\n"
                f"  or, if the capture has none:\n"
                f"    --declare-capture-hz N --declare-generator-defaults\n"
                f"  See carla/schema.json -> capture_preconditions, and "
                f"carla/simulation.template.json for the manifest shape.")
        gen = dict(declared)
        gen["_provenance"] = "declared by the caller; nothing verifies it"
        print(f"[info] capture settings DECLARED by the caller: "
              f"capture_hz={gen.get('capture_hz')}, generator defaults assumed "
              f"for thresholds, tables and abstraction.")
        data = {"generator": gen}
    else:
        try:
            data = json.loads(manifest.read_text(encoding="utf-8"))
        except ValueError as exc:
            raise CapturePreconditionError(f"{manifest} is not valid JSON: {exc}")

    gen = data.get("generator") or {}
    if not gen:
        # A manifest without a `generator` block is NOT the same as no manifest,
        # and it used to be treated as one: eleven of the twelve settings simply
        # went unchecked and the capture passed in silence. Four of the recorded
        # captures predate the block. Say so, once, rather than implying the
        # settings were verified.
        print(f"[warn] {manifest.name} predates the generator manifest: it "
              f"records only `fps`, so the thresholds, the abstraction and the "
              f"visibility settings this capture was made with are unknown and "
              f"assumed to be the defaults. Nothing verifies that. Re-record to "
              f"get them checked.")
    fatal: list[str] = []

    # --- semantic: refuse ---------------------------------------------------
    hz = gen.get("capture_hz", data.get("fps"))
    if hz is not None and int(hz) != ASSUMED_CAPTURE_HZ:
        fatal.append(
            f"capture_hz={hz}, but the library hard-codes {ASSUMED_CAPTURE_HZ} "
            f"in Core/Scene.lean::captureHz and every duration in every rule is "
            f"a frame count at that rate; converting would scale every window "
            f"by {hz}/{ASSUMED_CAPTURE_HZ}")

    delta = gen.get("fixed_delta_seconds")
    if delta and hz and abs(float(delta) * float(hz) - 1.0) > 1e-6:
        fatal.append(
            f"fixed_delta_seconds={delta} and capture_hz={hz} disagree "
            f"({float(delta) * float(hz):.4f} != 1.0); one frame is not one "
            f"simulation step, so a frame count is not a duration at all")

    bands = gen.get("proximity_thresholds")
    if bands is not None:
        normalised = [[str(name), int(metres)] for name, metres in bands]
        if normalised != ASSUMED_PROXIMITY_THRESHOLDS:
            fatal.append(
                f"proximity_thresholds={bands}, but "
                f"Core/Scene.lean::distanceBands hard-codes "
                f"{ASSUMED_PROXIMITY_THRESHOLDS}; the RSV keeps only the band "
                f"label, not the metres, so every `Pred.withinMetres` bound "
                f"would mean a different distance than the rule says")

    angles = gen.get("directional_thresholds")
    if angles is not None:
        got = {str(name): [[int(a), int(b)] for a, b in arcs]
               for name, arcs in angles}
        if got != ASSUMED_DIRECTIONAL_DEGREES:
            fatal.append(
                f"directional_thresholds={angles}, but Core/Vocab.lean reads "
                f"the four angular labels as the arcs "
                f"{ASSUMED_DIRECTIONAL_DEGREES}; `Pred.oncoming`, "
                f"`Pred.inFrontOf` and `Pred.behind` are exactly those labels, "
                f"so a re-cut sector silently redefines in front of and behind")

    abstraction = gen.get("abstraction")
    if abstraction is not None and abstraction != ASSUMED_ABSTRACTION:
        fatal.append(
            f"abstraction={abstraction!r}, but the vocabulary is derived from "
            f"{ASSUMED_ABSTRACTION!r}; another abstraction emits a different "
            f"entity and relation set, and Core/Scene.lean enumerates only this "
            f"one's")

    if fatal:
        raise CapturePreconditionError(
            f"{manifest} contradicts what the library assumes:\n  - "
            + "\n  - ".join(fatal)
            + "\n\nRe-record with the defaults, or change frozen Core and "
              "re-verify the whole library. See carla/schema.json -> "
              "capture_preconditions.")

    # --- visibility-only: warn ---------------------------------------------
    classes = gen.get("proximity_relation_classes")
    if classes is not None:
        missing = sorted(ASSUMED_PROXIMITY_CLASSES - set(classes))
        if missing:
            print(f"[warn] {manifest.name} records a proximity table without "
                  f"{missing}; a rule binding one of those road users by "
                  f"proximity cannot ground on this capture and will read as "
                  f"compliant for want of evidence, not because it is.")

    for key, (default, consequence) in VISIBILITY_DEFAULTS.items():
        got = gen.get(key)
        if got is not None and got != default:
            print(f"[warn] {manifest.name} records {key}={got} (assumed "
                  f"{default}): {consequence}. Verdicts stay sound; grounding "
                  f"counts are not comparable with other captures.")

    excluded = [i for i in (gen.get("exclude_ids") or []) if i != "ego"]
    if excluded:
        print(f"[warn] {manifest.name} excludes {excluded} from every frame in "
              f"addition to the ego; rules quantified over those actors are "
              f"vacuous on this capture.")
    return gen


class CrossCheck:
    """Contradictions between two descriptions of the same fact in one capture.

    Normalising a value at this boundary is only as good as the interpretation
    it applies, so the interpretation has to be checkable. Each test below
    compares two INDEPENDENT descriptions of one physical fact and reports a
    disagreement; none of them decides which side is right, because that is a
    judgement about how the capture was produced and belongs in the manifest.

    Cost is negligible: every test reuses the pass the conversion already makes
    over each frame and each entity, and adds only arithmetic. Conversion is a
    fraction of a percent of a pipeline run whose time is spent in Lean.
    """

    # A speed this small is indistinguishable from a parked vehicle.
    MOVING_MPS = 0.5
    # Relative disagreement below this is measurement noise, not a contradiction.
    SPEED_TOLERANCE = 0.25

    def __init__(self, capture_hz: Optional[float]) -> None:
        self.dt = (1.0 / capture_hz) if capture_hz else None
        self.ego_pos: dict[int, tuple[float, float, float]] = {}
        self.ego_graph_speed: dict[int, float] = {}
        self.ego_log_speed: dict[int, float] = {}
        self.landmarks: set[tuple[str, str]] = set()
        self.sign_kph: set[str] = set()

    @staticmethod
    def _f(value: Any) -> Optional[float]:
        try:
            return float(value)
        except (TypeError, ValueError):
            return None

    def observe_ego(self, index: int, attr: dict, record: Optional[dict]) -> None:
        # `vertex` is the same 3-vector `vector_attrs` lifts into pos_x/y/z.
        try:
            comps = [self._f(v) for v in list(attr.get("vertex"))][:3]
        except TypeError:
            comps = []
        if len(comps) == 3 and all(c is not None for c in comps):
            self.ego_pos[index] = (comps[0], comps[1], comps[2])
        graph_speed = self._f(attr.get("carla_speed"))
        if graph_speed is not None:
            self.ego_graph_speed[index] = graph_speed
        if record:
            log_speed = self._f(((record.get("state") or {})
                                 .get("velocity") or {}).get("value"))
            if log_speed is not None:
                self.ego_log_speed[index] = log_speed

    def observe_landmark(self, attr: dict) -> None:
        value, unit = attr.get("landmark_value"), attr.get("landmark_unit")
        if value is not None and unit is not None:
            self.landmarks.add((str(value), str(unit)))

    def observe_sign(self, attr: dict) -> None:
        type_id = str(attr.get("carla_type_id") or "")
        if "speed_limit." in type_id:
            self.sign_kph.add(type_id.rsplit(".", 1)[-1])

    # ── the tests ────────────────────────────────────────────────────────
    def _displacement_speeds(self) -> list[tuple[int, float]]:
        """Implied speed between consecutive frames, from position alone."""
        out = []
        if self.dt is None:
            return out
        for i, p in self.ego_pos.items():
            q = self.ego_pos.get(i + 1)
            if q is None:
                continue
            d = sum((a - b) ** 2 for a, b in zip(p, q)) ** 0.5
            out.append((i, d / self.dt))
        return out

    def report(self) -> list[str]:
        findings: list[str] = []
        implied = self._displacement_speeds()

        # 1. The ego moves between frames but the graph says it is stationary.
        #    A replayed actor is teleported, so `get_velocity()` returns zero
        #    while its position still advances. Reads as a parked vehicle to
        #    every dynamics predicate, and the direction is a missed violation.
        if implied and self.ego_graph_speed:
            moving = [i for i, v in implied if v > self.MOVING_MPS]
            zero = [i for i in moving
                    if self.ego_graph_speed.get(i, 1.0) <= 1e-6]
            if moving and len(zero) > 0.5 * len(moving):
                findings.append(
                    f"the ego's position advances on {len(moving)} frame(s) "
                    f"while `carla_speed` reads zero on {len(zero)} of them. "
                    f"The graph's speed is not evidence on this capture; the "
                    f"ego log is. Record `capture_mode` in the manifest so the "
                    f"conversion can prefer the log rather than guess.")

        # 2. Two sources for one quantity that disagree beyond noise.
        both = set(self.ego_graph_speed) & set(self.ego_log_speed)
        if both:
            bad = [i for i in both
                   if abs(self.ego_graph_speed[i] - self.ego_log_speed[i])
                   > self.SPEED_TOLERANCE * max(self.ego_log_speed[i], 1.0)]
            if len(bad) > 0.1 * len(both):
                findings.append(
                    f"graph `carla_speed` and the ego log's velocity disagree "
                    f"on {len(bad)} of {len(both)} shared frame(s). One of the "
                    f"two describes a different vehicle state than the other.")

        # 3. The same sign, described twice, with incompatible units. The sign
        #    ACTOR's unit is fixed by the blueprint id; the landmark's is
        #    written by the map author. Equal numbers under different unit
        #    claims mean the claim is wrong, not the number.
        if self.landmarks and self.sign_kph:
            # Compared numerically: the landmark writes "90.0" where the
            # blueprint id writes "90", and string equality would miss it.
            values = {self._f(v) for v, _ in self.landmarks} - {None}
            units = {u for _, u in self.landmarks}
            signs = {self._f(k) for k in self.sign_kph} - {None}
            if values & signs and units and "km/h" not in units:
                findings.append(
                    f"landmark values {sorted(values & signs)} match "
                    f"speed-limit sign blueprints, whose unit is km/h by "
                    f"construction, while the map labels them {sorted(units)}. "
                    f"The map's unit label contradicts the simulator's own; a "
                    f"rule matching on it exactly will never fire, and one "
                    f"converting from it will read a limit that is too high.")

        # 4. The rate the motion implies, against the rate that was declared.
        if implied and self.dt:
            ratios = []
            for i, v in implied:
                speed = self.ego_log_speed.get(i) or self.ego_graph_speed.get(i)
                if speed and speed > self.MOVING_MPS:
                    ratios.append(v / speed)
            if len(ratios) >= 20:
                ratios.sort()
                med = ratios[len(ratios) // 2]
                if abs(med - 1.0) > 0.2:
                    findings.append(
                        f"displacement per frame implies a rate {med:.2f}x the "
                        f"declared one. Every duration in every rule is a frame "
                        f"count at the declared rate, so this rescales all of "
                        f"them.")
        return findings


# Frames per generated chunk definition, sized so each chunk stays under the
# ~500 KB where Lean's code generator starts to fail.
#
# 25 was calibrated on captures carrying a handful of distinct entities, and it
# is not enough: chunk size scales with entities-per-frame, not frames. The
# SceneFlowLang agent routes carry 214 distinct entities against 6 for its
# replayed scenario captures, and every one of those 30 routes failed to build
# at 25 with `depends on declaration ...Chunk1, which has no executable code`.
# 8 builds all of them.
CHUNK_FRAMES = 8

# Lean namespace and library root of every converted capture. Kept as one
# constant because three consumers agree on it by name: `library/lakefile.lean`
# declares the root, `scripts/run_spec.py` imports the module the harness
# needs, and `scripts/lean_check.py` holds the same string for the check that
# keeps captures out of the tree the formalization agents read.
EVAL_NAMESPACE = "TrafficSpecEval"

# Enough decimals to preserve everything `Core/Decimal.lean` keeps — it
# truncates to thousandths — with margin, and few enough to stay readable.
_NUM_DECIMALS = 6


def fmt_num(value: Any, default: str = "0.0") -> str:
    """Render a numeric attribute in plain fixed-point notation.

    Must NOT be `str(float(value))`. Python switches to scientific notation
    below 1e-4, and `Core/Decimal.lean` accepts only
    `[+-]? digit+ ( '.' digit+ )?` — it documents that exponent notation yields
    `none`, and `leMilli`/`geMilli` both return **false** for an unparseable
    value.

    The consequence was not a missing comparison but an inverted one. A
    stationary ego has `speed` around 5e-05 m/s, which `str(float)` renders
    `"4.935048855259083e-05"`; `speedLeKph v 50` then reads false, and
    `□ (isEgo v ⟹ speedLeKph v 50)` reports a **speeding violation for a
    parked car**. `Pred.stopped` is false at the same time, since `speedLe`
    fails identically, so the vehicle is simultaneously not-stopped and
    over the limit. Every rule reading a numeric ego channel — speed, accel,
    throttle, brake, steer, yaw_rate — was affected on any capture where the
    ego came to rest, which is exactly what the compliant red-light and
    stop-sign captures are for.

    Fixed-point avoids the exponent for every magnitude CARLA produces.
    """
    try:
        number = float(value)
    except (TypeError, ValueError):
        return default
    # `nan`/`inf` are rejected by the parser too, and there is no honest
    # numeral for them; the default keeps the attribute readable as zero.
    if number != number or number in (float("inf"), float("-inf")):
        return default
    return f"{number:.{_NUM_DECIMALS}f}"


def fmt_bool(value: Any) -> str:
    return "true" if bool(value) else "false"


# Deliberately NOT lifted, each for a reason that holds for any law corpus:
#   vertex_point  the same x,y as `vertex`, as a shapely POINT.
#   light_All,    enum masks (all-on / no-lights), not lamps.
#   light_NONE
#   carla_type_id the blueprint id, already lifted as `sem_class`.
#   vehicle_light_state  the packed integer whose bits are lifted individually.
#   landmark physical geometry (pitch, roll, height, width, offsets, name) —
#                 sign shape and an authoring label; nothing relates the pose
#                 to lanes that carry no coordinates, and the legend a sign
#                 shows is `landmark_text`, which is lifted.
#   ego_control_* the control the CALLER passed to generate_graph_for_frame
#                 (sgg.py:565-570), written beside the applied control
#                 `copy_carla_control` reads back from the server (:562), which
#                 is lifted. The commanded and the applied control differ by at
#                 most one tick's latency.
# Consumed but emitted under another name: `threedbbox`, `right`, `up` (the
# half-extents) and `entity_id` (`map_scenery`, and the identity key).


def _vec3(raw: Any) -> Optional[tuple[float, float, float]]:
    """Three floats out of a numpy array or sequence, or None."""
    try:
        comps = [float(v) for v in list(raw)][:3]
    except (TypeError, ValueError):
        return None
    if len(comps) != 3 or any(c != c for c in comps):
        return None
    return (comps[0], comps[1], comps[2])


def _norm(v: tuple[float, float, float]) -> float:
    return (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) ** 0.5


def heading_vector(attr: dict) -> Optional[tuple[float, float, float]]:
    """The node's `forward`, as the unit direction it is meant to be.

    `sgg.py` writes `forward` as a unit vector on every path but one. In the
    traffic-light branch that iterates `get_light_boxes()` it computes
    `forward = bbox.location + <unit forward>` (:595-600) — a POINT one metre
    ahead of the light head, not a direction — and passes that to
    `__add_to_graph`, where it lands on the node as `forward`. Read raw, that
    makes every heading predicate over a traffic light compare a map
    coordinate with a unit vector. The point is recoverable exactly: subtracting
    `vertex` (the same `bbox.location`) returns the unit vector the generator
    added. The repair fires only when the raw value cannot be a direction
    (its norm is far from one) and the difference can (its norm is about one),
    so a genuine unit vector is never touched.
    """
    fwd = _vec3(attr.get("forward"))
    if fwd is None:
        return None
    n = _norm(fwd)
    if 0.5 <= n <= 1.5:
        return fwd
    pos = _vec3(attr.get("vertex"))
    if pos is None:
        return fwd
    diff = (fwd[0] - pos[0], fwd[1] - pos[1], fwd[2] - pos[2])
    if 0.5 <= _norm(diff) <= 1.5:
        return diff
    return fwd


def vector_attrs(attr: dict) -> list:
    """Position and heading, one decimal string per component."""
    out = []
    pos = _vec3(attr.get("vertex"))
    if pos is not None:
        out += list(zip(GEOMETRY_VECTORS["vertex"], (fmt_num(c) for c in pos)))
    fwd = heading_vector(attr)
    if fwd is not None:
        out += list(zip(GEOMETRY_VECTORS["forward"], (fmt_num(c) for c in fwd)))
    return out


def extent_attrs(attr: dict) -> list:
    """Half-extents of the body along its own axes, from `threedbbox`.

    Each of the eight corners is taken relative to `vertex` and projected onto
    the unit `forward`, `right` and `up` the same node carries; the half-extent
    on an axis is the largest absolute projection. Nothing is emitted when the
    box is absent (captures made with a generator predating the field) or when
    any axis is unreadable, so a rule reading the extents sees absence rather
    than a guessed size.
    """
    box = attr.get("threedbbox")
    if box is None:
        return []
    try:
        corners = [_vec3(c) for c in list(box)]
    except TypeError:
        return []
    if len(corners) != 8 or any(c is None for c in corners):
        return []
    pos = _vec3(attr.get("vertex"))
    axes = (heading_vector(attr), _vec3(attr.get("right")), _vec3(attr.get("up")))
    if pos is None or any(a is None for a in axes):
        return []
    out = []
    for name, axis in zip(EXTENT_ATTRS, axes):
        n = _norm(axis)
        if not (0.5 <= n <= 1.5):
            return []
        unit = (axis[0] / n, axis[1] / n, axis[2] / n)
        half = max(abs((c[0] - pos[0]) * unit[0] + (c[1] - pos[1]) * unit[1]
                       + (c[2] - pos[2]) * unit[2]) for c in corners)
        out.append((name, fmt_num(half)))
    return out


def landmark_orientation_name(raw: Any) -> Optional[str]:
    """`carla.LandmarkOrientation` as its member name, however it was pickled.

    A Boost.Python enum pickles as its class plus the integer value, so the
    unpickler's `OpaqueValue` stand-in receives the integer in `args`. A
    generator that `str()`s the field first would deliver the name itself, and
    a plain integer is accepted too. Anything else yields None and the key is
    not emitted.
    """
    if raw is None:
        return None
    if isinstance(raw, str):
        for name in LANDMARK_ORIENTATION_NAMES:
            if name.lower() in raw.lower():
                return name
        return None
    if isinstance(raw, bool):
        return None
    value: Any = raw
    if not isinstance(raw, int):
        args = getattr(raw, "args", None)
        value = args[0] if args else None
    if isinstance(value, int) and not isinstance(value, bool) \
            and 0 <= value < len(LANDMARK_ORIENTATION_NAMES):
        return LANDMARK_ORIENTATION_NAMES[value]
    return None


def scenery_attrs(attr: dict) -> list:
    """`map_scenery = "true"` for a node the level geometry produced.

    Two marks, either sufficient, both from sgg.py Step 4: a negative
    `entity_id` (:462), or a `sem_class` that is a `CityObjectLabel` member
    name rather than a blueprint id (:456). Older generator versions passed no
    `entity_id` at all, which is why the second test exists. Emitted only when
    true, like the light booleans.
    """
    eid = attr.get("entity_id")
    if isinstance(eid, int) and not isinstance(eid, bool) and eid < 0:
        return [(SCENERY_ATTR, "true")]
    if str(attr.get("sem_class")) in SCENERY_SEM_CLASSES:
        return [(SCENERY_ATTR, "true")]
    return []


def _pos_key(attr: dict) -> str:
    """A position rounded to the centimetre, as an identity for a static node."""
    pos = _vec3(attr.get("vertex"))
    if pos is None:
        return ""
    return "@" + ",".join(f"{c:.2f}" for c in pos)


def entity_key(name: str, lean_type: str, attr: dict) -> str:
    """The identity a Lean `EntityId` is assigned to — see the module docstring.

    Structure nodes: the name, which is the OpenDRIVE identity. Ego: `ego`.
    Traffic lights: `carla_id` plus position, because the light-box branch makes
    one node per lamp head of the same actor (sgg.py:585-612). Other actors:
    `carla_id`, or the ego-style `entity_id` when positive. Landmarks:
    `landmark_id`. Map scenery: the negative `entity_id`, or failing that the
    position — a static object does not move. Anything else static and
    unidentified: type plus position; and only when even that is missing, the
    counter name, which is then reported.
    """
    if lean_type in ("lane", "road", "junction", "offRoad"):
        return f"struct:{name}"
    if is_ego(name, attr):
        return "ego"
    cid = attr.get("carla_id")
    if isinstance(cid, int) and not isinstance(cid, bool):
        if lean_type == "trafficLight":
            return f"actor:{cid}{_pos_key(attr)}"
        return f"actor:{cid}"
    if lean_type == "landmark":
        lid = attr.get("landmark_id")
        if lid is not None:
            return f"landmark:{lid}"
    eid = attr.get("entity_id")
    if isinstance(eid, int) and not isinstance(eid, bool):
        if eid < 0:
            return f"static:{eid}"
        return f"actor:{eid}"
    pos = _pos_key(attr)
    if pos:
        return f"{lean_type}{pos}"
    return f"name:{name}"


def scalar_attrs(attr: dict, mapping: dict) -> list:
    """Lift `mapping`'s keys, rendering numbers fixed-point and bools as
    `"true"`/`"false"` so `Core/Decimal.lean` and `attrTrue` can read them."""
    out = []
    for lean_name, raw_key in mapping.items():
        if raw_key not in attr:
            continue
        value = attr[raw_key]
        if isinstance(value, bool):
            out.append((lean_name, "true" if value else "false"))
        elif isinstance(value, int):
            # An integer stays an integer: `Core/Decimal.lean` reads "672" and
            # "672.000000" alike, but an IDENTITY (`carla_id`, `landmark_id`)
            # is also compared by `attrEq`, and a scenario writes it plain.
            out.append((lean_name, str(value)))
        elif isinstance(value, float):
            out.append((lean_name, fmt_num(value)))
        else:
            out.append((lean_name, str(value)))
    return out


def lean_attr_list(pairs: list[tuple[str, str]]) -> str:
    inner = ", ".join(f'("{lean_str(k)}", "{lean_str(v)}")' for k, v in pairs)
    return f"[{inner}]"


def _num_or_none(value: Any) -> Optional[float]:
    return value if isinstance(value, (int, float)) and not isinstance(value, bool) else None


def ego_accel(attr: dict, state: dict, policy: "RecordingPolicy") -> str:
    """The scalar `accel` channel.

    Taken from the GRAPH's own `carla_acc_{x,y,z}` magnitude in preference to
    the ego log, which reverses the previous order for two reasons.

    First, correctness of frame position. The log is indexed separately from the
    frames and can be offset from them; the graph's components are in the frame
    they are read from, by construction. A channel whose value is right and
    whose frame is wrong is not usable — `Core` attaches it to a scene, and the
    scene is the other one.

    Second, availability. Taking it from the log alone meant that a capture with
    no ego log got `0.0`, silently, from `state.get(...).get("value", 0.0)`.
    That is every one of the 30 agent-rollout captures in the SceneFlowLang
    corpus — and their graphs carry an acceleration magnitude of up to
    12.69 m/s^2. `Pred.accelMagnitudeAtLeast` read a stationary vehicle on all
    of them.

    A square root over three components the graph already carries is a
    computation on this frame's own data, not a substitution from another
    source, so it does not weaken the guarantee the rest of this function makes.
    """
    if not policy.dynamics_valid:
        return UNMEASURED
    comps = [_num_or_none(attr.get(k))
             for k in ("carla_acc_x", "carla_acc_y", "carla_acc_z")]
    if all(c is not None for c in comps):
        return fmt_num(sum(c * c for c in comps) ** 0.5)
    logged = _num_or_none((state.get("acceleration") or {}).get("value"))
    return UNMEASURED if logged is None else fmt_num(logged)


def ego_channels(attr: dict, record: Optional[dict],
                 policy: "RecordingPolicy") -> list[str]:
    """The nine `mkEgo` channels.

    **No channel is ever filled with a number the capture did not supply.** A
    missing measurement is emitted as `UNMEASURED`, which every `Core/Decimal`
    comparison reads as false in both directions — the same verdict an absent
    attribute gets, and the only honest one. See `UNMEASURED` for why the
    fabricated `0.0` this replaced was not neutral.

    Three of the nine are destroyed by a recorder replay and are gated on
    `policy.dynamics_valid`: `speed`, `accel` and `yaw_rate`. The other six are
    not: `throttle`, `brake` and `steer` come from `get_control()`, which the
    replayer restores, and the three booleans are graph state. Measured on the
    replayed `HazardAtSideLaneTwoWays` capture: `carla_throttle` takes 0.8 and
    `carla_brake` 0.3 across frames while `carla_speed` and `carla_ang_vel_z`
    are identically zero on all 962.
    """
    record = record or {}
    state = record.get("state", {}) or {}
    control = record.get("control", {}) or {}

    def graph_or_log(graph_key: str, log_value: Any) -> str:
        """Graph first — it is in the frame being emitted. The log is a
        fallback whose alignment is the caller's to establish."""
        graphed = _num_or_none(attr.get(graph_key))
        if graphed is not None:
            return fmt_num(graphed)
        logged = _num_or_none(log_value)
        return UNMEASURED if logged is None else fmt_num(logged)

    def dynamic(graph_key: str, log_value: Any) -> str:
        """A channel a replay teleports away. Never guessed."""
        if not policy.dynamics_valid:
            return UNMEASURED
        return graph_or_log(graph_key, log_value)

    return [
        dynamic("carla_speed", (state.get("velocity") or {}).get("value")),
        ego_accel(attr, state, policy),
        graph_or_log("carla_throttle", control.get("throttle")),
        graph_or_log("carla_brake", control.get("brake")),
        graph_or_log("carla_steer", control.get("steer")),
        dynamic("carla_ang_vel_z",
                (state.get("angular_velocity") or {}).get("z")),
        fmt_bool(attr.get("carla_affected_by_traffic_light", False)),
        fmt_bool(attr.get("carla_hand_brake", control.get("hand_brake", False))),
        fmt_bool(attr.get("carla_reverse", control.get("reverse", False))),
    ]


def light_attrs(attr: dict) -> list[tuple[str, str]]:
    """Per-light booleans, emitted only when lit — an absent boolean already
    reads as false in Lean."""
    return [(key, "true") for key, raw in VEHICLE_LIGHTS.items()
            if bool(attr.get(raw, False))]


def posted_limit_kph(sem_class: Optional[str]) -> Optional[str]:
    """The posted value out of a `traffic.speed_limit.<kph>` blueprint id."""
    text = str(sem_class or "")
    prefix = "traffic.speed_limit."
    if prefix in text:
        tail = text.split(prefix, 1)[1].split(".")[0]
        if tail.isdigit():
            return tail
    return None


def is_ego(name: str, attr: dict) -> bool:
    return str(name).lower() == "ego" or attr.get("special_class") == "ego"


def build_module(rsv_dir: Path, ego_log: Optional[Path], module_name: str,
                 max_frames: Optional[int],
                 start_frame: int = 0,
                 manifest_path: Optional[Path] = None,
                 declared: Optional[dict] = None,
                 declared_recording: Optional[dict] = None) -> tuple[str, dict]:
    """Convert a window of a capture into a Lean `Trace`.

    `start_frame` exists because the whole trace is emitted as one Lean list
    literal, and Lean's *code generator* — not its elaborator — overflows on
    large ones with "maximum recursion depth reached in the code generator".
    The limit tracks the size of the generated literal rather than the frame
    count: a dense junction capture built at ~470 KB and failed at ~640 KB.

    Taking only a prefix (`--max-frames` alone) is not enough, because the
    moment a rule is about — the frame a vehicle crosses into a junction — is
    usually in the middle of a capture. A window keeps that moment and its
    surrounding context while staying under the limit.
    """
    settings = check_capture_preconditions(rsv_dir, manifest_path, declared)
    files = sorted(rsv_dir.glob("*.pkl"), key=lambda p: natural_key(p.name))
    if not files:
        raise ValueError(f"no .pkl frames found in {rsv_dir}")
    if start_frame < 0:
        raise ValueError(f"--start-frame must not be negative: {start_frame}")
    if start_frame >= len(files):
        raise ValueError(f"--start-frame {start_frame} is past the last of "
                         f"{len(files)} frames in {rsv_dir}")
    files = files[start_frame:]
    if max_frames:
        files = files[:max_frames]

    policy = resolve_recording_policy(rsv_dir, files, settings, manifest_path,
                                      declared_recording)
    print(f"[info] recording policy: {policy} ({policy.provenance})")

    ego_records: list[dict] = []
    if ego_log and ego_log.exists():
        ego_records = json.loads(ego_log.read_text(encoding="utf-8")).get("records", [])

    # Identity key -> Lean entity id, for the whole trace. Keyed by
    # `entity_key`, NOT by the RSV node name: the name is a per-frame counter
    # and splices different physical entities into one binding.
    ids: dict[str, int] = {}
    next_id = 1
    frames: list[str] = []
    stats = {
        "recording": policy.as_dict(),
        "frames": 0, "entities": 0, "names": 0,
        "unmapped_labels": {}, "types": {}, "labels": {},
        "unlifted_attrs": {}, "contradictions": [],
        # Identity bookkeeping: how many nodes fell back to the counter name,
        # how many frames had two nodes resolve to one key, and how many
        # traffic-light headings were repaired.
        "identity_by_name": 0, "identity_collisions": 0,
        "headings_repaired": 0,
    }
    names_seen: set[str] = set()
    xcheck = CrossCheck(settings.get("capture_hz"))

    for index, pkl in enumerate(files):
        with pkl.open("rb") as fh:
            graph = SGUnpickler(fh).load()

        nodes = {}
        frame_ids: dict[str, int] = {}
        used_keys: set[str] = set()
        for node in graph.nodes:
            name = str(getattr(node, "name", node))
            nodes[name] = node
            names_seen.add(name)
            attr = getattr(node, "attr", {}) or {}
            key = entity_key(name, classify(name, getattr(node, "base_class", None),
                                            attr.get("sem_class")), attr)
            if key.startswith("name:"):
                stats["identity_by_name"] += 1
            if key in used_keys:
                # Two nodes of one frame resolving to one identity would give
                # the frame two entities with one id, and `Scene.getEntity`
                # would read the first. Keep them apart and say so.
                stats["identity_collisions"] += 1
                key = f"{key}#{name}"
            used_keys.add(key)
            if key not in ids:
                ids[key] = next_id
                next_id += 1
            frame_ids[name] = ids[key]

        def emit(built: str, extra: list) -> None:
            """One place where an entity's lifted attributes are attached, so a
            new key reaches signals, landmarks and vehicles alike instead of
            only whichever branch someone remembered."""
            if extra:
                built = f"(({built}).withAttrs {lean_attr_list(extra)})"
            entity_src.append(built)

        entity_src: list[str] = []
        for name in sorted(nodes, key=natural_key):
            node = nodes[name]
            attr = getattr(node, "attr", {}) or {}
            sem = attr.get("sem_class")
            lean_type = classify(name, getattr(node, "base_class", None), sem)
            stats["types"][lean_type] = stats["types"].get(lean_type, 0) + 1
            eid = frame_ids[name]

            if lean_type not in ("lane", "road", "junction", "offRoad"):
                for key in attr:
                    if key not in CONSUMED_ATTRS:
                        stats["unlifted_attrs"][key] = \
                            stats["unlifted_attrs"].get(key, 0) + 1

            # Everything the generator put on this node that a builder does
            # not already take, appended uniformly. Structure nodes (lane, road,
            # junction, offRoad) carry no attributes at all — the abstraction
            # builds them as `Node(name=...)` — so they get nothing.
            raw_fwd = _vec3(attr.get("forward"))
            if raw_fwd is not None and heading_vector(attr) != raw_fwd:
                stats["headings_repaired"] += 1
            extra = (vector_attrs(attr)
                     + extent_attrs(attr)
                     + scalar_attrs(attr, IDENTITY_ATTRS)
                     + scenery_attrs(attr))
            if lean_type == "landmark":
                extra += scalar_attrs(attr, LANDMARK_EXTRA)
                orientation = landmark_orientation_name(
                    attr.get(LANDMARK_ORIENTATION_KEY))
                if orientation is not None:
                    extra.append((LANDMARK_ORIENTATION_KEY, orientation))
            if is_ego(name, attr):
                lifted = scalar_attrs(attr, EGO_VECTOR_CHANNELS)
                if not policy.dynamics_valid:
                    # Suppress the KEY, not the value. `Pred.acceleratingAtLeast`
                    # reads `acc_x/y/z` through `alongHeading`, which returns
                    # `none` when a component is missing and `false` from there
                    # — whereas three zeros are a well-formed vector of
                    # magnitude zero and read as "definitely not accelerating".
                    lifted = [(k, v) for k, v in lifted
                              if k not in EGO_REPLAY_INVALID_VECTORS]
                extra += lifted
            elif lean_type == "landmark":
                xcheck.observe_landmark(attr)
            elif lean_type == "speedLimitSign":
                xcheck.observe_sign(attr)

            if is_ego(name, attr):
                # The ego log is indexed by absolute capture frame, so a window
                # starting at `start_frame` must offset into it or every ego
                # dynamic channel is silently taken from the wrong frame.
                # The ego log is indexed by absolute capture frame, so a
                # window starting at `start_frame` must offset into it, and so
                # must a capture whose frame origin differs from the log's —
                # see `RecordingPolicy.ego_log_frame_offset`.
                log_index = start_frame + index + policy.ego_log_frame_offset
                record = (ego_records[log_index]
                          if 0 <= log_index < len(ego_records) else None)
                xcheck.observe_ego(index, attr, record)
                args = " ".join(f'"{lean_str(v)}"'
                                for v in ego_channels(attr, record, policy))
                emit(f"mkEgo {eid} .{lean_type} {args}", extra)
            elif lean_type == "lane":
                emit(f'mkLane {eid} "{lean_str(name)}"', extra)
            elif lean_type == "road":
                emit(f'mkRoad {eid} "{lean_str(name)}"', extra)
            elif lean_type == "junction":
                emit(f'mkJunction {eid} "{lean_str(name)}"', extra)
            elif lean_type == "offRoad":
                emit(f"mkOffRoad {eid}", extra)
            elif lean_type == "trafficLight":
                state = lean_str(str(attr.get("light_state", "Unknown")))
                emit(f'mkTrafficLight {eid} "{lean_str(name)}" "{state}"',
                     extra)
            elif lean_type == "stopSign":
                emit(f'mkStopSign {eid} "{lean_str(name)}"', extra)
            elif lean_type == "speedLimitSign":
                kph = posted_limit_kph(sem) or ""
                emit(f'mkSpeedLimitSign {eid} "{lean_str(name)}" '
                     f'"{lean_str(kph)}"', extra)
            elif lean_type == "landmark":
                fields = " ".join(
                    f'"{lean_str(str(attr.get(k, "")))}"' for k in LANDMARK_FIELDS)
                emit(f'mkLandmark {eid} "{lean_str(name)}" {fields}', extra)
            else:
                special = attr.get("special_class")
                special_arg = f'(some "{lean_str(special)}")' if special else "none"
                sem_arg = f'(some "{lean_str(str(sem))}")' if sem else "none"
                actor = (f'mkActor {eid} "{lean_str(name)}" .{lean_type} '
                         f'{special_arg} {sem_arg}')
                if lean_type in VEHICLE_TYPES:
                    extra = (light_attrs(attr)
                             + scalar_attrs(attr, EXTRA_VEHICLE_LIGHTS) + extra)
                emit(actor, extra)

        rel_src: list[str] = []
        for u, v, data in graph.edges(data=True):
            raw = str(data.get("label", "")) if isinstance(data, dict) else ""
            mapped = REL_LABELS.get(raw)
            if mapped is None:
                stats["unmapped_labels"][raw or "<empty>"] = \
                    stats["unmapped_labels"].get(raw or "<empty>", 0) + 1
                continue
            stats["labels"][mapped] = stats["labels"].get(mapped, 0) + 1
            src = frame_ids[str(getattr(u, "name", u))]
            tgt = frame_ids[str(getattr(v, "name", v))]
            rel_src.append(f"mkRel {src} .{mapped} {tgt}")

        frames.append(
            "    frame\n"
            f"      [{', '.join(entity_src)}]\n"
            f"      [{', '.join(rel_src)}]"
        )
        stats["frames"] += 1

    stats["entities"] = len(ids)
    stats["names"] = len(names_seen)

    # Emit the trace in chunks, not as one list literal.
    #
    # Lean's *code generator* — not its elaborator — recurses over a literal and
    # dies with "maximum recursion depth reached in the code generator" once it
    # gets large. The limit tracks the literal's size rather than the frame
    # count: a dense junction capture built at ~470 KB and failed at ~640 KB.
    #
    # A window was the previous workaround, and it was unsound: a rule's verdict
    # then depended on how many frames were converted, because
    # `Core/Semantics.lean::loopBounded` reads a window that overruns the trace
    # as false, which for a `□ (¬ₛ .bounded n bad)` rule means *compliant*.
    # Chunking removes the trade-off — every frame of the capture is evaluated,
    # and each chunk is small enough for the code generator on its own.
    chunks = [frames[i:i + CHUNK_FRAMES]
              for i in range(0, len(frames), CHUNK_FRAMES)] or [[]]
    chunk_defs: list[str] = []
    for index, chunk in enumerate(chunks):
        chunk_defs += [
            f"private def {module_name}Chunk{index} : Trace :=",
            "  [",
            ",\n".join(chunk),
            "  ]",
            "",
        ]
    joined = " ++ ".join(f"{module_name}Chunk{i}" for i in range(len(chunks)))

    lines = [
        "/- Generated by carla/adapter.py. Do not edit by hand. -/",
        "import TrafficSpec.Core.Builders",
        "",
        f"namespace {EVAL_NAMESPACE}",
        "",
        "open TrafficSpec",
        "",
        *chunk_defs,
        f"/-- Captured from {rsv_dir.name}: {stats['frames']} frames "
        f"(capture frames {start_frame}..{start_frame + stats['frames'] - 1}), "
        f"{stats['entities']} distinct entities, in "
        f"{len(chunks)} chunk(s) of at most {CHUNK_FRAMES}. -/",
        f"def {module_name}Trace : Trace :=",
        f"  {joined}",
        "",
        f"end {EVAL_NAMESPACE}",
        "",
    ]
    stats["contradictions"] = xcheck.report()
    return "\n".join(lines), stats


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--rsv-dir", type=Path, required=True)
    ap.add_argument("--ego-log", type=Path, default=None)
    ap.add_argument("--output", type=Path, required=True)
    ap.add_argument("--module-name", default="Captured")
    ap.add_argument("--max-frames", type=int, default=None)
    ap.add_argument("--manifest", type=Path, default=None,
                    help="capture settings, in the shape of "
                         "carla/simulation.template.json. Defaults to "
                         "simulation.json beside --rsv-dir. Required unless "
                         "--declare-capture-hz is given: every duration, metre "
                         "bound and angular relation in the library is read "
                         "against these settings, so they are never assumed.")
    ap.add_argument("--declare-capture-hz", type=int, default=None,
                    metavar="N",
                    help="assert the capture rate for a capture that has no "
                         "manifest. Must accompany --declare-generator-defaults.")
    ap.add_argument("--declare-capture-mode", choices=("live", "replay"),
                    default=None,
                    help="how the capture was recorded. `replay` means a CARLA "
                         "recorder log was replayed, which teleports actors: "
                         "speed, accel and yaw_rate are not measurements and "
                         "are emitted as `unmeasured` rather than as zeros. "
                         "Overrides the adapter's own detection.")
    ap.add_argument("--declare-ego-log-offset", type=int, default=None,
                    help="frames to add when indexing the ego log, for a "
                         "capture whose frame origin differs from its log's. "
                         "carla_sgg's capture_sensor_data.py produces +10.")
    ap.add_argument("--declare-generator-defaults", action="store_true",
                    help="assert that the generator ran with its default "
                         "proximity thresholds, directional thresholds, "
                         "relation tables and the process_to_junction_rsv "
                         "abstraction. An assertion by the caller, not a check.")
    ap.add_argument("--start-frame", type=int, default=0,
                    help="first capture frame to convert; with --max-frames "
                         "this selects a window, which is how a long capture "
                         "is kept under Lean's code-generator limit without "
                         "dropping the moment the rule is about")
    args = ap.parse_args()

    declared_recording = None
    if args.declare_capture_mode is not None or args.declare_ego_log_offset is not None:
        declared_recording = {
            "capture_mode": args.declare_capture_mode or "unknown",
            "dynamics_valid": args.declare_capture_mode != "replay",
            "ego_log_frame_offset": args.declare_ego_log_offset or 0,
        }

    declared = None
    if args.declare_capture_hz is not None:
        if not args.declare_generator_defaults:
            print("[error] --declare-capture-hz must accompany "
                  "--declare-generator-defaults: the rate alone leaves the "
                  "thresholds, tables and abstraction unstated, and those are "
                  "three of the five preconditions.")
            return 2
        declared = {"capture_hz": args.declare_capture_hz,
                    "fixed_delta_seconds": 1.0 / args.declare_capture_hz,
                    "abstraction": ASSUMED_ABSTRACTION}
    elif args.declare_generator_defaults:
        print("[error] --declare-generator-defaults must accompany "
              "--declare-capture-hz: the rate is the one setting no default "
              "can supply.")
        return 2

    try:
        text, stats = build_module(args.rsv_dir, args.ego_log,
                                   args.module_name, args.max_frames,
                                   args.start_frame,
                                   manifest_path=args.manifest,
                                   declared=declared,
                                   declared_recording=declared_recording)
    except Exception as exc:
        print(f"[error] {exc}")
        return 1

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    print(f"Wrote {args.output}: {stats['frames']} frames, {stats['entities']} entities")
    print(f"  entity types : {stats['types']}")
    print(f"  relations    : {stats['labels']}")
    print(f"  identity     : {stats['entities']} physical entities behind "
          f"{stats['names']} RSV node names; {stats['identity_by_name']} node(s) "
          f"identified by name only, {stats['identity_collisions']} same-frame "
          f"collision(s), {stats['headings_repaired']} heading(s) repaired")
    if stats.get("contradictions"):
        print("  CONTRADICTIONS — two descriptions of one fact disagree in this "
              "capture. Each makes some rule read the wrong thing, and every "
              "one of them errs toward reporting compliance:")
        for finding in stats["contradictions"]:
            print(f"    - {finding}")
    if stats["unmapped_labels"]:
        print("  UNMAPPED relation labels (dropped) — check carla/schema.json:")
        for label, count in sorted(stats["unmapped_labels"].items()):
            print(f"    {label}: {count}")
    if stats["unlifted_attrs"]:
        print("  attributes present but not lifted (see `available_not_exposed` "
              "in carla/schema.json before calling a law unsupported):")
        for key, count in sorted(stats["unlifted_attrs"].items()):
            print(f"    {key}: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


# ── What a rule can read: derived, never declared ──────────────────────────

def lifted_attribute_keys(library_root: Path) -> set[str]:
    """Every attribute key a Lean rule can read, derived from what puts it there.

    Two sources, and between them they are exhaustive: the mapping tables above,
    which say what THIS file lifts out of a scene graph, and the literal keys in
    `Core/Builders.lean`, which say what the constructors set on an entity
    regardless of any capture.

    `carla/schema.json` used to declare this as a hand-maintained list. It was
    exactly right — 53 keys, agreeing in both directions — which is the problem:
    a second copy that happens to be correct today is a maintenance cost with no
    guarantee attached, and adding a lifted key meant editing this file and then
    remembering to edit that list. Deriving it means the list cannot drift,
    because there is no list.
    """
    keys: set[str] = set(EGO_CHANNELS)
    for names in GEOMETRY_VECTORS.values():
        keys |= set(names)
    for table in (EGO_VECTOR_CHANNELS, EXTRA_VEHICLE_LIGHTS, IDENTITY_ATTRS,
                  LANDMARK_EXTRA, VEHICLE_LIGHTS):
        keys |= set(table)
    keys |= set(EXTENT_ATTRS) | {SCENERY_ATTR, LANDMARK_ORIENTATION_KEY}
    builders = library_root / "TrafficSpec" / "Core" / "Builders.lean"
    keys |= set(re.findall(r'\("(\w+)",', builders.read_text(encoding="utf-8")))
    return keys


def generator_key_to_lean(library_root: Path) -> dict[str, list[str]]:
    """Generator attribute key -> the Lean key(s) it is lifted as.

    The rename is real and easy to trip over: `vertex` reaches Lean as
    `pos_x`/`pos_y`/`pos_z`, `carla_speed` as `speed`. Without this, a rule that
    reaches for the generator's name is told the attribute does not exist —
    which is the answer that pushes a formalizable law toward `unsupported`.
    """
    out: dict[str, list[str]] = {}
    for raw, names in GEOMETRY_VECTORS.items():
        out[raw] = list(names)
    for table in (EGO_VECTOR_CHANNELS, EXTRA_VEHICLE_LIGHTS, IDENTITY_ATTRS,
                  LANDMARK_EXTRA, VEHICLE_LIGHTS):
        for lean, raw in table.items():
            out.setdefault(raw, []).append(lean)
    out[LANDMARK_ORIENTATION_KEY] = [LANDMARK_ORIENTATION_KEY]
    out["threedbbox"] = list(EXTENT_ATTRS)
    out["entity_id"] = [SCENERY_ATTR]
    for lean, raw in (("speed", "carla_speed"), ("throttle", "carla_throttle"),
                      ("brake", "carla_brake"), ("steer", "carla_steer"),
                      ("yaw_rate", "carla_ang_vel_z"),
                      ("hand_brake", "carla_hand_brake"),
                      ("reverse", "carla_reverse"),
                      ("at_traffic_light", "carla_affected_by_traffic_light")):
        out.setdefault(raw, []).append(lean)
    return out
