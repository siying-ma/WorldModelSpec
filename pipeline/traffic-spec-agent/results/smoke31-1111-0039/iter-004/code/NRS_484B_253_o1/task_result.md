# NRS_484B_253_o1 — task result

## Final verdict: OK (7 witnesses, 10 names, composes nothing)

## Gate runs (3 of 6 used)
1. **UNUSED_CLAIM**: I ran the gate on the skeleton by mistake, before the formulas were written. Every claimed name was reported unused, as expected for placeholder formulas. After this run I wrote the rule and the witnesses.
2. **WITNESS_FAIL**: forbid, permit, branch_1 and branch_2 had a yaw rate at the turning scene while the heading stayed the same as the scene before. The adapter holds a scene's yaw rate over the interval before it. I fixed this by turning x's heading 15° (or 12° in branch_1) to the left at those scenes, as (−tan θ, 1).
3. **OK**.

(One extra shell command, the gate command with `--help` appended, was denied by the permission system before it ran. It did not reach the gate.)

## How the node is written
- **Class (s1):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s2, s3):** there is an intersection `i` such that x occupies `i`, the source declares `int.left_turn x i`, and there is a `travel_region` carrier `c` x entered through. "Entered through" is written as `since (rel_occupies x i) (drv_motion_entering_region x i ∧ rel_occupies x c ∧ st_lane_enters c i)`. If the entry happened before the recording, `since` leaves this unknown.
- **Obligation (s4–s7):** this applies at every intersection selected the same way (the full selection is restated, including the intent). For each entry carrier `c`, x yields when it is not turning left (`drv_motion_turning_left x` with p.speed_resolution and p.yaw_rate_resolution) whenever some vehicle y ≠ x is owed precedence. y is owed precedence when either:
  - (a) y occupies `i` and its own latest entry was through a carrier `c2` with `drv_road_opposed_directions c c2` (p.opposed_carriers_cosine); or
  - (b) y does not occupy `i`, occupies an approach carrier `c2` of `i` opposed to `c`, and `st_region_geometry_distance y i ≤ kin_speed y × p.immediate_hazard_gap`.
- **Several entry carriers:** the record says the verdict is unknown when the carriers disagree. The obligation is written as `∀c(entry→yields) ∨ definedWhen(¬∃c(entry ∧ yields)) ff`. This is compliant if x yields through every carrier, violated if it yields through none, and unknown otherwise.

## Choices the node left open
- **Excluding the intersection as a carrier.** Carriers `c` and `c2` range over `travel_region`, which also covers the intersection itself. `st_lane_enters` on a region with no lane record is unobserved, not false. Without a guard, that would make the opposed-vehicle test unknown in every scene. So I excluded the intersection by identity (`not (same c i)`). This is not a narrowing: the intersection is no approach to itself, and no fact of the scene is added. No `narrowings` were declared.
- **Extra witness `branch_3` (violated):** x first crosses `i` from the west approach, leaves, then re-enters through the south approach and turns left while y is a hazard on the opposed north approach. While turning, x's body overlaps the end of the west approach. This tests that only x's latest entry decides which carrier governs. It also gives the leaves in the "carriers disagree" check something to do.
- **Witness windows:** every witness sets `window` from t=1000 ms to its last scene. These scenes come after the first, so the look-back is never cut off by the start of the trace.

## Why I finished
The gate returned OK on the rule and witness files as they stand.
