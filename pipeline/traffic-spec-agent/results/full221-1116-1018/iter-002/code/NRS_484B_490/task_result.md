# NRS_484B_490 — task result

**Final verdict: OK** (7 witnesses, 8 names, composes nothing)

## Gate runs
1. `OK` — first run, on the rule and witnesses as described below. No changes needed.

## Rule
- Class (d2): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (d1 + d4): `existsRegion travel_region r. rel_occupies subject r ∧ existsDevice zone_sign d. (dev_zone_sign_kind d narrow_highway ∧ dev_governs d r ∧ prim_conditions_hold d subject)`.
  `r` is tied to the subject by occupancy. `d` is tied to `r` by `dev.governs` and to the subject by the conditions primitive.
- Obligation (d3): `¬ drv_motion_parked subject [p.halt_speed_tolerance, p.parking_min_duration]`.

## Choices left open
- None that needed a narrowing; `narrowings` is empty. The record's own narrowings (d3 duration, d1 status, d2 agency) are not restated.
- I did not add a `dev_zone_sign_end = false` condition, because the record's applicability does not state it, and d1 is a trigger span, which may not be narrowed.

## Witnesses
Two lanes (10 and 11) and a single zone sign (device 100). Samples are 10 s apart. The `window` field limits judgement to instants whose 180 s look-back is fully recorded.
- forbid (violated): stands from t = 20 s; judged t = 200–240 s.
- permit (compliant): halts 20 s at t = 200–220 s; judged t = 200–290 s.
- idle (not_applicable): the narrow_highway sign governs lane 11; the vehicle stands in lane 10.
- blind (unknown): `governsObserved := false`, and `dev.governs` is masked.
- branch_1 (not_applicable): the sign kind is parking_restricted.
- branch_2 (not_applicable): the sign's legend says Mon–Fri 07:00–09:00, and the civil time is Saturday 12:00.
- branch_3 (not_applicable): the subject is a pedestrian.

## Why I finished
The gate returned OK on the first run.
