# drv.motion.complete_halt — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom).

## Gate runs
1. `OK` — first run. Nothing changed afterwards.

## Body
`.cmp (.measure "kin_speed" [a]) .le (.param "speed_tol")`: the sampled speed is at or below the
caller's tolerance at the observation. The comparison includes the tolerance itself, as the contract says ("at or below"). If the speed is unobserved, the result is unknown, not false.

## Choices left open
None. The contract fixes both the comparison and its direction, so `narrowings := []`.

## Witnesses
- Instance: `speed_tol` = 0.1 m/s (`Units.micrometresPerSecond 100000`).
- holds: three scenes with speeds 0, 0.1 m/s (exactly the tolerance) and 0. The concept holds at every scene.
- fails: the vehicle creeps east at 0.5 m/s, which is above the tolerance.
- blind: the same trace as holds, with `kin.speed` masked. The result is unknown.

## Why I finished
The gate returned `OK` on the first run.
