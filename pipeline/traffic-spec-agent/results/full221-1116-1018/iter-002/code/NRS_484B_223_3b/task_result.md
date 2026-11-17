# NRS_484B_223_3b — task result

**Final verdict: OK** (4 witnesses, 6 names, composes nothing)

## Gate runs (5 of 6 used)
1. UNUSED_CLAIM, on the untouched skeleton. I started this run by mistake before writing anything.
2. UNUSED_CLAIM, the same run repeated by mistake, again before any edit. Neither run tested my work.
3. WITNESS_FAIL: the adapter rejected the turning scenes because the headings were not rotated by the yaw rate. I changed the headings to rotate 17° per 1 s step (rational unit vectors to three decimals), and the post-turn heading stays at 85° with a yaw rate of 0.
4. WITNESS_FAIL: the path length grew less than the straight-line step during the turn, because of rounding (step ≈ 5.006 m against a 5 m increment). I set the path increment per turning step to 6 m.
5. OK.

## Rule as written
- Class (s3): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (s1, s5): `ru_aggregate subject "DEF-NRS-484A-285::traffic"` ∧ `drv_motion_left_turn subject (p.vehicle_turn_window, p.turn_heading_min, p.u_turn_heading_min, p.turn_yaw_rate_tol)` ∧ ∃ region `c` of kind `centre_turn_lane`: (the subject occupied `c` at some observation of the window behind, i.e. `not (holdsFor .time W (not occupies c))`) ∧ the subject does not occupy `c` now.
- Obligation (s4): ∀ `c` of kind `centre_turn_lane`: (the same selection) → `atLast .time W subject (occupies c) (distanceWhile subject (occupies c) ≤ Units.feet 200)`.

## Choices the node left open
- **Traffic (s1):** the claimed `ru.aggregate=DEF-NRS-484A-285::traffic` is written on the subject: the subject is part of the traffic the lane is provided for. This is a condition span, so it is carried as mapped and not declared as a narrowing.
- **Which lane:** the obligation restates the applicability's whole selection of `c` and reads the duty at every lane that meets it (forall … implies). For a single turn this is one lane.
- I declared no narrowings. The record's own narrowings, including the observable reading of s4, are not restated.

## Witnesses
All are sampled every 1 s, and each is judged from t = 10 s so the 10 s turn window is never truncated.
- **forbid:** violated. The subject runs 96 m in the lane (more than 200 ft = 60.96 m), then turns left 85° into a driveway. The turn is recognised at t = 17 s.
- **permit:** compliant. The subject runs 38 m in the lane, then turns left 85°. The turn is recognised at t = 12 s.
- **idle:** not applicable. The subject drives straight in a through lane with a yaw rate of 0.
- **blind:** unknown. This is the forbid trace with `kin.yaw_rate` masked, so the left turn is unknown.

## Why I finished
The gate returned OK.
