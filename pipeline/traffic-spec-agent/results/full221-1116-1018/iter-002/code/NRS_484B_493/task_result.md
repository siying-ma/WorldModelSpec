# NRS_484B_493 — task result

**Final verdict: OK** (8 witnesses, 18 names, composes nothing).

## Gate runs
1. `OK` on the first run. Nothing was changed after it.

(One stray shell call, `gate … --help`, was refused by the permission layer before it ran. It did not reach the gate and used up no gate run.)

## How the rule is written
- **e2 (class):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **e1 (notice):** there are two ways to get notice. Either some travel region the subject occupies is governed by a `regulatory_sign` with code `no_standing`/`no_parking` whose conditions hold for the subject (`prim_conditions_hold`), or the subject occupies a `curb_zone` of kind `no_parking`/`no_stopping`.
- **e5:** `asm.within_incorporated_city`.
- **e4 (left-hand side):** the subject occupies a `one_way_roadway` `ow` that lies on a `highway` `hw` (`st_on_way`). With dot = kin_heading · st_lane_direction(ow), some road edge `el` on `hw` must have dot × `prim_region_lateral_offset(subject, el)` > 0. Its `st_region_geometry_distance` must be strictly smaller than that of every road edge `er` on `hw` with dot × offset < 0. I wrote the record's "s times offset" as a product. That keeps the sign of s without a division.
- **e3 (obligation):** `¬ drv_motion_parked(subject; p.halt_speed_tolerance, p.standing_min_duration)`.

## Choices left open
- None that needed a narrowing, so `narrowings` is empty. "Nearer" is written as a strict `<`, which is how the record words it.

## Witnesses
- Setup: an eastbound one-way roadway (y 0…10) with a left edge (y 10…10.2) and a right edge (y −0.2…0), both on the highway. Two lanes are governed by a `no_parking` sign whose conditions were read and are empty.
- Timing: samples every 5 s from 0 to 165 s. The window is set to 65…165 s, so the 60 s look-back is always covered.
- `forbid`: stands 95 s at the left edge → violated.
- `permit`: halts 20 s, then drives on → compliant.
- `idle`: stands at the right edge → not applicable.
- `blind`: `dev.governs` is masked → unknown.
- `branch_1`: outside a city → not applicable.
- Extra witnesses:
  - `branch_2` (violated): no sign, but the vehicle stands inside a `no_parking` curb zone. This exercises the curb-zone limb.
  - `branch_3` (violated): the vehicle stands at the north edge facing west, against the roadway's direction. That edge is still on the left of the roadway's direction, so this exercises the sign of the dot product.
  - `branch_4` (not applicable): a pedestrian instead of a vehicle. This exercises the class.

## Why I finished
The gate returned `OK` on the first run.
