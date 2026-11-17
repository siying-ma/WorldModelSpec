# NRS_484B_560_7a — task result

**Final verdict: OK** (5 witnesses, 5 names, composes nothing).

## Gate runs
1. `OK` — first run, on the files as written below; no change after it.

## The rule
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (a2 + a5): `existsRegion railway_crossing c (dist(subject,c) < 15 ft ∧ since (dist < 15 ft) (rel_occupies subject c))`,
  with the distance as `st_region_geometry_distance` and 15 ft as `Units.feet 15` (the record's literal).
- Obligation (a3 + a4): `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`. The obligation names
  no region, so the crossing chosen in the applicability does not need to be selected again there.

## Choices left open
- None beyond the record's own narrowings, so `narrowings` is empty. "Below 15 ft" is written with a strict `<`, as the record states it.

## Witnesses
The road runs east. The crossing is the rectangle x∈[0,10] m. Each trace has three instants 1 s apart, and occupancy is stated in every scene.
- forbid: a truck at rest 2 m past the crossing after occupying it → violated.
- permit: a car crosses at speed and comes to rest 8 m past the crossing → compliant.
- idle: a car halts at an intersection far from the crossing → not applicable.
- blind: a car on the crossing with `kin.speed` unset and masked → unknown.
- branch_1: a car at rest while it still occupies the crossing → violated.

## Why I finished
The gate returned OK on the first run.
