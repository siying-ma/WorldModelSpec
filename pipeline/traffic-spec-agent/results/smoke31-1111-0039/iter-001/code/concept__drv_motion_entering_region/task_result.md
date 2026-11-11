# drv.motion.entering_region — task result

**Final verdict: OK**

## Gate runs
1. `OK` — 3 witnesses, 1 name, reads 1 atom. Nothing changed after it.

## Body
`.rises (.atom "rel_occupies" [x, r] [])`. Core's `rises φ` means φ holds at this observation and did not hold at the one before. That matches the contract exactly: the entry is a single observation, so a continuing overlap is not an entry. The result is unknown if either reading is unknown or if there is no earlier observation.

## Choices left open
None. The contract fixes the meaning of the element, so I declared no narrowings.

## Witnesses
- Region 100 is a lane, a rectangle with x from 10 to 20 m and y from -2 to 2 m. Road user 1 is a motor vehicle heading east, with half-extents 2 m × 1 m × 1 m.
- The trace has three observations, 1 s apart. Each scenario is judged at t1 only (`window := (1000, 1000)`).
- holds: x is at x=5 at t0, so its footprint is clear of the lane, and at x=15 from t1 on → compliant.
- fails: x is at x=15 at every observation, so the overlap continues → violated.
- blind: the same geometry as holds, with `rel.occupies` masked → unknown.

## Why I finished
The gate returned OK on the first run.
