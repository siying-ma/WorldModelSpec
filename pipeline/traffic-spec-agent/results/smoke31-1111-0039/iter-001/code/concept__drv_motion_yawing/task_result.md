# drv.motion.yawing — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom). 2 of 6 gate runs used.

## Body

`|kin_yaw_rate x| > yaw_floor`, written as
`.cmp (.abs (.measure "kin_yaw_rate" [aX])) .gt pYawFloor`.

## Gate runs

1. **WITNESS_FAIL**: in `holds`, the car's heading stayed the same (east) while its yaw rate was
   -15 deg/s. The adapter integrates the yaw rate over each interval, so this trace could not
   happen. The scene was wrong, not the body.
   *Fix:* the `holds` (and `blind`) car now turns its nose east → south → west at -90 deg/s over
   1 s intervals. Those headings are exact unit vectors and match the yaw rate. The car backs at
   1 m/s, in reverse gear, with velocity opposite its heading.
2. **OK**.

## Choices the record left open

None needed a narrowing:
- "either hand counts" → `Term.abs`.
- "exceeds" plus the parameter's meaning ("at or below it counts as no heading change") → strict `.gt`.
- An unobserved yaw rate leaves the comparison unknown, which is the `blind` result.

Witness figures (my own): `yaw_floor` = 1 deg/s. In `holds` the yaw rate is -90 deg/s (a
right-hand swing, which also tests the absolute value). In `fails` the car drives east at 10 m/s
along a straight lane with a yaw rate of 0. In `blind` the backing car's yaw rate is unset and
`kin.yaw_rate` is masked.

## Why I finished

The gate returned OK. The record is consistent: its one element maps to `kin.yaw_rate`, and the
body uses only that atom and the formal parameter.
