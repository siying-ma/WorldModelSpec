# NRS_484B_113_2 — task result

## Final verdict: OK (7 witnesses, 6 names, composes nothing)

## Gate runs
1. **WITNESS_FAIL**: `branch_2` and `branch_3` failed trace admission. They had a 20 deg/s yaw rate
   but the heading did not change. Fix: the car now backs around the corner with an exact quarter
   turn. Its heading goes from east to north over one second at 90 deg/s, then it backs straight
   south with no yaw. Both witnesses are judged on the 1–2 s window.
2. **OK**.

(Two non-gate shell calls, an `ls` and a no-op, were made by mistake early in the session. They
changed nothing.)

## Rule as written
- Class of `x`: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability: `.tt`. The record's applicability is only the vehicle class, and the binder
  class already carries it. b5 and b6 appear only in the corner limb, as the record puts them there.
- Obligation: `not (a ∨ b ∨ c)`, where:
  - (a) `drv_motion_reversing x [p.speed_resolution]` ∧ ∃ intersection r. `rises (rel_occupies x r)`
  - (b) reversing ∧ ∃ crosswalk c. `rel_occupies x c`
  - (c) `asm.within_city_limits` ∧ reversing ∧ `drv_motion_yawing x [p.yaw_rate_resolution]` ∧
    ∃ intersection k. `rel_occupies x k`

## Choices the node left open
- **Where the entry edge in (a) goes:** I put `rises` inside the region quantifier. "Begins here to
  overlap some st.intersection region" then means the entry into that particular region. It is not
  the rise of "occupies any intersection".
- **No narrowings declared:** every element is written exactly as the record maps it.

## Witnesses
All witnesses use the same layout: an intersection (−10..10 m square), a marked crosswalk on its
south leg and a stop line. Reversing is 2 m/s against the heading. Every witness is judged from
t = 1 s onward, so the entry edge always has a previous observation.
- `forbid`: the car backs west along the east leg and enters the intersection at 4 s. It is caught
  by (a) only.
- `permit`: the car backs into a mid-block bay, away from the junction.
- `idle`: a bicycle is walked backwards over the crosswalk. The bicycle class is excluded from the
  vehicle aggregate, so the class is decided false.
- `blind`: the car is on the crosswalk and `kin.velocity` is masked, so (b) is unknown.
- `branch_1`: the car backs from the intersection onto the crosswalk. It is caught by (b) only.
- `branch_2`: inside city limits, the car turns its heading a quarter turn while reversing inside the
  intersection. It is caught by (c) only.
- `branch_3`: the same motion as `branch_2`, outside city limits, so the result is compliant.

## Why I finished
The gate returned OK on run 2 of 6.
