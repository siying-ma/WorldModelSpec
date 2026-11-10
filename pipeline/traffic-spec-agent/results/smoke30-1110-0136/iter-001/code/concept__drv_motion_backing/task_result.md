# drv.motion.backing — task result

**Final verdict: OK** (1 of 6 gate runs used)

## Gate runs
1. `OK`: 3 witnesses, 2 names, reads 2 atoms. No changes after it.

## Body
`(vx·hx + vy·hy) < −tol`. This is the dot product of `kin_velocity` (components `"x"`, `"y"`) with
`kin_heading`, which Core reads as a normalised unit vector. So the left side is the signed
component of the velocity along the direction the body points. The comparison is strict (`.lt`)
because the contract says "below minus `tol`".

## Choices the record left open
None. I declared no narrowing. The contract's exclusions need no clause of their own:
- **Sideways slide or standing still:** the component along the heading is zero, which is not below `−tol`.
- **Gear:** the body doesn't read the gear.

## Witnesses
- **Instance:** `tol` = 0.1 m/s.
- **Scene:** one car, track 1, pointing east, at 0, 1 and 2 s.
- **holds:** velocity (−2, 0) m/s, reversing from x = 20 m to x = 16 m.
- **fails:** velocity (+5, 0) m/s, driving forwards.
- **blind:** the holds scene, with `kin.velocity` declared absent in the manifest.

## Why I finished
The gate returned `OK` on the first run.
