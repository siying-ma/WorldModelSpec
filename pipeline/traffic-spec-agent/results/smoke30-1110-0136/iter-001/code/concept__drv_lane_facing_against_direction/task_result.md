# drv.lane.facing_against_direction — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 2 atoms).

## Gate runs
1. `OK` — first run. Nothing changed after it.

## Body
The cosine is written as `kin_heading(x).x · st_lane_direction(c).x + kin_heading(x).y · st_lane_direction(c).y`.
Core reads both vectors normalised. The body is `cosine < -cos_tol`. If either vector is unobserved,
or if `c` has no designated direction, the comparison is unknown, as the contract requires.

## Choices left open
None. The contract fixes the dot product, the strict "below", and the bound `-cos_tol`, so no
narrowing is declared.

## Witnesses
- Region 100 is a one-way roadway, the rectangle [0,100]×[0,8] m, with designated direction east.
- Track 1 is a car at rest at (50, 4) m, so occupancy is not what decides the verdict.
- The instance sets `cos_tol` = 9/10.
- `holds`: the car heads west, so the cosine is −1 → compliant.
- `fails`: the car heads east, so the cosine is +1 → violated.
- `blind`: the same scene as `holds`, with `kin.heading` absent → unknown.

## Why I finished
The gate returned `OK` on the first run.
