# drv.motion.backing — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 2 atoms)

## Gate runs
1. `OK`. This was the only run, so nothing changed after it.

## Body
`(kin_velocity a "x" · kin_heading a "x" + kin_velocity a "y" · kin_heading a "y") < −motion_tolerance`

This is the component of the world-frame velocity along the heading. Core reads the heading as a unit vector, and the body compares that component strictly with the negated formal parameter. `kin.gear` is not read, as the record says.

## Choices the record left open
- **Strict versus non-strict comparison:** the contract says "lying below", which means strict `<`. That follows directly from the words, so I declared no narrowing.
- **Witness figures** (the witness file's own):
  - Motion tolerance: 10 cm/s.
  - Vehicle: a motor vehicle pointing east, always in reverse gear (gear −1).
  - **holds:** rolls west at 2 m/s, so the component along the heading is −2 m/s.
  - **fails:** stands still in reverse gear, so the component is 0.
  - **blind:** the holds scene with `kin.velocity` masked by the manifest.

## Why I finished
The gate returned `OK` on the first run.
