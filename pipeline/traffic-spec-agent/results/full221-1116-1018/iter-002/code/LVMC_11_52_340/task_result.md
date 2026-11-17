# LVMC_11_52_340 — task result

## Final verdict
**OK** (6 witnesses, 7 names, composes nothing)

## Gate runs
1. **OK**: first run, on the files as first written. Nothing changed after it.

## The rule
- Class (s3): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability: the subject is not a City vehicle (s4) and occupies some municipal parking space (s1/s5).
  - s4: `¬(ru_official_vehicle subject ∧ ru_official_vehicle_kind subject municipal)`.
  - s1/s5: `∃ parking_space r. st_parking_space_designation r municipal ∧ rel_occupies subject r`.
- Obligation (s2): `∀ parking_space r. (designation r municipal ∧ rel_occupies subject r) → ¬ drv_motion_parked subject [p.halt_speed_tolerance, p.parking_min_duration]`. The obligation repeats the applicability's whole selection of the space (rule 3c) and applies the duty at every selected space, as the record states.

## Choices the node left open
- **s4 conjunct.** The exception adds the class atom `ru_official_vehicle` alongside the kind atom. A road user that is not an official vehicle has no `officialKind` field, so the kind atom alone would be unknown for every private car. The class atom keeps the exception decided-false for those cars. Both names come from the claimed `ru.official_vehicle`, so this is the element's own mapping, not a narrowing.
- I declared no narrowings of my own. The record's narrowings cover the readings.

## Witnesses
The bay is the rectangle x∈[0,6] m, y∈[0,3] m. The street is y = −5 m. Samples are 10 s apart, or 60 s apart in the hour-long scenes.
- **forbid** (violated): a private car drives in, then rests in the municipal bay for 600 s. Judged from t = 240 s.
- **permit** (compliant): a private car drives for 200 s, rests 30 s in the bay, then leaves. Each judged instant's 180 s window includes moving samples.
- **idle** (not applicable): a municipal official vehicle rests in the bay for an hour.
- **blind** (unknown): a private car rests beside the bay with `rel.occupies` masked.
- **branch_1** (not applicable): a private car rests in a bay of designation `general`.
- **branch_2** (violated, added): an official vehicle of kind `tow` parks in the municipal bay for 600 s. Without it, nothing tests the municipal-kind atom on its own.

## Why I finished
The gate returned OK on the first run.
