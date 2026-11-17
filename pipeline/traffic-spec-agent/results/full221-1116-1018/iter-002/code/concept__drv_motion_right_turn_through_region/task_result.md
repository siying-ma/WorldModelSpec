# drv.motion.right_turn_through_region — task result

**Final verdict: OK** (3 witnesses, 3 names, reads 3 atoms)

## Gate runs
1. OK — the first run; nothing was changed after it.

## Body
`rises (¬ rel_occupies a r) ∧ headingSince a step (rises (rel_occupies a r)) > −u_turn_min ∧ headingSince a step (rises (rel_occupies a r)) ≤ −turn_min`
- Entry: `rises occ`. Exit, which is when the concept is recognised: `rises (not occ)`.
- The signed heading change since entry (left positive) is integrated from `kin.yaw_rate`, with the formal `step` passed directly as the sampling bound.
- The band is (−u_turn_min, −turn_min]: the lower end is exclusive and the upper end inclusive, as the contract says.

## Choices left open
None. The contract fixes each part of the body. No narrowings and no literals.

## Witnesses
- The instance uses step = 1 s, turn_min = 45° and u_turn_min = 150°.
- r is a roundabout, the rectangle (0,10)–(30,40). Each witness is judged only at the exit instant, 4000 ms.
- **holds:** a enters heading east. It then turns right at −30°/s through the scenes k2, k3 and k4 (the exit). Its headings are east, about −30°, about −60°, then south. The intermediate headings are rational unit vectors from the 33-56-65 triangle, since exact unit vectors at −30° and −60° are not rational. The integrated change is −90°, so the concept holds.
- **fails:** a passes straight through heading east with zero yaw rate. The change is 0°, so the concept does not hold.
- **blind:** the same trace as holds, with `kin.yaw_rate` masked, so the result is unknown.

## Why I finished
The gate returned OK on its first run.
