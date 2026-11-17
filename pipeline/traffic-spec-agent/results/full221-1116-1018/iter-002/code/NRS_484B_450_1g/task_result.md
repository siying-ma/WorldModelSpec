# NRS_484B_450_1g — task result

**Final verdict: OK** (14 witnesses, 26 names, composes nothing)

## Gate runs
1. OK. This was the first run, so nothing changed after it.

## How the rule is written
- **Class (s1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s9, s10):** there is some `traffic_signal` d and some `travel_region` r that the subject occupies, and all of the following hold:
  - d governs r, or r enters (`st_lane_enters`) an `intersection` i that d governs;
  - the head is ahead of the subject: the dot product of `st_lane_direction(r)` with (head − position) is greater than 0;
  - the head is within 30 ft of the vehicle's front, written as 4·|head − position|² ≤ (30 ft + 30 ft + L)². L is `kin_extent "length"`, and both sides are built from sums. This is the record's "≤ 30 ft + L/2" with no literal other than the text's 30 ft;
  - there is some `road_edge` e with l = `prim_region_lateral_offset(subject, e)`, and the head's lateral offset (heading × (head − position), left positive) is ≥ l when l > 0, or ≤ l when l < 0.
- **Obligation (s2–s7):** `¬ complete_halt(subject, p.halt_speed_tolerance)`, or one of the exceptions holds:
  - **(a) s3/s4:** some road user o other than the subject, belonging to `DEF-NRS-484A-285::traffic`, with `rel_ahead_behind_in_lane o subject` and `rel_surface_gap(subject, o)` (the distance form) ≤ `p.queue_halt_gap`;
  - **s5/s6/s7:** some `travel_region` q that the subject occupies is governed by any of these: a stop sign; a yield sign; a traffic signal showing circular_red, red_arrow(left/right/straight/u_turn) or flashing_red; a railway signal or gate with lights flashing or gate lowering or down; or a human direction with role police_officer and indication stop.

## Choices the node left open
- **Exceptions (b) and (d) are written once, as their union.** The devices in (b) are a subset of those in (d), so a second copy would be a leaf that could never decide anything. This changes no verdict, so I did not record a narrowing.
- **`red_arrow` matches every direction (`red_arrow(dir)`).** The record says "a red_arrow" without naming a direction.
- **The surface gap is read as the distance between bodies.** I used the 2-argument form, as the contract says ("distance between the nearest points").
- **Half the length is handled by doubling, not dividing.** Doubling both sides keeps the formula free of any bare literal.
- **No narrowings were declared.**

## Extra witnesses (beyond the planned ones)
I added these so that every leaf of the formula is exercised:
- **branch_5:** a stop sign → compliant.
- **branch_6:** a yield sign → compliant.
- **branch_7:** railway lights flashing, gate up → compliant.
- **branch_8:** railway gate down, lights dark → compliant.
- **branch_9:** the signal governs only the intersection the lane enters → violated.
- **branch_10:** the head is beyond the left road edge → violated.

## Why I finished
The gate returned OK on the first run.
