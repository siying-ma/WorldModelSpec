# LVMC_11_30_140_B_o1 — task result

**Final verdict: OK** (7 witnesses, 6 names, composes nothing). Three of the 6 budgeted gate runs were used.

## Rule
- Class: `(ru_aggregate subject "DEF-NRS-484A-165::pedestrian" ∧ ¬ru_pedestrian_with_white_cane_or_guide_animal subject) ∨ ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability: `existsUser blind_person` (it is not the subject, and it is of class `ru_pedestrian_with_white_cane_or_guide_animal`). For that person, either contact begins (`rises rel_contact`) or the subject approaches. Approaching means `rises (rel_centre_distance ≤ p.blind_person_approach_reach)` while the subject is not at rest (`¬drv_motion_complete_halt subject [p.halt_speed_tolerance]`).
- Obligation: `within .time p.immediate_stop_window "subject" (drv_motion_complete_halt subject [p.halt_speed_tolerance])`.
- No narrowings: every choice was fixed by the record's applicability and obligation.

## Gate runs
1. **WITNESS_FAIL**: `blind` came out violated rather than unknown. Masking `rel.centre_distance` in the manifest did not make the distance unknown. Core recomputes it from the two positions (`rel_centre_distance` falls back to `kin_position`). I removed the protected pedestrian's position from the `blind` scene and supplied `contact := some false`, a relation Core cannot compute without that position.
2. **WITNESS_FAIL**: the adapter rejected the `blind` trace because track 2 was in `occupancyObserved` without a footprint. I set `occupancyObserved := [1]`.
3. **OK**.

## Choices in the witnesses
- Every witness judges t = 1…9 s (`window`), because `rises` has no previous observation at t = 0.
- The vehicle approach crosses the 30 m reach between 35.9 m and 26.2 m.
- In `permit`, the car is at rest 3 s after the approach, inside the 4 s window. In `forbid`, it keeps 10 m/s.
- Added `branch_3` (not_applicable) so the "while not at rest" leaf of the approach is exercised: a car at rest, with a white-cane pedestrian walking to within reach of it.
- In `branch_2`, the centre distance is within reach from the start, so only the contact leaf begins inside the window.

## Observation for the harness
The planned `blind` mask on `rel.centre_distance` cannot leave the atom unknown on its own while both positions are observed, because Core computes it from them. A `blind` witness for this atom has to leave a position unobserved as well.

## Why I finished
The gate returned OK.
