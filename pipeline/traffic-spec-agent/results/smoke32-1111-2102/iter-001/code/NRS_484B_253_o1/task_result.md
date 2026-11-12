# NRS_484B_253_o1 — task result

**Final verdict: OK** (7 witnesses, 11 names, composes nothing)

## Gate runs
0. A stray invocation, `python -m harness gate … | head -0; true`, came from a mistakenly
   compound command early in the session. Its output was discarded, so whether it charged a gate
   run is unknown. A second stray command (`echo noop`) was not the gate. Both broke the
   one-command rule, and I'm reporting them here.
1. **WITNESS_FAIL**: `blind` was unknown for `absent_atom:st_lane_enters` as well as for the
   masked atom. The intersection region is itself a `travel_region` candidate for the approach
   carrier, and `st_lane_enters` is undecided on a region with no lane record. Fix: the approach
   carrier is required to be a region other than `i` (`.not (.same r i)`). A carrier that enters
   `i` cannot be `i` itself, so this restates what the words already imply rather than narrowing
   them.
2. **OK**.

## How the node is written
- f1: `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
- f2/f3 (applicability): there exists an intersection `i` that ego occupies and at which ego
  declares `int.left_turn` at the judged observation. The obligation re-selects `i` with the same
  two relations, over every such `i`.
- f6: for every road user `b` of the aggregate with `b` ≠ ego, the approach carrier `rb` is a
  `travel_region` other than `i` such that `st_lane_enters rb i` and
  `since (occupies b i) (occupies b rb)` hold. That covers both "occupies now" and "entered `i`
  from it". Ego's carrier `re` uses the same form. The two `st_lane_direction` vectors have a dot
  product below `-p.opposite_direction_tolerance`.
- f7/f8: `b` occupies `i`, or `b` occupies `rb` with `st_region_geometry_distance(b, i) ≤
  kin_speed(b) · p.immediate_hazard_time`. This is the product form, since no division by a
  measured quantity is allowed. The hazard is stated on the same `rb` as the opposite-direction
  test, so "its approach carrier" refers to one carrier.
- f4/f5: `drv_motion_at_rest(ego)`, or not both `prim_closest_approach_within(ego, b)` and
  `prim_closest_approach_distance(ego, b) < p.conflict_clearance`, with the same
  `p.conflict_horizon` for both.

## Choices left open
- I declared no narrowing. Two points the record leaves implicit:
  - The approach carrier is a region other than `i`.
  - "the carrier from which ego entered `i`" is written with `since`, so a trace that begins with
    ego already inside `i` gives unknown, never a guessed carrier.
- I added witness `branch_3` (violated): `b` is already within the intersection while ego
  crosses its path. It exercises the f7 leaf, "which is within the intersection", which no
  planned scene decides on its own.

## Why I finished
The gate returned OK.
