# drv.motion.veering_right — task result

## Final verdict
**OK** (3 witnesses, 4 names, reads 3 atoms). Used 1 of 6 gate runs.

## Gate runs
1. `OK`: first run, on the body and witnesses described below. Nothing changed after it.

## Body
`moving ∧ forward ∧ right`, at one observation:
- **moving**: `.derived "drv_motion_moving" [x] [speed_floor]`
- **forward**: `d.x·v.x + d.y·v.y > 0`, where d = `st_lane_direction c` (Core reads it normalised) and v = `kin_velocity x`
- **right**: `d.x·v.y − d.y·v.x < −(sine_tolerance · kin_speed x)`. This is the cross product with left positive. It is compared with a product rather than a ratio, so nothing is divided by a measurement.

## Choices the record left open
- I made no narrowing. The record states every element exactly, including how the cross product is compared.
- **"Unknown where the carrier carries no designated direction."** This uses the ordinary three-valued conjunction. When the direction is missing, both `forward` and `right` are unknown, so the whole body is unknown whenever x is moving. If x is not moving, `moving` is false and the conjunction is false. This is the standard reading of a conjunction, and the record's `blind` scenario has x moving. If the contract meant "unknown even when x is not moving", that would need a `definedWhen` around the body. I did not add one, because no atom states "the direction is observed".

## Witnesses
- **Setup:** lane 100 points east. The instance uses speed_floor = 1 m/s and sine_tolerance = 1/10.
- **holds:** x faces east but moves with velocity (8, −6) m/s at 10 m/s. The cross product is −6, which is below −1.
- **fails:** x moves with velocity (10, 0). The cross product is 0.
- **blind:** same motion as `holds`, but the lane's `direction := none` and `st.lane_direction` is masked.

## Why I finished
The gate returned `OK` on the first run.
