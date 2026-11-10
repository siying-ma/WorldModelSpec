# drv.motion.turning_left — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom). Gate runs used: 2 of 6.

## Body

```lean
def body : Formula := .cmp (.measure "kin_yaw_rate" [aX]) .gt pTol
```

"its yaw rate (kin.yaw_rate, positive to the left, counter-clockwise) exceeds `tol`": the strict `>`
matches the parameter's meaning (a yaw rate at or below `tol` reads as no turning to the left). The
yaw rate's sign alone decides the hand, and nothing about the gear or direction of travel is read, so
the concept holds whether x moves forwards or backwards. Where the yaw rate is unobserved, the result
is unknown.

## Gate runs

1. **WITNESS_FAIL**: the 3-scene traces kept a constant heading while the yaw rate was ±12 deg/s.
   The adapter rejects this because the rate is held over the interval before each scene, so the
   heading has to turn 12° per second. A 12° rotation can't be written exactly as a rational unit
   vector, so I made each witness trace a single observation. The concept reads only one
   observation, so one is enough.
2. **OK**.

(A `sed` command to make that edit was denied because the shell only runs the gate command. I used
the Edit tool instead.)

## Choices the record left open

None needing a narrowing. "Exceeds" is strict, as the meaning of `tol` states.
Witness figures: `tol` = 2 deg/s; track 1 is a motor vehicle at the origin heading north at
10 m/s. holds: +12 deg/s; fails: −12 deg/s; blind: +12 deg/s in the scene with `kin.yaw_rate`
masked by the manifest.

## Why I finished

The gate returned OK. The record matches the contract and needs no change.
