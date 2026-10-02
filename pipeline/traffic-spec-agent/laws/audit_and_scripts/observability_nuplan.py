"""Which corpus lines a nuPlan-sourced evaluation cannot judge, and why.

Reads `full_list/laws.jsonl` (posted law) and `evaluation_scenario/scenarios.jsonl`
(required observations per line) and joins them against a per-atom capability table
for the nuPlan source. Writes `observability_nuplan.jsonl` and the counts the
companion audit quotes. Re-run after either input changes:

    python3 audit_and_scripts/observability_nuplan.py

Source profile assumed: the nuPlan camera/lidar blobs with our own perception over
them, an HD map we author into the scene-graph generator, and the log's ego state.
Facts an HD map or a geometric derivation can supply are therefore NOT counted here.
"""
import json
import re
from collections import Counter
from pathlib import Path

LAWS = Path(__file__).resolve().parent.parent / "full_list" / "laws.jsonl"
SCEN = Path(__file__).resolve().parent.parent / "evaluation_scenario" / "scenarios.jsonl"
META = Path(__file__).resolve().parent / "laws_meta.jsonl"
OUT = Path(__file__).resolve().parent / "observability_nuplan.jsonl"

# ---------------------------------------------------------------------------
# Capability table. Only atoms that are NOT plainly obtainable are listed; every
# atom absent from this table is treated as obtainable (exact, or an estimate
# whose error class does not change a verdict).
#
#   blocked   no path on this source at any effort -> the line cannot be judged
#   degraded  obtainable as an estimate with a failure mode that must be carried
#             as a residue on any rule that reads it
#   note_only obtainable; the failure mode is recorded once here and no rule
#             carries a residue for it
# ---------------------------------------------------------------------------
CAPABILITY = {
    # --- BLOCKED: no audio channel ------------------------------------------
    # Neither source carries sound. nuPlan ships cameras and lidar and no
    # microphone; CARLA has no acoustic model, though a scripted scenario CAN
    # emit a horn event as ground truth, so these lines are evaluable in
    # simulation and not on real video.
    "sig.horn":              ("residue_required", "audio", "no microphone; a horn leaves no visual trace"),
    "sig.siren":             ("residue_required", "audio", "no microphone"),
    "sig.compression_brake": ("residue_required", "audio", "no microphone; the statute's own test for the offence is that the device is audible"),

    # --- DEGRADED: obtainable, with a failure mode a rule must carry --------
    "dev.regulatory_sign": ("degraded", "sign_legend", "the plate is detectable; its legend -- the hours, days, classes and exemptions printed on it -- is an OCR-and-parse problem and is what the rule turns on"),
    "dev.zone_sign":       ("degraded", "sign_legend", "as for regulatory_sign: the zone's extent and the condition printed on the plate"),
    "dev.human_direction": ("degraded", "officer_direction", "a THIRD PARTY directing traffic (officer, flagger, crossing guard), not the subject's own body: detectable in principle, but the indication vocabulary is unmodelled and the event is rare in real logs"),
    "dev.inoperative":     ("degraded", "device_fault", "a dark or bagged head is visible; distinguishing a fault from a phase is not"),
    "ru.procession_vehicle":      ("degraded", "context", "a funeral procession is read from placards, flags and an escort, not from the vehicle"),
    "ru.personal_delivery_device": ("degraded", "rare_class", "absent from nuPlan's released taxonomy and near-absent from the logs"),
    "ru.mobile_carrying_device":   ("degraded", "rare_class", "as for personal_delivery_device"),
    "ru.other_conveyance":         ("degraded", "catch_all", "a residual class with no detector of its own"),

    # --- NOTE_ONLY: obtainable; recorded once here, no residue on any rule ---
    # Interior and posture: resolved 2026-09-29. Occupants and rider posture are
    # read from the video; CARLA supplies both exactly.
    # Read from the video; the two sources fail on OPPOSITE halves here -- see the audit, section 5.
    "ru.occupant_count": ("note_only", "interior", "video: the loading/unloading cases are read from sig.door_open with a kerbside pedestrian track, and riders of an open machine are in plain view; an absolute count through the glazing of an enclosed cabin is the weak case. SIMULATION: CARLA vehicles carry no occupants, so the count is not a variable and a violation is not authorable"),
    "ru.rider_posture":  ("note_only", "posture", "video: on_seat, standing_on_deck, holding_another_vehicle, stunt and mounted-vs-dismounted are gross body configuration in plain view; hands_on_controls is a COUNT and is the weak field, unreliable at range, from behind and at night. SIMULATION: CARLA bakes the rider into the bike or motorcycle blueprint and exposes no posture attribute, so no field of Posture is a variable and a violation is not authorable"),
    # Ego-only: resolved 2026-09-29. CARLA supplies this for every agent;
    # nuPlan's EgoState.tire_steering_angle supplies it for the ego, which is
    # the subject the real-video evaluation judges. See the audit, section 6,
    # for the Core limitation this leaves open.
    "kin.steer_angle": ("note_only", "ego_only", "simulation: exact for every vehicle via Vehicle.get_wheel_steer_angle(). Video: exact for the ego via EgoState.tire_steering_angle, and for a third-party vehicle only while parked with the wheels toward the camera -- a split Core's manifest cannot currently express"),
    # Registry and designation: resolved 2026-09-29. Only a line that turns on a
    # vehicle the authority designates WITHOUT marking it is counted as
    # affected, and no line in this corpus does. Rated and licensed classes are
    # read from conspicuous evidence: size and axle count, hazmat placards,
    # seating capacity, livery.
    "ru.commercial_motor_vehicle": ("note_only", "registry", "size, axle count, placarding and seating capacity are conspicuous, and placards are themselves legally required to be so"),
    "ru.low_speed_vehicle":        ("note_only", "registry", "a distinctive form factor with its own equipment requirements"),
    "ru.moped":                    ("note_only", "registry", "displacement and rated power are not visible, but no line turns on telling a moped from a motorcycle"),
    "ru.electric_bicycle":         ("note_only", "registry", "as for moped: the class 1/2/3 distinction is rated, and no line turns on it"),
    "ru.official_vehicle":         ("note_only", "designation", "tow, utility, highway_maintenance, postal and armored-car liveries are conspicuous; an unmarked municipal or agency car is the designation gap recorded in the audit"),
    "ru.emergency_vehicle": ("note_only", "designation", "the marked class is a livery-and-silhouette detection; an unmarked designated vehicle is the gap recorded in the audit, and no line in this corpus names that case"),
    "ru.fire_apparatus":    ("note_only", "designation", "as for emergency_vehicle"),
    "ru.school_bus":        ("note_only", "designation", "as for emergency_vehicle; the livery and the signal arm are both conspicuous"),
    "ru.taxicab":           ("note_only", "livery", "roof light and medallion livery"),
    "ru.tour_bus_or_limousine": ("note_only", "livery", "livery-visible"),
}

