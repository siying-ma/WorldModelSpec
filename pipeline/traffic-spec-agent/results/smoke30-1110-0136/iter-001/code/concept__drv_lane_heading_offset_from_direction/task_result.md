# drv.lane.heading_offset_from_direction — task result

## Final verdict
**OK** (3 witnesses, 2 names, reads 2 atom(s)).

## Gate runs
1. `OK` — the first run, on the body and witnesses below. No changes followed.

## Body
`st_lane_direction(c).x · kin_heading(x).y − st_lane_direction(c).y · kin_heading(x).x`.
Each vector atom is read by component (`.lit "x"` / `.lit "y"`). Core normalises both, as their
contracts say. This is the contract's cross product, written word for word. A carrier with no
designated direction leaves `st_lane_direction` absent, so the value is unknown.

## Choices the record left open
None. No narrowing was declared, because the contract gives the formula exactly.

## Witnesses
- Lane 100 is the rectangle [-50, 50] × [-2, 2] m with direction east. Vehicle 1 stands at the
  origin, at rest, at three instants one second apart.
- holds: the heading is (0.985, 0.174), about 10° to the left. The value is ≈ 0.174, inside the bounds [0.15, 0.2].
- fails: the heading is east. The value is 0, outside the bounds.
- blind: the holds scene with `st.lane_direction` masked, which gives unknown.

## Why I finished
The gate returned OK on the first run.
