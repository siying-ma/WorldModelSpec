# NRS_484B_363_1 — task result

**Final verdict: OK** (gate run 1 of 6: "14 witnesses, 12 names, composes nothing").

## Gate runs
1. OK — first submission; nothing changed after it.

## The rule
- Class: `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`.
- Applicability: there is a zone sign `z` and a travel region `r` such that `z` is of kind `school`, is not an end sign, governs `r`, and the subject occupies `r` (s3). For that same `z` and `r`, none of these exceptions holds:
  - (a) `¬asm.school_in_session_day`
  - (b) `asm.school_outside_operation_margin`
  - (c) some beacon governs `r` and is not inoperative, `asm.pupils_in_class` holds, and no beacon that governs `r` and is not inoperative is flashing
  - (d) no beacon governs `r` and is not inoperative, and `prim_conditions_hold z subject` is false
- Obligation: `kin_speed subject ≤ Units.mph 15`.

## Choices the node left open
None. The record states that the duty applies if it applies for any `z` and `r`, and that the "not flashing" condition is checked for every operational beacon, so neither needed a choice. I declared no narrowing of my own.

## Witnesses
The 8 planned scenarios are included. I added 6 more so that every leaf of the formula changes some decided verdict:
- **branch_5:** the half-hour margin assumption is true (N/A).
- **branch_6:** pupils are not in class (violated).
- **branch_7:** the beacon is inoperative and the time is outside the sign's posted window (N/A).
- **branch_8:** the beacon is inoperative and the time is inside the window (violated).
- **branch_9:** the sign is an end sign (N/A).
- **branch_10:** the zone sign is of kind `speed_zone` (N/A).

branch_2 uses an evening time, outside the sign's posted window. That way only the operational beacon stops exception (d) from applying.

## Why I finished
The gate returned OK on the first run.
