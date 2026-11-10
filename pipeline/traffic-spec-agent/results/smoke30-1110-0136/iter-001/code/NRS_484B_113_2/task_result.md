# NRS_484B_113_2 — task result

**Final verdict: OK** (9 witnesses, 6 names, composes nothing)

## Gate runs (3 of 6 used)

1. `UNUSED_CLAIM` (all six claimed names): I ran this on the untouched skeleton, before writing anything. After it I wrote the class, applicability and obligation, plus all the witnesses.
2. `WITNESS_FAIL` on branch_2, branch_3 and branch_5: in these traces the car yawed at 15 deg/s but its heading never changed, which the adapter cannot produce. After it I changed the turning witnesses to a left yaw of 90 deg/s held over each 1 s interval. Their headings now step a quarter turn each time (east→north→west, west→south→east), so the vectors stay exact.
3. `OK`.

Before the first gate run I tried two other commands (`--help` and `--dry`). Both were denied by the permission system and did not run.

## Rule as written

- Class: `ru_aggregate(x, "DEF-NRS-484A-320::vehicle")`.
- Applicability has three parts, joined by "or". It is the record's applicability, with the same structure:
  - s3: `existsRegion intersection i: rises(rel_occupies(x, i))`
  - s4: `existsRegion crosswalk c: rel_occupies(x, c)`
  - s5–s7: `asm.within_city_limits ∧ drv_motion_turning(x; p.yaw_rate_tolerance) ∧ existsRegion intersection j: rel_occupies(x, j)`
- Obligation: `not drv_motion_backing(x; p.motion_speed_tolerance)`.

## Choices left open

None. The record states the applicability and obligation completely. I declared no narrowings of my own and did not restate the record's own.

## Witnesses

- Every witness sets `window = (1000, 2000)`. The entry test (a rising edge) cannot be decided at the first observation, so the 0 ms instant is left out.
- I added two branch witnesses so that every condition in the rule changes at least one result:
  - **branch_4 (not_applicable):** the car backs straight inside an intersection it had already entered, in a city. This exercises `drv_motion_turning`, and also the rising-edge test as opposed to plain occupancy.
  - **branch_5 (not_applicable):** the car backs while yawing mid-block, in a city, with no intersection under it. This exercises the intersection-occupancy test in the corner part.
- In `blind`, `kin.velocity` is masked in the manifest and also left unset in the scene.

## Why I finished

The gate returned `OK`.
