# drv.motion.clockwise_about_region — task result

**Final verdict: OK** (gate run 1 of 6: "3 witnesses, 3 names, reads 3 atom(s)").

## Gate runs
1. `OK` — first run, on the body and witnesses as written below; nothing changed after it.

## Body
- offset = `kin_position(x)` − `st_region_geometry(r)` by component (`"x"`, `"y"`); velocity = `kin_velocity(x)` by component.
- c = offX·velY − offY·velX (the contract's cross product).
- Holds where `offX·velY < offY·velX` (c negative, written without a zero literal) **and**
  `c·c > tol·tol·(offX² + offY²)` (the contract's magnitude test, with no division).

## Choices the record left open
None: the contract states the formula exactly, so I declared no narrowing. The only decision about how to write it
was to express "c is negative" as a comparison of the two products, which means the same thing.

## Witnesses
Island region 100 (roundabout): a 20 m square around the origin with its reference point at (0, 0). Car 1 moves at 10 m/s
on a 20 m circle at (0,20), (20,0), (0,−20); tol = 1 m/s.
- holds: heading east/south/west (clockwise), c = −200 → compliant.
- fails: heading west/north/east (counterclockwise), c = +200 → violated.
- blind: same as holds, but the island is mapped without its reference point and `st.region_geometry` is absent → unknown.

## Why I finished
The gate returned `OK` on the first run.
