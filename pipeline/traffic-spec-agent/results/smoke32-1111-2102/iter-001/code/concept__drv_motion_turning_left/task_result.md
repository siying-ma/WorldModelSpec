# drv.motion.turning_left — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 2 atoms)

## Body

```lean
.and
  (.not (.derived "drv_motion_at_rest" [aA] [pSpeedTolerance]))
  (.cmp (.measure "kin_yaw_rate" [aA]) .ge pYawTolerance)
```

Road user `a` is not at rest (`drv.motion.at_rest` with the speed tolerance) and its yaw rate is at or
above the yaw tolerance, at the observation judged. There are no time operators, no curvature, no
turn indicator and no intention.

## Gate runs

1. **WITNESS_FAIL**: the adapter rejected `holds` and `fails`. The car kept a constant heading
   (east) while its yaw rate (10 deg/s and 0.1 deg/s) was nonzero. The gate requires the heading to
   follow the yaw rate held over each interval.
   - **Change:** in `holds` the yaw rate is now 90 deg/s and the heading turns east → north → west
     at 1 s spacing; these are exact rational unit vectors. In `fails` the car now drives straight
     east with yaw rate 0 deg/s.
2. **OK.**

## Choices the record left open

- **Narrowings:** none. The body is the contract's two measured conditions as written.
- **Witness figures:**
  - Yaw tolerance 2 deg/s; speed tolerance 0.1 m/s; car speed 10 m/s.
  - `holds`: 90 deg/s, so that the headings stay exact unit vectors.
  - `fails`: 0 deg/s. This is "near zero" at its extreme, because a nonzero rate would require a
    heading that is not a rational unit vector.
  - `blind`: `holds` with `kin.yaw_rate` masked.

## Why I finished

The gate returned OK on the second run.
