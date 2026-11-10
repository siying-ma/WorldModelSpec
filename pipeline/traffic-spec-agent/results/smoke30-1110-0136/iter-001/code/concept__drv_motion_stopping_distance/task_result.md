# drv.motion.stopping_distance — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom).

## Gate runs
1. `OK` — first run, on the body and witnesses below; nothing changed after it.

## Body
`kin_speed x * reaction_time + (kin_speed x * kin_speed x) / (2 * decel)`

- The record's declared literal 2 (count) is written `.lit (Units.ratio 2 1) .count`. `Units` has no
  count constructor, so I used `ratio`.
- The divisor is `2 * decel`. It reads no measured atom, as `Term.div` requires, and the record says
  `decel` is strictly positive.
- The value is 0 for a road user standing still, and unknown where `kin.speed` is unobserved.

## Witnesses
- The instance sets `reaction_time` to 1 s and `decel` to 5 m/s², with bounds of [19 m, 21 m].
- **holds:** a motor vehicle heading north at a steady 10 m/s over 3 observations, 1 s apart. The value is 10 + 100/10 = 20 m.
- **fails:** the same vehicle at 20 m/s. The value is 20 + 400/10 = 60 m, so the bounds are wholly below it.
- **blind:** the same scene as holds, with `kin.speed` masked.

## Choices the record left open
None. The contract gives the formula exactly, so I declared no narrowing.

## Why I finished
The gate returned `OK` on the first run.
