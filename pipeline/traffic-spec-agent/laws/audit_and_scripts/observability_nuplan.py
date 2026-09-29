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
    # --- no audio channel: nuPlan ships cameras and lidar, no microphone ------
    "sig.horn":        ("blocked", "audio", "no microphone in the sensor suite; a horn leaves no visual trace"),
    "sig.siren":       ("blocked", "audio", "no microphone; the warning-lamp disjunct of drv.responding_emergency carries the emergency case instead"),
    "sig.compression_brake": ("blocked", "audio", "no microphone; the statute's own test for the offence is that the brake is audible"),
    # --- interior of an enclosed cabin ---------------------------------------
    "ru.occupant_count": ("blocked", "interior", "occupants of an enclosed cabin are behind glass at an angle; reliable only for open machines, where the riders are in plain view"),
    "kin.steer_angle": ("blocked", "ego_only", "EgoState.tire_steering_angle gives this exactly for the ego and for nothing else; visible on another vehicle only when it is parked and the wheels face the camera"),
    # --- facts that live in a register, not in the world ----------------------
    "ru.commercial_motor_vehicle": ("blocked", "registry", "rated gross weight and commercial licensing; no sensor reads either"),
    "ru.low_speed_vehicle": ("blocked", "registry", "manufactured speed capability, not observed speed"),
    "ru.moped": ("blocked", "registry", "separated from a motorcycle by engine displacement and rated power; nuPlan's own taxonomy folds both into 'bicycle'"),
    "ru.electric_bicycle": ("blocked", "registry", "motor wattage and the class 1/2/3 assist behaviour are rated facts; the bare 'has a motor' reading is a degraded estimate at best"),
    "ru.official_vehicle": ("blocked", "designation", "kinds regulatory_agency, coroner, municipal, incident_management and armored_car are designations, not liveries; tow, utility and highway_maintenance are livery-visible"),
    # --- observable, but with a failure mode a rule must carry ---------------
    "ru.rider_posture": ("degraded", "posture", "on an open machine the posture is in plain view; hands-on-controls and feet-on-pegs are unreliable at range and at night"),
    "dev.regulatory_sign": ("degraded", "sign_legend", "the sign is detectable; its legend -- the hours, days, classes and exemptions printed on it -- is an OCR-and-parse problem and is what the rule turns on"),
    "dev.zone_sign": ("degraded", "sign_legend", "as for regulatory_sign: the zone's extent and the condition printed on the plate"),
    "dev.human_direction": ("degraded", "rare_gesture", "an officer directing traffic is detectable in principle; the gesture vocabulary is unmodelled and the event is rare in the logs"),
    "dev.inoperative": ("degraded", "rare_gesture", "a dark or bagged head is visible; distinguishing a fault from a phase is not"),
    "ru.procession_vehicle": ("degraded", "context", "a funeral procession is read from placards, flags and an escort, not from the vehicle"),
    "ru.tour_bus_or_limousine": ("degraded", "livery", "livery-visible; the operating category behind it is not"),
    "ru.other_conveyance": ("degraded", "catch_all", "a residual class with no detector of its own"),
    "ru.personal_delivery_device": ("degraded", "rare_class", "absent from nuPlan's taxonomy and near-absent from the logs"),
    "ru.mobile_carrying_device": ("degraded", "rare_class", "as for personal_delivery_device"),
    # --- observable; failure recorded here, no residue on the rules ----------
    "ru.emergency_vehicle": ("note_only", "livery", "the marked class is a livery-and-silhouette detection; what is not recoverable is a vehicle the authority designates without marking it, and no line in this corpus turns on that case"),
    "ru.fire_apparatus": ("note_only", "livery", "as for emergency_vehicle"),
    "ru.school_bus": ("note_only", "livery", "as for emergency_vehicle; the Nevada livery and the sig.school_bus_signal arm are both conspicuous"),
    "ru.taxicab": ("note_only", "livery", "roof light and medallion livery"),
}
RANK = {"blocked": 0, "degraded": 1, "note_only": 2}

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
    """Return (capability, why-it-moved) for this atom in this line."""
    n = note.strip()
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
            "verdict": "blocked" if worst == 0 else "degraded",
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

    nb = sum(1 for r in records if r["verdict"] == "blocked")
    print(f"{len(laws)} corpus lines; {len(records)} affected "
          f"({nb} blocked, {len(records) - nb} degraded) -> {OUT.name}")
    print("\nby atom:")
    for (a, c), n in by_atom.most_common():
        print(f"  {n:4d}  {a:32s} {c}")
    print("\nby class:")
    for k, n in by_class.most_common():
        print(f"  {n:4d}  {k}")


if __name__ == "__main__":
    main()
