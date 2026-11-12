# NRS_484B_257_1_o2 — task result

**Final verdict: OK** (16 witnesses, 25 names, composes nothing). 5 of 6 gate runs used.

## Gate runs

1. **UNUSED_CLAIM** (every claim) — an accidental run on the untouched skeleton, before any edit.
   It confirmed the list of claim names. (A second Bash call was also attempted, a no-op wrapper
   around the gate command; it was denied and did not run.)
2. **WITNESS_FAIL** — `blind` was unknown for `st_lane_enters` and `st_lane_direction` as well as
   `dev.governs`. The cause was the carrier quantifier binding `c` to the intersection itself: once
   ego was inside `i`, the binding `c = i` was undecided because `i` has no lane relations.
   Fix: the entry observation now also requires ego **not** to occupy `i` (the last observation on
   `c` before ego overlaps `i` continuously). That decides `c = i` false.
3. **VACUOUS** — the obligation's copy of `ru_aggregate ego DEF-NRS-484A-285::traffic`. Fix: the
   obligation's repeated selection uses the g1 control itself (an officer or an operating signal
   over `c` or `i`) without the traffic membership. Every class included in
   DEF-NRS-484A-320::vehicle (the binder's class) is also included in DEF-NRS-484A-285::traffic, so
   wherever the rule is engaged the membership is true and both copies select the same `(i, c)`.
   The membership stays in the applicability, where `branch_6` moves it.
4. **OK**.

## How the node is written (choices the record left open)

- **g14 / entry.** The rule is judged where ego overlaps an intersection `i` and is not
  `drv.motion.at_rest`, and where, since an entry observation, ego has overlapped `i` at every
  observation (`since`). The entry observation is the one where ego occupies a travel region `c`
  but not `i`, and `c` enters `i` (`st_lane_enters`). At that observation:
  - g2: a stop or yield sign governs `c`.
  - g1: there is no control.
  - g8: the act was made.
- **g8, the approach start.** I read it as the start of ego's current continuous stay on `c`:
  `since (occupies ego c) act`. This follows the `st.lane_enters` contract, where the approach is
  the carrier ego occupies. If the stay reaches back past the trace start without the act, the
  result is unknown, as the applicability requires.
- **g8, the governing place.**
  - The stop line marking `c` (`st_entrance_of`).
  - If there is none, a crosswalk marking `c` that ego does not occupy.
  - If there is neither, `i`, with ego outside it.

  "At the place" means ego's body is within `p.stop_point_tolerance` of the region
  (`st_region_geometry_distance`), and ego's reference point is not past the region along `c`
  (`prim_region_offset_along ego r c ≥ 0`). For the yield limb, the "stopping zone" is this same
  relation.
- **g8, the yield limb.** It applies only when no stop sign governs `c` and a yield sign does. The
  limb requires `drv.motion.decelerating` (tolerances `p.decel_tolerance` and
  `p.rest_speed_tolerance`) at some observation of the `.path` window `p.yield_slowing_distance`
  behind an observation where ego is at the place.
- **g12.** `b` is a DEF-NRS-484A-320::vehicle other than ego. It overlaps `i`, and has overlapped
  it at every observation since it occupied a through carrier `cb`. A through carrier:
  - enters `i`;
  - lies on a highway that `c` does not lie on;
  - is governed by no stop or yield sign.
- **g13.** `b` occupies such a `cb`, and `st_region_geometry_distance b i ≤ kin_speed b × p.immediate_hazard_time`.
- **g10/g11.** For every such `b`, the obligation is: not (`prim_closest_approach_within` and
  `prim_closest_approach_distance < p.conflict_clearance`), both with horizon `p.conflict_horizon`.
  g10's "at rest" limb is not written. The duty is judged only where ego is not at rest (g14), so
  that limb is false wherever the obligation is read.
- **Selection repeated.** The obligation repeats the whole `(i, c)` selection and states the duty
  for every selected pair (`forallRegion` over both).
- No narrowings were declared, and residues are unchanged.

## Witnesses

The planned scenarios are `forbid`, `permit`, `idle`, `blind` and `branch_1`–`branch_3`. I added:

- `branch_4`: halt short of a crosswalk, no line → violated.
- `branch_5`: halt at the intersection edge, no line or crosswalk → violated.
- `branch_6`: a police officer governs `c` → not applicable.
- `branch_7`: an operating signal governs `i` → not applicable.
- `branch_8`: devices that control nothing relevant → violated. These are a flagger on `c`, a
  police officer and an operating signal on `b`'s lane, and an inoperative signal head on `i`.
- `branch_9`: a line well back; ego passes it and halts only before the crosswalk → not applicable.
- `branch_10`: a line well back; ego passes it and halts only at the edge → not applicable.
- `branch_11`: ego halts on the crosswalk → not applicable.
- `branch_12`: stop and yield signs both govern `c`; ego only slows → not applicable.

## Why I finished

The gate returned OK on both files. The node looks consistent: every claimed name is used, and
no span had to be declared unexpressed.
