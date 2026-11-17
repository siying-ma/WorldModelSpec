# drv.motion.left_turn — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 1 atom).

## Gate runs
1. `OK` — first run, on the body and witnesses below. No further changes.

## Body
`rises (turn_min ≤ Δψ ∧ Δψ < u_turn_min ∧ |kin_yaw_rate a| ≤ yaw_tol)`, with
`Δψ = Term.quantity "prim_heading_change" [a] [window]`.
- Band: signed, left positive. Turn_min is inclusive and u_turn_min exclusive, so a right turn and a reversal both fall outside it.
- Stopped turning: the magnitude of the yaw rate is at most yaw_tol.
- The concept holds only at the observation where the condition first holds, and holds again only after the condition has ceased and come back. `rises` expresses this.
- Unknowns come from the primitive and the atom: a truncated window or a missing yaw rate.

## Choices the record left open
None needed a narrowing. Every part of the body is the contract's own words, and `narrowings` is empty.

## Witnesses
- Instance: window 10 s, turn_min 45°, u_turn_min 150°, yaw_tol 1 °/s. Bicycle track 1, 30 scenes at 1 s spacing.
- **holds:** the bicycle rides east, turns at 15 °/s for 6 s to the north, then rides on with yaw 0. Judged at 21000 ms, where Δψ = 90° and the yaw rate is 0, while the yaw rate at 20000 ms was 15 °/s.
- **fails:** a lane change: +5 °/s for 2 s, then −5 °/s for 2 s. Δψ stays at or below 10° in every covered window. Judged at 10000–29000 ms.
- **blind:** the holds trace with `kin.yaw_rate` masked, judged at 21000 ms.
- Headings are direction vectors rounded to the nearest thousandth of (cos θ, sin θ). The exact angles are irrational except at multiples of 90°. The trace lint accepts any non-zero vector length, and only checks that a heading which keeps its direction has zero yaw rate between the two scenes.

## Why I finished
The gate returned `OK` on the first run.
