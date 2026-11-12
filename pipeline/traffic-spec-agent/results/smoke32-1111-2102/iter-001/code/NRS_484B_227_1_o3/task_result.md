# NRS_484B_227_1_o3 — task result

## Final verdict
**OK** (`13 witnesses, 12 names, composes nothing`), on the first gate run.

## Gate runs
1. **OK**: the first full version of the rule and witnesses passed. Nothing changed after it.

(Before the gate, an extra `--help` invocation of the harness was tried by mistake. The permission layer denied it and it never ran. No other command was executed apart from one directory listing of Core.)

## How the rule is written
- **Class (d1):** `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
- **Act (d6), judged at recognition:** `rises drv_motion_left_turn(ego; p.turn_window, p.left_turn_min_angle, p.left_turn_max_angle)` ∨ `rises drv_motion_u_turn(ego; p.turn_window, p.u_turn_min_angle, p.u_turn_max_angle)`.
- **Occasion (boundary `window`, `p.turn_window`):** every `some_moment` span is written `¬ holdsFor time W ego ¬(U ∧ φ)`, as prescribed.
- **Under-way formula U:** at some observation in the turn window behind this one, `|kin_yaw_rate ego| ≥ p.turn_yaw_tolerance`.
- **d2:** some highway `h` on which a median or divider lies (`st_on_way md h`), and at some moment of the turn ego overlaps (`rel_occupies`) a roadway on `h` or a median or divider on `h`.
- **Obligation:** the applicability's full selection of `h` (divided, and occupied during the turn) is repeated inside the obligation's own `existsRegion highway h`. This keeps the record's choice among highways.
- **d7 and d8 in the obligation:** read together at one `some_moment`:
  - d7: overlap with a median or divider on `h` whose `st_median_or_divider_opening` is set;
  - d8: overlap with an intersection on `h`.

## Choices the node left open
- **U's onset bound is approximate.** The record bounds the turn's onset by the window behind the *recognition*. Inside the outer window the language cannot refer back to the recognition. So U looks for a yaw rate at or above tolerance in the window of the same length behind *each* observation of the outer window.
  - I did not use an unbounded past `since`, because Core makes it unknown before any yaw has been observed. That would make the d7, d8 and d2 "outside" cases unknown instead of decided.
  - The difference only matters when two separate yaw episodes fall within about two windows of each other.
  - This is not a span reading, so no narrowing was declared. It is recorded in the rule header.
- **"Semicircular turn"** is read by `drv.motion.u_turn`, as the record maps it. Each concept's rise is its own occasion, so a left U-turn is judged at both recognitions.
- **No narrowings were declared.** The record's own observable readings (agency, status) are not restated.

## Witnesses
The planned scenarios are all present. I added three of my own:
- **branch_2** (compliant): the turn is completed inside a wide median crossover and never touches a roadway. This shows the "median on h" limb of d2 deciding on its own.
- **branch_3** (violated): a U-turn that starts in a lot beside the highway.
  - Its left-turn phase is recognized off the highway, so that occasion is not applicable.
  - The U-turn is recognized after crossing the roadway and the solid median, and that recognition is what makes the scenario violated. So the `u_turn` leaf decides the outcome alone.

Every trace is 42 s at 1 s spacing, with 32 s of straight approach. Each witness is judged at t = 30…41 s, where every 15 s look-back window is covered.

## Why I finished
The gate returned OK.
