# LVMC_11_52_136 — task result

**Final verdict: OK** (5 witnesses, 5 names, composes nothing)

## Gate runs
1. `OK` — first run, on the rule and witnesses as written below. Nothing changed after it.

## How the rule is written
- Class (s2): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (s3): `existsRegion parking_space aisle (st_parking_space_designation aisle access_aisle ∧ rel_occupies subject aisle)`.
- Obligation (s1): `forallRegion parking_space aisle ((designation access_aisle ∧ rel_occupies subject aisle) → ¬ drv_motion_parked subject [p.halt_speed_tolerance, p.parking_min_duration])`. This restates the whole selection from the applicability and gives the duty for every selected aisle, as the record says.

## Choices the node left open
None. The rule has no narrowings of its own. The record's three observable readings are not restated.

## Witnesses
Scenes are 10 s apart. Each witness has a window that starts at 200 s, so the 180 s look-back of `drv.motion.parked` stays inside the trace.
- `forbid`: a car stays at rest in the access aisle for 300 s → violated.
- `permit`: a car drives at 5 m/s until 190 s, stands in the aisle from 200 s to 260 s, then drives off → compliant.
- `idle`: a car stays at rest in a general bay for 300 s → not applicable.
- `blind`: a car stays at rest in the disabled bay next to the aisle for 300 s, with `rel.occupies` masked → unknown.
- `branch_1` (added): a pedestrian stands in the aisle for 300 s → not applicable. This tests the class leaf.

## Why I finished
The gate returned OK on the first run.
