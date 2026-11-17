# drv.lane.heading_left_of_carrier — task result

**Final verdict: OK** (3 witnesses, 3 names, reads 3 atoms)

## Gate runs
1. `OK` — first run. The body and witnesses below were written before it; nothing changed after.

## Body
The concept is the conjunction of three conditions, all at one observation:
- `d_x·h_x + d_y·h_y > 0` (the dot product of r's direction and a's heading is positive),
- `d_x·h_y − d_y·h_x > sin_tol` (the cross product is above `sin_tol`),
- `kin_speed a > speed_tol`.

h is read with `kin_heading a x/y` and d with `st_lane_direction r x/y`. Core normalises both. The only literal is zero, written `.lit Q.zero .ratio`.

## Witnesses
- Lane 100 points east. a is track 1, a motor vehicle at (50, 0) moving at 10 m/s.
- The instance sets `sin_tol` = 1/20 and `speed_tol` = 1 m/s.
- **holds:** a's heading is (0.9848, 0.1736), about 10° counter-clockwise from the lane's direction.
- **fails:** a's heading is (0.9848, −0.1736), about 10° clockwise.
- **blind:** the same scene as holds, with `kin.heading` masked.

## Choices the record left open
None. Every step is the contract's own words, so there are no narrowings.

## Why I finished
The gate returned OK on the first run.
