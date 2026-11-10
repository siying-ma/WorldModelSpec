# drv.motion.left_turn — task result

**Final verdict: OK** (gate run 1 of 6: "3 witnesses, 1 names, reads 1 atom(s)").

## Gate runs
1. OK. No changes were needed after this run.

## Body
`hc := Term.quantity "prim_heading_change" [x] [window]`;
body `hc ≥ min_angle ∧ hc < max_angle`. The contract says "by at least `min_angle`" (≥) and
"by less than `max_angle`" (<). Because the primitive measures over the back window, it already
covers recognition (the band is entered), onset (within the window), extent (holds while the
change stays in the band) and history (nothing before the window is read). Right turns, drift
below `min_angle` and reversals (≥ `max_angle`) all fall outside the band.

## Choices the record left open
None. The contract fixes both comparison operators and names the primitive and its window, so I
declared no narrowing.

## Witnesses
Instance: window 6 s, min_angle 60°, max_angle 150°. There is one car (track 1) at 5 m/s, observed
every 1 s over 14 scenes.
- holds: the car drives east, turns left at 22.5 °/s over t = 5–8 s (90°), then drives north.
  The judged window is 7–11 s, where the 6 s heading change is 67.5°–90°. Result: compliant.
- fails: the car drives straight east with a yaw rate of 0. The judged window is 6–13 s. Result:
  violated.
- blind: the holds trace and window, with `kin.yaw_rate` absent. Result: unknown, for the masked
  atom only.

Each scenario sets `window` because back windows before t = 6 s reach past the start of the trace.

## Why I finished
The gate returned OK on the first run.
