# NRS_484B_227_1_o3 — task result

**Final verdict: OK** (gate run 1 of 6: "11 witnesses, 11 names, composes nothing").

## Gate runs
1. `OK`. This was the first run, on the rule and witnesses as first written; nothing changed after it.

## The rule
- Class: `ru_aggregate(x, "DEF-NRS-484A-320::vehicle")`.
- s2 `onDivided`: there is a highway region `h` that `x` occupies, and a `median_or_divider` region `m` with `st_on_way(m, h)`.
- Applicability: `onDivided ∨ someMoment onDivided`. Here `someMoment φ = ¬ holdsFor .time p.turn_recognition_window x ¬(turning ∧ φ)`, where `turning = drv_motion_turning(x; p.yaw_rate_tolerance)` is the occasion's under-way element.
- Obligation: `(rises left_turn ∨ rises u_turn) → someMoment (throughOpening ∨ atIntersection)`.
  - `left_turn` takes (window, left_turn_min_angle, reversal_min_angle) and `u_turn` takes (window, reversal_min_angle, reversal_max_angle).
  - `throughOpening`: some median or divider `o` that `x` occupies, with `st_median_or_divider_opening(o)`. The s7 crossover is written as this same opening.
  - `atIntersection`: some intersection `i` that `x` occupies.

## Choices
- Each act is judged where it rises: `rises left ∨ rises u`, not `rises (left ∨ u)`. The record says "left_turn … or u_turn … rises". A left U-turn therefore gets judged twice, once when its left-turn band rises and again when its reversal rises. Both judgements read the same exception.
- I declared no narrowings of my own. All the record's narrowings are its own and were not restated.

## Witnesses
- The 10 planned scenarios have their planned verdicts.
- I added one: `branch_1` (violated), a right-hand U-turn mid-block. It is a reversal that never enters the left-turn band, so it is the only witness where the `u_turn` leaf alone decides the verdict. In `forbid`, the left-turn rise on its own already makes the case violated.
- Traces are sampled at 1 s and are 30 s long. The car drives straight for about the first 20 s, so the 15 s window is covered. Witness windows start at 16 s, or at 19 s for `occasion_s2_outside`, after the car has left the divided highway.
- Every trace ends before a U-turn's samples start dropping out of the window, so the left-turn band is not re-entered as the window decays.

## Why I finished
The gate returned OK on the first run.
