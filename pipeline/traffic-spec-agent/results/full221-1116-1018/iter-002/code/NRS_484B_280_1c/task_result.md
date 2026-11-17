# NRS_484B_280_1c — task result

**Final verdict: OK** (14 witnesses, 20 names, composes nothing).

## Gate runs
1. **WITNESS_FAIL**: five branch witnesses used regions with no outline and stated their occupancy, to separate "on" from "near". The adapter refuses these. A structure without a boundary is not allowed where occupancy is observed. I removed those witnesses. The point transit stop became a small rectangular shelter.
2. **VACUOUS**: the `rel_occupies` leaves for the highway, the transit stop and the crosswalk changed no decided witness. I added `branch_10` (compliant): the pedestrian stands where no highway, shelter or crosswalk is within reach. When a vacuity check negates one of those leaves, that witness's verdict changes.
3. **OK**.
4. **OK**, after I documented the rule file's header comment. The edit was comment-only.

## Rule
- Binder class: `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`.
- Applicability: `kin_speed(subject) > p.halt_speed_tolerance`. The record says the duty is read at every observation where the subject moves.
- Obligation: `forallUser p`. The antecedent is: p is not the subject ∧ p is a DEF-NRS-484A-165::pedestrian ∧ `rel_visible(subject, p)` ∧ p is at one of these places:
  - highway
  - transit stop
  - boarding a halted bus or transit vehicle with a door open
  - school or school-crossing zone travel region
  - crosswalk

  The consequent is: ¬`rel_contact(subject, p)` ∧ ¬(`prim_closest_approach_within` ∧ `prim_closest_approach_distance` < `p.conflict_centre_clearance`), both over `p.conflict_horizon`.
- "On/at/in" is written as `rel_occupies`. "Near" is written as `st_region_geometry_distance ≤ p.pedestrian_near_reach`.

## Choices the node left open
- The pedestrian conditions (z3–z11) go in the obligation's antecedent, not in the applicability. The record states the duty for every observed pedestrian, and the planned `branch_1` (no pedestrian) and `branch_2` (hidden pedestrian) expect **compliant**. A pedestrian-existence applicability would have made them not applicable.
- `sig_door_open` is read on any side. The record says "has a door open".
- A zone sign begins a zone when `dev_zone_sign_end` is false, as the record says.
- I declared no narrowings.

## Witnesses
These are the planned ones plus `branch_4`–`branch_10`:
- `branch_4`–`branch_7`: the pedestrian is near a highway, a transit shelter, a crosswalk, or a lane governed by a school zone sign. Each is the only place in its scene. All violated.
- `branch_8`: the lane is governed by a zone-end sign, and the beginning school zone is on a lane far away. Compliant.
- `branch_9`: the pedestrian is boarding a halted taxicab. A taxicab belongs to no bus aggregate and is not a transit bus. Compliant.
- `branch_10`: no place is within reach. Compliant.

## Observation for the plan
With the outlined regions the adapter requires, "on" (`rel_occupies`) never decides on its own. A body over a region always has a ground distance of zero, so "near" is already true. The occupancy leaves only do work through scenes where the pedestrian is at none of the places. This is not a defect, but "on" adds nothing to "near" under this reading.

## Why I finished
The gate returned OK.
