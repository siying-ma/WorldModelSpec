"""Write a complete manifest.json: every atom id of the full ontology, each declared observed or absent.

    python make_manifest.py > manifest.json        # from this directory

The atom ids are read from the full split's `Ontology/Ids.lean`, so the manifest lists exactly the
atoms the monitor (built from the full split) knows. An atom not in OBSERVED is written `absent`.
A value is `exact`, `estimate:<error class>`, `absent`, or `subject` — observed for the ego alone,
which is how CARLA reports the ego's controls (`hand_brake`, `gear`, `throttle`, `brake`, `steer`)
and the ego-to-actor ray cast `is_visible_from_ego`. OBSERVED below is an example for the modified
CARLA generator; decide every entry for the generator version you actually run, and change the
source string with it.
"""
import json
import re
import sys
from pathlib import Path

PIPELINE = Path(__file__).resolve().parents[3] / "traffic-spec-agent"
IDS = PIPELINE / "library/splits/full/TrafficSpec/Core/Vocab/Ontology/Ids.lean"
SOURCE = "carla-0.9.14 / carla_sgg modified / adapter v0"
REID_GAP_S = 0          # CARLA actor ids never break, so no re-identification is needed

KIN = ["kin.time", "kin.position", "kin.heading", "kin.velocity", "kin.speed",
       "kin.accel_longitudinal", "kin.yaw_rate", "kin.extent", "kin.path_length"]
# computed by Core from the kinematics above when no measured relation is supplied
REL = ["rel.centre_distance", "rel.surface_gap", "rel.ahead_behind_in_lane", "rel.longitudinal_overlap",
       "rel.oncoming", "rel.same_direction", "rel.bearing", "rel.contact"]
# the ego's own controls and its line of sight: CARLA has them for the ego only
EGO_ONLY = ["kin.steer_angle", "kin.parking_brake", "kin.gear", "kin.throttle", "kin.service_brake", "rel.visible"]

OBSERVED = {
    **{a: "exact" for a in KIN + REL},
    **{a: "subject" for a in EGO_ONLY},     # rel.visible needs the generator's check_occlusion; without it, write "absent"
    "ru.subject": "exact", "ru.aggregate": "exact",
    "ru.motor_vehicle": "exact", "ru.motorcycle": "exact", "ru.bicycle": "exact", "ru.pedestrian": "exact",
    "ru.truck": "estimate:blueprint_base_type", "ru.bus": "estimate:blueprint_base_type",
    "st.lane": "exact", "st.lane_direction": "exact", "st.lane_adjacency": "exact",
    "st.lane_connectivity": "exact", "st.lane_enters": "exact", "st.lane_marking": "exact", "st.lane_width": "exact",
    "st.region_geometry": "exact", "st.crosswalk": "exact",
    "st.intersection": "estimate:junction_bounding_box", "st.stop_line": "estimate:stop_waypoints",
    "st.entrance_of": "estimate:stop_waypoints",   # lanes of the stop waypoints; omitted where the map is ambiguous
    "rel.occupies": "exact",
    "dev.traffic_signal": "exact", "dev.stop_sign": "exact", "dev.yield_sign": "exact",
    "dev.speed_limit_sign": "exact", "dev.governs": "exact", "dev.position": "exact",
    "sig.turn_indicator": "exact", "sig.brake_lamp": "exact", "sig.hazard": "exact",
    "sig.headlamp": "exact", "sig.position_lamp": "exact", "sig.reverse_lamp": "exact", "sig.siren": "exact",
    "env.precipitation": "estimate:weather_parameter_threshold", "env.wet_road": "estimate:weather_parameter_threshold",
    "env.darkness": "estimate:sun_altitude",
}

ids = re.findall(r'^\s*"([a-z]+\.[a-z_]+)"', IDS.read_text(encoding="utf-8").split("primitiveIds")[0], re.M)
unknown = sorted(set(OBSERVED) - set(ids))
if unknown:
    sys.exit(f"not atom ids of the full ontology: {unknown}")
json.dump({"source": SOURCE, "reid_gap": REID_GAP_S, "atoms": {i: OBSERVED.get(i, "absent") for i in ids}},
          sys.stdout, indent=1)
print()
