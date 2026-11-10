# NRS_484B_440_1_o2 — task result

## Final verdict

**OK** (gate run 1 of 6): 11 witnesses, 9 names, composes nothing.

## Gate runs

1. `OK`: the first run, after writing the rule and the witnesses in one pass. Nothing was changed afterwards.

## The rule

- **Class (e4):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability:**
  - **e1, e6:** x occupies a highway `h` and also occupies a roadway `rw` with `st_on_way(rw, h)`.
  - **e2:** not `asm.business_or_residence_district`.
  - **e8:** x is halted (`drv_motion_stopped x [p.motion_speed_tolerance]`).
  - **e11–e13:** the exception does not hold. The exception is `asm.vehicle_disabled ∧ ∃ roadway r occupied by x ∧ asm.disabled_vehicle_immovable`.
- **Obligation:**
  - **Same highway:** the obligation repeats the applicability's whole selection of the highway `h` (x on it and on a roadway lying on it). Both formulas use the one helper `onPavedPartOf`, so they refer to the same highway (rule 3c).
  - **The lane left free:** inside that selection, some lane `l` lies on `h` (`st_on_way(l, h)`) and is not occupied by x.
  - **Width (e9):** `st_lane_width(l) ≥ p.free_passage_width`.
  - **Nobody standing alongside:** for every road user `y`, it is not the case that `y` is halted, occupies `l`, and has `rel_longitudinal_overlap(x, y) ≥ 0`.

## Choices the node left open

- **Excluding x from "other road users":** I didn't use `same y x`. x never occupies the chosen lane, so x can never count as an obstruction, and an extra `same` leaf would only be redundant.
- **Quantifier over the highway:** the record says "a highway h", so I kept it as an existential in both formulas.
- **Narrowings:** none declared. The only reading of e8 (a whole lane, other halted road users only) is the record's own narrowing.

## Witnesses

The scene is a two-lane eastbound roadway (lanes 4 m wide) with a shoulder, on a highway. The car (track 1) is at (0, 2); where there is a truck, it is track 2. The longitudinal overlap is computed by Core from the geometry; no witness supplies it.

| Witness | Scene | Expected |
|---|---|---|
| forbid | truck halted alongside in lane 13 | violated |
| permit | truck halted 40 m ahead (overlap −33 m) | compliant |
| idle | car moving at 10 m/s | not applicable |
| blind | no lane widths, `st.lane_width` masked | unknown |
| branch_1 | car alone | compliant |
| branch_2 | single-lane roadway | violated |
| branch_3 | truck moving alongside | compliant (exercises the other user's `stopped`) |
| branch_4 | truck halted alongside on the shoulder | compliant (exercises `rel_occupies y l`) |
| branch_5 | other lane 2.5 m wide | violated (exercises the width bound) |
| branch_6 | as forbid, but disabled and immovable | not applicable (the exception) |
| branch_7 | as forbid, but in a business or residence district | not applicable |

## Why I finished

The gate returned `OK` on the first run.
