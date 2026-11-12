# drv.motion.left_turn — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom). Used 3 of 6 gate runs.

## Body

```lean
def headingChange : Term := .quantity "prim_heading_change" [aA] [pWindow]
def body : Formula :=
  .and (.cmp headingChange .ge pMinAngle) (.cmp headingChange .le pMaxAngle)
```

- The body checks the band at every observation: heading change ≥ `min_angle` and ≤ `max_angle`, with both ends included as the contract says.
- Its extent is the run of observations inside the band.
- Recognition ("first reaches the lower bound") is the start of that run.
- The onset falls inside the window because of how the primitive is built.
- The unknowns (window truncated at the start, missing yaw rate) come from `prim_heading_change` itself.
- The record left no choice open, so there are no narrowings.

## Witnesses

- **Instance:** window 4 s, `min_angle` 30°, `max_angle` 150°.
- **Trace:** one car (track 1) observed every 1 s at t = 0…8 s, judged over the window [4000, 8000] ms. Every window in that range is covered and adequately sampled.
- **holds:** yaw rate 20°/s, so every window changes heading by 80°, which is inside the band. Headings are rational unit vectors near 20°·k.
- **fails:** a lane change to the left with yaw rates 0, 0, 0, 4, 4, −4, −4, 0, 0 °/s. The window changes are 8°, 4°, 0°, −4°, −8°, all below 30°. Headings are east, ≈4°, ≈8°, ≈4°, then east again.
- **blind:** the holds trace with `kin.yaw_rate` masked, which makes it unknown with reason `absentAtom kin_yaw_rate`.

## Gate runs

1. **WITNESS_FAIL**: admission rejected the traces because `Build.sparseUser` gives no heading or extent, so the footprint was undefined. I switched to `Build.user` with a heading, a speed of 5 m/s and a car extent.
2. **WITNESS_FAIL**: admission rejected `fails` because its heading stayed constant while the yaw rate was non-zero. I gave the lane-change car headings that match the yaw rate held over each interval.
3. **OK.**

## Why I finished

The gate returned OK. The record was consistent: one claimed element, used, and no literals.
