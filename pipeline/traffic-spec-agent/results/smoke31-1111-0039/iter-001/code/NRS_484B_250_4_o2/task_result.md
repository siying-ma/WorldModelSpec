# NRS_484B_250_4_o2 — task result

**Final verdict: OK** (7 witnesses, 12 names, composes NRS_484B_250_4_o1). 3 of 6 gate runs used.

## Gate runs

1. **WITNESS_FAIL**: forbid, permit, branch_2 and branch_3 were unknown (`absent_atom:st_lane_enters`), and branch_1 was not_applicable. Cause: `Build.scene` puts a user only in the region that holds its reference point. So at the entry, x was not in both its approach lane c and intersection i. The only remaining candidate carrier was i itself, for which `st_lane_enters i i` is unknown. Fix: the witnesses now derive occupancy from the body footprints (`bodyOccupancy`, the same overlap test as `TraceLint.completeOccupancy`), so a car entering i occupies both c and i.
2. **WITNESS_FAIL**: blind was unknown because of `st_lane_enters`, not the masked `rel.occupies`. Fix: in blind, signal d governs c instead of i. That makes the i-as-carrier candidate decided false, so only the masked occupancy is left undecided.
3. **OK**.

## How the rule is written

- Class: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability (s1, s2, s10, s9): some intersection i and travel region c satisfy all of the following:
  - `drv_motion_entering_region x i`;
  - `rel_occupies x c`;
  - `st_lane_enters c i`;
  - some `traffic_signal` d has (`dev_governs d i` or `dev_governs d c`) and `dev_inoperative d`.

  The whole is conjoined with `.rule "NRS_484B_250_4_o1" [("x","x")]` (composition as compliance).
- Obligation: for every i, c meeting that same selection (the entry, the carrier and the inoperative signal, written again in full), all three of these hold:
  1. (s12, s14) No vehicle y other than x occupies i.
  2. (s12, s13) No vehicle y other than x has a travel region c2 with `st_lane_enters c2 i` and x not on c2, where `since (y on c2 ∧ y not in i) (rises(halted x) ∧ x on c ∧ halted y ∧ ¬rises(halted y) ∧ y on c2)` holds. `halted` is `drv_motion_halted · [p.speed_resolution]`, and `halted y ∧ ¬rises(halted y)` is "halted here and at the observation before".
  3. (s11) No road user z other than x has `prim_closest_approach_within x z [p.immediate_hazard_gap]` together with `prim_closest_approach_distance x z [p.immediate_hazard_gap] < p.conflict_clearance`.

## Choices the node left open

- I added no narrowings: the record's obligation already states s13 and s14 exactly, and the narrowings on s2, s3, s11 and s12 are the record's own.
- The duty must hold for **every** selected (i, c) pair, following "the duty at each region selected".
- Witnesses:
  - **branch_1** (planned): a vehicle waits on the crossing approach, having stopped first. The signal here governs c, so the `dev_governs d c` disjunct is tested.
  - **branch_3** (added, violated): a pedestrian is predicted to conflict with x right after its entry. This tests the s11 standard on its own.
  - In forbid, y is inside i but moving away from x, so only conjunct (1) decides the verdict.
- All witnesses judge t = 1…12 s (`window`), because the entry has no observation before the first scene.

## Note for later sessions (not a defect of this node)

The intersection is itself a `travel_region`, but it never carries an approach record, so `st_lane_enters i i` is unknown rather than false. Any rule that quantifies a carrier over `travel_region` therefore has an undecided candidate (c = i) whenever x occupies i. This only matters where nothing else decides that candidate. Here it does not affect the decided witnesses, but it can mask a `blind` witness.

## Why I finished

The gate returned OK.
