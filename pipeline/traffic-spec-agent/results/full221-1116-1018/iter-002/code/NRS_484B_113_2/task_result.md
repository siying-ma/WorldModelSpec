# NRS_484B_113_2 — task result

**Final verdict: OK** (7 witnesses, 7 names, composes nothing)

## Gate runs

0. A stray invocation: my first shell call was the gate command piped into `head -0` and followed by an
   `ls` of `Core/Language`. That was not the permitted single command, and it may have used up one gate
   run. Its output was discarded, so I saw no verdict from it. This was my mistake.
1. `WITNESS_FAIL`: in branch_3, the scene at t=50 kept its t=0 heading while its 100 °/s yaw rate
   should have turned it 5°. Admission requires the rate at a scene to be held over the interval
   before it. Fix: at step k the heading is now 5k° left of east, with 17 scenes (0…16). Each position
   now moves 0.1 m against that step's heading.
2. `OK`.

## How the rule is written
- Class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability: `drv_motion_moving_backward(subject)[p.halt_speed_tolerance]`.
- Obligation: `¬((a) ∨ (b) ∨ (c))`
  - (a) `∃ r:intersection. rises(rel_occupies(subject, r))`
  - (b) `∃ x:crosswalk. rel_occupies(subject, x)`
  - (c) `∃ r:intersection. rel_occupies(subject, r) ∧ |headingSince(subject, p.heading_since_step_carla_scene_graph, moving_backward ∧ rel_occupies(subject, r))| ≥ p.turn_heading_min`

## Choices left open
None beyond the record. The record states each limb, including the previous-observation entry
(`rises`), the ψ of headingSince and the absolute value of the turn. No narrowing of my own was declared.

## Witnesses
All traces sample every 50 ms, so headingSince is defined. Occupancy is stated per scene from the
footprint. blind is windowed to [0, 150] ms, ending at the entry instant, so that it is unknown
only because of the masked `kin.velocity`.

## Why I finished
The gate returned OK.
