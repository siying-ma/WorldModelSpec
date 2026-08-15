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

# Base-graph attribute keys this adapter consumes. Everything else on an actor
# node is reported as unlifted, so the gap is visible instead of silent.
CONSUMED_ATTRS = frozenset(
    {"sem_class", "special_class", "light_state",
     "carla_speed", "carla_throttle", "carla_brake", "carla_steer",
     "carla_ang_vel_z", "carla_hand_brake", "carla_reverse",
     "carla_affected_by_traffic_light"}
    | set(VEHICLE_LIGHTS.values())
    | set(LANDMARK_FIELDS)
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


def fmt_num(value: Any, default: str = "0.0") -> str:
    """Render a numeric attribute the way `str(float)` does, so the decimal
    parser sees the same shapes a capture produces."""
    try:
        return str(float(value))
    except (TypeError, ValueError):
        return default


def fmt_bool(value: Any) -> str:
    return "true" if bool(value) else "false"


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
                 max_frames: Optional[int]) -> tuple[str, dict]:
    files = sorted(rsv_dir.glob("*.pkl"), key=lambda p: natural_key(p.name))
    if not files:
        raise ValueError(f"no .pkl frames found in {rsv_dir}")
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

            if is_ego(name, attr):
                record = ego_records[index] if index < len(ego_records) else None
                args = " ".join(f'"{lean_str(v)}"'
                                for v in ego_channels(attr, record))
                entity_src.append(f"mkEgo {eid} .{lean_type} {args}")
            elif lean_type == "lane":
                entity_src.append(f'mkLane {eid} "{lean_str(name)}"')
            elif lean_type == "road":
                entity_src.append(f'mkRoad {eid} "{lean_str(name)}"')
            elif lean_type == "junction":
                entity_src.append(f'mkJunction {eid} "{lean_str(name)}"')
            elif lean_type == "offRoad":
                entity_src.append(f"mkOffRoad {eid}")
            elif lean_type == "trafficLight":
                state = lean_str(str(attr.get("light_state", "Unknown")))
                entity_src.append(
                    f'mkTrafficLight {eid} "{lean_str(name)}" "{state}"')
            elif lean_type == "stopSign":
                entity_src.append(f'mkStopSign {eid} "{lean_str(name)}"')
            elif lean_type == "speedLimitSign":
                kph = posted_limit_kph(sem) or ""
                entity_src.append(
                    f'mkSpeedLimitSign {eid} "{lean_str(name)}" "{lean_str(kph)}"')
            elif lean_type == "landmark":
                fields = " ".join(
                    f'"{lean_str(str(attr.get(k, "")))}"' for k in LANDMARK_FIELDS)
                entity_src.append(f'mkLandmark {eid} "{lean_str(name)}" {fields}')
            else:
                special = attr.get("special_class")
                special_arg = f'(some "{lean_str(special)}")' if special else "none"
                sem_arg = f'(some "{lean_str(str(sem))}")' if sem else "none"
                actor = (f'mkActor {eid} "{lean_str(name)}" .{lean_type} '
                         f'{special_arg} {sem_arg}')
                lights = light_attrs(attr) if lean_type in VEHICLE_TYPES else []
                if lights:
                    actor = f"(({actor}).withAttrs {lean_attr_list(lights)})"
                entity_src.append(actor)

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

    lines = [
        "/- Generated by carla/adapter.py. Do not edit by hand. -/",
        "import TrafficSpec.Core.Builders",
        "",
        "namespace TrafficSpec.Carla",
        "",
        "open TrafficSpec",
        "",
        f"/-- Captured from {rsv_dir.name}: {stats['frames']} frames, "
        f"{stats['entities']} distinct entities. -/",
        f"def {module_name}Trace : Trace :=",
        "  [",
        ",\n".join(frames),
        "  ]",
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
    args = ap.parse_args()

    try:
        text, stats = build_module(args.rsv_dir, args.ego_log,
                                   args.module_name, args.max_frames)
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
