# NRS_484B_450_1h — task result

**Final verdict: OK** (12 witnesses, 23 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` (every claim): the run was on the untouched skeleton, and it used up one run of the budget.
2. `CHECK_FAIL` — `units: compares m^2 with m`. The opposite-sign test `lz·le < 0` compared a product with a 0 in metres. Changed the right-hand side to `0 m · 0 m`.
3. `OK`.

## How the record is written
- **Class (s1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s9/s10):** ∃ safety zone z not occupied by the subject, ∃ road edge e adjacent to z, where adjacent means |le−lz| ≤ |l2−lz| for every road edge e2, using `prim_region_lateral_offset`. Then one of:
  - **between:** lz·le < 0, and the distance from the body to z (`st_region_geometry_distance`) is ≤ |lz|;
  - **opposite the zone's ends:** ∃ travel region r the subject occupies, with d = |`prim_region_offset_along`(z, r)| − length/2 (`kin_extent "length"`), d > 0 and d² + g² ≤ (30 ft)², where g is the distance from the body to e.
- **Obligation (s2–s7):** ¬`drv_motion_complete_halt`(p.halt_speed_tolerance), or one of:
  - another road user of DEF-NRS-484A-285::traffic is ahead of the subject in its lane, with `rel_surface_gap` ≤ p.queue_halt_gap;
  - a travel region the subject occupies is governed by any of:
    - a stop sign;
    - a yield sign;
    - a traffic signal showing circular_red, flashing_red or red_arrow (any direction);
    - a railway signal or gate with its lights flashing or its gate lowering or down;
    - a police officer directing stop.

## Choices the node left open
- **The s10 inequality is doubled:** 2d = |a| + |a| − length, 2g = g + g, and 2·30 ft = 30 ft + 30 ft. This is the same comparison, and it keeps every figure except the text's own 30 ft out of the rule.
- **s5's stop sign and red signal are written once.** They are a subset of s7's device list, so they appear only in the shared device disjunction.
- **"Other" is written as `¬ same u subject`.**
- No narrowings of my own.
- **Witnesses:**
  - `forbid`, `permit`, `idle`, `blind` and `branch_1` to `branch_3` follow the node's narratives.
  - I added `branch_4` to `branch_8` (all compliant) to exercise the other device leaves: stop sign, yield sign, circular_red signal, railway lights flashing with gate up, and railway gate down with lights dark.

## Why I finished
The gate returned OK on run 3 of 6.
