"""Finding captures, and reporting what the corpus does and does not cover.

A capture is any directory holding an `rsv/` of `process_to_junction_rsv`
pickles. An `ego_logs.json` beside it is used when present and its frame offset
is measured rather than assumed.

The coverage report is the primary output while the dataset is under
construction. It answers, per obligation: did the situation ever arise, did it
arise on both sides, and if not, which of Bench2Drive's 44 scenarios would
produce it. That last column turns a coverage hole into a work item.
"""

from __future__ import annotations

import glob
import json
import os
from typing import Dict, List, Optional

#: Bench2Drive's 44 scenarios, grouped by the five skills its Table 2 defines.
#: The union of these lists is exactly 44; several scenarios carry two skills.
#: Used to translate an uncovered obligation into a concrete recording task.
BENCH2DRIVE_SKILLS = {
    "Merging": [
        "CrossingBicycleFlow", "EnterActorFlow", "HighwayExit",
        "InterurbanActorFlow", "HighwayCutIn", "InterurbanAdvancedActorFlow",
        "MergerIntoSlowTrafficV2", "MergeIntoSlowTraffic",
        "NonSignalizedJunctionLeftTurn", "NonSignalizedJunctionRightTurn",
        "NonSignalizedJunctionLeftTurnEnterFlow", "ParkingExit", "LaneChange",
        "SignalizedJunctionLeftTurn", "SignalizedJunctionRightTurn",
        "SignalizedJunctionLeftTurnEnterFlow"],
    "Overtaking": [
        "Accident", "AccidentTwoWays", "ConstructionObstacle",
        "ConstructionObstacleTwoWays", "HazardAtSideLaneTwoWays",
        "HazardAtSideLane", "ParkedObstacleTwoWays", "ParkedObstacle",
        "VehicleOpenDoorTwoWays"],
    "EmergencyBrake": [
        "BlockedIntersection", "DynamicObjectCrossing", "HardBreakRoute",
        "OppositeVehicleTakingPriority", "OppositeVehicleRunningRedLight",
        "ParkingCutIn", "PedestrianCrossing", "ParkingCrossingPedestrian",
        "StaticCutIn", "VehicleTurningRoute", "VehicleTurningRoutePedestrian",
        "ControlLoss"],
    "GiveWay": ["InvadingTurn", "YieldToEmergencyVehicle"],
    "TrafficSign": [
        "EnterActorFlow", "CrossingBicycleFlow",
        "NonSignalizedJunctionLeftTurn", "NonSignalizedJunctionRightTurn",
        "NonSignalizedJunctionLeftTurnEnterFlow",
        "OppositeVehicleTakingPriority", "OppositeVehicleRunningRedLight",
        "PedestrianCrossing", "SignalizedJunctionLeftTurn",
        "SignalizedJunctionRightTurn", "SignalizedJunctionLeftTurnEnterFlow",
        "TJunction", "VanillaNonSignalizedTurn",
        "VanillaSignalizedTurnEncounterGreenLight",
        "VanillaSignalizedTurnEncounterRedLight",
        "VanillaNonSignalizedTurnEncounterStopsign", "VehicleTurningRoute",
        "VehicleTurningRoutePedestrian"],
}

BENCH2DRIVE_44 = sorted(set(
    name for names in BENCH2DRIVE_SKILLS.values() for name in names))


class Capture(object):
    def __init__(self, name, rsv_dir, ego_log=None, meta=None):
        self.name = name
        self.rsv_dir = rsv_dir
        self.ego_log = ego_log
        self.meta = meta or {}

    def __repr__(self):
        return "Capture(%s, frames=%d)" % (self.name, self.frame_count())

    def frame_count(self):
        return len(glob.glob(os.path.join(self.rsv_dir, "*.pkl")))

    def scenario_guess(self):
        # type: () -> Optional[str]
        """Which Bench2Drive scenario this capture is, if its name says so."""
        stem = self.name.split("_")[0] if "_" in self.name else self.name
        for scenario in BENCH2DRIVE_44:
            if self.name.startswith(scenario) or stem == scenario:
                return scenario
        return None


def discover(root, max_depth=4):
    # type: (str, int) -> List[Capture]
    """Every capture under `root`, at any nesting depth."""
    found = []
    for depth in range(1, max_depth + 1):
        pattern = os.path.join(root, *(["*"] * depth + ["rsv"]))
        for rsv in sorted(glob.glob(pattern)):
            if not os.path.isdir(rsv):
                continue
            parent = os.path.dirname(rsv)
            ego_log = os.path.join(parent, "ego_logs.json")
            found.append(Capture(
                name=os.path.basename(parent), rsv_dir=rsv,
                ego_log=ego_log if os.path.isfile(ego_log) else None,
                meta={"path": parent}))
    # A capture reachable at two depths is the same capture.
    unique = {}
    for capture in found:
        unique.setdefault(capture.rsv_dir, capture)
    return sorted(unique.values(), key=lambda c: c.rsv_dir)


def scenario_coverage(captures):
    # type: (List[Capture]) -> dict
    """How much of Bench2Drive's 44 the corpus contains."""
    present = {}
    for capture in captures:
        scenario = capture.scenario_guess()
        if scenario:
            present.setdefault(scenario, []).append(capture.name)
    missing = [s for s in BENCH2DRIVE_44 if s not in present]
    by_skill = {}
    for skill, names in BENCH2DRIVE_SKILLS.items():
        have = [n for n in names if n in present]
        by_skill[skill] = {"have": len(have), "of": len(names),
                           "missing": [n for n in names if n not in present]}
    return {
        "bench2drive_total": len(BENCH2DRIVE_44),
        "present": len(present),
        "present_names": sorted(present),
        "missing": missing,
        "by_skill": by_skill,
    }


def obligation_coverage(scores, readings):
    # type: (dict, List) -> dict
    """Per obligation: witnessed, two-sided, and what would witness it.

    The `record_next` column is the deliverable. A rule with no witness is not a
    monitor failure and not a specification failure; it is a missing capture,
    and the reading already declares which Bench2Drive scenarios produce its
    situation. Coverage reporting that stops at a percentage leaves the reader
    to work that out; this does not.
    """
    by_id = dict((r.id, r) for r in readings)
    rows = []
    for rule_id in sorted(by_id):
        reading = by_id[rule_id]
        score = scores.get(rule_id)
        witnessed = bool(score and score.witnessed)
        two_sided = bool(score and score.two_sided)
        untestable = bool(score and score.captures_untestable and not witnessed)
        rows.append({
            "obligation": rule_id,
            "citation": reading.citation,
            "witnessed": witnessed,
            "two_sided": two_sided,
            "untestable_everywhere": untestable,
            "captures_applicable": score.captures_applicable if score else 0,
            "captures_violating": score.captures_violating if score else 0,
            "captures_compliant": score.captures_compliant if score else 0,
            "record_next": [] if two_sided else reading.scenarios,
        })
    return {
        "obligations": len(rows),
        "witnessed": sum(1 for r in rows if r["witnessed"]),
        "two_sided": sum(1 for r in rows if r["two_sided"]),
        "untestable_everywhere": sum(1 for r in rows
                                     if r["untestable_everywhere"]),
        "rows": rows,
    }
