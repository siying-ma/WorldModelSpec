# NRS_484B_307_9b_o4 — task result

## Final verdict

**OK** (gate run 1 of 6): 7 witnesses, 17 names, composes nothing.

## Gate runs

1. `OK`: the first and only run. Nothing was changed after it.

Before the gate run, one Bash call was mistaken. It was a compound no-op, meant as a placeholder,
that wrapped the gate command with `--help`. The permission layer denied it, so it did nothing.
An earlier `ls` of the Core directory went through; its output was used only to find the Core
file names.

## How the rule is written

- **Class of x (b2–b4):** five `ru_aggregate` atoms, one per claimed aggregate id, joined by `or`
  with `ru_motorcycle`.
- **Applicability (b1, b5, b6):** `existsRegion intersection i`, then one of three cases:
  - straight through (`drv_motion_straight_through_region`) under a red with either green arrow;
  - a right turn (`drv_motion_right_turn_through_region`) under `green_arrow(left)`;
  - a left turn (`drv_motion_left_turn_through_region`) under `green_arrow(right)`.

  Each movement is recognised at the exit. The signal is read at the entry with
  `since (¬ rises occupies(x,i)) (rises occupies(x,i) ∧ facing dir)`. `facing dir` means some
  `traffic_signal` s shows `circular_red` and `green_arrow(dir)`, and governs one of two things:
  - a `travel_region` c with `st_lane_enters(c, i)` that x occupied at the observation before the
    entry, or
  - i itself.

  The step bound is `p.heading_since_step_carla_scene_graph`. The upper end of both turn bands is
  `p.reversal_min_angle`.
- **Obligation (b12):** the rule selects i again with the applicability's whole selection
  (rule 3c). It then requires `¬ since (¬ rises occupies(x,i)) (¬ yieldsHere)`: no observation
  from the entry to the exit fails the duty. At one observation the duty applies where x occupies
  i and `drv_motion_moving` holds. For each pedestrian p (DEF-NRS-484A-165) and each member z of
  traffic (DEF-NRS-484A-285, other than x), the duty is not both:
  - `prim_closest_approach_within` over `p.conflict_time_horizon`, and
  - `prim_closest_approach_distance < p.conflict_centre_clearance`.

  The pedestrians counted are those occupying a `crosswalk` w that `st_entrance_of` records as
  marking a `travel_region` c2 with `st_lane_enters(c2, i)`. The traffic counted is the members
  occupying i.

## Choices the node left open

- **"Occupied at the observation before the entry" (b5):** the language has no operator for the
  previous observation. This is written from one-step edges:
  `rises(¬occupies(x,c)) ∨ (occupies(x,c) ∧ ¬rises(occupies(x,c)))`, which is exactly
  "occupies(x,c) at the previous observation".
- **Each crossing judged once:** the duty is judged at the exit, over the observations since the
  last entry. The span is written as the record states it, so no narrowing is declared.
- **`¬ same(c2, i)` guard on the adjacent-crosswalk carrier:** an intersection is not a carrier
  that enters itself, so the guard leaves out nothing the record admits. Without it,
  `st_lane_enters(i, i)` is unknown, because an intersection carries no entry topology. That
  unknown would make the masked `blind` witness unknown for reasons other than `st.entrance_of`.
  The header explains this. It is not declared as a narrowing because it narrows nothing.
- **Narrowings:** none added. The record's own b2 and b12 narrowings are not restated.

## Witnesses

All seven use one four-arm junction with scenes 50 ms apart. Each names its instants from 50 ms
on, because the entry and exit edges are unknown at the first scene. The header of the witness
file describes the geometry.

| witness | verdict | scene |
|---|---|---|
| forbid | violated | bicycle straight through; pedestrian in the far crosswalk in predicted conflict |
| permit | compliant | bicycle stops in the intersection while the pedestrian crosses, then rides on |
| idle | not applicable | bicycle turns left with the left arrow |
| blind | unknown | `st.entrance_of` masked |
| branch_1 | compliant | motorcycle straight through, alone |
| branch_2 | violated | moped turns right in conflict with a car inside the intersection |
| branch_3 | violated | added: left turn under a green right arrow, with the signal governing the intersection itself |

- **permit** also exercises `drv_motion_moving`: the closest approach to the pedestrian while
  the bicycle stands would count as a conflict if it were moving.
- **branch_3** exercises the left-turn case and the `dev_governs(s, i)` case. The pedestrian is
  in the west crosswalk.

## Why I finished

The gate returned OK on the first run.
