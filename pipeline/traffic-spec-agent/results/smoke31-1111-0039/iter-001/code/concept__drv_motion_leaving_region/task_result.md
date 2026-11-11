# drv.motion.leaving_region — task result

**Final verdict: OK** (gate run 1 of 6).

## Gate runs
1. `OK` — 3 witnesses, 1 name, reads 1 atom (`rel.occupies`). No changes after it.

## Body
`occ := rel_occupies x r`; `body := (rises (not occ)) or (rises tt)`.

- `rises (not occ)`: x is off r at this observation and on r at the one before. Because it is an edge, the later observations where x stays off r are not exits again. It is unknown when `occ` is unknown here or at the observation before. If x was not observed in the earlier scene, its occupancy there is unknown.
- `rises tt`: this is false at every observation that has one before it, so it changes nothing there. At the first observation of the trace it is unknown. Without it, `rises` would give a definite *false* at the first observation whenever x is on r, because of the three-valued conjunction. The contract says the result is "Unknown … where there is no observation of x before it", and this disjunct makes that hold. `tt` is not a leaf, so it adds no claimed name.

## Choices the record left open
None. There are no narrowings. The `rises tt` disjunct follows the contract's own rule for when the result is unknown; it is not a reading I chose.

## Witnesses
- Region 100 is a lane-kind rectangle from (0,−2) to (20,2).
- x (track 1) is a motor vehicle heading east at 10 m/s.
- There are three scenes, 1 s apart. Every scenario is judged at t1 = 1000 ms (`window := some (1000, 1000)`).
- holds: x is at (15,0) on r, then at (25,0) and (35,0), off r.
- fails: x is at (5,0), (10,0) and (15,0), on r throughout.
- blind: the holds geometry with `rel.occupies` masked.

## Why I finished
The gate returned OK on the first run.
