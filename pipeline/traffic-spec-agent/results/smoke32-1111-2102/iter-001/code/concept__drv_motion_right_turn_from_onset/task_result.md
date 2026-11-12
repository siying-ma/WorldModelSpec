# drv.motion.right_turn_from_onset — task result

**Final verdict: OK** (3 witnesses, 3 names, reads 3 atoms)

## Body

```
turning     := derived drv_motion_turning_right [a] [yaw_tolerance, speed_tolerance]
reached     := cmp (headingSince "a" step turning) le (neg turn_angle)
body        := and turning (rises reached)
```

- **Onset:** `headingSince` counts from the latest definite rise of `turning_right`. That rise must be observed, with `turning_right` known at every observation since. Otherwise the heading change is unknown, and so is the concept. This is the contract's history clause.
- **"Holding at every observation since it last became true":** this is expressed as `turning_right` true here together with a decided heading change. Once the last rise is observed and there is no unknown value after it, `turning_right` being true now means it was true at every observation since the rise. A false value in between would create a later rise, and that later rise would be the onset.
- **Recognition, "first reaches":** written as `rises reached`. Within a stretch the yaw rate is at or below −yaw_tolerance, so the heading change only decreases, and it starts at zero at the onset. That means the observation before a recognition belongs to the same stretch, and the rise marks the first observation at which the heading change reaches the angle. The concept holds there only.
- **Not read:** no turn indicator, intention or road geometry, so following a bend through the angle counts as a turn.

## Gate runs

1. **WITNESS_FAIL.** The trace lint rejected the traces because the heading stayed the same at the scene where a non-zero yaw rate first appeared. The rate at a scene applies to the interval before that scene. I changed the headings so they turn at every scene whose rate is not zero.
2. **OK.**

## Choices the record left open

- **Narrowings:** none. Leaving out a separate `since` for "holding since" is not a narrowing, because it is equivalent as argued above. It also avoids a truncation reason at the trace start that would otherwise make the blind witness unknown for a reason other than the masked atom.
- **Witness figures (all mine):**
  - Instance values: turn angle 60°, yaw tolerance 2 deg/s, speed tolerance 0.1 m/s, step 2 s. The instants are 1 s apart.
  - **holds:** yaw rate of −30 deg/s from t=1000 to t=4000, which is a quarter turn. The window is t=3000, where the heading change first reaches −60.
  - **fails:** a lane change at ±5 deg/s. The heading change is never below −5, so the concept is false at every instant.
  - **blind:** the `holds` trace with `kin.yaw_rate` masked, judged over t=1000…5000. The first instant is left out because `rises` there looks before the recording.

## Why I finished

The gate returned OK on the second run.
