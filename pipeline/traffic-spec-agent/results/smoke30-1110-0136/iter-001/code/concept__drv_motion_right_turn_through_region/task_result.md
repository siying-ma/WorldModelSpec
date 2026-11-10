# drv.motion.right_turn_through_region — task result

**Final verdict: OK** (3 witnesses, 3 names, reads 3 atoms). Gate runs used: 2 of 6.

## Body

```
and (rises (not (rel_occupies x i)))
    (and (cmp (headingSince "x" step (rel_occupies x i)) le (neg min_angle))
         (cmp (headingSince "x" step (rel_occupies x i)) gt (neg max_angle)))
```

- **Leaves the region:** `rises (not occupies)` is true when x does not overlap i at this observation but did at the one before. Because it is a `rises`, the concept holds only at the exit observation.
- **Heading change since entry:** `headingSince` with the formal `step` as its step bound, and its onset set to the overlap's last definite rise (the entry). If the recording does not show the entry, the change is unknown.
- **Band:** "at most minus `min_angle`" is written `≤ -min_angle`; "above minus `max_angle`" is written `> -max_angle`.

## Gate runs

1. **WITNESS_FAIL:** the adapter rejected all three traces. From t=3000 to t=4000 the path length grew by 8 m, but the straight-line distance between the two positions was about 9.05 m. I moved the exit position from (15, ∓15) to (15, ∓13); that chord is about 7.07 m and the point is still outside the region.
2. **OK.**

## Choices the record left open

- **Narrowings:** none. Each element maps directly onto an atom or operator the record names.
- **Witness figures** (the witness's own):
  - Parameters: `step` = 1 s, `min_angle` = 45°, `max_angle` = 180°.
  - Geometry: intersection 100 is the rectangle (0,-10)–(20,10). The car moves at 8 m/s with observations 1 s apart, five in all.
  - Entry is at t=1000 and exit at t=4000.
  - Yaw rate is 0 until the entry, then ∓30 deg/s.
  - Heading change at the exit: -90° in `holds`, +90° in `fails`. In `blind` the yaw rate is unobserved and `kin.yaw_rate` is masked.
- **Judging window:** every scenario is judged with `window = [4000, 4000]`. The concept can hold only at the exit observation, so the act's extent puts the judgement there.

## Why I finished

The gate returned OK.
