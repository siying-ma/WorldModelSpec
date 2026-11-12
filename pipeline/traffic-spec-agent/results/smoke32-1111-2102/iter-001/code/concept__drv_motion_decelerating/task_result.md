# drv.motion.decelerating — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 3 atoms)

## Gate runs
1. OK — first run: body and witnesses written as below; nothing changed after it.

## Body
`kin_accel_longitudinal a ≤ −decel_tolerance ∧ ¬ drv_motion_backing a [speed_tolerance]`

- "at or below" → non-strict `.le`, as the words say.
- "drv.motion.backing with the speed tolerance" → the speed tolerance fills backing's only
  parameter (`motion_tolerance`).
- Brake lamp and speed are not read, as the contract says.

## Choices the record left open
None. The contract fixes every comparison and how each parameter is passed on, so I declared no narrowings.

## Witnesses
Instance: decel_tolerance = 0.5 m/s², speed_tolerance = 0.1 m/s. Track 1 is a motor vehicle
pointing east, observed at 0, 1 and 2 s.
- holds: brakes at −2 m/s² from 20 m/s, moving east (not backing) → compliant.
- fails: constant 15 m/s with acceleration 0 and the brake lamp lit → violated.
- blind: the holds scene with kin.accel_longitudinal masked → unknown.

## Why I finished
The gate returned OK on the first run.
