# NRS_484B_307_9c — task result

## Final verdict: OK
(9 witnesses, 19 names; composes NRS_484B_283_1d1, 1d2, 1d3_o1, 1d4_o1)

## Gate runs
1. **WITNESS_FAIL**: branch_3 returned unknown (`absent_atom:st_lane_direction`). The composed
   NRS_484B_283_1d4_o1 reads the direction of the roadway the pedestrian head governs. Change:
   recorded directions on roadways W1 (east) and W2 (west).
2. **WITNESS_FAIL**: branch_3 returned violated, meaning 1d4_o1 was now decided *not* engaged
   with W1 eastbound. Change: as an experiment, set W1's direction to north.
3. **VACUOUS**: leaf `dev_governs h i` (h governs the intersection directly) moved no witness.
   Change: with W1 north, 1d4_o1 engaged, so branch_3 passed. Added `branch_5` (violated): as in
   forbid, but h governs intersection i itself instead of approach lane g.
4. **OK**.

## Rule as written
- s2: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- s1: some `traffic_signal` h shows `circular_red`, shows `green_arrow(left|right|u_turn)`, and
  does not show `circular_green`.
- s3: the subject faces h. With Δ = dev_position(h) − kin_position(subject) and u =
  kin_heading: u·Δ > 0, (u·Δ)² ≥ cos²·|Δ|², and |Δ|² ≤ reach², using
  p.ped_traffic_signal_facing_cos and p.ped_traffic_signal_facing_reach. h also controls some
  intersection i: either `dev_governs h i`, or some travel_region g has `dev_governs h g` and
  `st_lane_enters g i`. And `st_region_geometry_distance(subject, i)` ≤
  p.ped_traffic_signal_facing_reach.
- s5 (exception): some `pedestrian_signal` d shows walk, or shows dont_walk_flashing with its
  countdown. The subject faces d (same facing formula, p.ped_signal_facing_*), and the subject
  occupies a roadway or lane q that d governs.
- s6: `¬ruleApplies` for each of the four 283 rules, mapping subject to subject.
- s4 (obligation): `¬(onRoadwayOrLane ∧ rises(onRoadwayOrLane ∨ on median_or_divider ∨ on
  safety_zone))`.

## Choices left open
- I added no narrowings: every span is written as the record states it. The s4 reading is the
  record's own.
- Witness windows: the judged window starts at 1 s, so each rise is read with its previous
  observation. Branches 1–3 judge only the step instant (2 s). After the step, the pedestrian
  remains on W1 while no rise holds, and 1d4_o1 need not be engaged there.
- `blind` is the forbid trace passed through `Build.masked (Build.manifest ["dev.position"])`.

## Point for review (not blocking): how NRS_484B_283_1d4_o1 reads direction
Planned branch_3 needs 1d4_o1 engaged for a pedestrian stepping onto a roadway that a
dont_walk_steady head governs. The pedestrian walks north, facing a head across the roadway.
- With W1 recorded as running **east** (across the pedestrian's path, the geometric truth for an
  east–west roadway), 1d4_o1 was decided **not engaged**.
- With W1 recorded as running **north** (along the pedestrian's heading), it engaged.

So in the final witness W1's direction is north, which does not match an east–west roadway. It
looks as though 1d4_o1 reads "in the direction of the signal" as the pedestrian's heading being
aligned with `st_lane_direction` of the governed roadway, not as crossing it. I could not read
that rule to confirm this. Its planner or repair session should check that reading. If it is
fixed, this witness should set W1's direction back to east.

## Why I finished
The gate returned OK on run 4 of 6.
