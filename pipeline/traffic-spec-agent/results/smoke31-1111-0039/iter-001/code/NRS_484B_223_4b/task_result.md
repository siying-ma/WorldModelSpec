# NRS_484B_223_4b — task result

**Final verdict: OK** (7 witnesses, 11 names, composes nothing). 4 of 6 gate runs used.

## Gate runs

1. **UNUSED_CLAIM** (every claimed name). I ran this one by mistake on the untouched skeleton, before writing anything; it cost a run and changed nothing. (I also attempted one malformed shell command, which the permission layer denied without running it.)
2. **WITNESS_FAIL**: `permit`. The adapter refused the trace because the heading was held fixed while the yaw rate was non-zero (the rate at a scene is held over the interval before it). Change: rebuilt every trace from a heading sequence in 4.5° steps (±90°/s at 50 ms), using a cos/sin table in millionths. Positions are integrated from the velocity of each scene. The `branch_1` lane change became a real left-then-right yaw manoeuvre.
3. **VACUOUS**: obligation leaf `st_turn_lane_side M right`. This is the obligation's copy of the "single" test. No witness had a lane that x occupied and that was not single. Change: added `branch_3` (compliant). The car leaves a single right turn lane, crosses the through lane into one of a pair of adjacent right turn lanes, and goes straight across the intersection from it.
4. **OK**.

## How the rule is written
- Class: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Selection of L (applicability, and written again in full in the obligation):
  - L is a `turn_lane` region with side `right`.
  - L lies on some `highway` region (`st_on_way`).
  - No `lane` region N is L's left or right neighbour (`st_lane_adjacency` with the side literal) while also being a `turn_lane` M of side right. M is tied to N by `same`.
  - x occupies L now or did earlier: `since tt (rel_occupies x L)`.
- Obligation, for every selected L and every `intersection` I that L enters (`st_lane_enters`), it is not the case that all of these hold:
  - x leaves I here: `rises (not (rel_occupies x I))`.
  - x's latest entry into I happened while it occupied L: `since (not (rises occ I)) (rises occ I ∧ occ L)`.
  - `drv_motion_heading_change_since_entry(x, I; p.heading_since_step_carla_scene_graph) > −p.turn_recognition_angle`.

## Choices the node left open
- **How "a right turn lane" is tested on a neighbour.** I quantified the neighbour as a `lane` (claimed `st.lane`) and read "is a right turn lane" through a second `turn_lane` quantifier bound to the same region. This lets a through neighbour, which has no turn-side field, decide "not a right turn lane" from its kind instead of coming out unknown. This only writes the record's selection; I declared no narrowing.
- **"Since that entry".** I read it as x's latest entry into I, which matches the concept restarting at each entry.

## Witnesses
- Six witnesses (`forbid`, `permit`, `idle`, `blind`, `branch_1`, `branch_2`) set a `window` from the second scene onward, because the exit and entry edges read the previous scene. `branch_3` sets one too (50 to 5500 ms).
- `blind` is the `forbid` trace with `kin.yaw_rate` masked.
- Added `branch_2` (not applicable): two adjacent right turn lanes, so neither is single.
- Added `branch_3` (compliant): described under gate run 3.

## Note on Core's "once"
`since tt φ` is never false: when φ has not yet held, it is unknown because of the unobserved past. A turn lane that x never occupied therefore leaves the applicability unknown unless another conjunct is false for it. In every witness that conjunct is decided false (no such lane, or a lane that is not single). A future witness with an unoccupied single right turn lane would be unknown, not not-applicable.

## Why I finished
The gate returned OK.
