# drv.motion.at_rest — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom)

## Gate runs
1. `OK` — first run. Nothing changed after it.

## Body
`.cmp (.measure "kin_speed" [a]) .le (.param "speed_tolerance")`: the road user's speed is at or
below the speed tolerance at the observation, and nothing else. It does not read the brake lamp,
the brake input or any place.

## Choices the record left open
None. The contract says "at or below", which maps directly to `.le`. No narrowings were declared.

## Witnesses
- Instance: speed_tolerance = 0.1 m/s (`Units.micrometresPerSecond 100000`).
- Every scene has one motor vehicle (track 1) at (0, 0), heading east, at 3 instants 1 s apart.
- holds: speed 0 m/s → compliant.
- fails: speed 10 m/s with the brake lamp lit → violated.
- blind: the `holds` trace with kin.speed masked by the manifest (`Build.masked`), and the scenario's
  manifest also declares kin.speed absent → unknown.

## Why I finished
The gate returned `OK` on the first run.
