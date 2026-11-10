# NRS_484B_440_1_o1 — task result

**Final verdict: OK** (12 witnesses, 22 names, composes nothing).

## Gate runs
1. `BUILD_FAIL` — rule line 124: too many closing parentheses at the end of `directedHalt`. Removed them.
2. `BUILD_FAIL` — I removed one too many, so the same line was now one short. Added one back.
3. `OK`.

## How the rule is written
- Class (e4): `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability (e1, e2, e6, e11–e13):
  - x occupies some highway `h`, and some roadway `rw` with `st_on_way(rw, h)`.
  - `asm.business_or_residence_district` is false.
  - The exception does not hold: `asm.vehicle_disabled` ∧ x occupies some roadway ∧ `asm.disabled_vehicle_immovable`.
- Obligation (e3, e7): violated at some selected `h` (the applicability's whole selection, written again) when all three hold:
  - x is halted (`drv_motion_stopped`, `p.motion_speed_tolerance`).
  - The halt is not excepted, that is:
    - no other road user z is ahead of x in its lane (`rel_ahead_behind_in_lane(z, x)`) with `rel_surface_gap(x, z) < p.queue_standstill_gap`;
    - no other road user is in a predicted conflict with x (`prim_closest_approach_within` with `p.conflict_time_horizon`, and `prim_closest_approach_distance < p.conflict_centre_clearance`);
    - no travel region x occupies is governed by a red signal (circular_red, flashing_red or a red arrow), a stop sign, a yield sign, or a police officer signalling stop.
  - Halting off the roadway is practicable: some shoulder `s` has `st_on_way(s, h)` and `st_region_geometry_distance(x, s) ≤ p.off_roadway_reach`, and no other halted road user occupies `s` with `rel_longitudinal_overlap(x, w) ≥ 0`.

## Choices left open
None beyond the record's; I added no narrowings. Two choices follow from the contracts:
- The argument order `rel_ahead_behind_in_lane(z, x)` means z is ahead of x.
- A red arrow is checked in each of its four directions as one leaf.

## Witnesses
The shared scene has a highway, a roadway, two lanes and a shoulder 0.95 m from the car's body. The car is halted in the eastbound lane.

| Witness | Expected | What happens |
|---|---|---|
| forbid | violated | the halt as described |
| permit | compliant | the shoulder is 8.35 m away, beyond the reach |
| idle | not_applicable | `asm.business_or_residence_district` is true |
| blind | unknown | `kin.speed` is masked |
| branch_1 | compliant | a stopped truck is 2 m ahead in the lane |
| branch_2 | not_applicable | the car is disabled and cannot be moved |
| branch_3 | compliant | a pedestrian's predicted closest approach is 3 m within 1.5–2.5 s |
| branch_4 | compliant | a red signal governs the lane |
| branch_5 | compliant | a stop sign governs the lane |
| branch_6 | compliant | a yield sign governs the lane |
| branch_7 | compliant | a police officer signals stop for the lane |
| branch_8 | compliant | a halted truck stands on the shoulder alongside the car |

## Session note
Once, I tried to read the Semantics file with `grep` through the shell. That command was denied, as the access rules say it should be, so I used the Read tool instead.

## Why I finished
The gate returned OK, and 3 of the 6 runs were used.
