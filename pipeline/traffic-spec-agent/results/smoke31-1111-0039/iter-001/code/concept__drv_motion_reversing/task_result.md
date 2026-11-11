# drv.motion.reversing — task result

## Final verdict
**OK** (`3 witnesses, 2 names, reads 2 atom(s)`), first gate run (1 of 6 used).

## Gate runs
1. **OK**: the first submission passed, so nothing was changed afterwards.

## Body
`vx·hx + vy·hy < −speed_floor`, where:
- `vx` and `vy` are `.measure "kin_velocity" [x, "x"/"y"]`
- `hx` and `hy` are `.measure "kin_heading" [x, "x"/"y"]`, which the evaluator normalises

This dot product is the velocity component along the body axis. `kin.gear` is not read.

## Choices the record left open
- **"Below" is a strict `<`**, as the words say. A rearward component exactly equal to speed_floor is not reversing, which matches the parameter's meaning ("at or below it counts as no backward motion").
- **No narrowing was declared.** The contract fixes the reading completely.

## Witnesses (speed_floor = 0.1 m/s, set with `Units.micrometresPerSecond 100000`)
- **holds:** a car faces north and rolls south at 1 m/s out of a parking bay, in a forward gear (gear +1). The component along its heading is −1 m/s.
- **fails:** a car faces east and drives east along a lane at 10 m/s, with the gear set to reverse (−1). The component is +10 m/s.
- **blind:** the same car as in holds, with `kin.heading` masked, so the result is unknown.

Headings are axis-aligned, so normalisation is exact.

## Why I finished
The gate returned OK.
