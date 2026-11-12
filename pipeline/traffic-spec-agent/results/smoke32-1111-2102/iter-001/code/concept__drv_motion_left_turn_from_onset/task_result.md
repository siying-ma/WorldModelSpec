# drv.motion.left_turn_from_onset — task result

**Final verdict: OK** (3 witnesses, 3 names, reads 3 atoms).

## Body

```lean
.rises (.and turningLeft (.cmp (.headingSince "a" pStep turningLeft) .ge pTurnAngle))
-- turningLeft = .derived "drv_motion_turning_left" [a] [yaw_tolerance, speed_tolerance]
```

- When `turning_left` is true at an observation, it has held at every observation since it last
  became true. `headingSince` counts from that same rise, using the `step` formal directly as its
  step bound.
- The conjunction says "the stretch is under way and its heading change has reached the turn
  angle". Its rise is the first observation in the stretch where the heading change reaches the
  angle, which is the recognition observation, so the concept holds there only.
- Where the onset isn't observed (an onset before the recording, or one hidden by an unknown turning
  state) or a yaw rate is missing, `headingSince` is unknown, so the concept is unknown too.

## Gate runs

1. **WITNESS_FAIL**: in `holds` and `fails` the headings didn't match the yaw rates. The adapter
   holds each scene's rate over the interval before it, and my headings kept the previous value.
   - **Change:** I rebuilt each heading from the rate. `holds` yaws 3, 42 and 45 deg/s, giving
     about 3°, about 45°, then north: a quarter turn. `fails` yaws 10 deg/s left, then 10 deg/s
     right to straighten.
   - The headings are rational unit vectors within 0.02° of the target angles.
2. **OK**.

## Choices the record left open

- **No narrowing was declared.** Writing "first reaches" as the rise of (turning_left ∧ heading
  change ≥ turn angle) follows directly from the contract's words.
- **Witness figures:**
  - Parameters: turn angle 60°, yaw tolerance 2°/s, speed tolerance 0.1 m/s, step bound 2 s.
  - Timing: 7 observations 1 s apart.
  - `holds` and `blind` are judged only at the recognition observation (`window` = 4000–4000 ms),
    because the concept holds there only.

## Why I finished

The gate returned OK on the second run (2 of 6 used).
