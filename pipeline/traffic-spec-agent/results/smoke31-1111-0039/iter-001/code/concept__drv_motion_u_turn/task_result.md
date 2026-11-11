# drv.motion.u_turn — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom)

## Gate runs
1. `OK` — first run, on the body and witnesses below. Nothing changed after it.

## Body
`|(|prim_heading_change(x, window)|) − 180 deg| ≤ reversal_tolerance`, judged at the observation
alone. The 180 deg is the record's declared literal, written `Units.degrees 180`. The primitive
integrates `kin.yaw_rate`, so forward and backing movements both count. It is unknown on a
truncated or sparsely sampled window and where a yaw rate is missing. A change past the half turn
by more than the tolerance fails.

## Choices the record left open
None, so there are no narrowings. The act's extent (it holds while the reversal stays inside the
back window) is what the windowed condition already does, so no time operator was added.

## Witnesses
- One motor vehicle, 20 observations at 1 s spacing. Instance: window 10 s, tolerance 10 deg.
- Each scenario is judged over t = 10–14 s, where the window is covered and contains the whole
  turning.
- **holds:** a left turn at 45 deg/s over 4 intervals, +180 deg.
- **fails:** a right turn at −45 deg/s over 2 intervals, −90 deg.
- **blind:** the holds motion with the yaw rate unset everywhere and `kin.yaw_rate` masked.

## Why I finished
The gate returned OK on the first run.
