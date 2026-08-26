#!/usr/bin/env python3
"""Convert CARLA RSV scene-graph frames into a Lean `Trace`.

    python3 carla/adapter.py --rsv-dir <dir of .pkl> --ego-log <ego_logs.json> \
        --output library/TrafficSpec/Carla/Captured.lean --module-name Captured

Reads the RoadScene2Vec-style abstraction produced by
`carla_sgg.sgg_abstractor.process_to_junction_rsv` (see
https://github.com/less-lab-uva/carla_scene_graphs) and emits a Lean module
defining `TrafficSpec.Carla.<module_name>Trace`.

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
# Measured on the 240-frame junction_yield_violation capture, bytes added to the
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

# Stable cross-frame identity. The adapter keys entities by NAME, which merges
# two nodes that share one; `carla_id` is the repair.
IDENTITY_ATTRS: dict[str, str] = {"carla_id": "carla_id"}

# Which lanes a landmark is valid for — the governance the `mayAffect` edge
# only approximates.
LANDMARK_EXTRA: dict[str, str] = {
    "landmark_lane_validities": "landmark_lane_validities"}

# Base-graph attribute keys this adapter consumes. Everything else on an actor
# node is reported as unlifted, so the gap is visible instead of silent.
CONSUMED_ATTRS = frozenset(
    {"sem_class", "special_class", "light_state",
     "carla_speed", "carla_throttle", "carla_brake", "carla_steer",
     "carla_ang_vel_z", "carla_hand_brake", "carla_reverse",
     "carla_affected_by_traffic_light"}
    | set(VEHICLE_LIGHTS.values())
    | set(LANDMARK_FIELDS)
    | set(GEOMETRY_VECTORS)
    | set(EGO_VECTOR_CHANNELS.values())
    | set(EXTRA_VEHICLE_LIGHTS.values())
    | set(IDENTITY_ATTRS.values())
    | set(LANDMARK_EXTRA)
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


def check_capture_preconditions(rsv_dir: Path) -> None:
    """Fail closed when a capture's own manifest contradicts frozen Core.

    The manifest is `simulation.json` beside the frame directory, written by
    `sg/carla_scene_graphs/src/carlaspec/runner.py`. It is optional: captures
    predating it convert with a warning, because refusing them outright would
    break the bundled `sceneflow_sample`. When it *is* present its numbers are
    binding.

    Measured on the current library, 17 of 21 rules carry at least one constant
    whose meaning comes from one of these settings — 9 use `secondsToFrames`, 6 a
    metre bound, 8 an angular relation. A capture that breaks a precondition does
    not make those rules fail loudly; it makes them mean something else.
    `secondsToFrames 1` is 20 frames, which at a 40 Hz capture is half a second,
    so a rolling stop satisfies a one-second dwell rule. Nothing in the trace
    would reveal it: `time_base` in the schema records that frames carry no
    timestamp.
    """
    manifest = rsv_dir.parent / "simulation.json"
    if not manifest.exists():
        print(f"[warn] {manifest.name} not found beside {rsv_dir}; assuming the "
              f"capture was recorded at {ASSUMED_CAPTURE_HZ} Hz with the "
              f"generator's default thresholds and abstraction. Nothing "
              f"verifies that.")
        return
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


# Frames per generated chunk definition. 25 keeps each chunk near 100 KB on a
# dense junction capture, comfortably under the ~500 KB where Lean's code
# generator starts to fail, with plenty of margin for denser scenes.
CHUNK_FRAMES = 25

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
#   threedbbox    734,510 bytes — 54% of everything unlifted, and it is eight
#                 corners of a box whose centre `vertex` already gives.
#   vertex_point  127,870 — the same x,y as `vertex`, as a shapely POINT.
#   right, up     238,970 — an orthonormal frame with `forward`; for a vehicle
#                 on a road surface, `forward` alone fixes the heading.
#   light_All,    enum masks (all-on / no-lights), not lamps.
#   light_NONE
#   carla_type_id 52,380 — the blueprint id, already lifted as `sem_class`.
#   entity_id     45,580 — an SGG-internal index, and None on traffic lights.
#   vehicle_light_state  the packed integer whose bits are lifted individually.
#   landmark physical geometry (pitch, roll, height, width, offsets,
#                 orientation, id, name, is_dynamic) — 168,000 bytes of sign
#                 shape, and no predicate can use it while lane nodes carry no
#                 coordinates to relate it to.


def vector_attrs(attr: dict) -> list:
    """Position and heading, one decimal string per component."""
    out = []
    for key, names in GEOMETRY_VECTORS.items():
        raw = attr.get(key)
        if raw is None:
            continue
        try:
            comps = list(raw)
        except TypeError:
            continue
        for lean_name, value in zip(names, comps):
            out.append((lean_name, fmt_num(value)))
    return out


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
        elif isinstance(value, (int, float)):
            out.append((lean_name, fmt_num(value)))
        else:
            out.append((lean_name, str(value)))
    return out


def lean_attr_list(pairs: list[tuple[str, str]]) -> str:
    inner = ", ".join(f'("{lean_str(k)}", "{lean_str(v)}")' for k, v in pairs)
    return f"[{inner}]"


def ego_channels(attr: dict, record: Optional[dict]) -> list[str]:
    """The nine `mkEgo` channels, preferring the graph and falling back to the
    ego log.

    `accel` is the one channel the graph cannot supply: it carries only the
    component vector `carla_acc_{x,y,z}`, whose magnitude needs a square root,
    so the scalar comes from the log's `state.acceleration.value`.
    """
    record = record or {}
    state = record.get("state", {}) or {}
    control = record.get("control", {}) or {}

    def graph_or_log(graph_key: str, log_value: Any) -> str:
        if graph_key in attr:
            return fmt_num(attr[graph_key])
        return fmt_num(log_value)

    return [
        graph_or_log("carla_speed", state.get("velocity", {}).get("value", 0.0)),
        fmt_num(state.get("acceleration", {}).get("value", 0.0)),
        graph_or_log("carla_throttle", control.get("throttle", 0.0)),
        graph_or_log("carla_brake", control.get("brake", 0.0)),
        graph_or_log("carla_steer", control.get("steer", 0.0)),
        graph_or_log("carla_ang_vel_z",
                     state.get("angular_velocity", {}).get("z", 0.0)),
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
                 start_frame: int = 0) -> tuple[str, dict]:
    """Convert a window of a capture into a Lean `Trace`.

    `start_frame` exists because the whole trace is emitted as one Lean list
    literal, and Lean's *code generator* — not its elaborator — overflows on
    large ones with "maximum recursion depth reached in the code generator".
    The limit tracks the size of the generated literal rather than the frame
    count: a Town03 junction capture built at ~470 KB and failed at ~640 KB.

    Taking only a prefix (`--max-frames` alone) is not enough, because the
    moment a rule is about — the frame a vehicle crosses into a junction — is
    usually in the middle of a capture. A window keeps that moment and its
    surrounding context while staying under the limit.
    """
    check_capture_preconditions(rsv_dir)
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

    ego_records: list[dict] = []
    if ego_log and ego_log.exists():
        ego_records = json.loads(ego_log.read_text(encoding="utf-8")).get("records", [])

    ids: dict[str, int] = {}
    next_id = 1
    frames: list[str] = []
    stats = {
        "frames": 0, "entities": 0,
        "unmapped_labels": {}, "types": {}, "labels": {},
        "unlifted_attrs": {},
    }

    for index, pkl in enumerate(files):
        with pkl.open("rb") as fh:
            graph = SGUnpickler(fh).load()

        nodes = {}
        for node in graph.nodes:
            name = str(getattr(node, "name", node))
            nodes[name] = node
            if name not in ids:
                ids[name] = next_id
                next_id += 1

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
            eid = ids[name]

            if lean_type not in ("lane", "road", "junction", "offRoad"):
                for key in attr:
                    if key not in CONSUMED_ATTRS:
                        stats["unlifted_attrs"][key] = \
                            stats["unlifted_attrs"].get(key, 0) + 1

            # Everything the generator put on this node that a builder does
            # not already take, appended uniformly. Structure nodes (lane, road,
            # junction, offRoad) carry no attributes at all — measured: 19 of 23
            # nodes on a real frame have `attr == {}` — so they get nothing.
            extra = (vector_attrs(attr)
                     + scalar_attrs(attr, IDENTITY_ATTRS)
                     + scalar_attrs(attr, LANDMARK_EXTRA))
            if is_ego(name, attr):
                extra += scalar_attrs(attr, EGO_VECTOR_CHANNELS)

            if is_ego(name, attr):
                # The ego log is indexed by absolute capture frame, so a window
                # starting at `start_frame` must offset into it or every ego
                # dynamic channel is silently taken from the wrong frame.
                log_index = start_frame + index
                record = (ego_records[log_index]
                          if log_index < len(ego_records) else None)
                args = " ".join(f'"{lean_str(v)}"'
                                for v in ego_channels(attr, record))
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
            src = ids[str(getattr(u, "name", u))]
            tgt = ids[str(getattr(v, "name", v))]
            rel_src.append(f"mkRel {src} .{mapped} {tgt}")

        frames.append(
            "    frame\n"
            f"      [{', '.join(entity_src)}]\n"
            f"      [{', '.join(rel_src)}]"
        )
        stats["frames"] += 1

    stats["entities"] = len(ids)

    # Emit the trace in chunks, not as one list literal.
    #
    # Lean's *code generator* — not its elaborator — recurses over a literal and
    # dies with "maximum recursion depth reached in the code generator" once it
    # gets large. The limit tracks the literal's size rather than the frame
    # count: a Town03 junction capture built at ~470 KB and failed at ~640 KB.
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
        "namespace TrafficSpec.Carla",
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
        "end TrafficSpec.Carla",
        "",
    ]
    return "\n".join(lines), stats


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--rsv-dir", type=Path, required=True)
    ap.add_argument("--ego-log", type=Path, default=None)
    ap.add_argument("--output", type=Path, required=True)
    ap.add_argument("--module-name", default="Captured")
    ap.add_argument("--max-frames", type=int, default=None)
    ap.add_argument("--start-frame", type=int, default=0,
                    help="first capture frame to convert; with --max-frames "
                         "this selects a window, which is how a long capture "
                         "is kept under Lean's code-generator limit without "
                         "dropping the moment the rule is about")
    args = ap.parse_args()

    try:
        text, stats = build_module(args.rsv_dir, args.ego_log,
                                   args.module_name, args.max_frames,
                                   args.start_frame)
    except Exception as exc:
        print(f"[error] {exc}")
        return 1

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    print(f"Wrote {args.output}: {stats['frames']} frames, {stats['entities']} entities")
    print(f"  entity types : {stats['types']}")
    print(f"  relations    : {stats['labels']}")
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
