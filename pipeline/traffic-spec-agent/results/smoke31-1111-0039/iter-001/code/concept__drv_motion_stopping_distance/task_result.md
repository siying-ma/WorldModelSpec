# drv.motion.stopping_distance — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom).

## Gate runs
1. **OK**: first run. The body and the witnesses were already written; nothing changed after it.

## Body
`v·reaction_time + (v·v) / (2·deceleration)`, where `v` is `Term.measure "kin_speed" [x]` and `2`
is the declared literal `Units.ratio 2 1` (`.ratio`). The divisor reads only the formal parameter
`deceleration` and the literal, never a measured atom, so `Term.div` is allowed. The value is unknown
wherever the speed is absent, and zero for a body at a standstill.

## Choices the record left open
None. The contract gives the formula exactly, so no narrowings were declared.

## Witnesses
- Instance: `reaction_time` = 1 s, `deceleration` = 5 m/s², bounds [19 m, 21 m].
- Every scenario has one car (track 1) driving east at a steady speed, sampled at three instants 1 s apart.
- `holds`: 10 m/s gives 10 + 100/10 = 20 m, which is inside the bounds, so the verdict is compliant.
- `fails`: 20 m/s gives 20 + 400/10 = 60 m, which is above 21 m, so the verdict is violated.
- `blind`: the same as `holds`, except that `kin.speed` is masked in the manifest and the scene's speed is `none`. The verdict is unknown.

## Why I finished
The gate returned OK on its first run.
