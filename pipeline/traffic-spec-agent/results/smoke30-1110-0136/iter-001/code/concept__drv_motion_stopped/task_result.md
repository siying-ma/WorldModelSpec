# drv.motion.stopped — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom).

## Gate runs
1. `OK` — first run, on the body and the witnesses below. Nothing was changed after it.

## Body
`.cmp (.measure "kin_speed" [x]) .le (.param "tol")`. This is the record's one element: "the magnitude of its velocity (kin.speed) at or below `tol`", read at the single observation being judged.

## Choices the record left open
None. The contract names the atom (`kin.speed`), the comparison ("at or below", so `.le`) and the parameter (`tol`). It also rules out a window ("the concept reads the one observation"). No narrowing is declared.

## Witnesses
- Instance: `tol` is 0.2 m/s (`Units.micrometresPerSecond 200000`).
- Track 1 (x) is a motor vehicle at (0, 0) heading east, with no structures or devices. The trace has 3 instants, 1 s apart.
- **holds:** speed is 0.05 m/s, so the body is compliant.
- **fails:** speed is 2 m/s and x advances 2 m each second, so the body is violated.
- **blind:** this is the holds scene with `kin.speed` set to `none` and `kin.speed` left out of the manifest, so the result is unknown.

## Why I finished
The gate returned `OK` on the first run.
