"""Derive a per-law label file from the CARLA ground-truth oracle.

The output is the label file `traffic-spec-agent`'s `scripts/capture_eval.py`
reads: one verdict per law per capture, drawn from `compliant`, `violated` and
`not_applicable`.

Independence, and its limits
----------------------------
These verdicts come from the simulator's own state (`oracle.jsonl`), not from
the scene graph the Lean rules evaluate over and not from the agent that wrote
those rules. A disagreement between a label here and a `monitor` verdict is
therefore a genuine finding about the specification, the abstraction, or the
adapter — the three things sitting between the two.

Each threshold below is tagged with where it comes from:

  [statute]  stated in the law text in `laws/example/laws.jsonl`
  [reading]  the statute is qualitative ("remain", "reasonable") and this is a
             quantification of it, chosen here and stated in the label note
  [rule]     the statute gives no number at all and the figure is borrowed from
             the Lean rule, which makes that law a weaker cross-check than the
             others; the note says so

A `[rule]` threshold cannot catch a rule that chose the wrong number, only one
that reads the wrong field or never fires. That is called out per law rather
than averaged away.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import Callable, Optional

# --------------------------------------------------------------------------
# Thresholds
# --------------------------------------------------------------------------

SPEED_LIMIT_KPH = 50.0            # [statute] EX-SPEED-001
JUNCTION_LIMIT_KPH = 30.0         # [statute] EX-SPEED-002
FOLLOW_GAP_M = 4.0                # [statute] EX-FOLLOW-001, "within four metres"
STOP_DWELL_SECONDS = 1.0          # [statute] EX-STOP-001, "not less than one second"

# [reading] "shall not *remain* within four metres" implies persistence but
# names no duration. A tenth of a second would convict a momentary sensor
# flicker; a full second would excuse a sustained tailgate that ends in braking.
REMAIN_SECONDS = 0.2

# [reading] "shall be driven upon the right half of the roadway, except when
# overtaking" — an instantaneous departure is a lane change, not an offence.
KEEP_RIGHT_GRACE_SECONDS = 4.0

# [reading] a vehicle counts as stopped below this speed; CARLA's handbrake-held
# vehicles jitter at a few cm/s.
STOPPED_MPS = 0.15

# [reading] the ego "is following" another vehicle when that vehicle is ahead in
# the same lane and close enough for the gap to be a driver's concern.
FOLLOWING_ENGAGED_M = 30.0

# [reading] the ego is "approaching an occupied intersection" when it is outside
# one and a vehicle inside one is this close ahead. See label_junction_yield.
JUNCTION_APPROACH_M = 30.0

# [rule] EX-EMERGENCY-001 gives no distance and no duration. These are
# R0012/R0013's own constants (`approachMetres`, `graceFrames`,
# `clearanceFrames`), so this law's label tests only whether the rules fire on
# the right situation, not whether they chose the right numbers.
EMERGENCY_APPROACH_M = 25.0
EMERGENCY_YIELD_GRACE_SECONDS = 1.0
EMERGENCY_JUNCTION_CLEAR_SECONDS = 2.0

# [reading] "shall not *remain* within the intersection" is about obstructing
# it, not about occupying it: a driver who is crossing and continues to cross is
# clearing the junction, which is what the clause asks for. Presence alone
# convicts every lawful traverse of a large intersection — Town03's junction 103
# takes 5.5 s to cross at 20 km/h, well over the two-second clearance window —
# so the run is gated on the ego failing to make progress. A vehicle under
# 1 m/s inside a junction is stopped or crawling, not transiting.
EMERGENCY_BLOCKING_MPS = 1.0

# [reading] an overtake is in progress when a same-heading vehicle sits in the
# lane to the ego's right, roughly abreast.
OVERTAKE_LATERAL_MIN_M = 1.5
OVERTAKE_LONGITUDINAL_MAX_M = 30.0

COMPLIANT = "compliant"
VIOLATED = "violated"
NOT_APPLICABLE = "not_applicable"


# --------------------------------------------------------------------------
# Helpers over the frame sequence
# --------------------------------------------------------------------------

def longest_run(flags: list[bool]) -> tuple[int, int]:
    """(length, start index) of the longest contiguous True run."""
    best_len = best_start = run = 0
    start = 0
    for i, flag in enumerate(flags):
        if flag:
            if run == 0:
                start = i
            run += 1
            if run > best_len:
                best_len, best_start = run, start
        else:
            run = 0
    return best_len, best_start


def seconds_to_frames(seconds: float, fps: int) -> int:
    return max(1, int(round(seconds * fps)))


def transitions(flags: list[bool]) -> list[int]:
    """Indices t where flags[t] is False and flags[t+1] is True."""
    return [t for t in range(len(flags) - 1) if not flags[t] and flags[t + 1]]


@dataclass
class Label:
    law: str
    verdict: str
    note: str
    evidence: dict = field(default_factory=dict)

    def as_dict(self) -> dict:
        # `law`, `verdict` and `note` are what capture_eval reads; `evidence` is
        # free-form documentation it ignores.
        return {"law": self.law, "verdict": self.verdict, "note": self.note,
                "evidence": self.evidence}


# --------------------------------------------------------------------------
# One function per law
# --------------------------------------------------------------------------

def label_speed(records: list[dict], fps: int) -> Label:
    speeds = [r["ego"]["speed_kph"] for r in records]
    peak = max(speeds)
    over = [i for i, s in enumerate(speeds) if s > SPEED_LIMIT_KPH]
    if not any(s > 0.5 for s in speeds):
        return Label("EX-SPEED-001", NOT_APPLICABLE,
                     "ego never moves in this capture", {"peak_kph": peak})
    if over:
        return Label(
            "EX-SPEED-001", VIOLATED,
            f"ego exceeds {SPEED_LIMIT_KPH:.0f} km/h on {len(over)} of "
            f"{len(speeds)} frames, peaking at {peak:.1f} km/h "
            f"(first at frame {over[0]})",
            {"peak_kph": peak, "frames_over": len(over), "first_over": over[0]})
    return Label("EX-SPEED-001", COMPLIANT,
                 f"peak speed {peak:.1f} km/h, under the "
                 f"{SPEED_LIMIT_KPH:.0f} km/h limit for all {len(speeds)} frames",
                 {"peak_kph": peak})


def label_junction_speed(records: list[dict], fps: int) -> Label:
    inside = [(i, r) for i, r in enumerate(records)
              if r["ego"]["lane"]["is_junction"]]
    if not inside:
        return Label("EX-SPEED-002", NOT_APPLICABLE,
                     "ego never enters an intersection in this capture", {})
    speeds = [(i, r["ego"]["speed_kph"]) for i, r in inside]
    peak_frame, peak = max(speeds, key=lambda p: p[1])
    over = [i for i, s in speeds if s > JUNCTION_LIMIT_KPH]
    evidence = {"junction_frames": len(inside), "peak_kph_in_junction": peak,
                "peak_frame": peak_frame}
    if over:
        return Label(
            "EX-SPEED-002", VIOLATED,
            f"ego is inside an intersection for {len(inside)} frames and exceeds "
            f"{JUNCTION_LIMIT_KPH:.0f} km/h on {len(over)} of them, peaking at "
            f"{peak:.1f} km/h at frame {peak_frame}",
            dict(evidence, frames_over=len(over)))
    return Label("EX-SPEED-002", COMPLIANT,
                 f"ego is inside an intersection for {len(inside)} frames, "
                 f"peaking at {peak:.1f} km/h, under the "
                 f"{JUNCTION_LIMIT_KPH:.0f} km/h limit", evidence)


def label_following(records: list[dict], fps: int) -> Label:
    """EX-FOLLOW-001. Judged on the **bumper gap**, which is what the statute
    means; the centre-to-centre distance the scene graph bands is reported too,
    because that is what a `Pred.withinMetres` rule actually sees."""
    def lead(record: dict) -> Optional[dict]:
        candidates = [a for a in record["actors"]
                      if a["same_lane_as_ego"]
                      and a["relative"]["ahead"]
                      and a["relative"]["heading_dot"] > 0.0
                      and a["base_class"] != "person"]
        if not candidates:
            return None
        return min(candidates, key=lambda a: a["relative"]["longitudinal"])

    leads = [lead(r) for r in records]
    engaged_frames = [i for i, a in enumerate(leads)
                      if a and a["relative"]["bumper_gap"] < FOLLOWING_ENGAGED_M]
    if not engaged_frames:
        return Label("EX-FOLLOW-001", NOT_APPLICABLE,
                     "ego never travels behind another vehicle in its own lane "
                     "in this capture", {})

    gaps = [(i, a["relative"]["bumper_gap"], a["relative"]["centre_distance"])
            for i, a in enumerate(leads) if a]
    min_frame, min_gap, min_centre = min(gaps, key=lambda t: t[1])
    close = [bool(a and a["relative"]["bumper_gap"] < FOLLOW_GAP_M) for a in leads]
    need = seconds_to_frames(REMAIN_SECONDS, fps)
    run, start = longest_run(close)

    evidence = {
        "engaged_frames": len(engaged_frames),
        "min_bumper_gap_m": min_gap,
        "min_centre_distance_m": min_centre,
        "min_gap_frame": min_frame,
        "longest_under_4m_frames": run,
        "frames_required": need,
    }
    if run >= need:
        return Label(
            "EX-FOLLOW-001", VIOLATED,
            f"ego remains within {FOLLOW_GAP_M:.0f} m (bumper to bumper) of the "
            f"vehicle it is following for {run} consecutive frames from frame "
            f"{start} ({run / fps:.2f} s); closest gap {min_gap:.2f} m at frame "
            f"{min_frame}, centre-to-centre {min_centre:.2f} m there",
            evidence)
    return Label(
        "EX-FOLLOW-001", COMPLIANT,
        f"ego follows another vehicle for {len(engaged_frames)} frames but never "
        f"remains within {FOLLOW_GAP_M:.0f} m for {need} frames "
        f"({REMAIN_SECONDS:.1f} s); closest gap {min_gap:.2f} m at frame "
        f"{min_frame} (centre-to-centre {min_centre:.2f} m)",
        evidence)


def label_junction_yield(records: list[dict], fps: int) -> Label:
    """EX-JUNCTION-001: entering an intersection already occupied."""
    def ego_junction(record: dict) -> Optional[int]:
        lane = record["ego"]["lane"]
        return lane["junction_id"] if lane["is_junction"] else None

    def occupants(record: dict, junction_id: int) -> list[dict]:
        return [a for a in record["actors"]
                if a["lane"]["is_junction"]
                and a["lane"]["junction_id"] == junction_id
                and a["base_class"] != "person"]

    ego_in = [ego_junction(r) for r in records]
    shared = [i for i, jid in enumerate(ego_in)
              if jid is not None and occupants(records[i], jid)]

    # The clause is engaged whenever the ego approaches an intersection that
    # another vehicle is already inside, whether or not it goes on to enter:
    # a capture where the ego correctly waits for the junction to clear is the
    # compliant counterpart of the one where it drives in, not an untested one.
    # This is the same reading `label_lane` applies to the oncoming sentence,
    # and without it the lawful run is unscoreable — the ego that yields never
    # shares a junction with anyone, so `shared` and `entries` are both empty
    # and the ideal compliant capture comes out `not_applicable`.
    approaching = [
        i for i, r in enumerate(records)
        if ego_in[i] is None
        and any(a["lane"]["is_junction"]
                and a["relative"]["ahead"]
                and a["relative"]["centre_distance"] < JUNCTION_APPROACH_M
                and a["base_class"] != "person"
                for a in r["actors"])]

    entries: list[tuple[int, int, int]] = []   # (frame, junction, n occupants)
    for t in range(len(records) - 1):
        target = ego_in[t + 1]
        if target is None or ego_in[t] == target:
            continue
        blocking = occupants(records[t], target)
        if blocking:
            entries.append((t, target, len(blocking)))

    if not shared and not entries and not approaching:
        engaged_at_all = any(jid is not None for jid in ego_in)
        reason = ("ego enters an intersection but never shares it with another "
                  "vehicle, and never approaches one that is occupied"
                  if engaged_at_all
                  else "ego never enters or approaches an occupied intersection "
                       "in this capture")
        return Label("EX-JUNCTION-001", NOT_APPLICABLE, reason, {})

    evidence = {"shared_junction_frames": len(shared),
                "approach_to_occupied_frames": len(approaching),
                "approach_within_m": JUNCTION_APPROACH_M,
                "occupied_entries": [{"frame": f, "junction": j, "occupants": n}
                                     for f, j, n in entries]}
    if entries:
        frame, junction, count = entries[0]
        return Label(
            "EX-JUNCTION-001", VIOLATED,
            f"ego enters junction {junction} at frame {frame + 1} while {count} "
            f"other vehicle(s) are already inside it "
            f"({len(entries)} such entries in the capture)",
            evidence)
    return Label(
        "EX-JUNCTION-001", COMPLIANT,
        f"ego approaches an occupied intersection on {len(approaching)} frames "
        f"and shares one with another vehicle on {len(shared)}, but never "
        f"enters one that was already occupied",
        evidence)


def label_lane(records: list[dict], fps: int) -> Label:
    """EX-LANE-001, both sentences: keep to the right half, and do not occupy an
    opposing lane while a vehicle approaches in it."""
    def overtaking(record: dict) -> bool:
        for a in record["actors"]:
            rel = a["relative"]
            if (rel["lateral"] > OVERTAKE_LATERAL_MIN_M
                    and abs(rel["longitudinal"]) < OVERTAKE_LONGITUDINAL_MAX_M
                    and rel["heading_dot"] > 0.5
                    and a["base_class"] != "person"):
                return True
        return False

    left_of_right = [bool(r["ego"]["lane"]["has_driving_lane_to_right"])
                     and not overtaking(r) for r in records]
    need = seconds_to_frames(KEEP_RIGHT_GRACE_SECONDS, fps)
    run, start = longest_run(left_of_right)

    head_on = [i for i, r in enumerate(records)
               if r["ego"]["lane"]["wrong_way"]
               and any(a["same_lane_as_ego"] and a["relative"]["oncoming"]
                       and a["relative"]["ahead"] and a["base_class"] != "person"
                       for a in r["actors"])]
    wrong_way_frames = sum(1 for r in records if r["ego"]["lane"]["wrong_way"])
    multi_lane_frames = sum(1 for r in records
                            if r["ego"]["lane"]["has_driving_lane_to_right"])

    # The second sentence is engaged whenever a vehicle approaches in the
    # opposing lane, whether or not the ego is in it: a capture where the ego
    # correctly stays out of that lane while an oncoming car passes is the
    # compliant counterpart of the wrong-way case, not an untested one.
    oncoming_encounters = [
        i for i, r in enumerate(records)
        if any(a["opposing_lane_to_ego"] and a["relative"]["oncoming"]
               and a["relative"]["ahead"]
               and a["relative"]["centre_distance"] < 30.0
               and a["base_class"] != "person"
               for a in r["actors"])]

    evidence = {
        "frames_with_lane_to_the_right": multi_lane_frames,
        "longest_left_of_rightmost_frames": run,
        "frames_required": need,
        "frames_wrong_way": wrong_way_frames,
        "head_on_frames": len(head_on),
        "oncoming_encounter_frames": len(oncoming_encounters),
    }

    if head_on:
        return Label(
            "EX-LANE-001", VIOLATED,
            f"ego occupies an opposing lane with a vehicle approaching head-on "
            f"in it on {len(head_on)} frames (first at frame {head_on[0]}); "
            f"{wrong_way_frames} frames wrong-way in total",
            evidence)
    if run >= need:
        return Label(
            "EX-LANE-001", VIOLATED,
            f"ego drives outside the rightmost lane of its carriageway, not "
            f"overtaking, for {run} consecutive frames from frame {start} "
            f"({run / fps:.1f} s)",
            evidence)
    if multi_lane_frames == 0 and wrong_way_frames == 0 and not oncoming_encounters:
        return Label("EX-LANE-001", NOT_APPLICABLE,
                     "ego is on a single-lane carriageway throughout, never "
                     "drives against the flow, and meets no oncoming vehicle, so "
                     "neither sentence of the clause is engaged", evidence)
    return Label(
        "EX-LANE-001", COMPLIANT,
        f"ego keeps to the rightmost lane of its direction of travel "
        f"({multi_lane_frames} frames had a lane to the right, the longest "
        f"non-overtaking stretch being {run} frames, under the {need}-frame "
        f"allowance), never drives against the flow, and stays out of the "
        f"opposing lane through {len(oncoming_encounters)} frames of oncoming "
        f"traffic",
        evidence)


def label_stop_sign(records: list[dict], fps: int) -> Label:
    """EX-STOP-001: a complete stop of at least a second before the junction."""
    posted = [i for i, r in enumerate(records)
              if r["stop_sign"] is not None
              and not r["ego"]["lane"]["is_junction"]]
    in_junction = [bool(r["ego"]["lane"]["is_junction"]) for r in records]
    entries = transitions(in_junction)

    # Only an entry preceded by a posted stop sign engages the clause.
    governed = [t for t in entries if any(p <= t for p in posted)]
    if not governed:
        reason = ("no stop sign is posted for any lane the ego travels in"
                  if not posted else
                  "a stop sign is posted for the ego's lane but the ego never "
                  "reaches the intersection within the capture")
        return Label("EX-STOP-001", NOT_APPLICABLE, reason,
                     {"frames_with_posted_stop": len(posted),
                      "junction_entries": len(entries)})

    need = seconds_to_frames(STOP_DWELL_SECONDS, fps)
    findings = []
    for entry in governed:
        approach_start = min(p for p in posted if p <= entry)
        window = records[approach_start:entry + 1]
        stopped = [r["ego"]["speed_mps"] < STOPPED_MPS
                   if "speed_mps" in r["ego"] else False for r in window]
        dwell, dwell_start = longest_run(stopped)
        findings.append({
            "entry_frame": entry + 1,
            "approach_from_frame": approach_start,
            "longest_dwell_frames": dwell,
            "dwell_started_at_frame": approach_start + dwell_start if dwell else None,
        })

    evidence = {"frames_required": need, "entries": findings}
    short = [f for f in findings if f["longest_dwell_frames"] < need]
    if short:
        first = short[0]
        return Label(
            "EX-STOP-001", VIOLATED,
            f"ego enters the intersection at frame {first['entry_frame']} after a "
            f"stop of only {first['longest_dwell_frames']} frames "
            f"({first['longest_dwell_frames'] / fps:.2f} s) on the approach; the "
            f"clause requires {need} frames ({STOP_DWELL_SECONDS:.0f} s) at rest "
            f"({len(short)} of {len(findings)} governed entries fall short)",
            evidence)
    best = findings[0]
    return Label(
        "EX-STOP-001", COMPLIANT,
        f"ego comes to rest for {best['longest_dwell_frames']} frames "
        f"({best['longest_dwell_frames'] / fps:.2f} s) before entering the "
        f"intersection at frame {best['entry_frame']}, meeting the "
        f"{STOP_DWELL_SECONDS:.0f} s requirement",
        evidence)


def label_signal(records: list[dict], fps: int) -> Label:
    """EX-SIGNAL-001: do not enter the intersection against a steady red."""
    in_junction = [bool(r["ego"]["lane"]["is_junction"]) for r in records]
    facing_red = [bool(r["signal"] and r["signal"]["state"] == "Red")
                  for r in records]
    engaged = [i for i in range(len(records))
               if facing_red[i] and not in_junction[i]]

    entries_on_red = [t for t in transitions(in_junction) if facing_red[t]]
    evidence = {
        "frames_facing_red_outside_junction": len(engaged),
        "junction_entries": len(transitions(in_junction)),
        "entries_on_red": [t + 1 for t in entries_on_red],
    }

    if not engaged:
        signalled = any(r["signal"] for r in records)
        reason = ("ego never faces a red signal from outside the intersection in "
                  "this capture" if signalled else
                  "no traffic signal governs any lane the ego travels in")
        return Label("EX-SIGNAL-001", NOT_APPLICABLE, reason, evidence)

    if entries_on_red:
        return Label(
            "EX-SIGNAL-001", VIOLATED,
            f"ego crosses into the intersection at frame {entries_on_red[0] + 1} "
            f"while the signal governing it is Red "
            f"({len(entries_on_red)} such entries; {len(engaged)} frames facing "
            f"red from outside the junction)",
            evidence)
    return Label(
        "EX-SIGNAL-001", COMPLIANT,
        f"ego faces a red signal from outside the intersection on "
        f"{len(engaged)} frames and does not enter while it is red",
        evidence)


def label_emergency(records: list[dict], fps: int) -> Label:
    """EX-EMERGENCY-001. Both thresholds are [rule]-sourced — see the module
    docstring; the statute names neither a distance nor a duration."""
    def nearest_emergency(record: dict) -> Optional[dict]:
        near = [a for a in record["actors"]
                if a["is_emergency"]
                and a["relative"]["centre_distance"] <= EMERGENCY_APPROACH_M]
        if not near:
            return None
        return min(near, key=lambda a: a["relative"]["centre_distance"])

    approaching = [nearest_emergency(r) for r in records]
    engaged = [i for i, a in enumerate(approaching) if a]
    if not engaged:
        present = any(a["is_emergency"] for r in records for a in r["actors"])
        reason = (f"an emergency vehicle is in the capture but never comes within "
                  f"{EMERGENCY_APPROACH_M:.0f} m of the ego" if present
                  else "no emergency vehicle appears in this capture")
        return Label("EX-EMERGENCY-001", NOT_APPLICABLE, reason, {})

    invisible = [i for i in engaged
                 if not approaching[i]["proximity_edge_possible"]]

    # R0012, "pull to the right-hand edge". Junction-internal lanes are excluded:
    # `has_driving_lane_to_right` describes a carriageway's lane ordering, and
    # inside an intersection CARLA renumbers lanes per connecting road, so the
    # field says nothing about whether the ego is at the edge of the roadway.
    not_right = [bool(a)
                 and records[i]["ego"]["lane"]["has_driving_lane_to_right"]
                 and not records[i]["ego"]["lane"]["is_junction"]
                 for i, a in enumerate(approaching)]
    # R0013, "clear the intersection". See EMERGENCY_BLOCKING_MPS: the ego must
    # be failing to make progress, not merely inside the junction.
    blocking = [bool(a) and records[i]["ego"]["lane"]["is_junction"]
                and records[i]["ego"]["speed_mps"] < EMERGENCY_BLOCKING_MPS
                for i, a in enumerate(approaching)]
    in_junction_frames = sum(1 for i, a in enumerate(approaching)
                             if a and records[i]["ego"]["lane"]["is_junction"])
    yield_need = seconds_to_frames(EMERGENCY_YIELD_GRACE_SECONDS, fps)
    clear_need = seconds_to_frames(EMERGENCY_JUNCTION_CLEAR_SECONDS, fps)
    yield_run, yield_start = longest_run(not_right)
    clear_run, clear_start = longest_run(blocking)

    evidence = {
        "engaged_frames": len(engaged),
        "min_centre_distance_m": min(
            approaching[i]["relative"]["centre_distance"] for i in engaged),
        "longest_not_at_right_edge_frames": yield_run,
        "yield_frames_required": yield_need,
        "frames_in_junction_while_engaged": in_junction_frames,
        "longest_blocking_junction_frames": clear_run,
        "clear_frames_required": clear_need,
        "blocking_below_mps": EMERGENCY_BLOCKING_MPS,
        "frames_with_no_possible_proximity_edge": len(invisible),
    }
    caveat = ""
    if invisible:
        caveat = (f" NOTE: on {len(invisible)} of those frames the emergency "
                  f"vehicle's base class carries no proximity edge in the scene "
                  f"graph, so no distance-based rule can ground on it.")

    if yield_run >= yield_need:
        return Label(
            "EX-EMERGENCY-001", VIOLATED,
            f"an emergency vehicle is within {EMERGENCY_APPROACH_M:.0f} m while "
            f"ego stays out of the right-hand edge lane for {yield_run} "
            f"consecutive frames from frame {yield_start} "
            f"({yield_run / fps:.1f} s).{caveat}",
            evidence)
    if clear_run >= clear_need:
        return Label(
            "EX-EMERGENCY-001", VIOLATED,
            f"an emergency vehicle is within {EMERGENCY_APPROACH_M:.0f} m while "
            f"ego sits inside an intersection without clearing it for "
            f"{clear_run} consecutive frames from frame {clear_start} "
            f"({clear_run / fps:.1f} s, below "
            f"{EMERGENCY_BLOCKING_MPS:.0f} m/s throughout).{caveat}",
            evidence)
    crossed = (f"; it is inside an intersection on {in_junction_frames} of them "
               f"but keeps moving through" if in_junction_frames else "")
    return Label(
        "EX-EMERGENCY-001", COMPLIANT,
        f"an emergency vehicle comes within {EMERGENCY_APPROACH_M:.0f} m on "
        f"{len(engaged)} frames; ego is at the right-hand edge and never "
        f"obstructs an intersection{crossed}.{caveat}",
        evidence)


LABELERS: dict[str, Callable[[list[dict], int], Label]] = {
    "EX-FOLLOW-001": label_following,
    "EX-SPEED-001": label_speed,
    "EX-SPEED-002": label_junction_speed,
    "EX-JUNCTION-001": label_junction_yield,
    "EX-LANE-001": label_lane,
    "EX-STOP-001": label_stop_sign,
    "EX-SIGNAL-001": label_signal,
    "EX-EMERGENCY-001": label_emergency,
}

ANNOTATOR = (
    "carlaspec.labeler — derived mechanically from oracle.jsonl, which is "
    "recorded from the CARLA server API during the run (actor transforms and "
    "bounding boxes, OpenDRIVE waypoints, Vehicle.get_traffic_light().get_state()). "
    "Independent of carla_sgg's abstraction and of the Lean rules. Camera stills "
    "are written to camera/ for human spot-checking; the per-law `evidence` block "
    "names the frames each verdict rests on."
)


def build_label_file(records: list[dict], capture: str, fps: int,
                     meta: Optional[dict] = None) -> dict:
    labels = [LABELERS[law](records, fps).as_dict() for law in LABELERS]
    return {
        "capture": capture,
        "annotator": ANNOTATOR,
        "source": "oracle.jsonl (CARLA server ground truth)",
        "frames": len(records),
        "fps": fps,
        "scenario": meta or {},
        "threshold_provenance": {
            "statute": ["EX-SPEED-001 50 km/h", "EX-SPEED-002 30 km/h",
                        "EX-FOLLOW-001 4 m", "EX-STOP-001 1 s"],
            "reading": [f"EX-FOLLOW-001 'remain' = {REMAIN_SECONDS} s",
                        f"EX-LANE-001 keep-right grace = "
                        f"{KEEP_RIGHT_GRACE_SECONDS} s",
                        f"stopped = below {STOPPED_MPS} m/s",
                        f"EX-JUNCTION-001 approaching an occupied intersection "
                        f"= a vehicle inside one within "
                        f"{JUNCTION_APPROACH_M} m ahead",
                        f"EX-EMERGENCY-001 'remain within the intersection' = "
                        f"inside it below {EMERGENCY_BLOCKING_MPS} m/s, so a "
                        f"lawful traverse is not counted as blocking"],
            "rule": [f"EX-EMERGENCY-001 approach = {EMERGENCY_APPROACH_M} m, "
                     f"yield grace = {EMERGENCY_YIELD_GRACE_SECONDS} s, "
                     f"junction clearance = {EMERGENCY_JUNCTION_CLEAR_SECONDS} s "
                     "(borrowed from R0012/R0013 — the statute names no figure, "
                     "so this law's label cannot falsify those constants)"],
        },
        "labels": labels,
    }


def engaged_laws(label_file: dict) -> set[str]:
    return {entry["law"] for entry in label_file["labels"]
            if entry["verdict"] != NOT_APPLICABLE}


def write_label_file(label_file: dict, path) -> None:
    with open(path, "w", encoding="utf-8") as fd:
        json.dump(label_file, fd, indent=2, ensure_ascii=False)
        fd.write("\n")
