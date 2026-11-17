# LVMC_11_30_050: task result

## Final verdict
`SCOPE_VIOLATION`. The gate never judged the rule or the witnesses. It stopped at its scope check
every time because of files under `.runtime/tmp/claude-154266/…/tasks/*.output` and
`.runtime/tmp/claude-154266/cache-break-state-*.json`. The agent runtime writes these files when it
runs a shell command. Some of them come from other sessions (LVMC-11-18-020, LVMC-11-43-010-B-o1).
Every gate call adds a new output file, so this session can't clear the problem. It is an
infrastructure problem (the scope check should ignore `.runtime/tmp`), not a defect in the node's
files. Only the two node files were edited.

## Gate runs (3 of 6 used)
1. `SCOPE_VIOLATION`: my mistake. I sent the gate command with a pipe/echo attached before writing
   anything, so it was not the exact command required. Its only output was the `.runtime/tmp` scope failure.
2. `SCOPE_VIOLATION`: also my mistake, a stray second call before any edit. Same `.runtime/tmp` files.
3. `SCOPE_VIOLATION`: after writing the rule and the witnesses. Same cause; my files were not the problem.
I stopped there. Each further run creates another `.runtime/tmp/.../tasks/*.output` file, so it would
return the same verdict.

## The rule as written
- Class: `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
- Applicability (e2, e4): the subject occupies some `roadway`, and occupies no `crosswalk`, and
  occupies some carrier it moves across. The carrier is a `lane` or a `roadway`, each tied to the
  subject by `rel_occupies`, with `drv_motion_moving_across_carrier(subject, k)
  [p.halt_speed_tolerance, p.crossing_motion_cos]`.
- Obligation (e3): for every lane and every roadway selected the same way (occupied and moved across
  with `p.crossing_motion_cos`), `drv_motion_moving_across_carrier(subject, k)
  [p.halt_speed_tolerance, p.right_angle_crossing_cos]`. The record says "for each such carrier k",
  so this is a universal over each carrier kind.
- No narrowings of my own; the record's e3 narrowing is not restated.

## Choices the node left open
- Carrier kinds: lane and roadway are written as two separate quantifiers, because the applicability
  names both ("a lane, st.lane, or a roadway").
- Witness geometry: on a two-way laned roadway the roadway itself carries no direction, so its
  carrier leaf is unknown there. In `permit` and `blind` the roadway is one-way and carries a
  direction, so they are not left unknown by an unobserved `st_lane_direction`. `forbid` uses the
  two-way roadway: the lane leaf alone decides the violation there. `branch_2` (violated: an unlaned
  one-way roadway crossed diagonally) covers the roadway carrier leaf on its own.
- Angles: diagonal heading (3/5, 4/5), |cos| = 0.6, which is under 0.94 and over 0.26. Near-square
  heading (21/221, 220/221), |cos| ≈ 0.095, under 0.26. Lanes run east, which is axis-aligned, so the
  normalised direction is exact.

## Why I finished
The gate can't judge the files: its scope check fails on runtime temp files under `.runtime/tmp`,
which neither this session nor the node controls, and each run adds another one. The rule and
witnesses are written in full but have not been checked by the gate (it has not built, checked or
run them). The harness re-runs the gate after this session, and that run may get past the scope check.
