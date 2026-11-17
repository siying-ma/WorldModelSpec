# NRS_484B_777_1_o1 — task result

## Final verdict: OK

Gate output: `OK — 14 witnesses, 17 names, composes NRS_484B_785_1a`.

## Gate runs
1. By mistake, before any edit I issued the gate command with extra shell text appended
   (`… | head -0; echo skip`). That broke the one-command rule. Its output was thrown away, so
   I cannot say whether the gate actually ran or what it returned. If it did run, it counted
   against the budget on the unedited skeleton files.
2. After I wrote the rule and the witnesses: **OK**. Nothing changed after this run.

## How the node is written
- s1: the binder class is the three `ru_aggregate` atoms (bicycle, electric bicycle, electric scooter) joined by `or`.
- s2: the subject occupies some roadway: `existsRegion roadway r (rel_occupies subject r)`.
- Exception (a), s3/s4/s4b: three conditions together.
  - The subject's `kin_speed` is above `p.halt_speed_tolerance`.
  - `.rule "NRS_484B_785_1a"` holds (the compliance composition).
  - Every road user other than the subject is checked: if it belongs to the traffic aggregate and its `rel_surface_gap` to the subject is within `p.nearby_traffic_reach`, its speed must be at most the subject's speed plus `p.commensurate_speed_margin`.
- Exception (b), s5: there is a roadway the subject occupies, a highway that roadway lies on (`st_on_way`), and an intersection or driveway/alley entrance on that highway (`st_on_way`). The source declares `int.left_turn` for the subject at that place, read at the observation being judged.
- Exception (c), s7/s12/s13/s14: any one of three conditions.
  - **An obstruction:** its `prim_region_offset_along` (measured along the occupied roadway's direction) is in [0, reach], and its `prim_region_lateral_offset` is ≤ 0.
  - **A road user:** someone other than the subject, of the vehicle, bicycle or pedestrian aggregate, whose `rel_surface_gap` is ≤ reach, with `rel_bearing` longitudinal > 0 and lateral ≤ 0.
  - **A narrow lane:** a lane the subject occupies with `st_lane_width` below `p.shared_lane_min_width`.
- Obligation, s8/s9: take a roadway the subject occupies, a highway it lies on, and a road edge on that highway with a negative lateral offset (on the subject's right). The rule requires 2·|offset| − `kin_extent` width ≤ 2·`p.bicycle_keep_right_gap`. The rule wraps this in `definedWhen` so it applies only where such a right-hand edge exists; where none exists, or its offset is unobserved, the verdict is unknown.

## Choices the node left open
- **Doubled comparison.** I wrote "offset magnitude less half the width" doubled on both sides, which is exactly equivalent. Halving would need a literal 2, and the node declares no literals.
- **Bearing components.** `rel_bearing` components are read with the `"x"` (longitudinal) and `"y"` (lateral) selectors. These are the only component selectors that `evalMeasure` accepts.
- **Offset carrier.** The carrier for `prim_region_offset_along` is the roadway the subject occupies, as the record's applicability states.
- **No narrowings.** None declared; nothing was read more narrowly than the record states.

## Witnesses
All witnesses are single-observation scenes.
- **The nine planned witnesses** are built as the node's narratives describe.
- **branch_6 to branch_9** (not applicable) each exercise one limb of the exceptions that the planned scenes never reach:
  - branch_6: debris ahead on the right;
  - branch_7: a pedestrian ahead on the right;
  - branch_8: another bicycle ahead on the right;
  - branch_9: a declared left turn at a driveway entrance on the subject's highway.
- **branch_10** (violated): an electric-bicycle subject in the forbid geometry.
- **The electric-scooter class limb has no witness that decides it.** The aggregate `DEF-NRS-484B-018::electric_scooter` has no included class, so that atom is never true. The gate still returned OK.

## Why I finished
The gate returned OK, and both files are complete.