# Lines kept in the corpus although an audio duty in them cannot be evaluated (decided
# 2026-09-29). Each must carry the residue named here on any rule written for it. The lines whose
# EVERY duty was audio were moved out of the corpus instead -- see nrs_tools/tiers.py UNOBSERVABLE.
KEPT_WITH_RESIDUE = {
    ("NRS-484B-413-1", "sig.horn"):
        "the audible warning owed to a pedestrian is not evaluated; the line's other duty, an "
        "appropriate signal to affected vehicles, and its precondition that the turn be made with "
        "reasonable safety, both are",
    ("LVMC-11-40-180-C", "sig.horn"):
        "the audible signal owed before overtaking a pedestrian is not evaluated; the yield duty "
        "the same sentence imposes is",
    ("NRS-484D-400-5", "sig.siren"):
        "sig.siren is supplied as a special light flag in simulation and as a visible light bar on "
        "video, never as sound; this line's obligation is a siren-use prohibition, and its own last "
        "sentence permits operating the warning lamps WITHOUT the siren, so the exempt case is "
        "indistinguishable from the offence and the verdict may report a violation against it",
}

# Lines whose audio atom is carried by a limb that IS observable, so the duty
# still engages and the line stays evaluable. Keyed by (law id, atom).
AUDIO_HAS_VISIBLE_LIMB = {
    ("NRS-484B-207-2", "sig.horn"):
        "the trigger is disjunctive -- 'upon observing the overtaking vehicle OR hearing a "
        "signal' -- and the visual limb engages the duty; only an overtaken driver who could "
        "hear but not see is missed",
    ("NRS-484B-553-1", "sig.horn"):
        "limb (c), the train's audible signal, is one of three warnings; limbs (a) a signal "
        "device and (b) a lowered gate or a flagger are visible and engage the same duty",
    ("NRS-484B-710", "sig.siren"):
        "the responding state is evidenced by sig.warning_lamp or sig.siren, and NRS 484A.480(3) "
        "requires the lamp, so the visible limb carries the trigger",
    ("LVMC-11-12-090", "sig.horn"):
        "the horn appears inside the standard ('every reasonable precaution to prevent the "
        "frightening'); the duties the line imposes -- reduce speed, do not proceed on request "
        "-- are observable",
}

RANK = {"residue_required": 0, "degraded": 1, "note_only": 2}

