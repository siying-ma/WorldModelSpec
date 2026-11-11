# drv.motion.veering_left — task result

**Final verdict: OK** (3 witnesses, 4 names, reads 3 atoms)

## Gate runs
1. `OK`. This was the first and only run, so nothing changed after it.

## Body
`drv_motion_moving x speed_floor ∧ (dX·vX + dY·vY > 0) ∧ (dX·vY − dY·vX > sine_tolerance · kin_speed x)`

- d = `st_lane_direction c` with the component selectors `"x"` and `"y"`. Core reads it normalised.
- v = `kin_velocity x` with the same component selectors.
- The cross product is written as a comparison with a product. Nothing is divided by a measurement, as the record says.

## Choices the record left open
- The comparison against zero has its literal zero tagged `.metrePerSecond`, which is the dimension of d·v.
- The scenarios use these figures:
  - speed_floor is 0.1 m/s and sine_tolerance is 1/10.
  - In `holds` the velocity is (9.6, 2.8) m/s at a speed of 10 m/s, so the sine is 0.28.
  - In `fails` the car drives east at 10 m/s, parallel to the lane's direction.
  - `blind` uses the car from `holds`, with lane 100's direction set to `none` and `st.lane_direction` marked absent.
- No narrowing is declared. The contract sets every comparison as strict, and it names every atom and parameter.

## Why I finished
The gate returned `OK` on the first run.
