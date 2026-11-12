# drv.motion.stopping_distance — task result

## Final verdict
**OK** (3 witnesses, 1 name, reads 1 atom).

## Gate runs
1. `OK` — first run, on the body and witnesses as written below. Nothing changed after it.

## Body
`kin_speed(a) · reaction_time + kin_speed(a)² / (2 · deceleration)`, written as
`.add (.mul speed pReactionTime) (.div (.mul speed speed) (.mul two pDeceleration))`.
- `speed` = `.measure "kin_speed" [aA]`, the record's only element.
- `two` = the declared literal 2 (count), written `.lit (Units.ratio 2 1) .count`. There is no
  `count` constructor in `Units`, so `ratio 2 1` is how the literal is written.
- The divisor is `2 · deceleration`, which uses only a parameter. It never reads a measured atom,
  as `Term.div` requires.

## Choices the record left open
None. The contract fixes every term of the formula, so there are no narrowings.

## Witnesses
Instance: reaction_time = 1 s, deceleration = 5 m/s², bounds [0 m, 30 m]. There is one motor
vehicle (track 1) heading east over three observations 1 s apart.
- holds: 10 m/s → 10 + 100/10 = 20 m, inside the bounds → compliant.
- fails: 30 m/s → 30 + 900/10 = 120 m, above 30 m → violated.
- blind: the same scene as holds, with `kin.speed` absent from the manifest → unknown.

## Why I finished
The gate returned `OK` on the first run.