# ---------------------------------------------------------------------------
# Refinement by the role the atom plays in the line. The capability table above
# is per atom; what a line actually needs of the atom is narrower, and the
# scenario's own note records it. Three rules, applied in order:
# ---------------------------------------------------------------------------
_ALTERNATIVE = re.compile(r"^(?:or|and)\b", re.I)
_IRRELEVANT = re.compile(r"expressly irrelevant", re.I)
# A change in who is aboard, rather than a count of them.
_EXCHANGE = re.compile(r"loading|unloading|exchange|picked up|delivered|"
                       r"change in occupancy", re.I)
# Machines whose riders sit in the open.
_OPEN_MACHINE = re.compile(r"persons carried|additional person", re.I)


def refine(atom: str, capability: str, note: str) -> tuple[str, str]:
    """Return (capability, why-it-moved) for this atom in this line.

    Only ever relaxes: the capability table is the ceiling, and the role a line
    gives an atom can make it easier to supply, never harder.
    """
    n = note.strip()
    if RANK[capability] == RANK["note_only"]:
        return capability, ""
    if _IRRELEVANT.search(n):
        return "note_only", "the line states the fact is irrelevant to the duty"
    if atom.startswith("ru.") and _ALTERNATIVE.match(n):
        return "note_only", ("named only as an alternative in a joint subject: the duty "
                             "falls on the union, which is observable, so the class "
                             "need not be told from its sibling")
    if atom == "ru.occupant_count":
        if _EXCHANGE.search(n):
            return "degraded", ("the line needs a change in who is aboard, not a count: "
                                "sig.door_open with a kerbside pedestrian track is the proxy, "
                                "and it misses an exchange through a door the cameras do not see")
        if _OPEN_MACHINE.search(n):
            return "degraded", ("the riders of an open machine are in plain view; the count "
                                "is an estimate that fails at range and at night")
    return capability, ""


def main() -> None:
    laws = {json.loads(l)["id"]: json.loads(l) for l in LAWS.open()}
    scen = {json.loads(l)["id"]: json.loads(l) for l in SCEN.open()}
    meta = {json.loads(l)["id"]: json.loads(l) for l in META.open()}
    assert set(laws) == set(scen), "corpus and scenarios disagree on ids"

    records, by_atom, by_class = [], Counter(), Counter()
    for lid, s in scen.items():
        obs = s["required_observations"]
        hits = []
        for o in obs:
            if o["atom"] not in CAPABILITY:
                continue
            cap, klass, why = CAPABILITY[o["atom"]]
            limb = AUDIO_HAS_VISIBLE_LIMB.get((lid, o["atom"]))
            keep = KEPT_WITH_RESIDUE.get((lid, o["atom"]))
            if limb:
                cap2, moved = "degraded", limb
            elif keep:
                cap2, moved = "residue_required", keep
            else:
                cap2, moved = refine(o["atom"], cap, o["note"])
            hits.append((o["atom"], cap2, klass, why, o["note"], moved))
        if not hits:
            continue
        worst = min(RANK[h[1]] for h in hits)
        if worst == RANK["note_only"]:
            continue                      # observable; nothing to carry
        blocking = [h for h in hits if h[1] != "note_only"]
        records.append({
            "id": lid,
            "title": laws[lid]["title"],
            "source": laws[lid]["source"],
            "subject": meta.get(lid, {}).get("subject"),
            "theme": meta.get(lid, {}).get("theme"),
            "tier": meta.get(lid, {}).get("tier"),
            "verdict": "residue_required" if worst == 0 else "degraded",
            "affected": [{"atom": a, "capability": c, "class": k, "why": w,
                          "role_in_law": note,
                          **({"refined": moved} if moved else {})}
                         for a, c, k, w, note, moved in blocking],
            "n_required": len(obs),
            "n_affected": len(blocking),
            "share_affected": round(len(blocking) / len(obs), 3),
        })
        for a, c, k, _w, _n, _m in blocking:
            by_atom[(a, c)] += 1
            by_class[k] += 1

    records.sort(key=lambda r: (RANK[r["verdict"]], -r["share_affected"], r["id"]))
    with OUT.open("w") as fh:
        for r in records:
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")

    nb = sum(1 for r in records if r["verdict"] == "residue_required")
    print(f"{len(laws)} corpus lines; {len(records)} affected "
          f"({nb} residue_required, {len(records) - nb} degraded) -> {OUT.name}")
    print("\nby atom:")
    for (a, c), n in by_atom.most_common():
        print(f"  {n:4d}  {a:32s} {c}")
    print("\nby class:")
    for k, n in by_class.most_common():
        print(f"  {n:4d}  {k}")


if __name__ == "__main__":
    main()
