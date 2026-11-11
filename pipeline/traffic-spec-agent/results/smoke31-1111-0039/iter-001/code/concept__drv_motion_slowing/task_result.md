# drv.motion.slowing — task result

## Final verdict
**OK** (gate run 1 of 6): 3 witnesses, 3 names, reads 3 atom(s).

## Gate runs
1. `OK`. This was the first run, so nothing changed after it.

## Body
`(kin_velocity[x,"x"]·kin_heading[x,"x"] + kin_velocity[x,"y"]·kin_heading[x,"y"]) > speed_floor
 ∧ kin_accel_longitudinal[x] < −decel_floor`

The `kin_heading` measure reads the heading normalised, so the dot product is the velocity's
component along the heading. That is what the contract asks for, and it is what rules out backing.

## Choices the record left open
- No narrowing was needed. "exceeds" and "is below" are written as the strict `>` and `<`.
- Witness figures (the witness's own): speed_floor 0.1 m/s, decel_floor 0.1 m/s². Track 1 is a motor vehicle
  heading east at 8 m/s, observed at t = 0, 1, 2 s. Its acceleration is −2 m/s² in holds,
  0 in fails, and unobserved and masked in blind.

## Why I finished
The gate returned `OK` on the first run.
