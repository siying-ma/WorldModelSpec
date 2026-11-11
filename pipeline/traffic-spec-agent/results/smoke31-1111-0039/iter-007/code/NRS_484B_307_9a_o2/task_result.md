# NRS_484B_307_9a_o2 — task result

**Final verdict: OK** (gate run 1 of 6: "6 witnesses, 14 names, composes NRS_484B_307_9b_o1, narrowings declared by the coder: 1").

## Gate runs
1. OK. This was the first run, with the formulas and the six witnesses written as described below. Nothing changed after it.

## How the node is written
- **Class (b3):** `ru_aggregate(x, DEF-NRS-484A-285::traffic) ∧ ru_aggregate(x, DEF-NRS-484A-320::vehicle)`.
- **Applicability (b1/b4/b5, b2):** an intersection `i` that x occupies now, read with `since (rel_occupies x i) entry`. Here `entry` means three things hold at the same observation:
  - `drv_motion_entering_region(x, i)`;
  - x occupies a `travel_region` carrier `c` with `st_lane_enters(c, i)`;
  - some `traffic_signal` `s` that governs `c` or `i` shows `circular_red` together with `green_arrow(left)` or `green_arrow(right)`.

  This is conjoined with `¬ ruleApplies NRS_484B_307_9b_o1 {x↦x}`. If the entry happened before the recording, `since` stays unknown (its head is unobserved).
- **Obligation (b7/b9):** wherever `drv_motion_moving(x, p.speed_resolution)` holds, every intersection selected as in the applicability is checked. The whole selection is restated there. For each such intersection, no party may be in danger:
  - **Danger** is `prim_closest_approach_within(x, ·, p.immediate_hazard_gap)` with `prim_closest_approach_distance(x, ·, p.immediate_hazard_gap) < p.conflict_clearance`.
  - **Parties:** every road user `p ≠ x` carrying `DEF-NRS-484A-165::pedestrian` that occupies a `crosswalk` `w`, where `st_entrance_of(w, c2)` holds for some `travel_region` `c2` with `st_lane_enters(c2, i)`. Also every road user `u ≠ x` carrying `DEF-NRS-484A-285::traffic` that occupies `i`.

## Choices the node left open
- **Narrowing on b9 (kind `reading`):** x itself is excluded from the pedestrians yielded to (`¬ same p x`). The words already exclude x from "other traffic", and a road user does not yield to itself. Without this, a vehicle's pedestrian membership, which is unresolved, could make the clause unknown for no reason.
- **Kind of the carrier `c2` in b9:** `travel_region`, the claimed kind that carriers belong to. I added no exclusion of other kinds.
- **Witnesses:** I added `branch_1` (violated: a stopped motor vehicle inside the intersection, which exercises the "other traffic" limb). I also added `branch_2` (violated: the signal governs the intersection rather than the approach lane, which exercises the `dev_governs(s, i)` limb).
- **Occupancy at the entry:** x's body lies across the approach lane and the intersection at that moment, so in the witnesses that occupancy is stated explicitly rather than derived from geometry.

## Notes
- By mistake I ran one `ls` of the Core directory before the first gate run, and then attempted one `grep`. The `grep` was denied. Neither changed any file.

## Why I finished
The gate returned OK on the first run, with every planned scenario plus two branch witnesses passing.
