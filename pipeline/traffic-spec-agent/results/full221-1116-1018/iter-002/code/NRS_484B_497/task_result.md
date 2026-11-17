# NRS_484B_497 — task result

**Final verdict: OK** (8 witnesses, 19 names, composes nothing)

## Gate runs
1. `OK` — first run. Rule and witnesses written in one pass; nothing changed after it.

(Before the first gate run, one shell command that added `--help` to the gate command was denied by the
permission layer. It did not run and did not use a gate run.)

## How the rule is written
- **Class**: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s1, s3)**: ∃ a `one_way_roadway` r and a `highway` h such that the subject occupies r
  (`rel_occupies`), r lies on h (`st_on_way`), and some `lane` lies on h (`st_on_way`).
- **Obligation**: for every r and h with that same full selection, it is not the case that all of the following hold:
  - (s2) `drv_motion_parked(subject; p.halt_speed_tolerance, p.standing_min_duration)`;
  - (s3) some `road_edge` e on h whose |`prim_region_lateral_offset`| is ≤ that of every road edge on h,
    and offset(e) × (`kin_heading` · `st_lane_direction`(r)) > 0. A positive product means a positive
    offset with a positive dot product, or a negative offset with a negative one, which is the
    record's two-case wording. A zero dot product decides "not left".
  - (s4) no `parking_space` the subject occupies, no `regulatory_sign` with code `angle_parking`, and no
    `zone_sign` of kind `parking_restricted` whose `prim_conditions_hold` for the subject and that
    `dev_governs` a `travel_region` the subject occupies.

## Choices left open
- **Ties for the nearest edge**: "the one with the smallest absolute offset" is written as "no larger
  than every road edge on h". If two edges are equally near, an edge that is on the left
  satisfies the condition. This choice only matters when two edges are exactly equally near. It is
  not declared as a narrowing because it does not narrow any span.
- **Conditions on the angle-parking sign**: the record attaches `prim_conditions_hold` to both device
  kinds, and the rule follows that.
- No narrowings declared.

## Witnesses
- `forbid`, `permit`, `idle`, `blind` as planned. `blind` is the forbid trace masked with
  `Build.masked` on `st.lane_direction`.
- `branch_1`: parking bay. `branch_2`: a 20 s halt between moving stretches.
- Added `branch_3` (angle-parking regulatory sign) and `branch_4` (parking-restricted zone sign) so that
  both device limbs of s4 are exercised.
- Every witness has a `window` starting at 70 s, so the 60 s look-back of `drv.motion.parked` stays
  inside the trace.

## Why I finished
The gate returned OK on the first run.
