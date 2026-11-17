# NRS_484B_450_1l — task result

## Final verdict
**OK** (19 witnesses, 24 names, composes nothing).

## Gate runs
1. `OK`. This was the first gate run, on the first full write of both files. Nothing changed after it.

(Before that, a stray shell call that was not the gate command was denied by the sandbox. It did not run and did not use any of the gate budget.)

## How the rule is written
- **Subject class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s9, s10, s11):** there is a road user `b` that is not the subject and is in the vehicle aggregate. `b` is at rest (`drv_motion_complete_halt` with `p.halt_speed_tolerance`). There is a `road_edge` region `e` with all of the following:
  - `e` lies on some `highway` region (`st_on_way`).
  - The distance from `b`'s body to `e` (`st_region_geometry_distance`) is at most `p.edge_standing_gap`.
  - `rel_longitudinal_overlap subject b ≥ 0`.
  - `b`'s lateral bearing (`rel_bearing … "y"`) and `e`'s lateral offset (`prim_region_lateral_offset subject e`) are both negative or both positive.
- **Obligation (s2, s3/s4, s5–s7):** the subject is not at rest, or one of these exceptions holds:
  - **Queue exception (the operationalization):** some member `c` of the traffic aggregate, other than the subject, is ahead of the subject in the same lane (`rel_ahead_behind_in_lane c subject`) and within `p.queue_halt_gap` (`rel_surface_gap subject c`, the gap's length).
  - **Device or officer exception:** some `travel_region` the subject occupies is governed by any of these:
    - a stop sign;
    - a yield sign;
    - a traffic signal showing circular_red, flashing_red or red_arrow in any direction;
    - a railway signal or gate with lights flashing, or with the gate lowering or down;
    - a human direction with role police_officer and indication stop.

## Choices the node left open
- **s5 and s7 written as one disjunction.** s5's devices (stop sign, red signal) are a subset of s7's. I wrote each device limb once, under one occupied travel region, instead of repeating them. This does not change the meaning.
- **"a red_arrow":** read as every arrow direction (left, right, straight, u_turn), since the record names none.
- **No narrowings of my own.**

## Witnesses
The eight planned witnesses are `forbid`, `permit`, `idle`, `blind` and `branch_1` to `branch_4`. I added eleven more, `branch_5` to `branch_15`, so that every leaf is exercised:
- **Queue:** a vehicle 2 m ahead is compliant; 12 m ahead is violated.
- **Stop sign:** governing the subject's lane is compliant; governing only the other lane is violated.
- **Yield sign:** compliant.
- **Railway:** lights flashing is compliant; gate down is compliant.
- **Human direction:** a police officer signalling stop is compliant; a flagger signalling stop is violated; a police officer signalling proceed is violated.
- **Green signal:** violated.

## Why I finished
The gate returned OK on the first run.
