# drv.motion.right_turn_from_onset — task result

## Final verdict
**OK** (3 witnesses, 3 names, reads 3 atoms).

## Gate runs
1. `OK`: first run. Nothing was changed after it.

## Body
`rises (turning_right(a; yaw_tolerance, speed_tolerance) ∧ headingSince(a, step, turning_right(a; …)) ≤ −turn_angle)`.

This mirrors the accepted `drv.motion.left_turn_from_onset`, with the opposite hand and the comparison flipped:
- **Onset:** the last definite rise of `turning_right`, which is where `headingSince` starts counting from zero.
- **Recognition:** the rise of the conjunction. If zero already reaches −turn_angle, recognition is at the onset itself, because the conjunction was false at the previous observation. Otherwise it is the first later observation of the same stretch.
- **Earlier stretches:** the change built up over an earlier stretch is dropped, because the next rise of `turning_right` restarts `headingSince`.
- **Unobserved onset or missing yaw rate:** the result is unknown.

## Choices the record left open
None. The contract's words fix the body. There are no narrowings.

## Witnesses
- **Instance:** turn angle 60°, yaw tolerance 2°/s, speed tolerance 0.1 m/s, step 2 s. Samples are 1 s apart.
- **holds:**
  - A first right-yaw stretch at instants 2–3 (−10 and −20°/s), then straight at instant 4.
  - A second stretch at instants 5–7 (−5, −40 and −50°/s): a quarter turn from the second onset.
  - The change since the second onset reads 0, −40 and −90°, so the turn is recognized at 7000 ms; the window is that instant.
  - Counted from the first onset, the change would already read −65° at 6000 ms, so the scenario separates the two stretches.
- **fails:** a lane-change drift, −10°/s at instant 2 and +10°/s at instant 3. The heading change never reaches −60°.
- **blind:** the `holds` trace with `kin.yaw_rate` masked, window at 7000 ms.

## Why I finished
The gate returned OK on the first run.
