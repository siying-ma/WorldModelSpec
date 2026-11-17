# NRS_484B_627_2 — task result

**Final verdict: OK** (16 witnesses, 21 names, composes nothing)

## Gate runs
1. `BUILD_FAIL` — witness: `busAhead` passed only an x coordinate as the position (missing the y component). Fixed the tuple.
2. `WITNESS_FAIL` — `blind` got violated: masking `rel.ahead_behind_in_lane` only drops a *measured* relation, and Core still computed it from occupancy and kinematics. Fixed the blind scene: only the subject's occupancy is observed, so the follower's lane is unknown. The relation cannot be computed, and its unknown is tagged with the masked atom.
3. `OK`.

(One stray no-op shell call, `echo skip`, was made before the first gate run. It was not a gate run and changed nothing.)

## How the rule is written
- Class (x1): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (x3): the subject occupies (`rel_occupies`) some region of kind `roadway`.
- Obligation: `(halt ∧ trafficHeldBehind) → (haltBehindTraffic ∨ predictedConflict ∨ haltRequiredByControl)`.
  - x2: `drv_motion_complete_halt subject p.halt_speed_tolerance`.
  - x4/x5: there is some user f other than the subject, in `DEF-NRS-484A-285::traffic`, with `rel_ahead_behind_in_lane(subject, f)`, `rel_surface_gap(subject, f)` ≤ `p.rear_signal_reach`, and f either halted (`complete_halt`) or with `kin_accel_longitudinal` ≤ −`p.speed_decrease_decel_min`.
  - x6/x7: either there is a user a with `rel_ahead_behind_in_lane(a, subject)` and gap ≤ `p.queue_halt_gap`, or there is a user c with `prim_closest_approach_within` and `prim_closest_approach_distance` ≤ `p.conflict_centre_clearance`, both over `p.conflict_horizon`.
  - x8: a `travel_region` g that the subject occupies is governed (`dev_governs`) by one of:
    - a stop sign;
    - a yield sign;
    - a traffic signal showing circular_red, flashing_red or red_arrow (any direction);
    - a human_direction device with indication stop and one of the four roles;
    - a railway signal or gate with lights flashing, or a gate that is lowering, down or raising.

## Choices left open
- **Where the exceptions sit:** x7 and x8 are in the obligation, so they make the halt compliant rather than not applicable. This follows the record's obligation text ("except where …") and the planned verdict for branch_1 (compliant).
- **Gate component:** `rel_surface_gap` is read as its distance (the two-argument form), because the record says "body gap" / "gap between bodies".
- **"A gate not up":** read as gate ∈ {lowering, down, raising}. `GateState.none` means there is no gate, so it is not read as a gate that is not up. This is the words' own meaning, not a narrowing.
- **Narrowings:** none declared.

## Witnesses added beyond the plan
- branch_3: yield sign (compliant).
- branch_4: red signal (compliant).
- branch_5: police officer signalling stop (compliant).
- branch_6: rail lights flashing (compliant).
- branch_7: rail gate down (compliant).
- branch_8: pedestrian conflict at 2 m (compliant).
- branch_9: pedestrian passing at 5 m (violated).
- branch_10: follower decelerating at −2 m/s² (violated).
- branch_11: follower 40 m behind (compliant).
- branch_12: bus 10 m ahead (violated).

## Why I finished
The gate returned OK on the third run.
