# NRS_484B_223_4a — task result

## Final verdict

`UNANCHORED_VARIABLE` (gate run 1 of 6). The node is wrong: it claims no atom that ties the
right turn's target region (intersection / driveway-or-alley entrance) to the subject or to the
turn lane. Session ended to report it.

## Gate runs

1. `UNANCHORED_VARIABLE` — "the quantified variable `r` shares no atom with a binder, nor with a
   variable that does". `r` is the target region of `int.right_turn`, bound by
   `existsRegion "intersection"` / `existsRegion "driveway_or_alley_entrance"` in the obligation.
   Its only tie to the subject is `intent "int.right_turn" subject r`, and the gate does not count a
   declared intention as an anchoring relation. Nothing changed after this run (see below).

## What was written

- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (s1): `∃ t : turn_lane. st_turn_lane_side t right ∧ rel_occupies subject t`.
- Obligation (s3/s4): `∀ t : turn_lane. (side right ∧ occupies) → (∃ r : intersection.
  intent int.right_turn subject r) ∨ (∃ r : driveway_or_alley_entrance. intent int.right_turn subject r)`.
  Here the whole selection of `t` is restated (rule 3c), and the intention is read at the judged observation.
- Witnesses: forbid, permit, idle, blind as planned. I also wrote `branch_1`, a left turn lane
  (not_applicable), and `branch_2`, which declares the turn at the driveway only (compliant). None
  were evaluated, because the gate stopped at anchoring.
- No narrowings were declared.

## Why the node is wrong (for the plan agent)

Span **s3** (and the s4 intention that reads it) needs a target region `r` of kind `st.intersection`
or `st.driveway_or_alley_entrance` that belongs to *this* turn lane. The element's justification
expects the intention itself to pick the region ("the declared intention of s4 takes one of them
as its target region"). The gate does not accept that, so without a tie the rule would accept a
declared right turn at any intersection or driveway in the scene.

The only anchoring atom the node claims is `rel.occupies`. Using it for the target region would
mean "the subject occupies the intersection/driveway". That is false while the vehicle is driven in
the turn lane before the turn, so it would change the duty. Something like `st_region_geometry_distance`
is not claimed either, and it would need a distance parameter the node does not have.

**Required change:** in the s3 element, claim an atom that relates the occupied turn lane `t` (or
the subject) to the target region:
- for the intersection: `st.lane_enters` (`st_lane_enters t r`, the intersection the turn lane is
  an approach to). The forbid narrative already speaks of "the intersection the lane enters".
- for the driveway or alley entrance: an atom of the surface that relates the lane to it, e.g.
  `st.lane_connectivity` (`st_lane_connectivity t r`, the lane leads to it), or
  `st.region_geometry` / `st_region_geometry_distance` with a declared reach parameter. The plan
  agent should pick the one the reading supports.

Alternatively, if the plan means a right turn at *any* such region the subject's plan names, the
record must state that and the gate's anchoring rule must allow it. As written, the gate refuses it.

## Choices left open

None beyond those listed above. The intention is read at the judged observation, never ahead, and
the two target kinds are joined by `or`, as the element states.

## Why I finished

The gate returned `UNANCHORED_VARIABLE`, and the node claims no atom that can anchor the target
region without changing the duty. Rule 3b says to report a node in that state rather than work
around it.
