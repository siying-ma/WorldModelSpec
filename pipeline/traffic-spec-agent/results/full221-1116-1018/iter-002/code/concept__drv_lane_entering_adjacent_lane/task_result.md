# drv.lane.entering_adjacent_lane — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 2 atoms)

## Gate runs
1. **OK** — first run, on the body and witnesses as written below. No changes after it.

## Body
`st_lane_adjacency r1 s r2 ∧ (rel_occupies a r1 ∧ ¬ rises (rel_occupies a r1)) ∧ rises (rel_occupies a r2)`

- "r2 is r1's neighbour on side s": the Boolean `st_lane_adjacency [r1, s, r2]`, where the literal formal s goes in the side position.
- "overlaps both r1 and r2 at the observation, and at the previous observation it overlapped r1 and did not overlap r2": the formula language has no `previous` operator, so I wrote this with the edge `rises`:
  - `rises (occ r2)` means a overlaps r2 now and did not at the previous observation.
  - `occ r1 ∧ ¬rises (occ r1)` means a overlaps r1 now and also did at the previous observation.
  - The body reads only the previous observation, as the contract says.
- "holds at that observation only, and not again until…": this follows from the edge on r2.
- Unknowns:
  - `rises` at the first observation of a trace is truncated, so it is unknown there.
  - An unobserved occupancy or adjacency is unknown.
  - The conjunction is three-valued, so the concept is unknown wherever one of those unknowns decides the result.

## Choices the record left open
- None that needed a narrowing; `narrowings` is empty.
- One thing to be aware of, which follows from three-valued logic: at a trace's first observation, if a decidedly does not overlap r2, the concept is false rather than unknown. The missing previous observation can't change the result in that case. This is the same three-valued treatment the accepted example `u_turn_through_region` uses.
- Witnesses:
  - Two eastbound lanes, 4 m wide: r1 = 100 (y 0–4) and r2 = 101 (y 4–8). r2 is r1's left neighbour and r1 is r2's right neighbour, with ordinals and counts set. s = left.
  - a = track 1, heading east, half-extent 2×1×1 m.
  - Each scenario is judged only at t = 1000 ms, which has a previous observation at t = 0.
  - I gave occupancy explicitly from the footprints. At t = 1000 in `holds`, the centre is on the shared line, so the builder's centre-point default would not give the straddle.

## Why I finished
The gate returned OK on the first run.
