# NRS_484B_250_1 — task result

**Final verdict: OK** (35 witnesses, 16 names, composes NRS_484B_250_4_o1, NRS_484B_250_4_o2)

## Gate runs

1. **UNUSED_CLAIM**: I ran the gate on the untouched skeleton to get a baseline. Every claim was reported unused, as expected.
2. **(unreported)**: I made a mistaken second call to the gate command, piped through `head -0`. It printed nothing, but it probably used up a run.
3. **WITNESS_FAIL**: the gate rejected branch_1, branch_7, branch_10 and branch_15 because a car's yaw rate was not matched by a heading change over the interval before that scene. I changed every turning scene to a 90 deg/s yaw with the heading turned a quarter turn, so the headings stay exact.
4. **VACUOUS**: the gate flagged these leaves as never moving a witness:
   - the device-exception leaves for the cases no witness reached: a signal governing an approach lane, and a stop sign or yield sign governing i itself;
   - every device-exception leaf in the obligation's re-selection;
   - the obligation's copies of the four left-turn limbs.

   Changes after this run:
   - **Formula:** `ca` (s8) and `cy` (s5) must now be no intersection (`¬ st_intersection`), replacing the earlier `¬ same cy i`. A carrier is never an intersection, and an intersection region records no entrance. Without the guard, a device governing a *different* intersection made `st_lane_enters ca i` unknown, and so made the whole selection unknown.
   - **Witnesses:** I added 16 (branch_16 … branch_31):
     - single-junction scenes with a signal on the approach lane, and a stop sign or yield sign on i itself (not applicable);
     - a two-junction plan:
       - a device governing the far junction directly, while the conflict at the uncontrolled junction violates the duty;
       - a device controlling the far junction where the conflict is, so no duty is owed there (compliant), for each device kind and each path (the junction itself, or its approach lane);
     - scenes where a counted vehicle keeps the rule applicable while a conflicting vehicle is excepted by exactly one left-turn limb (compliant).
5. **OK**

## Choices the node left open

- **s5 "has entered":** I wrote it as `occupies y i ∧ since (occupies y i) (occupies y cy)`, with `cy` a travel region where `st_lane_enters cy i` holds.
- **The carrier guards:** I described the `¬ st_intersection` guards on `cy` and `ca` above. They state nothing the record doesn't, since a carrier entering i at its entrance end is no intersection. I don't count them as a narrowing; s5 and s8 decide applicability and may not be narrowed. The header comment explains them.
- **s11 for y:** I wrote it as `drv_motion_turning_left y` alone. y's overlap with i is already required by its selection (s5). For x it is `turning_left x ∧ occupies x i`.
- **s9 "opposite directions":** a comparison of the dot product of the two carriers' `st_lane_direction` components against `−p.opposed_approach_cos_tolerance`, as the record states.
- **s8 device exception:** three device quantifiers (traffic signal, stop sign, yield sign). Each tests whether the device governs i directly, or governs a carrier entering i. The suspension through s7 is the conjunct `¬ ruleApplies o1 {x↦x} ∧ ¬ ruleApplies o2 {x↦x}`, as the `unless` composition requires.
- **Obligation:** for every selected i and c, the whole selection is repeated, including the device exception with its suspension and the left-turn exception. The duty is that no counted y is in conflict (s4's two primitives with the horizon and the clearance) wherever x overlaps i and is moving.
- **No narrowings of my own:** the record's narrowings (s1 and s8 observable readings, s3) are not restated.

## Notes

- For branch_4 (suspension through o2 alone), x stands with its front touching the stop line before it moves in. The gate accepted this against the run's `p.stop_point_tolerance`.

## Why I finished

The gate returned OK.
