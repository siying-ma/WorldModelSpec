# drv.motion.left_turn_through_region — task result

**Final verdict: OK** (3 witnesses, 3 names, reads 3 atoms)

## Gate runs
1. **OK** — first run, on the body and witnesses as written below. Nothing changed after it.

## Body
`rises (¬ rel_occupies a r) ∧ headingSince a step (rises (rel_occupies a r)) ≥ turn_min ∧ headingSince a step (rises (rel_occupies a r)) < u_turn_min`

- entry = rise of `rel_occupies a r`; exit = rise of its negation (the act is recognised here, and the concept can hold only at this observation).
- The heading change is the signed `headingSince` (positive to the left), with `step` passed directly as the sampling bound. This means a turn to the right (negative) falls below `turn_min`.
- The band is `[turn_min, u_turn_min)`: inclusive at the bottom and exclusive at the top, as the contract states.

## Choices the record left open
- None in the body. Every part comes from the contract's own words, so there are no narrowings.
- Witness figures were left to me:
  - **Region:** an intersection square (0,0)–(20,20) m.
  - **Timing:** 1 s spacing.
  - **Turn:** yaw rate ±45°/s through a diagonal heading of (1,±1). The heading is never required to be a unit vector, and the lint for heading against yaw rate only checks scenes where the direction does not change.
  - **Velocity:** left unobserved at the diagonal scene, because no rational vector of the speed's length lies on the diagonal and no atom of the concept reads velocity.
  - **Instance:** step = 1 s, turn_min = 30°, u_turn_min = 150°.
  - **Window:** each scenario judges only the exit instant, t = 3000 ms.

## Why I finished
The gate returned OK on the first run.
