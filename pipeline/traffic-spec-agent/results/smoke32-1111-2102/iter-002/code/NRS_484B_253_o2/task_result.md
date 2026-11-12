# NRS_484B_253_o2 — task result

**Final verdict: OK** (12 witnesses, 12 names, composes NRS_484B_253_o1).

## Gate runs
1. `UNUSED_CLAIM` — run on the untouched skeleton (all formulas `.tt`), to see the baseline. Then wrote the rule and the witnesses.
2. `WITNESS_FAIL` — every turning trace was rejected as one the adapter cannot produce: t kept its heading between scenes while its yaw rate (15 deg/s) should have turned it. Changed t's headings during the turn to rational unit vectors about 16°, 31°, 44° and 58° left of north, with each scene's yaw rate (16, 14, 13, 15 deg/s) matching the step before it. Re-checked the conflict geometry with the new velocities.
3. `OK`.

(One stray attempt to run the gate with `--help` appended was denied by the sandbox and did not run.)

## How the rule is written
- Class of ego: `ru_aggregate ego DEF-NRS-484A-320::vehicle`.
- Applicability: there exist an intersection `i`, a `travel_region` `ce` and a road user `t` satisfying `selection`:
  - ego occupies `ce`, and `st_lane_enters ce i` holds;
  - `t` is not ego, `t` is a vehicle (aggregate), `t` occupies `i`, `t` declares `int.left_turn` at `i`, and `t` is turning left now;
  - there exists a `travel_region` `ct` such that:
    - `st_lane_enters ct i` holds;
    - the dot product of the `st_lane_direction`s of `ct` and `ce` is below −`p.opposite_direction_tolerance`;
    - `since turningLeft (rises turningLeft ∧ soYielded)`: the turn has been continuous since its onset, and f10 is read at that onset;
    - `soYielded` = `since (occupies t i ∧ rule NRS_484B_253_o1 {ego↦t}) (occupies t ct ∧ ¬occupies t i)`;
    - `since (¬ rises (occupies t ct)) (indicator left ∨ hand signal left)`: the signal was given since t's latest stretch on `ct` began.
- Obligation: ego is `drv.motion.at_rest`, or for every `i`, `ce` and `t` satisfying the same `selection` formula (the whole selection re-bound), ego is not in conflict with `t`. Conflict means `prim_closest_approach_within` (horizon `p.conflict_horizon`) holds and `prim_closest_approach_distance` is below `p.conflict_clearance`.

## Choices left open
None beyond the record's own wording. The record spells out every quantifier, onset and history bound, so I declared no narrowing.

## Witnesses
- The planned witnesses are `forbid`, `permit`, `idle`, `blind` and `branch_1`–`branch_4`.
- I added four more:
  - `branch_5` (compliant): ego is moving but far off, so the closest approach lies beyond the horizon.
  - `branch_6` (compliant): the closest approach is within the horizon but more than 5 m apart, above the clearance.
  - `branch_7` (not applicable): ego approaches on a perpendicular carrier, so the two directions are not opposed.
  - `branch_8` (not applicable): t is a bicycle, not a vehicle of the aggregate.
- `blind` is the `forbid` trace masked with `Build.masked` on the two signal atoms.

## Why I finished
The gate returned OK on the third run.
