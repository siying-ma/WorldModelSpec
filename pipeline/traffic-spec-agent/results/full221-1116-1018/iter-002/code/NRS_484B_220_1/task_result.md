# NRS_484B_220_1 — task result

## Final verdict
**OK** (4 witnesses, 4 names, composes nothing).

## Gate runs
1. My first shell call was a mistake. I piped the gate command into `head -0` and added an
   `echo`, which is a different command from the one I was told to run. Its output was thrown
   away, so I don't know whether the harness counted it as a gate run. No files had been
   edited yet at that point.
2. `OK`: this run used the rule and witnesses as written below. I made no changes after it.

## How the rule is written
- **Class (s2):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s1):** `ru_aggregate subject "DEF-NRS-484A-285::traffic"` and
  `∃ r : one_way_roadway, rel_occupies subject r`.
- **Obligation (s3):** for every one-way roadway `r` with `rel_occupies subject r`, the
  following must not hold:
  `drv_motion_moving_against_carrier subject r [p.halt_speed_tolerance]`.
  This repeats the full s1 selection of the region.

## Choices the node left open
- **Where the traffic aggregate goes.** I put it in the applicability as a condition on the
  subject. Every class included in "vehicle" is also included in "traffic", so for any
  subject that passes the class check this conjunct is always true. The gate did not flag it
  as `VACUOUS`.
- **Narrowings.** I declared none. The node's own three narrowings already cover the
  readings, and the concept's contract handles motion across the roadway.

## Witnesses
All four scenes use roadway region 10, covering x 0–200 m and y 0–8 m, with its designated
direction east. The subject is a motor vehicle travelling at 8 m/s over 3 instants.

| Witness | Region kind | Subject's motion | Expected |
|---|---|---|---|
| forbid | one-way roadway | westward | violated |
| permit | one-way roadway | eastward | compliant |
| idle | two-way `roadway` | westward | not applicable |
| blind | one-way roadway, `st.lane_direction` masked | eastward | unknown |

## Why I finished
The gate returned `OK`.
