# NRS_484B_413_2 — task result

**Final verdict: OK** (8 witnesses, 8 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` (the harness skeleton, before any edit; listed drv_lane_heading_left/right_of_carrier,
   kin_path_length, rel_occupies). Then I wrote the rule and the witnesses.
2. `OK`.

## How the rule is written
- Class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability (s6): `definedWhen (∃ lane l, rel_occupies(subject,l)) (∃ lane l, rel_occupies(subject,l) ∧ (rises heading_left_of_carrier(subject,l) ∨ rises heading_right_of_carrier(subject,l)))`,
  with `p.course_departure_sin_tol` and `p.halt_speed_tolerance` as the concepts' parameters.
- Obligation (s1–s5): for every lane l, occupied with a rising left departure ⇒ left signal; the same
  for the right. "Signal to side" = `sig_turn_indicator(subject, side) ∨ sig_hand_signal(subject, side)`.
  The window is two branches: `asm ∧ holdsFor .path 100 ft` or `¬asm ∧ holdsFor .path 300 ft`.
  The obligation repeats the applicability's whole lane selection (rule 3c).
- s8: the node's residue, unchanged.

## Choices the node left open
None beyond the record's own reading, so `narrowings` is empty. Applying the duty to every occupied lane
on which a departure rises (the forall) follows the record's "the side of the departure, read on the
same lane l".

## Witnesses
There is one east-pointing lane. The subject moves at 10 m/s, sampled every 1 s with a path length
of 10·k m, and departs at k = 12 (heading (10, ±1), sine ≈ 0.0995 > 0.035). I added `branch_4`
(compliant, left hand signal with the indicator off) so the hand-signal leaf is exercised.

## Why I finished
The gate returned OK.
