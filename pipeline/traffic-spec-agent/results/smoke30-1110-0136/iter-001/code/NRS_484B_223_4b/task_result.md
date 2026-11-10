# NRS_484B_223_4b — task result

**Final verdict: OK** (7 witnesses, 10 names, composes nothing)

## Gate runs
1. `OK`: first run, nothing changed afterwards.

## How the node is written
- **s2 (class):** `ru_aggregate(x, "DEF-NRS-484A-320::vehicle")`.
- **s1 (applicability):** there is a highway `h` with `rel_occupies(x, h)`, and on it a `turn_lane` `l` with:
  - `st_turn_lane_side(l, right)`;
  - `st_on_way(l, h)`;
  - `st_lane_adjacency` ordinal = count, so `l` is the rightmost lane;
  - no `turn_lane` `m` with `st_lane_adjacency(l, left, m)` and `st_turn_lane_side(m, right)`.
- **s3 (obligation):** it repeats the whole s1 selection of `l` (the highway `x` occupies included), then requires: not (some intersection `i` with all of the following):
  - `st_lane_enters(l, i)`;
  - `rises(drv_motion_straight_through_region(x, i; p.heading_since_step_carla_scene_graph, p.straight_through_max_heading_change))`. This judges the act once, when it is recognised at the exit.
  - `since(not rises(rel_occupies(x, i)), rel_occupies(x, l))`. This means the footprint overlapped `l` at some observation from the latest entry into `i` (the declared onset) up to the exit. The search into the past stops at that entry.

## Choices the node left open
- **Nesting order:** the highway quantifier encloses the lane quantifier, which is the order the record's applicability states. I declared no narrowings of my own.
- **Witness window:** each witness judges `t ∈ [100 ms, end]`. At the first observation there is no previous one to read an exit or a rise against, so `rises` is truncated there.

## Witnesses
All traces are sampled every 50 ms, which equals the reading's step bound. Occupancy is computed from the overlap between the car's footprint and each region, so a car straddling two regions occupies both.

| Witness | Scene | Expected |
|---|---|---|
| forbid | Straight out of the single right turn lane | violated |
| blind | Same scene as forbid, with `kin.yaw_rate` masked | unknown |
| permit | A 90° right turn inside the intersection | compliant |
| idle | No turn lane | not applicable |
| branch_1 | Straight from the through lane | compliant |
| branch_2 | Two right turn lanes side by side, straight from the rightmost | not applicable |
| branch_3 | As branch_2, plus a single right turn lane on the westbound approach that the car never uses | compliant |

I added two witnesses of my own:
- **branch_2** shows that the left-neighbour test in the applicability matters.
- **branch_3** shows that the same test, repeated in the obligation, matters on its own.

## Why I finished
The gate returned OK on the first run.
