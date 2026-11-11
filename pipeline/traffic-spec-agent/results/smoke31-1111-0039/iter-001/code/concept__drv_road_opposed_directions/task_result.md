# drv.road.opposed_directions — task result

**Final verdict: OK** (gate run 1 of 6)

## Gate runs
1. `OK`: 3 witnesses, 1 name, reads 1 atom. Nothing changed after this run.

## Body
`(dir(c1).x · dir(c2).x + dir(c1).y · dir(c2).y) < −opposed_cosine`. Each component is
`Term.measure "st_lane_direction" [c, .lit "x"|"y"]`. Core reads that measure normalised in the world
frame (`Geom.unit`). If either carrier has no direction, its components are unknown, so the
comparison is unknown, as the contract says.

## Choices the record left open
None. The contract fixes the dot product, the strict "below" comparison and the negated
parameter, so I declared no narrowings.

## Witnesses
- Instance: `opposed_cosine = 9/10` (`Units.ratio 9 10`).
- Scene: c1 (100) is a lane designated east. One stationary car is on c1.
- `holds`: c2 (101) is the lane beside c1, designated west. The dot product is −1 < −0.9, so the verdict is compliant.
- `fails`: c2 is a lane designated north that crosses c1. The dot product is 0, not < −0.9, so the verdict is violated.
- `blind`: c2 is a lane region with no lane record, so it has no direction. The manifest masks `st.lane_direction`, so the verdict is unknown.

## Why I finished
The gate returned `OK` on the first run.
