# drv.motion.circulating_clockwise_about — task result

**Final verdict: OK** (3 witnesses, 4 names, reads 4 atoms).

## Gate runs
1. `CHECK_FAIL` — `units: compares m^2·s^-1 with 1 (no unit)`. The sign test was `cross < 0` with a
   `.ratio` zero literal. Changed to `dx·vy < dy·vx` (the same condition, no literal).
2. `OK`.

## Body
- d = (px − rx, py − ry), with `kin_position a "x"/"y"` and `st_region_geometry r "x"/"y"` (the
  reference point).
- Clockwise sense: d × v = dx·vy − dy·vx < 0, with `kin_velocity a "x"/"y"`.
- Share across the line: (d × v)² > sin_tol² · (dx² + dy²) · speed², with `kin_speed a`, written as
  products so that nothing is divided by a measured quantity.
- speed > speed_tol.
- A road user at the reference point has d = 0, so the cross product is 0 and the strict
  inequality fails, as the contract says.

## Choices the record left open
None. The contract gives the formula exactly, so I declared no narrowing. The only change in how
the formula is written is the one above: the sign test as a comparison of two products instead of
a comparison with zero.

## Witnesses
- r = 100: a roundabout island, the square (−5,−5)–(5,5) m with reference point (0,0).
- a = 1: a motor vehicle moving at 10 m/s on a 15 m circle around the island.
- Instance: speed_tol = 1 m/s, sin_tol = 1/2.
- holds: the car goes clockwise (d × v = −150 at every scene).
- fails: the car goes counter-clockwise (d × v = +150).
- blind: the holds trace with `kin.velocity` and `kin.speed` masked.

## Why I finished
The gate returned OK on the second run.
