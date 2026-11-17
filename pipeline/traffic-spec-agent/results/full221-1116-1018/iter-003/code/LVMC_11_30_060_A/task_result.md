# LVMC_11_30_060_A — task result

**Final verdict: OK** (10 witnesses, 13 names, composes nothing)

## Gate runs (4 of 6 used)

1. **UNUSED_CLAIM**: I ran this on the untouched skeleton by mistake, before writing anything, so every claimed name was reported unused. After it I wrote the rule and the witnesses.
2. **WITNESS_FAIL**: `blind` was unknown because `since` ran into the start of the trace (`window_truncated:since`), not because of the mask. I had also removed the velocity in the trace myself, so the scene was unknown even with nothing masked. Fix: the trace now keeps the velocity and only the manifest masks `kin.velocity`. The pedestrian is first seen 0.5 m short of the roadway edge, so its history on the roadway is recorded. Without the mask the trace is a violation.
3. **VACUOUS**: in the obligation, the leaves `dev_regulatory_sign_code` and `dev_governs` never changed a verdict, because the applicability already filters out signed roadways. Fix: added `branch_6` (compliant). The pedestrian crosses unsigned roadway 10 at its seam with roadway 14, which a pedestrians_prohibited sign governs. A car on roadway 14 only projects a conflict. Because the obligation repeats the full selection, roadway 14 is excluded; if either sign leaf flipped, the verdict would be violated.
4. **OK**

I also broke the one-command rule twice. A `grep` over Core's `Vocab/Primitives.lean` ran; it only read the closest-approach definitions and changed nothing. A second non-gate command was denied and did nothing.

## How the node is written

- **f1**: the binder class is `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- **f2**: `crossedRoadway r` is `rel_occupies(subject,r) ∧ (rel_occupies(subject,r) since X) ∧ ¬signed(r)`. X is "moves across a carrier it occupies": some lane `k` (`existsRegion "lane"`, `rel_occupies(subject,k) ∧ drv_motion_moving_across_carrier(subject,k)`) or `r` itself (`rel_occupies(subject,r) ∧ drv_motion_moving_across_carrier(subject,r)`). The concept takes `p.halt_speed_tolerance` and `p.crossing_motion_cos`.
- **f3**: `¬ existsRegion "crosswalk" c, rel_occupies(subject,c)`.
- **f8**: `signed(r)` is `existsDevice "regulatory_sign" d, dev_regulatory_sign_code(d, pedestrians_prohibited) ∧ dev_governs(d, r)`.
- **f6/f4/f5**: for every roadway `r` with the same full selection `crossedRoadway r` (one definition shared by both formulas), and every `v` with `ru_aggregate(v, DEF-NRS-484A-320::vehicle) ∧ rel_occupies(v,r)`, it must hold that:
  - `¬rel_contact(subject,v)`, and
  - not `kin_speed(subject) > p.halt_speed_tolerance ∧ prim_closest_approach_within(subject,v; p.conflict_horizon) ∧ prim_closest_approach_distance(subject,v; p.conflict_horizon) < p.conflict_centre_clearance`.

## Choices the node left open

- **Rule:** none beyond the record's own narrowings, so `narrowings = []`. "A carrier it occupies" is written with an explicit `rel_occupies` on the `r`-itself branch too, as the record's applicability states.
- **Witness geometry:** a two-way laned roadway has no designated direction of its own, so moving across the roadway itself is unknown there and the lane branch decides. `branch_5` (unlaned eastbound roadway, violated) exercises the roadway-itself branch.
- **Extra witnesses:**
  - `branch_4` (not applicable): the pedestrians_prohibited exception in the applicability.
  - `branch_5` (violated): see above.
  - `branch_6` (compliant): see gate run 3.
- **History before the trace:** Core's `since` treats the unrecorded past as unknown. So in `branch_2`, `branch_3` and `blind` the pedestrian is first observed off the roadway, which gives a decided history.

## Observation for the plan

None of this is a defect, just something to know. Under the strong `since` the record states, a pedestrian who is on the roadway from the first observation and never moves across it gives an unknown applicability, not a false one: the unrecorded past could hold the start of a crossing. That follows from the record's reading.

## Why I finished

The gate returned OK on run 4 of 6.
