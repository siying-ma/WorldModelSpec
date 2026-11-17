# NRS_484B_223_1b — task result

## Final verdict: OK (9 witnesses, 10 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` — run by mistake on the untouched skeletons (I meant to read a Core file). Nothing changed before it.
2. `UNUSED_CLAIM` — run by mistake again on the untouched skeletons. Nothing changed before it.
3. `OK` — after writing the rule and the 9 witnesses. No further runs.

The two wasted runs went against the "run only the gate" discipline. I also ran one stray `echo` once. Neither changed any file.

## How the rule is written
- **Class (s2):** `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
- **Applicability (s1 + s3 trigger):**
  - `ru_aggregate(subject, DEF-NRS-484A-285::traffic)`, and
  - ∃ lane l1, ∃ lane l2, for side left or right:
    - `rel_occupies(subject, l1)`
    - `st_lane_adjacency(l1, count) ≥ 2` (the literal 2, written as `Units.ratio 2 1`, unit `.count`)
    - `rel_occupies(subject, l2)`
    - `drv_lane_entering_adjacent_lane(subject, l1, l2, side)`
- **Obligation (s3 duty):** for every lane l1 and l2, and each side, the same selection implies `signals(side) ∧ ¬rises(signals(side))`.
  - `signals(side)` = `sig_turn_indicator(subject, side) ∨ sig_hand_signal(subject, side)`.
  - Not rising, with the signal on now, means the signal was also on at the previous observation. That is the record's own narrowing: "at the move and at the observation before it".
- **Safety standard (s5), conjoined:** ∀ other road user, either it is the subject (`same`), or it is not in contact (`¬rel_contact`) and it does not both reach its closest approach within `p.conflict_horizon` and come below `p.conflict_centre_clearance` at that approach.
  - The `same` guard is needed because Core's `rel_contact` counts a body as touching itself.

## Choices left open by the node
- **Traffic aggregate:** "lanes for traffic" (s1) is written as the subject being a member of the traffic aggregate. The node's s1 element claims the aggregate but does not say which road user it applies to. This is how the element is written, not a narrowing.
- **No narrowings of my own:** `narrowings := []`.

## Witnesses
- **Judged window:** each witness judges from its second instant on. The lane-change concept is unknown where there is no previous observation, so the first instant is excluded.
- **Added branches:**
  - `branch_2`: arm signal only, compliant.
  - `branch_3`: contact with a vehicle alongside, violated.
  - `branch_4`: move to the right with the right indicator, compliant.
  - `branch_5`: indicator comes on only at the move, violated.
- `blind` sets the indicator to left and masks `sig.turn_indicator`, so the masked atom is what decides.

## Why I finished
The gate returned `OK` on run 3 of 6.
