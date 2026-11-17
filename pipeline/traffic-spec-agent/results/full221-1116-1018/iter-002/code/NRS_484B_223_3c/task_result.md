# NRS_484B_223_3c — task result

**Final verdict: OK** (4 witnesses, 8 names, composes nothing).

## Gate runs
1. `WITNESS_FAIL`. The adapter rejected the turn traces (forbid, permit, blind) as physically
   inconsistent. Headings were not rotated by the yaw rate held over the preceding interval, and
   one lane-change step grew path_length by less than the straight-line distance.
   Changed: the turn is now one exact 90° step (yaw 90 deg/s over the interval ending at t=11 s,
   north to west), so every heading is an exact unit vector. Path increments now always cover
   the straight-line displacement.
2. `OK`.

(One stray shell command, a `--help` variant of the gate, was denied by the sandbox before
run 1 and never ran. It did not count as a gate run.)

## The rule
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Trigger, `turnOntoHighway c h`: `rel_occupies subject c` ∧ `drv_motion_left_turn subject`
  (p.vehicle_turn_window, p.turn_heading_min, p.u_turn_heading_min, p.turn_yaw_rate_tol)
  ∧ ¬`holdsFor .time p.vehicle_turn_window subject (rel_occupies subject h)`. The last
  conjunct means that at some observation in the window behind, the subject occupied no part of h.
- Condition, `inLaneAfterTurn c h`: `.since (rel_occupies subject c) (turnOntoHighway c h)`.
- Applicability: `ru_aggregate subject "DEF-NRS-484A-285::traffic"` ∧ ∃ c of kind
  centre_turn_lane, ∃ h of kind highway, with `st_on_way c h` ∧ `inLaneAfterTurn c h`.
- Obligation: for every c and h with that same whole selection,
  `distanceWhile subject (inLaneAfterTurn c h) ≤ 50 ft` (written as `Units.feet 50`).

## Choices the node left open
- **Where "traffic" goes.** The record claims `ru.aggregate=DEF-NRS-484A-285::traffic` on s1
  and s6, but neither its applicability nor its obligation text says where it applies. I wrote
  it as the subject belonging to traffic, conjoined into the applicability: the lane is used by
  traffic, of which the turning subject is a member. The end of the counted travel ("merging")
  follows the record's own narrowing: the footprint leaves c.
- **Which lanes the obligation covers.** The duty is required for every selected (c, h) pair,
  with the selection restated in full. The applicability is existential.
- I declared no narrowings of my own.

## Witnesses
Each witness is 1 s sampling on a highway y∈[0,12] m: an eastbound lane, the centre turn lane
(on the highway via `ways`) and a westbound lane, plus a driveway off the highway to the south.
- **forbid:** the subject travels 30 m in the centre lane after the recognized turn.
- **permit:** it travels 10 m, then moves to the westbound lane.
- **idle:** it drives straight in the westbound lane.
- **blind:** the forbid trace with kin.yaw_rate masked.

The narrative's "85 degrees" became 90° so the headings stay exact and pass the adapter's
consistency check. 90° still lies well inside the turn band [45°, 135°).

## Why I finished
The gate returned OK on run 2.
