# drv.motion.turning_right — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 2 atoms)

## Body

```lean
.and
  (.not (.derived "drv_motion_at_rest" [aA] [pSpeedTolerance]))
  (.cmp (.measure "kin_yaw_rate" [aA]) .le (.neg pYawTolerance))
```

The body is the contract's two elements, checked at the observation being judged: the road user is not at rest (the
negation of `drv.motion.at_rest` with the speed tolerance), and its yaw rate is at or below
−yaw_tolerance. It reads no turn indicator, no intention and no road geometry.

## Gate runs

1. **WITNESS_FAIL**: the trace lint rejected `holds` and `fails`. The car kept a constant east
   heading while its nonzero yaw rate implied a turn. Changed: each scene's heading is now a
   rational unit vector that turns between instants the way the yaw rate says. `holds` goes east →
   (12/13, −5/13) → (3/5, −4/5) under −25 deg/s. `fails` goes east → ≈0.5° → ≈1° left under
   0.5 deg/s, with vectors from Pythagorean triples. The body was not changed.
2. **OK**.

## Choices the record left open

- No narrowings: the contract's words fix the body exactly.
- Witness figures (the witness's own): yaw tolerance 2 deg/s, speed tolerance 0.1 m/s, a car at
  8 m/s.
  - **holds**: yaw rate −25 deg/s, inside an intersection rectangle.
  - **fails**: yaw rate 0.5 deg/s ("near zero"), on a straight roadway rectangle.
  - **blind**: the `holds` trace with `kin.yaw_rate` masked.

## Why I finished

The gate returned OK on the second run.
