# drv.motion.clockwise_about_region — task result

**Final verdict: OK** (3 witnesses, 5 names, reads 4 atoms). Gate runs used: 2 of 6.

## Gate runs
1. `CHECK_FAIL`: "units: compares m^2·s^-1 with 1 (no unit)". The test "cross product < 0" compared
   against a zero literal tagged `.ratio`, and no unit tag fits m²/s. Fix: wrote it as
   `dx·vy < dy·vx`, which means the same thing and needs no literal.
2. `OK`.

## Body
- `drv_motion_moving x speed_floor` (the call the record names).
- d = kin_position(x) − st_region_geometry(r), taken by "x"/"y" component. This uses the region's
  reference point; its boundary and distance are not read.
- c = dx·vy − dy·vx, with v = kin_velocity(x).
- c < 0, written as dx·vy < dy·vx.
- c·c > sine_tolerance² · (dx² + dy²) · kin_speed(x)². This is the contract's "compared as
  squares".

## Choices the record left open
- Both comparisons are strict, following "negative" and "larger".
- No narrowings: the contract fixes the reading. The body does not read whether x occupies r; the
  contract leaves that to the caller.

## Witnesses
- Roundabout 100: an octagon of radius 30 m around the reference point (0, 0).
- Car 1 drives at 8 m/s on a 20 m radius, sampled 3 times 2 s apart.
- Instance: speed_floor = 0.1 m/s, sine_tolerance = 1/10.
- **holds**: tangential and clockwise; c = −160 at each instant.
- **fails**: tangential and counter-clockwise; c = +160.
- **blind**: same scene as holds, with kin.velocity masked.

## Why I finished
The gate returned OK on both files.
